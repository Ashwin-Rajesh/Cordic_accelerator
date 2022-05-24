`include "LutInterface.svh"

module Lut #(
  parameter 	p_WIDTH = 32,
  parameter   p_ANGLE_ADDR_WIDTH = 5
) (
  LutInterface.lut intf
);
  reg[p_WIDTH-1 : 0] aTanhLut [32] = {
    32'h00000000,
    32'h464FA9EA,
    32'h20B15DF5,
    32'h1015891C,
    32'h0802AC45,
    32'h04005562,
    32'h02000AAB,
    32'h01000155,
    32'h0080002A,
    32'h00400005,
    32'h00200000,
    32'h00100000,
    32'h00080000,
    32'h00040000,
    32'h00020000,
    32'h00010000,
    32'h00008000,
    32'h00004000,
    32'h00002000,
    32'h00001000,
    32'h00000800,
    32'h00000400,
    32'h00000200,
    32'h00000100,
    32'h00000080,
    32'h00000040,
    32'h00000020,
    32'h00000010,
    32'h00000008,
    32'h00000004,
    32'h00000002,
    32'h00000001
  };

  reg[p_WIDTH-1 : 0] aTanLut [32] = {
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
    32'h00000517,
    32'h0000028B,
    32'h00000145,
    32'h000000A2,
    32'h00000051,
    32'h00000028,
    32'h00000014,
    32'h0000000A,
    32'h00000005,
    32'h00000002,
    32'h00000001,
    32'h00000000,
    32'h00000000
  };
  wire[p_ANGLE_ADDR_WIDTH-1:0] offset = intf.lutOffset;
  
  assign intf.lutAngle = intf.lutSystem ? aTanLut[offset] : aTanhLut[offset];
endmodule
