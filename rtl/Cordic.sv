`include "CordicInterface.svh"

module Cordic #(
  parameter 	p_WIDTH = 32
) (
  CordicInterface.core intf
);

  // Arithmetic right shift
  wire signed [p_WIDTH-1:0] w_xshifted = intf.xPrev >>> intf.shiftAmount;
  wire signed [p_WIDTH-1:0] w_yshifted = intf.yPrev >>> intf.shiftAmount;

  reg signed  [p_WIDTH-1:0] r_deltax;
  reg signed  [p_WIDTH-1:0] r_deltay;
  reg signed  [p_WIDTH-1:0] r_deltaz;
  
  always @(*) begin
    if(intf.rotationSystem) begin
      // Circular mode
      if(intf.rotationDir) begin
        // Rotate by intf.rotationAngle
        r_deltax = - w_yshifted;
        r_deltay =   w_xshifted;
        r_deltaz = - intf.rotationAngle;
      end else begin
        // Rotate by -intf.rotationAngle
        r_deltax =   w_yshifted;
        r_deltay = - w_xshifted;
        r_deltaz =   intf.rotationAngle;
      end
    end else begin
      // Hyperbolic mode
      if(intf.rotationDir) begin
        // Rotate by intf.rotationAngle
        r_deltax =   w_yshifted;
        r_deltay =   w_xshifted;
        r_deltaz = - intf.rotationAngle;
      end else begin
        // Rotate by -intf.rotationAngle
        r_deltax = - w_yshifted;
        r_deltay = - w_xshifted;
        r_deltaz =   intf.rotationAngle;
      end
    end
  end

  assign intf.xResult = intf.xPrev + r_deltax;
  assign intf.yResult = intf.yPrev + r_deltay;
  assign intf.zResult = intf.zPrev + r_deltaz;  

  assign intf.xOverflow = (intf.xPrev[p_WIDTH-1]^r_deltax[p_WIDTH-1]) ? 0: (intf.xResult[p_WIDTH-1]^intf.xPrev[p_WIDTH-1]);
  assign intf.yOverflow = (intf.yPrev[p_WIDTH-1]^r_deltay[p_WIDTH-1]) ? 0: (intf.yResult[p_WIDTH-1]^intf.yPrev[p_WIDTH-1]);
  assign intf.zOverflow = (intf.zPrev[p_WIDTH-1]^r_deltaz[p_WIDTH-1]) ? 0: (intf.zResult[p_WIDTH-1]^intf.zPrev[p_WIDTH-1]);
endmodule
