module testbench;
  reg[31:0] r_x = 0;
  reg[31:0] r_y = 0;
  reg[31:0] r_z = 0;
  reg r_d 		= 1;
  
  reg r_mode 	= 0;
  
  wire[31:0] r_lut;
  
  reg[31:0] r_lut_mem[20];
  
  reg[4:0] r_shift_amnt = 0;
  
  wire[31:0] w_x;
  wire[31:0] w_y;
  wire[31:0] w_z;
  wire w_d;
  
  reg r_enable = 0;
  
  event e_sync;
  
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
    .o_znext(w_z),
    .o_dnext(w_d)
  );
  
  int i;
  real angle_deg = 10;
  real angle_rad = angle_deg * $acos(-1) / 180;
  
  initial begin
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    // Circular mode settings
    /*
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
	
    @(e_sync);
    r_x = frac_to_hex(0.6072529350092496);
    r_y = 0;
    r_z = degrees_to_hex(angle_deg);

    r_mode = 1;			// Circular mode
    r_enable = 1;		// Start computation
    r_d = ~r_z[31];
    */
    
    // Hyperbolic mode settings
	///*
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
    
	@(e_sync);
 	r_x = frac_to_hex2(1.2051363584457304);
    $display(hex2_to_frac(r_x));
    r_y = 0;
    r_z = degrees_to_hex(angle_deg);
	// r_z = 0;
    
    r_mode = 0;			// Circular mode
    r_shift_amnt = 1;
    r_enable = 1;		// Start computation
    r_d = ~r_z[31];
	//*/

    #1;
    
    repeat(20) begin
      disp_state_frac_2(r_x, r_y, r_z);
      //$display("%8h | %8h | %8h", r_x, r_y, r_z);
      @(e_sync);
    end
    
    disp_state_frac_2(r_x, r_y, r_z);
    $display("cos : %f, sine : %f", $cos(angle_rad), $sin(angle_rad));
    $display("cosh : %f, sinh : %f", $cosh(angle_rad), $sinh(angle_rad));
    
    r_enable = 0;
    
 	#10 $finish;
  end
  
  always @e_sync if(r_enable) begin
  	r_x <= w_x;
    r_y <= w_y;
    r_z <= w_z;
    r_d <= w_d;
    r_shift_amnt <= r_shift_amnt + 1;
  end
  
  assign r_lut = r_lut_mem[r_shift_amnt];
  
  always #1 ->e_sync;

endmodule

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
