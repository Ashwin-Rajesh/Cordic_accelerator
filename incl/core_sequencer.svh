`ifndef CORE_SEQUENCER_SVH
`define CORE_SEQUENCER_SVH

`include "types.svh"
`include "cordic_if.svh"
`include "core_driver.svh"
`include "core_monitor.svh"

class core_sequencer #(parameter width =  32, parameter int_width = 0);  
  typedef number #(width, int_width) fixed_pt;		// qn.m fixed point notation, n is integer width and m = width - int_width - 1
  typedef angle #(width) 	  ang_type;				// Angle in q.m representation, m = width, with 1 representing 180 degrees, -1 representing -180 degrees 
  
  core_monitor #(32, 0) monitor;
  
  // CORDIC data inputs
  fixed_pt x_num;			// x value
  fixed_pt y_num;			// y value
  ang_type z_ang;			// angle value

  bit[width-1:0] r_x;
  bit[width-1:0] r_y;
  bit[width-1:0] r_z;
  
  // CORDIC control inputs
  bit system;				// 1 for circular, 0 for hyperbolic
  bit mode;					// 1 for rotation, 0 for vectoring
  
  // Lookup tables
  ang_type atan_lut[$];
  ang_type atanh_lut[$];
  
  virtual cordic_if.controller intf;
  
  static real atan_lut_real[] = {
    45.0,
    26.56505117707799,
    14.036243467926477,
    7.125016348901798,
    3.5763343749973515,
    1.7899106082460694,
    0.8951737102110744,
    0.44761417086055305,
    0.22381050036853808,
    0.1119056770662069,
    0.05595289189380367,
    0.027976452617003676,
    0.013988227142265016,
    0.006994113675352918,
    0.0034970568507040113,
    0.0017485284269804495,
    0.0008742642136937803,
    0.00043713210687233457,
    0.00021856605343934784,
    0.0001092830267200715,
    5.464151336008544e-05,
    2.7320756680048934e-05,
    1.3660378340025243e-05,
    6.830189170012719e-06,
    3.4150945850063712e-06,
    1.7075472925031871e-06,
    8.537736462515938e-07,
    4.2688682312579694e-07,
    2.1344341156289847e-07,
    1.0672170578144923e-07,
    5.336085289072462e-08,
    2.668042644536231e-08,
    1.3340213222681154e-08,
    6.670106611340577e-09,
    3.3350533056702886e-09,
    1.6675266528351443e-09,
    8.337633264175721e-10,
    4.1688166320878607e-10,
    2.0844083160439303e-10,
    1.0422041580219652e-10,
    5.211020790109826e-11,
    2.605510395054913e-11,
    1.3027551975274565e-11,
    6.513775987637282e-12,
    3.256887993818641e-12,
    1.6284439969093206e-12,
    8.142219984546603e-13,
    4.0711099922733015e-13,
    2.0355549961366507e-13,
    1.0177774980683254e-13
  };
  
  static real atanh_lut_real[] = {
    0,
    31.47292373094538,
    14.634076154464474,
    7.1996280356195665,
    3.585659920928566,
    1.7910762943408547,
    0.8953194209170899,
    0.4476323846983689,
    0.22381277709826164,
    0.1119059616574223,
    0.0559529274677056,
    0.02797645706374141,
    0.013988227698107234,
    0.006994113744833197,
    0.0034970568593890457,
    0.001748528428066079,
    0.000874264213829484,
    0.00043713210688929756,
    0.00021856605344146822,
    0.00010928302672033655,
    5.4641513360118576e-05,
    2.7320756680053074e-05,
    1.3660378340025761e-05,
    6.830189170012783e-06,
    3.4150945850063793e-06,
    1.707547292503188e-06,
    8.537736462515939e-07,
    4.2688682312579694e-07,
    2.1344341156289847e-07,
    1.0672170578144923e-07,
    5.336085289072462e-08,
    2.668042644536231e-08,
    1.3340213222681154e-08,
    6.670106611340577e-09,
    3.3350533056702886e-09,
    1.6675266528351443e-09,
    8.337633264175721e-10,
    4.1688166320878607e-10,
    2.0844083160439303e-10,
    1.0422041580219652e-10,
    5.211020790109826e-11,
    2.605510395054913e-11,
    1.3027551975274565e-11,
    6.513775987637282e-12,
    3.256887993818641e-12,
    1.6284439969093206e-12,
    8.142219984546603e-13,
    4.0711099922733015e-13,
    2.0355549961366507e-13,
    1.0177774980683254e-13
  };
    
  ang_type temp;

  function new(virtual cordic_if.controller inp_intf);
    // Initialize internal variables
    x_num = new(0);
    y_num = new(0);
    z_ang = new(0);
  
    r_x   = 0;
    r_y   = 0;
    r_z   = 0;
    
	system = 0;
    mode  = 0;

    intf  = inp_intf;   

    intf.mode = system;
    
    monitor = new(intf);
    
    for(int i = 0; i < atan_lut_real.size(); i++) begin
      temp = new(atan_lut_real[i]);
      atan_lut.push_back(temp);
      temp = new(atanh_lut_real[i]);
      atanh_lut.push_back(temp);
    end
  endfunction
  
  function bit reset(real x_val, real y_val, real z_val);
  	// Set internal variables
    x_num.set_real(x_val);
    y_num.set_real(y_val);
    z_ang.set_deg(z_val);
    
    intf.xprev = x_num.val_bin;
    intf.yprev = y_num.val_bin;
    intf.zprev = z_ang.val_bin;
    
    if(mode)
      intf.dir        = ~intf.zprev[width-1];
    else
      intf.dir        = intf.yprev[width-1];

    if(system) begin
      intf.shift_amnt = 0;
      intf.angle      = atan_lut[intf.shift_amnt].val_bin();
    end else begin
      intf.shift_amnt = 1;
      intf.angle      = atanh_lut[intf.shift_amnt].val_bin();
    end
    
    intf.mode = system;
  endfunction
  
  function bit set_system(bit inp);
  	system = inp;
  endfunction
  
  function bit set_mode(bit inp);
  	mode = inp;
  endfunction
  
  function void next_iter();
    intf.xprev = intf.xnext;
    intf.yprev = intf.ynext;
    intf.zprev = intf.znext;
  	
    x_num.set_bin(intf.xprev);
    y_num.set_bin(intf.yprev);
    z_ang.set_bin(intf.zprev);
    
    intf.shift_amnt = intf.shift_amnt + 1;
  
    if(mode)
      intf.dir        = ~intf.zprev[width-1];
    else
      intf.dir        = intf.yprev[width-1];
      
    if(system)
      intf.angle      = atan_lut[intf.shift_amnt].val_bin();
    else
      intf.angle      = atanh_lut[intf.shift_amnt].val_bin();

  endfunction
endclass

`endif
