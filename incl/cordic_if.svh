`ifndef CORDIC_IF_SVH
`define CORDIC_IF_SVH

interface cordic_if #(
  parameter 	p_WIDTH = 32,
  localparam 	p_LOG2_WIDTH = $clog2(p_WIDTH)
);
  // Data inputs
  logic signed [p_WIDTH - 1:0] 	xprev;
  logic signed [p_WIDTH - 1:0] 	yprev;
  logic signed [p_WIDTH - 1:0] 	zprev;

  // Control inputs
  logic 						dir;
  logic 						mode;
  logic[p_WIDTH - 1:0] 			angle;
  logic[p_LOG2_WIDTH-1:0] 		shift_amnt;

  // Data outputs
  logic signed [p_WIDTH-1:0] 	xnext;
  logic signed [p_WIDTH-1:0] 	ynext;
  logic signed [p_WIDTH-1:0] 	znext;
  
  // Flag outputs
  logic 						xOverflow;
  logic 						yOverflow;
  logic 						zOverflow;

  // modport on CORDIC core or compute unit side
  modport core(
    input 	xprev, yprev, zprev,			// Data inputs 
    input 	dir, mode, angle, shift_amnt,	// Control inputs
    output 	xnext, ynext, znext,			// Data outputs
    output  xOverflow, yOverflow, zOverflow // Flag outputs
  );
  // modport on the controller side
  modport controller(
    output 	xprev, yprev, zprev,			// Data inputs 
    output 	dir, mode, angle, shift_amnt,	// Control inputs
    input 	xnext, ynext, znext,			// Data outputs
    input   xOverflow, yOverflow, zOverflow // Flag outputs
  );
endinterface

`endif
