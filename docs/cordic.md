
# Cordic Compute Unit Documentation

Documentation of the main cordic compute Unit.

Verilog Model:

- `rtl/cordic.v`
    - `incl/cordic_if.svh`
    - `incl/types.svh`

Test Benches

- `tb/testbench.sv`
    - `tb/core_test.sv`

## Module Interface

Module Interface defined in file `incl/cordic_if.svh`. 

### Parameters

- p_WIDTH : bus width of the architecture, default 32.

### Ports

Defined in interface `cordic_if.core`.

| Port name     | Direction | Width     | Description
|---            |---        |---        |---
| xPrev         | Input     | p_WIDTH   | Previous (input) x value
| yPrev         | Input     | p_WIDTH   | Previous (input) y value
| zPrev         | Input     | p_WIDTH   | Previous (input) angle value
| rotationDir   | Input     | 1         | 0 for anti-clockwise, 1 for clockwise rotation
| rotationSystem | Input    | 1         | 0 for hyperbolic, 1 for circular
| rotationAngle | Input     | p_WIDTH   | Angle we are rotating with (from LUT)
| shiftAmount   | Input | p_LOG2_WIDTH  | Shift amount in current iteration
| xResult       | Output    | p_WIDTH   | Output x value
| yResult       | Output    | p_WIDTH   | Output y value
| zResult       | Output    | p_WIDTH   | Output angle 
| xOverflow     | Output    | 1         | Did x addition lead to overflow?
| yOverflow     | Output    | 1         | Did y addition lead to overflow?
| zOverflow     | Output    | 1         | Did z addition lead to overflow?
