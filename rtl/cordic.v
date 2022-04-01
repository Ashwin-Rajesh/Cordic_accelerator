`include "cordic_if.svh"

module cordic #(
  parameter 	p_WIDTH = 32
) (
  cordic_if.core intf
);

  // Arithmetic right shift
  wire signed [p_WIDTH-1:0] w_xshifted = intf.xprev >>> intf.shift_amnt;
  wire signed [p_WIDTH-1:0] w_yshifted = intf.yprev >>> intf.shift_amnt;

  reg signed  [p_WIDTH-1:0] r_deltax;
  reg signed  [p_WIDTH-1:0] r_deltay;
  reg signed  [p_WIDTH-1:0] r_deltaz;
  
  always @(*) begin
    if(intf.mode) begin
      // Circular mode
      if(intf.dir) begin
        // Rotate by intf.angle
        r_deltax = - w_yshifted;
        r_deltay =   w_xshifted;
        r_deltaz = - intf.angle;
      end else begin
        // Rotate by -intf.angle
        r_deltax =   w_yshifted;
        r_deltay = - w_xshifted;
        r_deltaz =   intf.angle;
      end
    end else begin
      // Hyperbolic mode
      if(intf.dir) begin
        // Rotate by intf.angle
        r_deltax =   w_yshifted;
        r_deltay =   w_xshifted;
        r_deltaz = - intf.angle;
      end else begin
        // Rotate by -intf.angle
        r_deltax = - w_yshifted;
        r_deltay = - w_xshifted;
        r_deltaz =   intf.angle;
      end
    end
  end

  assign intf.xnext = intf.xprev + r_deltax;
  assign intf.ynext = intf.yprev + r_deltay;
  assign intf.znext = intf.zprev + r_deltaz;  

  assign intf.xOverflow = (intf.xprev[p_WIDTH-1]^r_deltax[p_WIDTH-1]) ? 0: (intf.xnext[p_WIDTH-1]^intf.xprev[p_WIDTH-1]);
  assign intf.yOverflow = (intf.yprev[p_WIDTH-1]^r_deltay[p_WIDTH-1]) ? 0: (intf.ynext[p_WIDTH-1]^intf.yprev[p_WIDTH-1]);
  assign intf.zOverflow = (intf.zprev[p_WIDTH-1]^r_deltaz[p_WIDTH-1]) ? 0: (intf.znext[p_WIDTH-1]^intf.zprev[p_WIDTH-1]);
endmodule
