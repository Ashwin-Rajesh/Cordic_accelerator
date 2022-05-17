`ifndef LUTINTERFACE_SVH

`define LUTINTERFACE_SVH


interface LutInterface #(
  parameter 	p_WIDTH = 32,
  localparam 	p_LOG2_WIDTH = $clog2(p_WIDTH)
);

    logic signed [p_WIDTH - 1 : 0] lutAngle;
    logic signed [p_LOG2_WIDTH - 1 : 0] lutOffset;
    logic lutSystem;


    modport controller (
        input lutAngle,
        output lutOffset, lutSystem
    );

    modport lut (
        output lutAngle,
        input lutOffset, lutSystem
    );

endinterface

`endif