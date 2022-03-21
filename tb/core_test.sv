`ifndef CORE_TEST_SV
`define CORE_TEST_SV

`include "types.svh"
`include "cordic_if.svh"

// Display functions for CORDIC state (x, y, z)
/*
function string disp_state_frac_hex(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("x : %s | y : %s | z : %s", frachex_to_str(x), frachex_to_str(y), anglehex_to_str(z));
endfunction

function string disp_state_frac(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("x : %f | y : %f | z : %8f", hex_to_frac(x), hex_to_frac(y), hex_to_degrees(z));
endfunction

function string disp_state_frac_2(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("x : %f | y : %f | z : %8f", hex2_to_frac(x), hex2_to_frac(y), hex_to_degrees(z));
endfunction
*/

typedef number #(32, 0) fixedpt_1;
typedef number #(32, 3) fixedpt_2;
typedef angle #(32) 	ang_type;

function string disp_state(number x, number y, ang_type z);
  $display("%s, %s, %s", x.to_string(), y.to_string(), z.to_string());
endfunction

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
  reg r_d 		= 1;  
  reg r_mode 	= 0;
  reg[4:0] r_shift_amnt = 0;
    
  // CORDIC Lookup table
  reg[31:0] r_lut_mem[20];

  cordic_if #(32) intf();

  assign intf.xprev       = r_x;
  assign intf.yprev       = r_y;
  assign intf.zprev       = r_z;
  
  assign intf.dir         = r_d;
  assign intf.mode        = r_mode;
  assign intf.shift_amnt  = r_shift_amnt;

  // Initializing the CORDIC core
  cordic #(.p_WIDTH(32)) dut (
    intf.core
  );

  // For the control logic to function
  reg r_enable = 0;
  
  // Event for triggering a CORDIC iteration
  event e_sync;

  // Trigger CORDIC event
  always #2 ->e_sync;

  // Controller logic for rotation
  always @e_sync if(r_enable) begin
  	r_x <= intf.xnext;
    r_y <= intf.ynext;
    r_z <= intf.znext;
    r_d <= ~intf.znext[31];
    r_shift_amnt <= r_shift_amnt + 1;
  end
  
  // Look up the LUT value for current iteration number (thats equal to the shift amount)
  assign intf.angle = r_lut_mem[r_shift_amnt];

  fixedpt_1 num1_x = new(0);
  fixedpt_1 num1_y = new(0);

  fixedpt_2 num2_x = new(0);
  fixedpt_2 num2_y = new(0);
  
  ang_type init_angle = new(10);	// Input angle

  ang_type ang_obj = new(0);		// Temporary variable to read from CORDIC outputs
  
  initial begin
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    @e_sync #1;
    
    r_mode = 1;		// Circular mode
    // r_mode = 0;		// Hyperbolic mode
    
    if(r_mode) begin
      // Circular mode settings
      
      // Set lookup table to tan inverse of 2^-i
      r_lut_mem = {
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

      // CORDIC initial data inputs
      num1_x.set_real(0.6072529350092496);
      $display("%h", num1_x.val_bin);
      num1_y.set_real(0);
      
      r_x = num1_x.val_bin;
      r_y = num1_y.val_bin;
      r_z = init_angle.val_num.val_bin;			// Load angle into z field (in q.31 representation)

      // CORDIC initial control inputs
      r_d = ~r_z[31];
      r_shift_amnt = 0;							// Circular rotations must start from i = 0

    end else begin
      // Hyperbolic mode settings
      
      // Set lookup table to tanh inverse of 2^-i
      r_lut_mem = {
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

      // CORDIC initial data inputs
      num2_x.set_real(1.2051363584457304);
      num2_y.set_real(0);
      
      r_x = num2_x.val_bin;
      r_y = num2_y.val_bin;
      r_z = init_angle.val_num.val_bin;
      
      // CORDIC initial control inputs
      r_d = ~r_z[31];
      r_shift_amnt = 1;							// Hyperbolic rotations must start with 1 (because arctanh(1) = inf)

    end
	
    r_enable = 1;								// Start computation

    // 20 iterations
    repeat(20) begin
      if(r_mode) begin
        num1_x.set_bin(r_x);
      	num1_y.set_bin(r_y);
        ang_obj.set_bin(r_z);
        disp_state_1(num1_x, num1_y, ang_obj);    
//        disp_state_frac(r_x, r_y, r_z);			// Show x, y in q.31 representation and z in degrees for circular mode
      end else begin
		num2_x.set_bin(r_x);
      	num2_y.set_bin(r_y);
        ang_obj.set_bin(r_z);
        disp_state_2(num2_x, num2_y, ang_obj);    
//        disp_state_frac_2(r_x, r_y, r_z);		// Show x, y in q3.28 representation and z in degrees for hyperbolic mode
      end
      @(e_sync) #1;								// Compute 1 iteration of CORDIC
    end
    
    if(r_mode) begin
      num1_x.set_bin(r_x);
      num1_y.set_bin(r_y);
      ang_obj.set_bin(r_z);
      disp_state_1(num1_x, num1_y, ang_obj);    
//        disp_state_frac(r_x, r_y, r_z);			// Show x, y in q.31 representation and z in degrees for circular mode
    end else begin
      num2_x.set_bin(r_x);
      num2_y.set_bin(r_y);
      ang_obj.set_bin(r_z);
      disp_state_2(num2_x, num2_y, ang_obj);    
//        disp_state_frac_2(r_x, r_y, r_z);		// Show x, y in q3.28 representation and z in degrees for hyperbolic mode
    end

    if(r_mode) begin
      $display("cos : %f, sine : %f", $cos(init_angle.val_rad), $sin(init_angle.val_rad));		// Show sine and cosine for circular mode
      num1_x.set_bin(r_x);
      num1_y.set_bin(r_y);
      $display("Error - cos : %e, sine : %e", $cos(init_angle.val_rad) - num1_x.val, $sin(init_angle.val_rad) - num1_y.val);
    end else begin
      $display("cosh : %f, sinh : %f", $cosh(init_angle.val_rad), $sinh(init_angle.val_rad));		// Show sinh and cosh for hyperbolic mode
      num2_x.set_bin(r_x);
      num2_y.set_bin(r_y);
      $display("Error - cosh : %e, sinh : %e", $cosh(init_angle.val_rad) - num2_x.val, $sinh(init_angle.val_rad) - num2_y.val);
    end
      
    r_enable = 0;								// Halt computation
    
 	#10 $finish;								// Finish simulation
  end
  
endmodule

`endif
