
#include "vga.h"


/*
unsigned long SpriteData[]=
{
	0xCF000000,0x00000000,
	0x8CFFF000,0x00000000,
	0x08CCFFF0,0x00000000,
	0x08CCCCFF,0xFF000000,
	0x088CCCCC,0xCFFF0000,
	0x008CCCCC,0xCCC80000,
	0x0088CCCC,0xCC800000,
	0x0008CCCC,0xCF000000,
	0x0008CCCC,0xCCF00000,
	0x00088CC8,0xCCCF0000,
	0x00008C80,0x8CCCF000,
	0x00008800,0x08CCCF00,
	0x00000000,0x008CCCF0,
	0x00000000,0x0008CCC8,
	0x00000000,0x00008C80,
	0x00000000,0x00000800
};
*/

extern unsigned long StandardPointer[];
static short screenmode=FLAG_VGA_CONTROL_OVERLAY | FLAG_VGA_CONTROL_VISIBLE | MASK_VGA_CONTROL_PIXELCLOCK_4;

void VGA_SetScreenMode(enum VGA_ScreenModes mode)
{
	switch(mode)
	{
		case MODE_640_480:
			HW_VGA(REG_VGA_HTOTAL)=800;
			HW_VGA(REG_VGA_HSIZE)=640;
			HW_VGA(REG_VGA_HBSTART)=656;
			HW_VGA(REG_VGA_HBSTOP)=752;
			HW_VGA(REG_VGA_VTOTAL)=525;
			HW_VGA(REG_VGA_VSIZE)=480;
			HW_VGA(REG_VGA_VBSTART)=500;
			HW_VGA(REG_VGA_VBSTOP)=502;
			screenmode=(screenmode&(FLAG_VGA_CONTROL_OVERLAY | FLAG_VGA_CONTROL_VISIBLE)) | MASK_VGA_CONTROL_PIXELCLOCK_4;
			HW_VGA(REG_VGA_CONTROL)=screenmode;
			break;	

		case MODE_320_480:
			HW_VGA(REG_VGA_HTOTAL)=400;
			HW_VGA(REG_VGA_HSIZE)=320;
			HW_VGA(REG_VGA_HBSTART)=328;
			HW_VGA(REG_VGA_HBSTOP)=376;
			HW_VGA(REG_VGA_VTOTAL)=525;
			HW_VGA(REG_VGA_VSIZE)=480;
			HW_VGA(REG_VGA_VBSTART)=490;
			HW_VGA(REG_VGA_VBSTOP)=492;
			screenmode=(screenmode&(FLAG_VGA_CONTROL_OVERLAY | FLAG_VGA_CONTROL_VISIBLE)) | MASK_VGA_CONTROL_PIXELCLOCK_8;
			HW_VGA(REG_VGA_CONTROL)=screenmode;
			break;

		case MODE_800_600:
			HW_VGA(REG_VGA_HTOTAL)=1024;
			HW_VGA(REG_VGA_HSIZE)=800;
			HW_VGA(REG_VGA_HBSTART)=824;
			HW_VGA(REG_VGA_HBSTOP)=896;
			HW_VGA(REG_VGA_VTOTAL)=625;
			HW_VGA(REG_VGA_VSIZE)=600;
			HW_VGA(REG_VGA_VBSTART)=601;
			HW_VGA(REG_VGA_VBSTOP)=602;
			screenmode=(screenmode&(FLAG_VGA_CONTROL_OVERLAY | FLAG_VGA_CONTROL_VISIBLE)) | MASK_VGA_CONTROL_PIXELCLOCK_3;
			HW_VGA(REG_VGA_CONTROL)=screenmode;
		break;

		case MODE_800_600_72:
			HW_VGA(REG_VGA_HTOTAL)=1040;
			HW_VGA(REG_VGA_HSIZE)=800;
			HW_VGA(REG_VGA_HBSTART)=856;
			HW_VGA(REG_VGA_HBSTOP)=976;
			HW_VGA(REG_VGA_VTOTAL)=666;
			HW_VGA(REG_VGA_VSIZE)=600;
			HW_VGA(REG_VGA_VBSTART)=637;
			HW_VGA(REG_VGA_VBSTOP)=643;
			screenmode=(screenmode&(FLAG_VGA_CONTROL_OVERLAY | FLAG_VGA_CONTROL_VISIBLE)) | MASK_VGA_CONTROL_PIXELCLOCK_2;
			HW_VGA(REG_VGA_CONTROL)=screenmode;
		break;

		case MODE_768_576:
			HW_VGA(REG_VGA_HTOTAL)=976;
			HW_VGA(REG_VGA_HSIZE)=768;
			HW_VGA(REG_VGA_HBSTART)=792;
			HW_VGA(REG_VGA_HBSTOP)=872;
			HW_VGA(REG_VGA_VTOTAL)=597;
			HW_VGA(REG_VGA_VSIZE)=576;
			HW_VGA(REG_VGA_VBSTART)=577;
			HW_VGA(REG_VGA_VBSTOP)=580;
			screenmode=(screenmode&(FLAG_VGA_CONTROL_OVERLAY | FLAG_VGA_CONTROL_VISIBLE)) | MASK_VGA_CONTROL_PIXELCLOCK_3;
			HW_VGA(REG_VGA_CONTROL)=screenmode;
			break;
	}
}

void VGA_SetSprite()
{
	HW_VGA_L(SP0PTR)=(unsigned long)StandardPointer;
}

void VGA_ShowOverlay()
{
	screenmode|=FLAG_VGA_CONTROL_OVERLAY;
	HW_VGA(REG_VGA_CONTROL)=screenmode;
}

void VGA_HideOverlay()
{
	screenmode&=~FLAG_VGA_CONTROL_OVERLAY;
	HW_VGA(REG_VGA_CONTROL)=screenmode;
}

