
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

- <i>input</i> `xprev` `signed [p_WIDTH]` : Previous X value.
- <i>input</i> `yprev` `signed [p_WIDTH]` : Previous Y value.
- <i>input</i> `zprev` `signed [p_WIDTH]` : Previous Z value.
- <i>input</i> `dir` : Direction of Rotation.
- <i>input</i> `mode` : Mode of operation Circular/ Hyperbolic.
- <i>input</i> `angle` : angle to rotate by.
- <i>input</i> `shift_amnt` : Amount to shift by in operation.
- <i>output</i> `xnext` : X result.
- <i>output</i> `ynext` : Y result.
- <i>output</i> `znext` : Z result.




