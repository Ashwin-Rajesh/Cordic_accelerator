// Code your testbench here
// or browse Examples

module testbench;
  reg[31:0] r_x = 0;
  reg[31:0] r_y = 0;
  reg[31:0] r_z = 0;
  reg r_d 		= 1;
  
  reg r_mode 	= 0;
  
  wire[31:0] r_lut;
  
  reg[31:0] r_lut_mem[10];
  
  initial $readmemh("data/arctan_lookup.txt", r_lut_mem);
  
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
    $dumpfile("out/cordic.vcd");
    $dumpvars(0);
    
    /*
    Python code to generate lookup table
    for i in range(0, 10):
		x = int(np.arctan(2**(-i))*(2**31)/np.pi)
  		print('32'h0x{0:0{1}X},'.format(x,8))
    */

    @(e_sync);
    r_x = 32'h0FFFFFFF;
    r_y = 0;
    r_z = 32'h20000000;
    
    r_mode = 1;			// Circular mode
    r_enable = 1;		// Start computation
    r_d = r_z > 0;
    
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
endmodule
