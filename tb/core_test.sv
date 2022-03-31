`ifndef CORE_TEST_SV
`define CORE_TEST_SV

`include "types.svh"
`include "cordic_if.svh"
`include "core_monitor.svh"
`include "core_driver.svh"
`include "core_sequencer.svh"

typedef number #(32, 0) fixedpt_1;
typedef number #(32, 3) fixedpt_2;
typedef angle #(32) 	ang_type;

// Display functions for CORDIC state (x, y, z)
function string disp_state_frac(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("%f, %f, %f", fixedpt_1::bin_to_real(x), fixedpt_1::bin_to_real(y), ang_type::bin_to_deg(z));
endfunction

function string disp_state_frac_2(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("%f, %f, %f", fixedpt_2::bin_to_real(x), fixedpt_2::bin_to_real(y), ang_type::bin_to_deg(z));
endfunction

// Display functions using number
function string disp_state_1(fixedpt_1 x, fixedpt_1 y, ang_type z);
  $display("%f, %f, %f", x.val, y.val, z.val_deg);
endfunction

function string disp_state_2(fixedpt_2 x, fixedpt_2 y, ang_type z);
  $display("%f, %f, %f", x.val, y.val, z.val_deg);
endfunction

// Main testbench
module testbench;
  // CORDIC data inputs
  reg[31:0] r_x = 0;
  reg[31:0] r_y = 0;
  reg[31:0] r_z = 0;

  // CORDIC control inputs
  reg r_d 		= 1;  		// 0 for clockwise, 1 for counter-clockwise
  reg r_mode 	= 1;		// 0 for hyperbolic, 1 for circular
  reg[4:0] r_shift_amnt = 0;
  
  // Controller logic variables
  reg r_mode_control = 1;	// 0 for vectoring, 1 for rotation
  reg r_enable = 0;			// Enable CORDIC functioning

  // Set lookup table to tan inverse of 2^-i
  reg[31:0] r_lut_atan[] = {
    32'h20000000,
    32'h12E4051D,
    32'h09FB385B,
    32'h051111D4,
    32'h028B0D43,
    32'h0145D7E1,
    32'h00A2F61E,
    32'h00517C55,
    32'h0028BE53,
    32'h00145F2E,
    32'h000A2F98,
    32'h000517CC,
    32'h00028BE6,
    32'h000145F3,
    32'h0000A2F9,
    32'h0000517C,
    32'h000028BE,
    32'h0000145F,
    32'h00000A2F,
    32'h00000517
  };
  
  real p_CIRC_FACTOR = 0.6072529350092496;

  // Set lookup table to tanh inverse of 2^-i
  reg[31:0] r_lut_atanh[] = {
    32'h00000000,
    32'h1661788D,
    32'h0A680D61,
    32'h051EA6FC,
    32'h028CBFDD,
    32'h01460E34,
    32'h00A2FCE8,
    32'h00517D2E,
    32'h0028BE6E,
    32'h00145F32,
    32'h000A2F98,
    32'h000517CC,
    32'h00028BE6,
    32'h000145F3,
    32'h0000A2F9,
    32'h0000517C,
    32'h000028BE,
    32'h0000145F,
    32'h00000A2F,
    32'h00000517
  };
  
  real p_HYP_FACTOR = 1.2051363584457304;
  
  // CORDIC-controller interface
  cordic_if #(32) intf();
  
  // Monitors
  core_monitor #(32, 0) monitor1 = new(intf.controller);	// For circular mode
  core_monitor #(32, 3) monitor2 = new(intf.controller);	// For hyperbolic mode

  core_sequencer #(32, 0) seq1 = new(intf.controller);
  
  // Initializing the CORDIC core
  cordic #(.p_WIDTH(32)) dut (
    intf.core
  );

  // Event for triggering a CORDIC iteration
  event e_sync;

  // Trigger CORDIC event
  always #2 ->e_sync;

  // Controller logic for
  always @e_sync if(r_enable) begin
    // Data values are shifted from output to input
    r_x <= intf.xnext;
    r_y <= intf.ynext;
    r_z <= intf.znext;
    
	// Increase shift amount by 1
    r_shift_amnt <= r_shift_amnt + 1;
  end
  
  // Control direction of rotation in next cycle
  always @(*)
    if(r_mode_control)
      r_d <= ~r_z[31];	// Rotation mode
    else
      r_d <= r_y[31];	// Vectoring mode
  
  // Drive signals
  assign intf.xprev       = r_x;
  assign intf.yprev       = r_y;
  assign intf.zprev       = r_z;  
  assign intf.dir         = r_d;
  assign intf.mode        = r_mode;
  assign intf.shift_amnt  = r_shift_amnt;

  // Look up the LUT value for current iteration number (thats equal to the shift amount)
  always @(*)
    intf.angle = r_mode ? r_lut_atan[r_shift_amnt] : r_lut_atanh[r_shift_amnt];

  fixedpt_1 num1_x = new(0);
  fixedpt_1 num1_y = new(0);

  fixedpt_2 num2_x = new(0);
  fixedpt_2 num2_y = new(0);
  
  ang_type init_angle = new(0);		// Input angle

  ang_type ang_obj = new(0);		// Temporary variable to read from CORDIC outputs
  
  real x_exp, y_exp, z_exp;
  
  initial begin
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    @e_sync #1;
    
    r_mode = 1;			// Circular mode
    //r_mode = 0;		// Hyperbolic mode
    
    r_mode_control = 1;	// Rotation mode
    //r_mode_control = 0;	// Vectoring mode
    
    if(r_mode) begin
      if(r_mode_control) begin
        $display("Circular rotation");
        // Circular rotation mode initial data settings
        num1_x.set_real(p_CIRC_FACTOR);
        num1_y.set_real(0);
        init_angle.set_deg(45);
        
        x_exp = (num1_x.val * $cos(init_angle.val_rad) - num1_y.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
        y_exp = (num1_y.val * $cos(init_angle.val_rad) + num1_x.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
        z_exp = 0;
      end else begin
        $display("Circular vectoring");
        // Circular vectoring mode initial data settings
        num1_x.set_real(0);
        num1_y.set_real(0.1);
        init_angle.set_deg(0);
        
        x_exp = (num1_x.val ** 2 + num1_y.val ** 2) ** 0.5 / p_CIRC_FACTOR;
        y_exp = 0;
        z_exp = init_angle.val_deg + ($atan2(num1_y.val, num1_x.val) * 180 / $acos(-1));
      end
	  r_x = num1_x.val_bin;
      r_y = num1_y.val_bin;

      r_shift_amnt = 0;
   	end else begin
      if(r_mode_control) begin
        $display("Hyperbolic rotation");
        // Hyperbolic rotation mode initial data settings
        num2_x.set_real(p_HYP_FACTOR);
        num2_y.set_real(0);
        init_angle.set_deg(23);      
        
        x_exp = (num2_x.val * $cosh(init_angle.val_rad) + num2_y.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
        y_exp = (num2_y.val * $cosh(init_angle.val_rad) + num2_x.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
        z_exp = 0;
      end else begin
        $display("Hyperbolic vectoring");
        // Hyperbolic vectoring mode initial data settings
        num2_x.set_real(p_HYP_FACTOR);
        num2_y.set_real(p_HYP_FACTOR);
        init_angle.set_deg(0);
        
        z_exp = init_angle.val_deg + ($atanh(num2_y.val / num2_x.val) * 180 / $acos(-1));
      end
      r_x = num2_x.val_bin;
      r_y = num2_y.val_bin;    
   	  
      r_shift_amnt = 1;
    end

    r_z = init_angle.val_num.val_bin;			// Load angle into z field (in q.31 representation)
		
    @(e_sync) #1;
    
    r_enable = 1;								// Start computation

    // 20 iterations
    repeat(20) begin
      disp_state();								// Display state before each iteration
    
      @(e_sync) #1;								// Wait for one CORDIC iteration
    end
    disp_state();								// Display final state
    
    // Compare with expected results
    $display("Expected results :");
    $display("%f, %f, %f", x_exp, y_exp, z_exp);
    
    $display("Error :");
    if(r_mode)
      $display("%e, %e, %f deg", fixedpt_1::bin_to_real(r_x) - x_exp, fixedpt_1::bin_to_real(r_y) - y_exp, ang_type::bin_to_deg(r_z) - z_exp);
    else
      $display("%e, %e, %f deg", fixedpt_2::bin_to_real(r_x) - x_exp, fixedpt_2::bin_to_real(r_y) - y_exp, ang_type::bin_to_deg(r_z) - z_exp);
      
    r_enable = 0;								// Halt computation
    
 	#10 $finish;								// Finish simulation
  end
  
  task disp_state();
    // $display(r_shift_amnt);
    if(r_mode) begin
      monitor1.sample();
      disp_state_frac(r_x, r_y, r_z);
      //disp_state_1(monitor1.x_num, monitor1.y_num, monitor1.z_ang);    
    end else begin
      monitor2.sample();
      disp_state_frac_2(r_x, r_y, r_z);
      //disp_state_2(monitor2.x_num, monitor2.y_num, monitor2.z_ang);    
    end
  endtask
  
endmodule

`endif
