module cordic #(
  parameter 	p_WIDTH,
  localparam 	p_LOG2_WIDTH = $clog2(p_WIDTH)
) (
  // Data inputs
  input signed [p_WIDTH-1:0] i_xprev,
  input signed [p_WIDTH-1:0] i_yprev,
  input signed [p_WIDTH-1:0] i_zprev,
  input i_dprev,				// 0 for d = -1  1 for d = 1

  // Control inputs
  input i_mode,					// 0 for hyperbolic, 1 for circular
  
  // LUT input for z computation
  input signed [p_WIDTH-1:0] i_lut,
  
  // Shift amount at stage
  input[p_LOG2_WIDTH-1:0] i_shift_amnt,
  
  // Data outputs
  output reg signed [p_WIDTH-1:0] o_xnext,
  output reg signed [p_WIDTH-1:0] o_ynext,
  output reg signed [p_WIDTH-1:0] o_znext,
  output o_dnext
);

  wire signed [p_WIDTH-1:0] w_xshifted = i_xprev >>> i_shift_amnt;
  wire signed [p_WIDTH-1:0] w_yshifted = i_yprev >>> i_shift_amnt;
  
  // Testing circular mode only
  always @(*) begin
    if(i_mode) begin
      // Circular mode
      if(i_dprev) begin
        o_xnext = i_xprev - w_yshifted;
        o_ynext = i_yprev + w_xshifted;

        o_znext = i_zprev - i_lut;
      end else begin
        o_xnext = i_xprev + w_yshifted;
        o_ynext = i_yprev - w_xshifted;

        o_znext = i_zprev + i_lut;
      end
    end else begin
      if(i_dprev) begin
        o_xnext = i_xprev + w_yshifted;
        o_ynext = i_yprev + w_xshifted;

        o_znext = i_zprev - i_lut;
      end else begin
        o_xnext = i_xprev - w_yshifted;
        o_ynext = i_yprev - w_xshifted;

        o_znext = i_zprev + i_lut;
      end
    end
  end

  assign o_dnext = ~o_znext[31];

endmodule
