`ifndef CORE_DRIVER_SVH
`define CORE_DRIVER_SVH

`include "types.svh"
`include "cordic_if.svh"

class core_driver #(parameter width =  32, parameter int_width = 0);
  typedef number #(width, int_width) fixed_pt;		// qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef angle #(width) 	  ang_type;				// Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  // CORDIC data inputs
  fixed_pt x_num;			// x value
  fixed_pt y_num;			// y value
  ang_type z_ang;			// angle value
  
  // CORDIC control inputs
  bit mode;
  
  virtual CordicInterface.controller intf;
  
  function new(virtual CordicInterface.controller inp_intf);
    // Initialize internal variables
    x_num = new(0);
    y_num = new(0);
    z_ang = new(0);
    mode  = 0;
    this.intf = inp_intf;    
  endfunction
  
  function bit set(fixed_pt x_val, fixed_pt y_val, ang_type z_val);
  	x_num = x_val;
    y_num = y_val;
    z_ang = z_val;
  endfunction
  
  function bit set_real(real x_val, real y_val, real z_val);
  	// Set internal variables
    x_num.set_real(x_val);
    y_num.set_real(y_val);
    z_ang.set_deg(z_val);    
  endfunction
  
  function bit set_mode(bit inp);
  	mode = inp;
  endfunction
  
  function bit drive(int unsigned shift_amnt, ang_type angle, bit dir);
  	intf.xPrev = x_num.val_bin;
    intf.yPrev = y_num.val_bin;
    intf.zPrev = z_ang.val_num.val_bin;
  
    intf.rotationAngle = angle.val_num.val_bin;
    intf.rotationDir   = dir;
    intf.rotationSystem  = mode;
    intf.shiftAmount = shift_amnt;
  endfunction
endclass

`endif
