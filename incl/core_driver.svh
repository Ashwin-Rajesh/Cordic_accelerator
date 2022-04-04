`ifndef CORE_DRIVER_SVH
`define CORE_DRIVER_SVH

`include "types.svh"
`include "cordic_if.svh"

class CoreDriver #(parameter width =  32, parameter int_width = 0);
  typedef Number #(width, int_width)  NumType;		// qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef Angle #(width) 	            AngType;    // Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  // CORDIC data inputs
  NumType xNum;			// x value
  NumType yNum;			// y value
  AngType zAng;			// angle value
  
  // CORDIC control inputs
  bit rotationSystem;
  
  virtual CordicInterface.controller intf;
  
  function new(virtual CordicInterface.controller inpIntf);
    // Initialize internal variables
    xNum = new(0);
    yNum = new(0);
    zAng = new(0);
    rotationSystem  = 0;
    this.intf = inpIntf;    
  endfunction
  
  function bit set(NumType xInp, NumType yNum, AngType zInp);
  	xNum = xInp;
    yNum = yNum;
    zAng = zInp;
  endfunction
  
  function bit setReal(real xInp, real yNum, real zInp);
  	// Set internal variables
    xNum.setReal(xInp);
    yNum.setReal(yNum);
    zAng.setDeg(zInp);    
  endfunction
  
  function bit set_rotationSystem(bit inp);
  	rotationSystem = inp;
  endfunction
  
  function bit drive(int unsigned shiftAmount, AngType rotationAngle, bit rotationDir);
  	intf.xPrev = xNum.binVal;
    intf.yPrev = yNum.binVal;
    intf.zPrev = zAng.getBin();
  
    intf.rotationAngle    = rotationAngle.getBin();
    intf.rotationDir      = rotationDir;
    intf.rotationSystem   = rotationSystem;
    intf.shiftAmount      = shiftAmount;
  endfunction
endclass

`endif
