`include "cordic_if.svh"

module cordic #(
  parameter 	p_WIDTH = 32
) (
  cordic_if.core intf
);

  // Arithmetic right shift
  wire signed [p_WIDTH-1:0] w_xshifted = intf.xprev >>> intf.shift_amnt;
  wire signed [p_WIDTH-1:0] w_yshifted = intf.yprev >>> intf.shift_amnt;

  // Combinational datapath definition (currently not optimal for synthesis)
  always @(*) begin
    if(intf.mode) begin
      // Circular mode
      if(intf.dir) begin
        // Rotate by intf.angle
        intf.xnext = intf.xprev - w_yshifted;
        intf.ynext = intf.yprev + w_xshifted;
        intf.znext = intf.zprev - intf.angle;
      end else begin
        // Rotate by -intf.angle
        intf.xnext = intf.xprev + w_yshifted;
        intf.ynext = intf.yprev - w_xshifted;
        intf.znext = intf.zprev + intf.angle;
      end
    end else begin
      // Hyperbolic mode
      if(intf.dir) begin
        // Rotate by intf.angle
        intf.xnext = intf.xprev + w_yshifted;
        intf.ynext = intf.yprev + w_xshifted;
        intf.znext = intf.zprev - intf.angle;
      end else begin
        // Rotate by -intf.angle
        intf.xnext = intf.xprev - w_yshifted;
        intf.ynext = intf.yprev - w_xshifted;
        intf.znext = intf.zprev + intf.angle;
      end
    end
  end
endmodule
