// Code your design here

module cordic #(
  parameter 	p_WIDTH = 32,
  localparam 	p_LOG2_WIDTH = $clog2(p_WIDTH)
) (
  // Data inputs
  input[p_WIDTH-1:0] i_xprev,
  input[p_WIDTH-1:0] i_yprev,
  input[p_WIDTH-1:0] i_zprev,
  input i_dprev,				// 0 for d = -1  1 for d = 1

  // Control inputs
  input i_mode,					// 0 for hyperbolic, 1 for circular
  
  // LUT input for z computation
  input[p_WIDTH-1:0] i_lut,
  
  // Shift amount at stage
  input[p_LOG2_WIDTH-1:0] i_shift_amnt,
  
  // Data outputs
  output reg [p_WIDTH-1:0] o_xnext,
  output reg [p_WIDTH-1:0] o_ynext,
  output reg [p_WIDTH-1:0] o_znext,
  output o_dnext
);

  wire[p_WIDTH-1:0] w_xshifted = i_xprev >> i_shift_amnt;
  wire[p_WIDTH-1:0] w_yshifted = i_yprev >> i_shift_amnt;

  /*
  always @(*) begin
    if(i_dprev) begin	// d = 1
      o_znext = i_zprev - i_lut;
      o_ynext = i_yprev + w_xshifted;
      if(i_mode)
      	o_xnext = i_xprev - w_yshifted;		// Circular mode
	  else
      	o_xnext = i_xprev + w_yshifted;		// Hyperbolic mode
    end else begin		// d = -1
      o_znext = i_zprev + i_lut;
      o_ynext = i_yprev - w_xshifted;
      if(i_mode)
      	o_xnext = i_xprev + w_yshifted;		// Circular mode
	  else
      	o_xnext = i_xprev - w_yshifted;		// Hyperbolic mode
    end
  end
  */
  
  // Testing circular mode only
  always @(*) begin
    if(i_dprev) begin
      o_xnext = i_xprev - w_yshifted;
      o_ynext = i_yprev + w_xshifted;
      
      o_znext = i_zprev - i_lut;
    end else begin
      o_xnext = i_xprev + w_yshifted;
      o_ynext = i_yprev - w_xshifted;
      
      o_znext = i_zprev + i_lut;
    end
  end

  assign o_dnext = ~o_znext[31];

endmodule
