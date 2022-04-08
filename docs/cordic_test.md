# CORDIC test

### Options

The testbench has several options :

| Option name               | Type  | Meaning                           |
|---                        |---    |---                                |
| ```p_CORDIC_NUM_ITER```   | int   | Number of CORDIC iterations       |
| ```p_CORDIC_SYSTEM```     | bit   | 1 for circular, 0 for hyperbolic  |
| ```p_CORDIC_MODE```       | bit   | 1 for rotation, 0 for vectoring   |
| ```p_INT_BITS```          | int   | Number of bits used for integer part in fixed point representation |
| ```p_LOG_ITER```          | bit   | 1 to log data variables in each CORDIC iteration |
| ```p_LOG_TESTS```         | bit   | 1 to log info about each test (initial, final, exp, error) |
| ```p_NUM_TESTS```         | int   | Number of tests to be run         |

By default, ```p_INT_BITS``` is set to be 0 for circular mode and 3 for hyperbolic mode

### Input generation

The inputs (x, y, z) are generated as follows :

| Rotation System   | Control Mode  | Initial x     | Initial y     | Initial z     |
|---                |---            |---            |---            |---            |
| Circular          | Rotation      | random        | random        | -100 to 100   |
| Circular          | Vectoring     | random        | random        | 0             |
| Hyperbolic        | Rotation      | random        | random        | -60 to 60     |
| Hyperbolic        | Vectoring     | > 0           | abs(y) < x    | 0             |

If ```p_NUM_TESTS``` is 1, then some constant values are taken. Else, they are randomized. 

Expected x, y and z values are generated as follows:

| Rotation System   | Control Mode  | Expected x                    | Expected y    | Expected z    |
|---                |---            |:---:|:---:|:---:|
| Circular          | Rotation      | ```x cos(z) - y sin(z)``` | ```y cos(z) + x sin(z)``` | 0 |
| Circular          | Vectoring     | ```root(x^2 + y^2)``` | 0 | ```atan(y / x)``` |
| Hyperbolic        | Rotation      | ```x cosh(z) + y sinh(z)``` | ```y cosh(z) + x sinh(z)``` | 0 |
| Circular          | Vectoring     | ```root(x^2 - y^2)``` | 0 | ```atanh(y / x)``` |

Expected values are checked to ensure that overflow does not occur.

If either the inputs are generated randomly to not be within the given constratints or they lead to overflow, they are generated again.
