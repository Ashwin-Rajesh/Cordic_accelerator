`ifndef BUSINTERFACE_SVH

`define BUSINTERFACE_SVH

interface BusInterface #(
  parameter 	p_WIDTH = 32
);

    logic signed [p_WIDTH - 1 : 0] xInput;
    logic signed [p_WIDTH - 1 : 0] yInput;
    logic signed [p_WIDTH - 1 : 0] zInput;
    logic unsigned [p_WIDTH - 1 : 0] controlRegisterInput;

    logic signed [p_WIDTH - 1 : 0] xResult;
    logic signed [p_WIDTH - 1 : 0] yResult;
    logic signed [p_WIDTH - 1 : 0] zResult;
    logic unsigned [p_WIDTH - 1 : 0] controlRegisterOutput;
    logic unsigned [p_WIDTH - 1 : 0] controlRegisterMask;

    logic rst;
    logic clk;

    modport controller (
        input xInput, yInput, zInput, controlRegisterInput, clk, rst,
        output xResult, yResult, zResult, controlRegisterOutput, controlRegisterMask
    );

    modport bus (
        output xInput, yInput, zInput, controlRegisterInput, clk, rst,
        input xResult, yResult, zResult, controlRegisterOutput, controlRegisterMask
    );

endinterface

`endif BUSINTERFACE_SVH