`ifndef BUSINTERFACE_SVH

`define BUSINTERFACE_SVH

interface BusInterface #(
  parameter 	p_WIDTH = 32,
  localparam 	p_LOG2_WIDTH = $clog2(p_WIDTH)
);

  logic signed [p_WIDTH - 1 : 0] xInput;
  logic signed [p_WIDTH - 1 : 0] yInput;
  logic signed [p_WIDTH - 1 : 0] zInput;
  logic signed [p_WIDTH - 1 : 0] angle;
  logic unsigned [p_LOG2_WIDTH - 1 : 0] lutAddress;
  logic unsigned [p_WIDTH - 1 : 0] controlRegisterInput;

  logic signed [p_WIDTH - 1 : 0] xResult;
  logic signed [p_WIDTH - 1 : 0] yResult;
  logic signed [p_WIDTH - 1 : 0] zResult;
  logic unsigned [p_WIDTH - 1 : 0] controlRegisterOutput;
  logic unsigned [p_WIDTH - 1 : 0] controlRegisterMask;

  logic rst;
  logic clk;
  logic interrupt;

  modport controller (
    input xInput, yInput, zInput, controlRegisterInput, clk, rst, angle,
    output xResult, yResult, zResult, controlRegisterOutput, controlRegisterMask, interrupt, lutAddress
  );

  modport lut (
    input lutAddress,
    output angle
  )

  modport bus (
    output xInput, yInput, zInput, controlRegisterInput, clk, rst,
    input xResult, yResult, zResult, controlRegisterOutput, controlRegisterMask, interrupt
  );

endinterface

`endif BUSINTERFACE_SVH