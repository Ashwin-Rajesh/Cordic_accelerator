
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

---

### CORDIC core defintion

```xPrev``` and ```yPrev``` are shifted to the right with sign extension by ```shiftAmount```. Let these by ```xShifted``` and ```yShifted```. 

```deltaX```, ```deltaY``` and ```deltaZ``` define the change in x, y and z from ```xPrev```, ```yPrev``` and ```zPrev``` to ```xResult```, ```yResult``` and ```zResult```. I.e,

```
xResult = xPrev + deltaX
yResult = yPrev + deltaY
zResult = zPrev + deltaZ
```

The following table decides the magnitude of change (or delta)

| Delta variable    | Magnitude of change   |
|---                |---                    |
| deltaX            | xShifted (```xPrev >>> shiftAmount```) |
| deltaY            | yShifted (```yPrev >>> shiftAmount```) |
| deltaZ            | rotationAngle         |

The sign of ```deltaX```, ```deltaY``` and ```deltaZ``` depend on direction of rotation and rotation system. The following table documents this

| rotationSystem    | rotationDir   | deltaX    | deltaY    | deltaZ        |  
|:---:              |:---:          |:---:|:---:|:---:|
| Hyperbolic (1)    | - (0)         | - | - | + |
| Hyperbolic (1)    | + (1)         | + | + | - |
| Circular (1)      | - (0)         | + | - | + |
| Circular (1)      | + (1)         | - | + | - |

So, effectively, these are the equations for the results (and for CORDIC rotations) :

| rotationSystem    | rotationDir   | xResult   | yResult   | zResult   |  
|:---:              |:---:          |:---:|:---:|:---:|
| Hyperbolic (1)    | - (0)         | ```xPrev - (xPrev >>> shiftAmount)``` | ```yPrev - (yPrev >>> shiftAmount)``` | ```zPrev + rotationAngle``` |
| Hyperbolic (1)    | + (1)         | ```xPrev + (xPrev >>> shiftAmount)``` | ```yPrev + (yPrev >>> shiftAmount)``` | ```zPrev - rotationAngle``` |
| Circular (1)      | - (0)         | ```xPrev + (xPrev >>> shiftAmount)``` | ```yPrev + (yPrev >>> shiftAmount)``` | ```zPrev - rotationAngle``` |
| Circular (1)      | + (1)         | ```xPrev - (xPrev >>> shiftAmount)``` | ```yPrev - (yPrev >>> shiftAmount)``` | ```zPrev + rotationAngle``` |

Each of these additions can overflow, and if they do, they are reported using active high signals, ```xOverflow```, ```yOverflow``` and ```zOverflow```

---

### Controlling the CORDIC core

The CORDIC core is a purely combinational unit that does the computation and the controller / sequencer gives appropriate control inputs to the CORDIC. These are the important points for controlling the CORDIC core.

#### Inputs to the controller

- Initial x value
- Initial y value
- Initiail angle (z) value
- Hyperbolic / circular rotation system?
- Rotation / vectoring mode?
- Number of iterations

#### Control logic

| Port Name     | How to initialize?    | On each iteration?    |
|---            |---                    |---                    |
| xPrev         | Set required input    | ```= xResult```       |
| yPrev         | Set required input    | ```= yResult```       |
| zPrev         | Set required input    | ```= zResult```       |
| rotationDir   | rotation or vectoring condition | rotation or vectoring condition |
| rotationSystem | Hyperbolic / Circular | Hyperbolic / Circular (should not change) |
| rotationAngle | Look up from table    | Look up from table    |
| shiftAmount   | 0 for circ, 1 for hyp | ```= shiftAmount + 1``` |

#### Limitations

Maximum rotation angle (for both rotation and vectoring) is :

| Rotation system   | Maximum /minimum rotation angle       |
|---                |--- |
| Circular          | +/- 100 degrees                       |
| Hyperbolic        | +/- 60 degrees                        |

Also, for rotations, ```abs(x) < abs(y)``` and x < 0 (abs is short for absolute / magnitude)
