
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

void SetSprite()
{
	HW_VGA_L(SP0PTR)=(unsigned long)StandardPointer;
}