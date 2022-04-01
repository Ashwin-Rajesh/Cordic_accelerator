`ifndef CORE_MONITOR_SVH
`define CORE_MONITOR_SVH

`include "types.svh"
`include "cordic_if.svh"

class core_monitor #(parameter width =  32, parameter int_width = 0);
  typedef number #(width, int_width) fixed_pt;		// qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef angle #(width) 	  ang_type;				// Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  // CORDIC data inputs
  fixed_pt x_num;			// x value
  fixed_pt y_num;			// y value
  ang_type z_ang;			// angle value
  
  bit xOverflow;
  bit yOverflow;
  bit zOverflow;
  
  virtual cordic_if.controller intf;
  
  function new(virtual cordic_if.controller inp_intf);
    // Initialize internal variables
    x_num = new(0);
    y_num = new(0);
    z_ang = new(0);
    this.intf = inp_intf;    
  endfunction
  
  function bit sample();
    x_num.set_bin(intf.xnext);
    y_num.set_bin(intf.ynext);
    z_ang.set_bin(intf.znext);
    
	xOverflow = intf.xOverflow;    
	yOverflow = intf.yOverflow;    
	zOverflow = intf.zOverflow;    
    
    return (xOverflow || yOverflow || zOverflow);
  endfunction
endclass

`endif
