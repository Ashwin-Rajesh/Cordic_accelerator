`ifndef CORE_MONITOR_SVH
`define CORE_MONITOR_SVH

`include "types.svh"
`include "cordic_if.svh"

class CoreMonitor #(parameter width =  32, parameter int_width = 0);
  typedef Number #(width, int_width)  NumType;    // qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef Angle #(width) 	            AngType;    // Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  // CORDIC data inputs
  NumType  xOut;			// x output value
  NumType  yOut;			// y output value
  AngType  zOut;			// angle output value

  NumType  xInp;        // x input value
  NumType  yInp;        // y input value
  AngType  zInp;        // angle input value
  
  bit       xOverflow;
  bit       yOverflow;
  bit       zOverflow;
  
  virtual CordicInterface.controller intf;
  
  function new(virtual CordicInterface.controller inpIntf);
    // Initialize internal variables
    xOut = new(0);
    yOut = new(0);
    zOut = new(0);

    xInp = new(0);
    yInp = new(0);
    zInp = new(0);

    this.intf = inpIntf;    
  endfunction
  
  function bit sample();
    xOut.setBin(intf.xOut);
    yOut.setBin(intf.yOut);
    zOut.setBin(intf.zOut);
    
    xInp.setBin(intf.xPrev);
    yInp.setBin(intf.yPrev);
    zInp.setBin(intf.zPrev);

	  xOverflow = intf.xOverflow;    
    yOverflow = intf.yOverflow;    
    zOverflow = intf.zOverflow;    
    
    return (xOverflow || yOverflow || zOverflow);
  endfunction
endclass

`endif
