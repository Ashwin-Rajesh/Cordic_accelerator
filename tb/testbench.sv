module testbench;
  reg[31:0] r_x = 0;
  reg[31:0] r_y = 0;
  reg[31:0] r_z = 0;
  reg r_d 		= 1;
  
  reg r_mode 	= 0;
  
  wire[31:0] r_lut;
  
  reg[31:0] r_lut_mem[10];
  
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
  
  initial begin
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
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
      32'h00145F2E
    };
    
	
    @(e_sync);
    r_x = 32'h09B71758;
    r_y = 0;
    r_z = 32'h15555555;

    #1;
    $display("0x%8h = %f", r_z, hex_to_degrees(-r_z));

    
    r_mode = 1;			// Circular mode
    r_enable = 1;		// Start computation
    r_d = r_z > 0;
    
    @e_sync;
    @e_sync;
    @e_sync;
    @e_sync;
    @e_sync;
    @e_sync;
    @e_sync;
    @e_sync;
    @e_sync;
    @e_sync;
    
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
  
  function real hex_to_degrees(bit[31:0] val);
    return hex_to_frac(val) * 180;
  endfunction
  
  function real hex_to_frac(bit[31:0] val);
    int temp;
    temp = val;
    return real'(temp) * (2.0 ** -31);
  endfunction
  
  function bit[31:0] frac_to_hex(real frac);
    return int'(frac * (2.0 ** 31));
  endfunction
  
  function bit[31:0] degrees_to_hex(real degrees);
    return frac_to_hex(degrees / 180);
  endfunction
endmodule
