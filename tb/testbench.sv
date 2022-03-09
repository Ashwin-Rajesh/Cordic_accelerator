// Helper functions

// Functions for converting between signed q.31 representation and -1 to 1 fraction
function real hex_to_frac(bit[31:0] val);
  int temp;
  temp = val;
  return real'(temp) * (2.0 ** -31);
endfunction

function bit[31:0] frac_to_hex(real frac);
  return int'(frac * (2.0 ** 31));
endfunction

// Functions for converting between signed q3.28 representation and -1 to 1 fraction
function real hex2_to_frac(bit[31:0] val);
  int temp;
  temp = val;
  return real'(temp) * (2.0 ** -28);
endfunction

function bit[31:0] frac_to_hex2(real frac);
  return int'(frac * (2.0 ** 28));
endfunction

// Functions for converting between signed q.31 representation and -180 degree to 180 degree angle
function real hex_to_degrees(bit[31:0] val);
  return hex_to_frac(val) * 180;
endfunction

function bit[31:0] degrees_to_hex(real degrees);
  return frac_to_hex(degrees / 180);
endfunction

// String conversion functions
function string anglehex_to_str(bit[31:0] val);
  return $sformatf("0x%8h (%.4f deg)", val, hex_to_degrees(val));
endfunction

function string frachex_to_str(bit[31:0] val);
  return $sformatf("0x%8h (%.4f)", val, hex_to_frac(val));
endfunction

// Display functions for CORDIC state (x, y, z)
function string disp_state_frac_hex(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("x : %s | y : %s | z : %s", frachex_to_str(x), frachex_to_str(y), anglehex_to_str(z));
endfunction

function string disp_state_frac(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("x : %f | y : %f | z : %8f", hex_to_frac(x), hex_to_frac(y), hex_to_degrees(z));
endfunction

function string disp_state_frac_2(bit[31:0] x, bit[31:0] y, bit[31:0] z);
  $display("x : %f | y : %f | z : %8f", hex2_to_frac(x), hex2_to_frac(y), hex_to_degrees(z));
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
  
  // CORDIC LUT input
  wire[31:0] r_lut;
  
  // CORDIC Lookup table
  reg[31:0] r_lut_mem[20];

  // CORDIC outputs
  wire[31:0] w_x;
  wire[31:0] w_y;
  wire[31:0] w_z;

  // Initializing the CORDIC core
  cordic #(.p_WIDTH(32)) dut (
    .i_xprev(r_x),
    .i_yprev(r_y),
    .i_zprev(r_z),
    .i_dprev(r_d),
    .i_mode(r_mode),
    .i_lut(r_lut),
    .i_shift_amnt(r_shift_amnt),
    .o_xnext(w_x),
    .o_ynext(w_y),
    .o_znext(w_z)
  );

  // For the control logic to function
  reg r_enable = 0;
  
  // Event for triggering a CORDIC iteration
  event e_sync;

  // Trigger CORDIC event
  always #2 ->e_sync;

  // Controller logic for rotation
  always @e_sync if(r_enable) begin
  	r_x <= w_x;
    r_y <= w_y;
    r_z <= w_z;
    r_d <= ~w_z[31];
    r_shift_amnt <= r_shift_amnt + 1;
  end
  
  // Look up the LUT value for current iteration number (thats equal to the shift amount)
  assign r_lut = r_lut_mem[r_shift_amnt];
  
  // The angle input
  real angle_deg = 10;
  real angle_rad = angle_deg * $acos(-1) / 180;
  
  initial begin
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    @e_sync #1;
    
    // r_mode = 1;		// Circular mode
    r_mode = 0;		// Hyperbolic mode
    
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
      r_x = frac_to_hex(0.6072529350092496);		// Load the multiplication factor into x field (in q.31 representation)
      r_y = 0;									// Load 0 into y field
      r_z = degrees_to_hex(angle_deg);			// Load angle into z field (in q.31 representation)

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
      r_x = frac_to_hex2(1.2051363584457304);		// Load the multiplication factor into x field (in q3.28 representation)
      $display(r_x);
      r_y = 0;									// Load 0 into y field
      r_z = degrees_to_hex(angle_deg);			// Load angle into z field (in q.31 representation)

      // CORDIC initial control inputs
      r_d = ~r_z[31];
      r_shift_amnt = 1;							// Hyperbolic rotations must start with 1 (because arctanh(1) = inf)

    end
	
    r_enable = 1;								// Start computation

    // 20 iterations
    repeat(20) begin
      if(r_mode)
        disp_state_frac(r_x, r_y, r_z);			// Show x, y in q.31 representation and z in degrees for circular mode
      else
        disp_state_frac_2(r_x, r_y, r_z);		// Show x, y in q3.28 representation and z in degrees for hyperbolic mode
      @(e_sync) #1;								// Compute 1 iteration of CORDIC
    end
    
    if(r_mode)
      disp_state_frac(r_x, r_y, r_z);			// Show x, y in q.31 representation and z in degrees for circular mode
    else
      disp_state_frac_2(r_x, r_y, r_z);			// Show x, y in q3.28 representation and z in degrees for hyperbolic mode

    if(r_mode) begin
      $display("cos : %f, sine : %f", $cos(angle_rad), $sin(angle_rad));		// Show sine and cosine for circular mode
      $display("Error - cos : %e, sine : %e", $cos(angle_rad) - hex_to_frac(r_x), $sin(angle_rad) - hex_to_frac(r_y));
    end else begin
      $display("cosh : %f, sinh : %f", $cosh(angle_rad), $sinh(angle_rad));		// Show sinh and cosh for hyperbolic mode
      $display("Error - cosh : %e, sinh : %e", $cosh(angle_rad) - hex2_to_frac(r_x), $sinh(angle_rad) - hex2_to_frac(r_y));
    end
      
    r_enable = 0;								// Halt computation
    
 	#10 $finish;								// Finish simulation
  end
  
endmodule
