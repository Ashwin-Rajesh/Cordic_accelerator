`ifndef BUSINTERFACE_SVH

`define BUSINTERFACE_SVH

localparam p_CNTRL_START        = 0;
localparam p_CNTRL_STOP         = 1;
localparam p_CNTRL_ROT_MODE     = 2;
localparam p_CNTRL_ROT_SYS      = 3;
localparam p_CNTRL_ERR_INT_EN   = 4;
localparam p_CNTRL_RSLT_INT_EN  = 5;
localparam p_CNTRL_OV_ST_EN     = 6;
localparam p_CNTRL_Z_OV_ST_EN   = 7;
localparam p_CNTRL_ITER_L       = 8;
localparam p_CNTRL_ITER_H       = 12;
localparam p_CNTRL_Z_OV_EN      = 13;

localparam p_FLAG_READY         = 16;
localparam p_FLAG_INP_ERR       = 17;
localparam p_FLAG_OV_ERR        = 18;
localparam p_FLAG_X_OV_ERR      = 19;
localparam p_FLAG_Y_OV_ERR      = 20;
localparam p_FLAG_Z_OV_ERR      = 21;
localparam p_FLAG_ELAPS_ITER_L  = 22;
localparam p_FLAG_ELAPS_ITER_H  = 26;
localparam p_FLAG_OV_ITER_L     = 27;
localparam p_FLAG_OV_ITER_H     = 31;

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

  // Control  : Upper 16 Flags (writeable from both controller and bus)
  // Flags    : Lower 16 Control Bits (only controller can write)

  // Control  0       : Start
  //          1       : Stop
  //          2       : Rotation Mode
  //          3       : Rotation System
  //          4       : Error Interrupt Enable
  //          5       : Result Interrupt Enable
  //          6       : Overflow Stop Enable
  //          7       : Z Overflow stop Enable
  //          8, 12   : Number of Iteration
  //          13      : Z Overflow Report Enable.

  // Flags    16      : Ready
  //          17      : Error
  //          18      : Input Error
  //          19      : Overflow Error
  //          20      : X Overflow
  //          21      : Y Overflow
  //          22      : Z Overflow
  //          23, 27  : Iterations Elapsed
  //          28, 32  : Overflow Iteration

  modport controller (
    input xInput, yInput, zInput, controlRegisterInput, clk, rst,
    output xResult, yResult, zResult, controlRegisterOutput, controlRegisterWriteEnable, interrupt
  );

  modport bus (
    output xInput, yInput, zInput, controlRegisterInput, clk, rst,
    input xResult, yResult, zResult, controlRegisterOutput, controlRegisterWriteEnable, interrupt
  );

endinterface

`endif
