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

  // ControlRegister : Upper 16 Flags
  //                 : Lower 16 Control Bits

  // Control  0       : Start
  //          1       : Stop
  //          2       : Rotation Mode
  //          3       : Rotation System 
  //          4       : Error Interrupt Enable
  //          5       : Result Interrupt Enable
  //          6       : Overflow Stop Enable
  //          7       : Z Overflow stop Enable
  //          8, 12   : Number of Iteration

  // Flags    16      : Ready
  //          17      : Error
  //          18      : Input Error
  //          19      : Overflow Error
  //          20      : X Overflow 
  //          21      : Y Overflow
  //          22      : Z Overflow
  //          23, 27  : Iterations Elapsed
  //          28, 32  : Overflow Iteration

  

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