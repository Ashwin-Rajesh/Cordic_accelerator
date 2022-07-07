/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"

#define CNTRL_START        0
#define CNTRL_STOP         1
#define CNTRL_ROT_MODE     2
#define CNTRL_ROT_SYS      3
#define CNTRL_ERR_INT_EN   4
#define CNTRL_RSLT_INT_EN  5
#define CNTRL_OV_ST_EN     6
#define CNTRL_Z_OV_ST_EN   7
#define CNTRL_ITER_L       8
#define CNTRL_ITER_H       12
#define CNTRL_Z_OV_EN      13

#define FLAG_READY         16
#define FLAG_INP_ERR       17
#define FLAG_OV_ERR        18
#define FLAG_X_OV_ERR      19
#define FLAG_Y_OV_ERR      20
#define FLAG_Z_OV_ERR      21
#define FLAG_ELAPS_ITER_L  22
#define FLAG_ELAPS_ITER_H  26
#define FLAG_OV_ITER_L     27
#define FLAG_OV_ITER_H     31

#define REG_XINPUT 	0x43C00000
#define REG_YINPUT 	0x43C00004
#define REG_ZINPUT 	0x43C00008
#define REG_XRESULT 0x43C0000C
#define REG_YRESULT 0x43C00010
#define REG_ZRESULT 0x43C00014
#define REG_CNTRL   0x43C00018

typedef struct ControlRegister {
	  bool start				= 0;
	  bool stop					= 0;
	  bool rotationMode			= 0;
	  bool rotationSystem       = 0;
	  bool errorIntEn           = 1;
	  bool resultIntEn          = 1;
	  bool overflowStopEn       = 1;
	  bool zOverflowStopEn      = 1;
	  int iterCount             = 31;
	  bool zOverflowReportEn    = 1;

	  bool ready                = 1;
	  bool inpError             = 0;
	  bool overflowError        = 0;
	  bool xOverflow            = 0;
	  bool yOverflow            = 0;
	  bool zOverflow            = 0;

	  int iterElapsed           = 0;
	  int overflowIter          = 0;

	u32 getControl() {
		u32 temp = 0;

		if(start)
			temp = temp | 1 << 0;
		if(stop)
			temp = temp | 1 << 1;
		if(rotationMode)
			temp = temp | 1 << 2;
		if(rotationSystem)
			temp = temp | 1 << 3;
		if(errorIntEn)
			temp = temp | 1 << 4;
		if(resultIntEn)
			temp = temp | 1 << 5;
		if(overflowStopEn)
			temp = temp | 1 << 6;
		if(zOverflowStopEn)
			temp = temp | 1 << 7;
		temp = temp | (iterCount & 0x1F) << 8;
		if(zOverflowReportEn)
			temp = temp | 1 << 13;

		return temp;
	}

	void setFlags(u32 inp) {
		ready 			= (inp & (1 << 16)) != 0;
		inpError 		= (inp & (1 << 17)) != 0;
		overflowError 	= (inp & (1 << 18)) != 0;
		xOverflow		= (inp & (1 << 19)) != 0;
		yOverflow		= (inp & (1 << 20)) != 0;
		zOverflow 		= (inp & (1 << 21)) != 0;

		iterElapsed     = (inp >> 22) & 0x1F;
		overflowIter	= (inp >> 27) & 0x1F;
	}
};


void writeInputs(u32 xinp, u32 yinp, u32 zinp)
{
	Xil_Out32(REG_XINPUT, xinp);
	Xil_Out32(REG_YINPUT, yinp);
	Xil_Out32(REG_ZINPUT, zinp);
}

void writeControl(ControlRegister control)
{
	Xil_Out32(REG_CNTRL, control.getControl());
}

u32 getXResult()
{
	return Xil_In32(REG_XRESULT);
}

u32 getYResult()
{
	return Xil_In32(REG_XRESULT);
}

u32 getZResult()
{
	return Xil_In32(REG_XRESULT);
}

u32 getControlBin()
{
	return Xil_In32(REG_CNTRL);
}

ControlRegister getFlags()
{
	ControlRegister temp;
	temp.setFlags(getControlBin());
	return temp;
}

int main()
{
    init_platform();

    print("Hello World\n\r");

    u32 test_count = 1;

    while(1) {
    	xil_printf("Test no : %d", test_count);

    	writeInputs(0, 1, 2);
    	xil_printf("Wrote to x, y and z inputs.\n");
    	ControlRegister cntrl;

    	cntrl.start = 1;
    	cntrl.rotationMode = 1;		// 1 : Rotation
    	cntrl.rotationSystem = 1;	// 1 : Circular
    	cntrl.zOverflowStopEn = 0;

    	writeControl(cntrl);

    	xil_printf("X Input : %d\n", getXResult());
    	xil_printf("Y Input : %d\n", getYResult());
    	xil_printf("Z Input : %d\n", getZResult());
    	xil_printf("Control : %d\n", getControlBin());

//        slv_reg0_wdata = rand();
//
//        xil_printf("Writing %d to x input\n", slv_reg0_wdata);
//    	  Xil_Out32(REG_XINPUT, slv_reg0_wdata);
//
//    	slv_reg0_rdata = Xil_In32(REG_XINPUT);
//
//        xil_printf("Read value %d from x input\n", slv_reg0_rdata);
        test_count++;
    }
    cleanup_platform();
    return 0;
}
