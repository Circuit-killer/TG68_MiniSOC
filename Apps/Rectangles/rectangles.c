#include "vga.h"
#include "ints.h"
#include "uart.h"

short *FrameBuffer;

extern short pen;
extern void DrawIteration();

static short framecount=0;

void vblank_int()
{
	int yoff;
	framecount++;
	if(framecount==959)
		framecount=0;
	if(framecount>=480)
		yoff=959-framecount;
	else
		yoff=framecount;
	HW_VGA_L(FRAMEBUFFERPTR)=(unsigned long)(&FrameBuffer[yoff*640]);
}


int main(int argc,char **argv)
{
	unsigned char *fbptr;

	SetSprite();

	FrameBuffer=(short *)0x10000;
	HW_VGA_L(FRAMEBUFFERPTR)=FrameBuffer;

	EnableInterrupts();

	SetIntHandler(VGA_INT_VBLANK,&vblank_int);

	while(1)
	{
		DrawIteration();
	}
}

