library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

library work;
use work.DMACache_pkg.ALL;
use work.DMACache_config.ALL;


-- VGA controller
-- a module to handle VGA output

-- Self-contained, must generate timings
-- Programmable, must provide hardware registers that will respond to
-- writes.  Registers will include:  (Decode a 4k chunk)

-- 0 / 2   Framebuffer Address - hi and low
--     4   Even row modulo
--     6   Odd row modulo (allows scandoubling)

--     8  HTotal
--     A  HSize (typically 640)
--     C  HBStart
--     E  HBStop

--    10  VTotal
--    12  VSize (typically 480)
--    14  VBStart
--    16  VBStop

--    18  Control:
--     0  Visible
-- 3...1  Clocks per pixel
--     7  Character overlay on/off

--   Character buffer (2048 bytes)


-- Present the following signals to the SOC:
--	clk : in std_logic;
--	reset : in std_logic;

--	reg_addr_in : in std_logic_vector(10 downto 0);
--	reg_rw : std_logic;
--	reg_uds : std_logic;	-- only affects char buffer
--	reg_lds : std_logic;

	--		reqin : in std_logic;  -- now generated by VGA module
	--		data_out : out std_logic_vector(15 downto 0); -- now used internally

--		newframe : in std_logic; -- 
--		addrout : buffer std_logic_vector(23 downto 0); -- to SDRAM
--		data_in : in std_logic_vector(15 downto 0);	-- from SDRAM
--		fill : in std_logic; -- High when data is being written from SDRAM controller
--		req : buffer std_logic -- Request service from SDRAM controller

--		hsync : std_logic -- to monitor
--		vsync : std_logic -- to monitor
--		red : std_logic_vector(4 downto 0);		-- 16-bit 5-6-5 output
--		green : std_logic_vector(5 downto 0);
--		blue : std_logic_vector(4 downto 0);


-- FIXME - make address bus 32 bits wide.

entity vga_controller is
  generic (
		sysclk_frequency : integer := 1000 -- Sysclk frequency * 10
		);
  port (
		clk : in std_logic;
		reset : in std_logic;

		reg_addr_in : in std_logic_vector(11 downto 0); -- from host CPU
		reg_data_in: in std_logic_vector(15 downto 0);
		reg_data_out: out std_logic_vector(15 downto 0);
		reg_rw : in std_logic;
		reg_uds : in std_logic;
		reg_lds : in std_logic;
		reg_dtack : out std_logic;	-- Needed for char ram access.
		reg_req : in std_logic;

		dma_data : in std_logic_vector(15 downto 0);
		vgachannel_fromhost : out DMAChannel_FromHost;
		vgachannel_tohost : in DMAChannel_ToHost;
		spr0channel_fromhost : out DMAChannel_FromHost;
		spr0channel_tohost : in DMAChannel_ToHost;
		
		sdr_refresh : out std_logic;

		vblank_int : out std_logic;
		hsync : out std_logic; -- to monitor
		vsync : out std_logic; -- to monitor
		red : out unsigned(7 downto 0);		-- Allow for 8bpp even if we
		green : out unsigned(7 downto 0);	-- only currently support 16-bit
		blue : out unsigned(7 downto 0);		-- 5-6-5 output
		vga_window : out std_logic	-- '1' during the display window
	);
end entity;
	
architecture rtl of vga_controller is
	constant vgaticks : integer := (sysclk_frequency/250)-1;
	signal vga_pointer : std_logic_vector(31 downto 0);
	
	signal vgasetaddr : std_logic;
	signal spr0setaddr : std_logic;

	signal framebuffer_pointer : std_logic_vector(31 downto 0) := X"00100000";
	signal hsize : unsigned(11 downto 0) := TO_UNSIGNED(640,12);
	signal htotal : unsigned(11 downto 0) := TO_UNSIGNED(800,12);
	signal hbstart : unsigned(11 downto 0) := TO_UNSIGNED(656,12);
	signal hbstop : unsigned(11 downto 0) := TO_UNSIGNED(752,12);
	signal vsize : unsigned(11 downto 0) := TO_UNSIGNED(480,12);
	signal vtotal : unsigned(11 downto 0) := TO_UNSIGNED(525,12);
	signal vbstart : unsigned(11 downto 0) := TO_UNSIGNED(500,12);
	signal vbstop : unsigned(11 downto 0) := TO_UNSIGNED(502,12);
	
	signal clocks_per_pixel : unsigned(2 downto 0):="011";

	signal sprite0_pointer : std_logic_vector(31 downto 0) := X"00000000";
	signal sprite0_xpos : unsigned(11 downto 0);
	signal sprite0_ypos : unsigned(11 downto 0);
	signal sprite0_data : std_logic_vector(15 downto 0);
	signal sprite0_data_buf : std_logic_vector(15 downto 0); -- Prefetch buffer
	signal sprite0_counter : unsigned(1 downto 0);

	signal sprite_col : std_logic_vector(3 downto 0);
	
	signal currentX : unsigned(11 downto 0);
	signal currentY : unsigned(11 downto 0);
	signal end_of_pixel : std_logic;
	signal vga_newframe : std_logic;
	signal vgadata : std_logic_vector(15 downto 0);


	signal chargen_addr : std_logic_vector(10 downto 0);
	signal chargen_datain : std_logic_vector(7 downto 0);
	signal chargen_dataout : std_logic_vector(7 downto 0);
	signal chargen_window : std_logic := '0';
	signal chargen_pixel : std_logic := '0';
	signal chargen_rw : std_logic :='1';
	signal chargen_overlay : std_logic :='1';
	
	signal vga_window_d2 : std_logic;
	signal vga_window_d : std_logic;

	type charramstates is (writeupperbyte,writeupperbyte1,readupperbyte1,readupperbyte2,
									writelowerbyte,writelowerbyte1,readlowerbyte1,readlowerbyte2);
	signal charramstate : charramstates;			

	signal req_d : std_logic;
	signal req_e : std_logic;
	
begin

	-- Need this to be readable
	spr0channel_fromhost.setaddr<=spr0setaddr;
	vgachannel_fromhost.setaddr<=vgasetaddr;

	-- Detect the leading edge of the req pulse.
	process(clk)
	begin
		req_e<=reg_req and not req_d;
		if rising_edge(clk) then
			req_d<=reg_req;
		end if;
	end process;

	myVgaMaster : entity work.video_vga_master
		generic map (
			clkDivBits => 3
		)
		port map (
			clk => clk,
			clkDiv => clocks_per_pixel,

			hSync => hsync,
			vSync => vsync,

			endOfPixel => end_of_pixel,
			endOfLine => open,
			endOfFrame => open,
			currentX => currentX,
			currentY => currentY,

			-- Setup 640x480@60hz needs ~25 Mhz
			hSyncPol => '0',
			vSyncPol => '0',
			xSize => htotal,
			ySize => vtotal,
			xSyncFr => hbstart,
			xSyncTo => hbstop,
			ySyncFr => vbstart, -- Sync pulse 2
			ySyncTo => vbstop
		);		


	mychargen : entity work.charactergenerator
		generic map (
			xstart => 16,
			xstop => 624,
			ystart => 256,
			ystop => 464,
			border => 7
		)
		port map (
			clk => clk,
			reset => reset,
			xpos => currentX(9 downto 0),
			ypos => currentY(9 downto 0),
			pixel_clock => end_of_pixel,
			pixel => chargen_pixel,
			window => chargen_window,
			-- Char RAM access.
			addrin => chargen_addr,
			datain => chargen_datain,
			dataout => chargen_dataout,
			rw => chargen_rw
		);

	-- Handle CPU access to hardware registers
	
	process(clk,reset)
	begin
		if reset='0' then
			htotal <= TO_UNSIGNED(800,12);
			vtotal <= TO_UNSIGNED(525,12);
			hbstart <= TO_UNSIGNED(656,12);
			hbstop <= TO_UNSIGNED(752,12);
			vbstart <= TO_UNSIGNED(500,12);
			vbstop <= TO_UNSIGNED(502,12);
			clocks_per_pixel <= TO_UNSIGNED(vgaticks,3);
			reg_data_out<=X"0000";
			sprite0_xpos<=X"000";
			sprite0_ypos<=X"000";
			chargen_addr<="00000000000";
			chargen_overlay<='1';
		elsif rising_edge(clk) then
			reg_dtack<='1';
			chargen_rw<='1';

			charramstate<=writeupperbyte; -- Reset state machine.
			if reg_addr_in(11)='1' then	-- Character RAM access
				-- Need to deal with both word and byte reads/writes.
				-- We do one read and one write to both bytes on a 4-step cycle.
				case charramstate is
					when writeupperbyte =>
						if req_e='1' then
							chargen_addr<=reg_addr_in(10 downto 1) & '0';	-- Upper byte
							chargen_datain<=reg_data_in(15 downto 8);
							if reg_rw='0' and reg_uds='0' then
								chargen_rw<='0';
							end if;
							charramstate<=writeupperbyte1;
						end if;
					when writeupperbyte1 =>
						charramstate<=readupperbyte1;
					when readupperbyte1 =>
						charramstate<=readupperbyte2;	-- delay for data
					when readupperbyte2 =>			
						reg_data_out(15 downto 8)<=chargen_dataout;
						charramstate<=writelowerbyte;
					when writelowerbyte =>
						chargen_addr<=reg_addr_in(10 downto 1) & '1';	-- lower byte
						chargen_datain<=reg_data_in(7 downto 0);
						if reg_rw='0' and reg_lds='0' then
							chargen_rw<='0';
						end if;
						charramstate<=writelowerbyte1;
					when writelowerbyte1 =>
						charramstate<=readlowerbyte1;
					when readlowerbyte1 =>
						charramstate<=readlowerbyte2;	-- delay for data
					when readlowerbyte2 =>
						reg_data_out(7 downto 0)<=chargen_dataout;
						reg_dtack<='0';
				end case;
			elsif req_e='1' then
				case reg_addr_in is
					when X"000" =>
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							framebuffer_pointer(31 downto 16) <= reg_data_in;
						end if;
					when X"002" =>
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							framebuffer_pointer(15 downto 0) <= reg_data_in;
						end if;
					when X"008" => -- htotal
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							htotal<=unsigned(reg_data_in(11 downto 0));
						end if;				
					when X"00A" => -- hsize
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							hsize<=unsigned(reg_data_in(11 downto 0));
						end if;				
					when X"00C" => -- hbstart
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							hbstart<=unsigned(reg_data_in(11 downto 0));
						end if;
					when X"00E" => -- hbstop
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							hbstop<=unsigned(reg_data_in(11 downto 0));
						end if;
					when X"010" => -- vtotal
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							vtotal<=unsigned(reg_data_in(11 downto 0));
						end if;				
					when X"012" => -- vsize
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							vsize<=unsigned(reg_data_in(11 downto 0));
						end if;				
					when X"014" => -- vbstart
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							vbstart<=unsigned(reg_data_in(11 downto 0));
						end if;				
					when X"016" => -- vbstop
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							vbstop<=unsigned(reg_data_in(11 downto 0));
						end if;				
					when X"018" => -- Control register
						if reg_rw='0' then
							chargen_overlay<=reg_data_in(7);
							clocks_per_pixel<=unsigned(reg_data_in(3 downto 1));
						end if;
					when X"100" =>
						if reg_rw='0' then
							sprite0_pointer(31 downto 16) <= reg_data_in;
						end if;
					when X"102" =>
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							sprite0_pointer(15 downto 0) <= reg_data_in;
						end if;
					when X"104" =>
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							sprite0_xpos <= unsigned(reg_data_in(11 downto 0));
						end if;
					when X"106" =>
						if reg_rw='0' and reg_uds='0' and reg_lds='0' then
							sprite0_ypos <= unsigned(reg_data_in(11 downto 0));
						end if;
					when others =>
						reg_data_out<=X"0000";
				end case;
				reg_dtack<='0';
			end if;

-- Not yet implemented:
--     4   Even row modulo
--     6   Odd row modulo (allows scandoubling)

		end if;
	end process;

	
	-- Sprite positions
	process(clk, reset, currentX, currentY)
	begin
		if rising_edge(clk) then
			spr0channel_fromhost.req<='0';
			if currentX>=sprite0_xpos and currentX-sprite0_xpos<16
						and currentY>=sprite0_ypos and currentY-sprite0_ypos<16 then	
				if end_of_pixel='1' then
					case sprite0_counter is
						when "11" =>
							-- Read the first pixel from the buffer, copy to the sprite proper.
							-- Request the next word of sprite data.
							spr0channel_fromhost.req<='1';
							sprite0_data(11 downto 0) <= sprite0_data_buf(11 downto 0);
							sprite_col<=sprite0_data_buf(15 downto 12);
							sprite0_counter<="10";
						when "10" =>
							sprite_col<=sprite0_data(11 downto 8);
							sprite0_counter<="01";
						when "01" =>
							sprite_col<=sprite0_data(7 downto 4);
							sprite0_counter<="00";
						when "00" =>
							sprite_col<=sprite0_data(3 downto 0);
							sprite0_counter<="11";
						when others =>
							null;
					end case;
				end if;
			else
				sprite_col<="0000";
--				sprite0_counter<="11";
			end if;

--			Prefetch first word.
			if spr0setaddr='1' then -- spr0channel_fromhost.setaddr='1' then
				spr0channel_fromhost.req<='1';
				sprite0_counter<="11";
			end if;
			
			if spr0channel_tohost.valid='1' then
				sprite0_data_buf<=dma_data;
			end if;

		end if;
	end process;
	
	
	process(clk, reset,currentX, currentY)
	begin
		if rising_edge(clk) then
			sdr_refresh <='0';
			if end_of_pixel='1' and currentX=hsize then
				sdr_refresh<='1';
			end if;
		end if;
		
		if rising_edge(clk) then
			vblank_int<='0';
			vgachannel_fromhost.req<='0';
			vga_newframe<='0';
			vgachannel_fromhost.req<='0';
			vgasetaddr<='0';
			vgachannel_fromhost.setreqlen<='0';
			spr0setaddr<='0';
			spr0channel_fromhost.setreqlen<='0';	

			vga_window<=vga_window_d2;
			vga_window_d2<=vga_window_d;
			
			if(vgachannel_tohost.valid='1') then
				vgadata<=dma_data;
			end if;

			if end_of_pixel='1' then
--				sdr_reservebank<='1';

				if currentX<hsize and currentY<vsize then
					vga_window_d<='1';
					-- Request next pixel from VGA cache
					vgachannel_fromhost.req<='1';

					if sprite_col(3)='1' then
						red <= (others => sprite_col(2));
					elsif chargen_pixel='1' then
						red <= "11111111";
					elsif chargen_window='1' then
						red <= unsigned('0'&vgadata(15 downto 11)&"00");
					else
						red <= unsigned(vgadata(15 downto 11)&"000");
					end if;

					if sprite_col(3)='1' then
						green <= (others=>sprite_col(1));
					elsif chargen_pixel='1' then
						green <= "11111111";
					elsif chargen_window='1' then
						green <= unsigned('0'&vgadata(10 downto 6)&"00");
					else
						green <= unsigned(vgadata(10 downto 5)&"00");
					end if;

					if sprite_col(3)='1' then
						blue <= (others=>sprite_col(0));
					elsif chargen_pixel='1' then
						blue <= "11111111";
					elsif chargen_window='1' then
						blue <= unsigned('0'&vgadata(4 downto 0)&"00");
					else
						blue <= unsigned(vgadata(4 downto 0)&"000");
					end if;

				else
					vga_window_d<='0';
					
					-- New frame...
					if currentY=vsize and currentX=0 then
						vblank_int<='1';
--					end if;

					-- Last line of VBLANK - update DMA pointers
--					if currentY=vtotal then
--							if currentX=0 then
								vgachannel_fromhost.addr<=framebuffer_pointer;
								vgasetaddr<='1';
--							elsif currentX=1 then
								spr0channel_fromhost.addr<=sprite0_pointer;
								spr0setaddr<='1';
								spr0channel_fromhost.reqlen<=TO_UNSIGNED(64,16);
								spr0channel_fromhost.setreqlen<='1';
--							end if;
					end if;

					if currentY=vtotal or currentY<vsize then
						if currentX=hsize then	-- Signal to SDRAM controller that we're
							vgachannel_fromhost.reqlen<=(others=>'0');
							vgachannel_fromhost.reqlen(11 downto 0)<=hsize;
							vgachannel_fromhost.setreqlen<='1';
--						elsif currentX=3 then
--							spr0channel_fromhost.reqlen<=TO_UNSIGNED(4,16);
--							spr0channel_fromhost.setreqlen<='1';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
		
end architecture;