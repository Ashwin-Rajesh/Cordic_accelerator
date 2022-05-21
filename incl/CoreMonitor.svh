`ifndef CORE_MONITOR_SVH
`define CORE_MONITOR_SVH

`include "Types.svh"
`include "CordicInterface.svh"

class CoreMonitor #(parameter width =  32, parameter int_width = 0);
  typedef Number #(width, int_width)  NumType;    // qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef Angle #(width) 	            AngType;    // Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  // CORDIC data inputs
  NumType  xNum;			// x value
  NumType  yNum;			// y value
  AngType  zAng;			// angle value
  
  bit       xOverflow;
  bit       yOverflow;
  bit       zOverflow;
  
  virtual CordicInterface.controller intf;
  
  function new(virtual CordicInterface.controller inpIntf);
    // Initialize internal variables
    xNum = new(0);
    yNum = new(0);
    zAng = new(0);
    this.intf = inpIntf;    
  endfunction
  
  function bit sample();
    xNum.setBin(intf.xResult);
    yNum.setBin(intf.yResult);
    zAng.setBin(intf.zResult);
    
	  xOverflow = intf.xOverflow;    
    yOverflow = intf.yOverflow;    
    zOverflow = intf.zOverflow;    
      
    return (xOverflow || yOverflow || zOverflow);
  endfunction
endclass

`endif
