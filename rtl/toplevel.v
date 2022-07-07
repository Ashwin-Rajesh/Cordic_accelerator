`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.05.2022 23:14:45
// Design Name: 
// Module Name: toplevel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module toplevel#
(
  parameter integer C_S00_AXI_DATA_WIDTH	= 32,
  parameter integer C_S00_AXI_ADDR_WIDTH	= 5
) (
  // Ports of Axi Slave Bus Interface S00_AXI
  input wire  s00_axi_aclk,
  input wire  s00_axi_aresetn,
  input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
  input wire [2 : 0] s00_axi_awprot,
  input wire  s00_axi_awvalid,
  output wire  s00_axi_awready,
  input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
  input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
  input wire  s00_axi_wvalid,
  output wire  s00_axi_wready,
  output wire [1 : 0] s00_axi_bresp,
  output wire  s00_axi_bvalid,
  input wire  s00_axi_bready,
  input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
  input wire [2 : 0] s00_axi_arprot,
  input wire  s00_axi_arvalid,
  output wire  s00_axi_arready,
  output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
  output wire [1 : 0] s00_axi_rresp,
  output wire  s00_axi_rvalid,
  input wire  s00_axi_rready,
  output wire interrupt
);
    Accelerator #
    (
      .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
      .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) inst (
      // Ports of Axi Slave Bus Interface S00_AXI
      .s00_axi_aclk(s00_axi_aclk),
      .s00_axi_aresetn(s00_axi_aresetn),
      .s00_axi_awaddr(s00_axi_awaddr),
      .s00_axi_awprot(s00_axi_awprot),
      .s00_axi_awvalid(s00_axi_awvalid),
      .s00_axi_awready(s00_axi_awready),
      .s00_axi_wdata(s00_axi_wdata),
      .s00_axi_wstrb(s00_axi_wstrb),
      .s00_axi_wvalid(s00_axi_wvalid),
      .s00_axi_wready(s00_axi_wready),
      .s00_axi_bresp(s00_axi_bresp),
      .s00_axi_bvalid(s00_axi_bvalid),
      .s00_axi_bready(s00_axi_bready),
      .s00_axi_araddr(s00_axi_araddr),
      .s00_axi_arprot(s00_axi_arprot),
      .s00_axi_arvalid(s00_axi_arvalid),
      .s00_axi_arready(s00_axi_arready),
      .s00_axi_rdata(s00_axi_rdata),
      .s00_axi_rresp(s00_axi_rresp),
      .s00_axi_rvalid(s00_axi_rvalid),
      .s00_axi_rready(s00_axi_rready),
      .interrupt(interrupt)
    );

endmodule
