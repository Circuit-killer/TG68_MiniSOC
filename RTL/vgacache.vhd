library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;


entity vgacache is
	port(
		clk : in std_logic;
		reset : in std_logic;

		idle : in std_logic; -- indicates that the beam is off-picture so we can attend to other channels.
		addrin : in std_logic_vector(23 downto 0); -- shared address input

		-- VGA interface
		setvga : in std_logic;	-- Set current address as VGA pointer
		vga_req : in std_logic;
		data_out : out std_logic_vector(15 downto 0);

		-- Sprite interface
		setsprite0 : in std_logic;	-- Set current address as Sprite0 pointer
		sprite0_out : out std_logic_vector(3 downto 0);
		sprite0_req : in std_logic;

		-- SDRAM interface
		addrout : buffer std_logic_vector(23 downto 0);
		data_in : in std_logic_vector(15 downto 0);
		fill : in std_logic; -- High when data is being written from SDRAM controller
		req : buffer std_logic; -- Request service from SDRAM controller
		lowpri : out std_logic -- indicate to SDRAM that immediate response is not vital.
	);
end entity;

architecture rtl of vgacache is

signal sprite0addr : std_logic_vector(23 downto 0);
signal sprite0buf : std_logic_vector(63 downto 0);
signal sprite0pending : std_logic;
signal sprite0fill : std_logic;
signal spritecounter : unsigned(3 downto 0) := "0000";

signal framebufferaddr : std_logic_vector(23 downto 0);
signal buf1 : std_logic_vector(63 downto 0);
signal buf2 : std_logic_vector(63 downto 0);
signal buf3 : std_logic_vector(63 downto 0);
signal incounter : unsigned(1 downto 0);
signal outcounter : unsigned(1 downto 0);
signal preloadcounter : unsigned(1 downto 0);
signal bufdone : std_logic;

type cachestates is (preload, preload2, preload3, preload4, run);
signal cachestate : cachestates;

begin

	process(clk)
	begin

		if reset='0' then
			incounter<="00";
			outcounter<="00";
			cachestate<=run;
			sprite0fill<='0';
		elsif rising_edge(clk) then

			if setvga='1' then	-- Set the framebuffer address and start preloading data...
				outcounter<="00";
				addrout<=addrin;
				framebufferaddr<=addrin;
				cachestate<=preload;
				req<='1';
			end if;
			
			if setsprite0='1' then
				sprite0addr<=addrin;
			end if;

			case cachestate is
				when preload =>
					if fill='1' then
						cachestate<=preload2;
					end if;
				when preload2 => 		-- Once we've received a burst, pretend the buffer has been
					if fill='0' then	-- drained, to trigger the next burst read.
						cachestate<=preload3;
						bufdone<='1';
					end if;
					
				when preload3 =>		-- once the next burst starts, we can be sure that buf2 contains
					if fill='1' then 	-- valid data, so copy it to buf1...
						buf1<=buf2;
						cachestate<=preload4;
					end if;

				when preload4 =>		-- Once again pretend the main buffer has been drained,
					if fill='0' then 	-- and we're good to go.
						bufdone<='1';
						cachestate<=run;
					end if;

				when run =>
					if sprite0_req='1' then
						sprite0_out<=sprite0buf(63 downto 60);
						sprite0buf<=sprite0buf(59 downto 0) & "0000";
						if spritecounter="0000" then
							sprite0pending<='1';
						end if;
						spritecounter<=spritecounter+1;
					end if;
					if vga_req='1' then
						case outcounter is
							when "00" =>
								data_out<=buf1(63 downto 48);
							when "01" =>
								data_out<=buf1(47 downto 32);
							when "10" =>
								data_out<=buf1(31 downto 16);
							when "11" =>
								data_out<=buf1(15 downto 0);
								bufdone<='1';
								buf1<=buf2;
						end case;
						outcounter<=outcounter+1;
					end if;
				when others =>
					null;
			end case;

			if fill='1' then
				if sprite0fill='1' then -- Are we currently receiving data from SDRAM?	
					case incounter is
						when "00" =>
							sprite0addr<=std_logic_vector(unsigned(sprite0addr)+8);
							req<='0';
							sprite0buf(63 downto 48)<=data_in;
						when "01" =>
							sprite0buf(47 downto 32)<=data_in;
						when "10" =>
							sprite0buf(31 downto 16)<=data_in;
						when "11" =>
							sprite0buf(15 downto 0)<=data_in;
							sprite0fill<='0';
					end case;
				else
					case incounter is
						when "00" =>
							framebufferaddr<=std_logic_vector(unsigned(framebufferaddr)+8);
							req<='0';
							buf3(63 downto 48)<=data_in;
						when "01" =>
							buf3(47 downto 32)<=data_in;
						when "10" =>
							buf3(31 downto 16)<=data_in;
						when "11" =>
							buf3(15 downto 0)<=data_in;
					end case;
				end if;
				incounter<=incounter+1;
			elsif bufdone='1' and req='0' then
				buf2<=buf3;
				bufdone<='0';
				addrout<=framebufferaddr;
				req<='1';
			elsif idle='1' and sprite0pending='1' and req='0' then
				addrout<=sprite0addr;
				req<='1';
				sprite0fill<='1';
				sprite0pending<='0';
				lowpri<='1';
			end if;
			
			if idle='0' then
				lowpri<='0';
			end if;
		end if;
	end process;
end architecture;
