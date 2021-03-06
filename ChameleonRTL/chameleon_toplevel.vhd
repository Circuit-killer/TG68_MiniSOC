-- -----------------------------------------------------------------------
--
-- Turbo Chameleon
--
-- Toplevel file for Turbo Chameleon 64
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity chameleon_toplevel is
	generic (
		resetCycles: integer := 131071
	);
	port (
-- Clocks
		clk8 : in std_logic;
		phi2_n : in std_logic;
		dotclock_n : in std_logic;

-- Bus
		romlh_n : in std_logic;
		ioef_n : in std_logic;

-- Buttons
		freeze_n : in std_logic;

-- MMC/SPI
		spi_miso : in std_logic;
		mmc_cd_n : in std_logic;
		mmc_wp : in std_logic;

-- MUX CPLD
		mux_clk : out std_logic;
		mux : out unsigned(3 downto 0);
		mux_d : out unsigned(3 downto 0);
		mux_q : in unsigned(3 downto 0);

-- USART
		usart_tx : in std_logic;
		usart_clk : in std_logic;
		usart_rts : in std_logic;
		usart_cts : in std_logic;

-- SDRam
		sdram_clk : out std_logic;
		sd_data : inout std_logic_vector(15 downto 0);
		sd_addr : out std_logic_vector(12 downto 0);
		sd_we_n : out std_logic;
		sd_ras_n : out std_logic;
		sd_cas_n : out std_logic;
		sd_ba_0 : out std_logic;
		sd_ba_1 : out std_logic;
		sd_ldqm : out std_logic;
		sd_udqm : out std_logic;

-- Video
		red : out unsigned(4 downto 0);
		grn : out unsigned(4 downto 0);
		blu : out unsigned(4 downto 0);
		nHSync : buffer std_logic;
		nVSync : buffer std_logic;

-- Audio
		sigmaL : out std_logic;
		sigmaR : out std_logic
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of chameleon_toplevel is
	
-- System clocks
	signal clk : std_logic;

	signal reset_button_n : std_logic;
	
-- Global signals
	signal reset : std_logic;
	
-- MUX
	signal mux_clk_reg : std_logic := '0';
	signal mux_reg : unsigned(3 downto 0) := (others => '1');
	signal mux_d_reg : unsigned(3 downto 0) := (others => '1');
	signal mux_d_regd : unsigned(3 downto 0) := (others => '1');
	signal mux_regd : unsigned(3 downto 0) := (others => '1');

-- LEDs
	signal led_green : std_logic;
	signal led_red : std_logic;

-- PS/2 Keyboard
	signal ps2_keyboard_clk_in : std_logic;
	signal ps2_keyboard_dat_in : std_logic;
	signal ps2_keyboard_clk_out : std_logic;
	signal ps2_keyboard_dat_out : std_logic;

-- PS/2 Mouse
	signal ps2_mouse_clk_in: std_logic;
	signal ps2_mouse_dat_in: std_logic;
	signal ps2_mouse_clk_out: std_logic;
	signal ps2_mouse_dat_out: std_logic;

-- Video
	signal vga_r: unsigned(7 downto 0);
	signal vga_g: unsigned(7 downto 0);
	signal vga_b: unsigned(7 downto 0);
	signal vga_window : std_logic;

-- SDCARD
	signal spi_mosi : std_logic;
	signal spi_cs : std_logic;
	signal spi_clk : std_logic;
	
-- LEDS
	signal power_led : unsigned(5 downto 0);
	signal disk_led : unsigned(5 downto 0);
	signal net_led : unsigned(5 downto 0);
	signal odd_led : unsigned(5 downto 0);
	signal debugvalue : std_logic_vector(15 downto 0);

begin
	
	sd_addr(12)<='0'; -- FIXME - genericise the SDRAM size
	
-- -----------------------------------------------------------------------
-- Clocks and PLL
-- -----------------------------------------------------------------------
	pllInstance : entity work.PLL
		port map (
			inclk0 => clk8,
			c0 => clk,
			c1 => sdram_clk
		);

-- -----------------------------------------------------------------------
-- MUX CPLD
-- -----------------------------------------------------------------------
	-- MUX clock
	process(clk)
	begin
		if rising_edge(clk) then
			mux_clk_reg <= not mux_clk_reg;
		end if;
	end process;

	-- MUX read
	process(clk)
	begin
		if rising_edge(clk) then
			if mux_clk_reg = '1' then
				case mux_reg is
--				when X"6" =>
--					irq_n <= mux_q(2);
				when X"B" =>
					reset_button_n <= mux_q(1);
--					ir <= mux_q(3);
				when X"A" =>
--					vga_id <= mux_q;
				when X"E" =>
					ps2_keyboard_dat_in <= mux_q(0);
					ps2_keyboard_clk_in <= mux_q(1);
					ps2_mouse_dat_in <= mux_q(2);
					ps2_mouse_clk_in <= mux_q(3);
				when others =>
					null;
				end case;
			end if;
		end if;
	end process;

	-- MUX write
	process(clk)
	begin
		if rising_edge(clk) then
--			docking_ena <= '0';
			if mux_clk_reg = '1' then
				mux_reg<=X"C";
				mux_d_reg(3) <= '1'; -- usart_rx;	-- AMR transmit to Chameleons uC
				mux_d_reg(2) <= spi_cs;
				mux_d_reg(1) <= spi_mosi;
				mux_d_reg(0) <= spi_clk;

				case mux_reg is
				when X"7" =>
					mux_d_regd <= "1111";
					mux_regd <= X"6";
				when X"6" =>
					mux_d_regd <= "1111";
					mux_regd <= X"8";
				when X"8" =>
					mux_d_regd <= "1111";
					mux_regd <= X"A";
				when X"A" =>
					mux_d_regd <= "10" & led_green & led_red;
					mux_regd <= X"B";
				when X"B" =>
				   -- FIXME - RS232 serieal over IEC port?
--					mux_d_reg <= iec_reg;
					mux_d_regd <= "1111";
					mux_regd <= X"D";
--					docking_ena <= '1';
				when X"C" =>
					mux_reg <= mux_regd;
					mux_d_reg <= mux_d_regd;
				when X"D" =>
					mux_d_regd(0) <= ps2_keyboard_dat_out;
					mux_d_regd(1) <= ps2_keyboard_clk_out;
					mux_d_regd(2) <= ps2_mouse_dat_out;
					mux_d_regd(3) <= ps2_mouse_clk_out;
					mux_regd <= X"E";
				when X"E" =>
					mux_d_regd <= "1111";
					mux_regd <= X"7";
				when others =>
					mux_regd <= X"B";
					mux_d_regd <= "10" & led_green & led_red;
				end case;

			end if;
		end if;
	end process;
	
	mux_clk <= mux_clk_reg;
	mux_d <= mux_d_reg;
	mux <= mux_reg;
	
	power_led(5 downto 2)<=unsigned(debugvalue(15 downto 12));
	disk_led(5 downto 2)<=unsigned(debugvalue(11 downto 8));
	net_led(5 downto 2)<=unsigned(debugvalue(7 downto 4));
	odd_led(5 downto 2)<=unsigned(debugvalue(3 downto 0));


	myreset : entity work.poweronreset
		port map(
			clk => clk,
			reset_button => freeze_n,
			reset_out => reset
		);

	mydither : entity work.video_vga_dither
		generic map(
			outbits => 5
		)
		port map(
			clk=>clk,
			hsync=>nHSync,
			vsync=>nVSync,
			vid_ena=>vga_window,
			iRed => vga_r,
			iGreen => vga_g,
			iBlue => vga_b,
			oRed => red,
			oGreen => grn,
			oBlue => blu
		);
	
	mytg68test : entity work.TG68Test
		generic map(
			sdram_rows => 12,
			sdram_cols => 9,
			sysclk_frequency => 1000,
			spi_maxspeed => 16
		)
		port map(
			clk => clk,
			reset_in => reset,
			
			switches => (others =>'0'),
			
			-- SDRAM
			sdr_addr => sd_addr(11 downto 0),
			sdr_data(15 downto 0) => sd_data,
			sdr_ba(1) => sd_ba_1,
			sdr_ba(0) => sd_ba_0,
			sdr_cke => open, -- sd_cke,
			sdr_dqm(1) => sd_udqm,
			sdr_dqm(0) => sd_ldqm,
			sdr_cs => open,
			sdr_we => sd_we_n,
			sdr_cas => sd_cas_n,
			sdr_ras => sd_ras_n,
			
			-- VGA
			vga_red => vga_r,
			vga_green => vga_g,
			vga_blue => vga_b,
			
			vga_hsync => nHSync,
			vga_vsync => nVSync,
			
			vga_window => vga_window,

			-- UART
			rxd => '1', -- rs232_rxd,
			txd => open, -- rs232_txd,
			
			-- Misc
			pausecpu => '1',
			pausevga => '1',
			buttons => "111",
			
			-- PS/2
			ps2k_clk_in => ps2_keyboard_clk_in,
			ps2k_dat_in => ps2_keyboard_dat_in,
			ps2k_clk_out => ps2_keyboard_clk_out,
			ps2k_dat_out => ps2_keyboard_dat_out,
			ps2m_clk_in => ps2_mouse_clk_in,
			ps2m_dat_in => ps2_mouse_dat_in,
			ps2m_clk_out => ps2_mouse_clk_out,
			ps2m_dat_out => ps2_mouse_dat_out,
			
			-- SD Card interface
			sd_cs => spi_cs,
			sd_miso => spi_miso,
			sd_mosi => spi_mosi,
			sd_clk => spi_clk,
			
			-- Audio - FIXME abstract this out, too.
--			aud_l => aud_l,
--			aud_r => aud_r,
			
			-- LEDs
			counter => debugvalue
		);

end architecture;