// Toplevel port definitions taken from the DE1 default example code 

module DE1_Toplevel
	(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_24,						//	24 MHz
		CLOCK_27,						//	27 MHz
		CLOCK_50,						//	50 MHz
		EXT_CLOCK,						//	External Clock
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton[3:0]
		////////////////////	DPDT Switch		////////////////////
		SW,								//	Toggle Switch[9:0]
		////////////////////	7-SEG Dispaly	////////////////////
		HEX0,							//	Seven Segment Digit 0
		HEX1,							//	Seven Segment Digit 1
		HEX2,							//	Seven Segment Digit 2
		HEX3,							//	Seven Segment Digit 3
		////////////////////////	LED		////////////////////////
		LEDG,							//	LED Green[7:0]
		LEDR,							//	LED Red[9:0]
		////////////////////////	UART	////////////////////////
		UART_TXD,						//	UART Transmitter
		UART_RXD,						//	UART Receiver
		/////////////////////	SDRAM Interface		////////////////
		DRAM_DQ,						//	SDRAM Data bus 16 Bits
		DRAM_ADDR,						//	SDRAM Address bus 12 Bits
		DRAM_LDQM,						//	SDRAM Low-byte Data Mask 
		DRAM_UDQM,						//	SDRAM High-byte Data Mask
		DRAM_WE_N,						//	SDRAM Write Enable
		DRAM_CAS_N,						//	SDRAM Column Address Strobe
		DRAM_RAS_N,						//	SDRAM Row Address Strobe
		DRAM_CS_N,						//	SDRAM Chip Select
		DRAM_BA_0,						//	SDRAM Bank Address 0
		DRAM_BA_1,						//	SDRAM Bank Address 0
		DRAM_CLK,						//	SDRAM Clock
		DRAM_CKE,						//	SDRAM Clock Enable
		////////////////////	Flash Interface		////////////////
		FL_DQ,							//	FLASH Data bus 8 Bits
		FL_ADDR,						//	FLASH Address bus 22 Bits
		FL_WE_N,						//	FLASH Write Enable
		FL_RST_N,						//	FLASH Reset
		FL_OE_N,						//	FLASH Output Enable
		FL_CE_N,						//	FLASH Chip Enable
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		////////////////////	USB JTAG link	////////////////////
		TDI,  							// CPLD -> FPGA (data in)
		TCK,  							// CPLD -> FPGA (clk)
		TCS,  							// CPLD -> FPGA (CS)
	    TDO,  							// FPGA -> CPLD (data out)
		////////////////////	I2C		////////////////////////////
		I2C_SDAT,						//	I2C Data
		I2C_SCLK,						//	I2C Clock
		////////////////////	PS2		////////////////////////////
		PS2_DAT,						//	PS2 Data
		PS2_CLK,						//	PS2 Clock
		////////////////////	VGA		////////////////////////////
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_R,   						//	VGA Red[3:0]
		VGA_G,	 						//	VGA Green[3:0]
		VGA_B,  						//	VGA Blue[3:0]
		////////////////	Audio CODEC		////////////////////////
		AUD_ADCLRCK,					//	Audio CODEC ADC LR Clock
		AUD_ADCDAT,						//	Audio CODEC ADC Data
		AUD_DACLRCK,					//	Audio CODEC DAC LR Clock
		AUD_DACDAT,						//	Audio CODEC DAC Data
		AUD_BCLK,						//	Audio CODEC Bit-Stream Clock
		AUD_XCK,						//	Audio CODEC Chip Clock
		////////////////////	GPIO	////////////////////////////
		GPIO_0,							//	GPIO Connection 0
		GPIO_1							//	GPIO Connection 1
	);

////////////////////////	Clock Input	 	////////////////////////
input	[1:0]	CLOCK_24;				//	24 MHz
input	[1:0]	CLOCK_27;				//	27 MHz
input			CLOCK_50;				//	50 MHz
input			EXT_CLOCK;				//	External Clock
////////////////////////	Push Button		////////////////////////
input	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT Switch		////////////////////////
input	[9:0]	SW;						//	Toggle Switch[9:0]
////////////////////////	7-SEG Dispaly	////////////////////////
output	[6:0]	HEX0;					//	Seven Segment Digit 0
output	[6:0]	HEX1;					//	Seven Segment Digit 1
output	[6:0]	HEX2;					//	Seven Segment Digit 2
output	[6:0]	HEX3;					//	Seven Segment Digit 3
////////////////////////////	LED		////////////////////////////
output	[7:0]	LEDG;					//	LED Green[7:0]
output	[9:0]	LEDR;					//	LED Red[9:0]
////////////////////////////	UART	////////////////////////////
output			UART_TXD;				//	UART Transmitter
input			UART_RXD;				//	UART Receiver
///////////////////////		SDRAM Interface	////////////////////////
inout	[15:0]	DRAM_DQ;				//	SDRAM Data bus 16 Bits
output	[11:0]	DRAM_ADDR;				//	SDRAM Address bus 12 Bits
output			DRAM_LDQM;				//	SDRAM Low-byte Data Mask 
output			DRAM_UDQM;				//	SDRAM High-byte Data Mask
output			DRAM_WE_N;				//	SDRAM Write Enable
output			DRAM_CAS_N;				//	SDRAM Column Address Strobe
output			DRAM_RAS_N;				//	SDRAM Row Address Strobe
output			DRAM_CS_N;				//	SDRAM Chip Select
output			DRAM_BA_0;				//	SDRAM Bank Address 0
output			DRAM_BA_1;				//	SDRAM Bank Address 0
output			DRAM_CLK;				//	SDRAM Clock
output			DRAM_CKE;				//	SDRAM Clock Enable
////////////////////////	Flash Interface	////////////////////////
inout	[7:0]	FL_DQ;					//	FLASH Data bus 8 Bits
output	[21:0]	FL_ADDR;				//	FLASH Address bus 22 Bits
output			FL_WE_N;				//	FLASH Write Enable
output			FL_RST_N;				//	FLASH Reset
output			FL_OE_N;				//	FLASH Output Enable
output			FL_CE_N;				//	FLASH Chip Enable
////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask 
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable
////////////////////	SD Card Interface	////////////////////////
input          SD_DAT;     //  SD Card Data            - spi MISO
output         SD_DAT3;    //  SD Card Data 3          - spi CS
output         SD_CMD;     //  SD Card Command Signal  - spi MOSI
output         SD_CLK;     //  SD Card Clock           - spi CLK
////////////////////////	I2C		////////////////////////////////
inout			I2C_SDAT;				//	I2C Data
output			I2C_SCLK;				//	I2C Clock
////////////////////////	PS2		////////////////////////////////
inout		 	PS2_DAT;				//	PS2 Data
inout			PS2_CLK;				//	PS2 Clock
////////////////////	USB JTAG link	////////////////////////////
input  			TDI;					// CPLD -> FPGA (data in)
input  			TCK;					// CPLD -> FPGA (clk)
input  			TCS;					// CPLD -> FPGA (CS)
output 			TDO;					// FPGA -> CPLD (data out)
////////////////////////	VGA			////////////////////////////
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output	[3:0]	VGA_R;   				//	VGA Red[3:0]
output	[3:0]	VGA_G;	 				//	VGA Green[3:0]
output	[3:0]	VGA_B;   				//	VGA Blue[3:0]
////////////////////	Audio CODEC		////////////////////////////
output			AUD_ADCLRCK;			//	Audio CODEC ADC LR Clock
input			AUD_ADCDAT;				//	Audio CODEC ADC Data
output			AUD_DACLRCK;			//	Audio CODEC DAC LR Clock
output			AUD_DACDAT;				//	Audio CODEC DAC Data
inout			AUD_BCLK;				//	Audio CODEC Bit-Stream Clock
output			AUD_XCK;				//	Audio CODEC Chip Clock
////////////////////////	GPIO	////////////////////////////////
inout	[35:0]	GPIO_0;					//	GPIO Connection 0
inout	[35:0]	GPIO_1;					//	GPIO Connection 1
////////////////////////////////////////////////////////////////////

//	All inout port turn to tri-state
assign	DRAM_DQ		=	16'hzzzz;
assign	FL_DQ		=	8'hzz;
assign	SRAM_DQ		=	16'hzzzz;
// assign	SD_DAT		=	1'bz;  -- input only in SPI mode
assign	I2C_SDAT	=	1'bz;
assign	GPIO_0		=	36'hzzzzzzzzz;
assign	GPIO_1		=	36'hzzzzzzzzz;
//	Audio

wire	[15:0]	mSEG7_DIG;
reg		[27:0]	Cont;
reg		[9:0]	mLEDR;
reg				ST;


// PS/2 keyboard
wire PS2K_DAT_IN=PS2_DAT;
wire PS2K_DAT_OUT;
assign PS2_DAT = (PS2K_DAT_OUT == 1'b0) ? 1'b0 : 1'bz;
wire PS2K_CLK_IN=PS2_CLK;
wire PS2K_CLK_OUT;
assign PS2_CLK = (PS2K_CLK_OUT == 1'b0) ? 1'b0 : 1'bz;

// PS/2 Mouse
wire PS2M_DAT_IN=GPIO_1[19];
wire PS2M_DAT_OUT;
assign GPIO_1[19] = (PS2M_DAT_OUT == 1'b0) ? 1'b0 : 1'bz;
wire PS2M_CLK_IN=GPIO_1[18];
wire PS2M_CLK_OUT;
assign GPIO_1[18] = (PS2M_CLK_OUT == 1'b0) ? 1'b0 : 1'bz;


always@(posedge CLOCK_50)		Cont	<=	Cont+1'b1;

// assign	mSEG7_DIG	=	{	Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24]	};

SEG7_LUT_4 			u0	(	HEX0,HEX1,HEX2,HEX3,mSEG7_DIG );

TG68Test myTG68Test
(	
	.clk50(CLOCK_50),
	.src({SW[9:5],SW[5],SW[5],SW[4],SW[4],SW[4],SW[3],SW[3],SW[3:0]}),
	.reset_in(!SW[0]^KEY[0]),
	.pausecpu(SW[1]),
	.pausevga(SW[2]),
	.buttons(KEY[3:1]),
	.counter(mSEG7_DIG),
	
	// video
	.vga_hsync(VGA_HS),
	.vga_vsync(VGA_VS),
	.vga_red(VGA_R),
	.vga_green(VGA_G),
	.vga_blue(VGA_B),
	
	// sdram
	.sdr_data(DRAM_DQ),
	.sdr_addr(DRAM_ADDR),
	.sdr_dqm({DRAM_UDQM,DRAM_LDQM}),
	.sdr_we(DRAM_WE_N),
	.sdr_cas(DRAM_CAS_N),
	.sdr_ras(DRAM_RAS_N),
	.sdr_cs(DRAM_CS_N),
	.sdr_ba({DRAM_BA_1,DRAM_BA_0}),
	.sdr_clk(DRAM_CLK),
	.sdr_clkena(DRAM_CKE),

	// uart
	.rxd(UART_RXD),
	.txd(UART_TXD),
	
	// PS/2
	.ps2k_clk_in(PS2K_CLK_IN),
	.ps2k_dat_in(PS2K_DAT_IN),
	.ps2k_clk_out(PS2K_CLK_OUT),
	.ps2k_dat_out(PS2K_DAT_OUT),
	.ps2m_clk_in(PS2M_CLK_IN),
	.ps2m_dat_in(PS2M_DAT_IN),
	.ps2m_clk_out(PS2M_CLK_OUT),
	.ps2m_dat_out(PS2M_DAT_OUT),
	// SD card
	.sd_cs(SD_DAT3),
	.sd_miso(SD_DAT),
	.sd_mosi(SD_CMD),
	.sd_clk(SD_CLK)
);

endmodule
