`ifndef CORDIC_IF_SVH
`define CORDIC_IF_SVH

interface CordicInterface #(
  parameter 	p_WIDTH = 32,
  localparam 	p_LOG2_WIDTH = $clog2(p_WIDTH)
);
  // Data inputs
  logic signed [p_WIDTH - 1:0] 	xPrev;
  logic signed [p_WIDTH - 1:0] 	yPrev;
  logic signed [p_WIDTH - 1:0] 	zPrev;

  // Control inputs
  logic                       rotationDir;      // 1 for clockwise, 0 for counter-clockwise
  logic 						          rotationSystem;   // 1 for circular, 0 for hyperbolic
  logic[p_WIDTH - 1:0] 			  rotationAngle;    // Angle we are rotation by (from LUT)
  logic[p_LOG2_WIDTH-1:0] 		shiftAmount;

  // Data outputs
  logic signed [p_WIDTH-1:0] 	xResult;
  logic signed [p_WIDTH-1:0] 	yResult;
  logic signed [p_WIDTH-1:0] 	zResult;
  
  // Flag outputs
  logic 						xOverflow;
  logic 						yOverflow;
  logic 						zOverflow;

  // modport on CORDIC core or compute unit side
  modport core(
    input 	xPrev, yPrev, zPrev,			      // Data inputs 
    input 	rotationDir, rotationSystem, rotationAngle, shiftAmount,	// Control inputs
    output 	xResult, yResult, zResult,			// Data outputs
    output  xOverflow, yOverflow, zOverflow // Flag outputs
  );
  // modport on the controller side
  modport controller(
    output 	xPrev, yPrev, zPrev,			      // Data inputs 
    output 	rotationDir, rotationSystem, rotationAngle, shiftAmount,	// Control inputs
    input 	xResult, yResult, zResult,			// Data outputs
    input   xOverflow, yOverflow, zOverflow // Flag outputs
  );
endinterface

`endif
