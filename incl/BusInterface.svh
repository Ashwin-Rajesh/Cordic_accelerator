`ifndef BUSINTERFACE_SVH

`define BUSINTERFACE_SVH

interface BusInterface #(
  parameter 	p_WIDTH = 32,
  localparam 	p_LOG2_WIDTH = $clog2(p_WIDTH)
);

  logic signed [p_WIDTH - 1 : 0] xInput;
  logic signed [p_WIDTH - 1 : 0] yInput;
  logic signed [p_WIDTH - 1 : 0] zInput;
  logic unsigned [p_WIDTH - 1 : 0] controlRegisterInput;

  logic signed [p_WIDTH - 1 : 0] xResult;
  logic signed [p_WIDTH - 1 : 0] yResult;
  logic signed [p_WIDTH - 1 : 0] zResult;
  logic unsigned [p_WIDTH - 1 : 0] controlRegisterOutput;
  logic unsigned controlRegisterWriteEnable;

  logic rst;
  logic clk;
  logic interrupt;

  modport controller (
    input xInput, yInput, zInput, controlRegisterInput, clk, rst,
    output xResult, yResult, zResult, controlRegisterOutput, controlRegisterWriteEnable, interrupt
  );

  modport bus (
    output xInput, yInput, zInput, controlRegisterInput, clk, rst,
    input xResult, yResult, zResult, controlRegisterOutput, controlRegisterWriteEnable, interrupt
  );

endinterface

`endif BUSINTERFACE_SVH