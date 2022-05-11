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

### Log

#### Test configuration

The log file starts with info about the configuration.

```
Circular vectoring test
---------------------------------------------
Number of tests             : 1
Number of CORDIC iterations : 10
Number format               : q0.31
CORDIC iteration logging    :  ON
Test logging                :  ON
---------------------------------------------
```

#### Individual test results

Individual test info is logged if ```p_LOG_TESTS``` is ```1```.

If ```p_LOG_CORDIC_ITER``` is ```1```, the x, y and z values are logged in that order. z value is logged in degrees and x and y are logged as fractional numbers.

Initial, Final, Expected and Error (final - expected) values are logged for all tests if ```p_LOG_TESTS``` is ```1```

```
---------------------------------------------
 Test no :           0
Initial  :   0.000000,   0.100000,   0.000000
       0 :   0.000000,   0.100000,   0.000000
       1 :   0.100000,   0.100000,  45.000000
       2 :   0.150000,   0.050000,  71.565051
       3 :   0.162500,   0.012500,  85.601295
       4 :   0.164062,  -0.007812,  92.726311
       5 :   0.164551,   0.002441,  89.149977
       6 :   0.164627,  -0.002701,  90.939887
       7 :   0.164669,  -0.000129,  90.044714
       8 :   0.164670,   0.001158,  89.597099
       9 :   0.164675,   0.000515,  89.820910
Final    :   0.164676,   0.000193,  89.932816
Expected :   0.164676,   0.000000,  90.000000
Error    : -2.191630e-07, 1.930976e-04, -0.067184 deg
---------------------------------------------
```

Sometimes, the intiail value or expected value can violate our required conditions. In those cases, it will report the issue and try again until it finds a proper value.

Example :

```
---------------------------------------------
 Test no :           0
Initial  :   0.210901,  -0.717887,  49.825163
Expected value will overflow
 Test no :           0
Initial  :   0.271516,   0.229429,   5.503677
       0 :   0.271516,   0.229429,   5.503677
       1 :   0.042087,   0.500944, -39.496323
       2 :   0.292559,   0.479901, -12.931272
       3 :   0.412534,   0.406761,   1.104972
       4 :   0.361689,   0.458328,  -6.020045
       5 :   0.390335,   0.435723,  -2.443710
       6 :   0.403951,   0.423525,  -0.653800
       7 :   0.410569,   0.417213,   0.241374
       8 :   0.407309,   0.420420,  -0.206240
       9 :   0.408951,   0.418829,   0.017570
Final    :   0.408133,   0.419628,  -0.094336
Expected :   0.408824,   0.418956,   0.000000
Error    : -6.906095e-04, 6.722796e-04, -0.094336 deg
---------------------------------------------
```

If individual iteration values are not needed, they can be turned OFF by setting ```p_LOG_ITER``` to ```0```

```
---------------------------------------------
 Test no :           0
Initial  :   0.210901,  -0.717887,  49.825163
Expected value will overflow
 Test no :           0
Initial  :   0.271516,   0.229429,   5.503677
Final    :   0.408133,   0.419628,  -0.094336
Expected :   0.408824,   0.418956,   0.000000
Error    : -6.906095e-04, 6.722796e-04, -0.094336 deg
---------------------------------------------
```

The value could overflow during addition even if final value is within given range. Such cases are also reported

```
---------------------------------------------
 Test no :           1
Initial  :  -0.674466,  -0.113178,  -9.612945
Expected value will overflow
 Test no :           1
Initial  :  -0.872169,  -0.014341,  59.612102
Expected value will overflow
 Test no :           1
Initial  :  -0.651902,  -0.478119,  10.850380
Overflow detected after iteration  0
Final    :  -0.173782,   0.869979, -34.149620
Expected :  -0.906119,  -0.975357,   0.000000
Error    : 7.323366e-01, 1.845337e+00, -34.149620 deg
---------------------------------------------
```

#### Test results table

The important info from each test is aggregated into a table and displayed at the end

```
---------------------------------------------
Test table
No :     init x,     init y,   init ang |      exp x,      exp y,     exp ang |      error x,      error y,  error ang
 0 :   0.271516,   0.229429,   5.503677 |   0.408824,   0.418956,    0.000000 | 6.906095e-04, 6.722796e-04,   0.094336 :       OK
 1 :  -0.651902,  -0.478119,  10.850380 |  -0.906119,  -0.975357,    0.000000 | 7.323366e-01, 1.845337e+00,  34.149620 : Overflow
 2 :   0.607230,  -0.373656,  77.562912 |   0.816242,   0.843975,    0.000000 | 1.320974e-03, 1.280609e-03,   0.089782 :       OK
 3 :   0.288310,   0.022787,  54.128957 |   0.247794,   0.406718,    0.000000 | 2.654505e-04, 1.621988e-04,   0.037425 :       OK
 4 :   0.266653,   0.321852, -42.085398 |   0.681121,   0.099037,    0.000000 | 1.380574e-04, 9.572526e-04,   0.080510 :       OK
---------------------------------------------
```

#### Test summary

Important statistics of error is shown at the end. The minimum and maximum magnitude and average are shown as of writing.

```
---------------------------------------------
Test summary
 Error of x : 1.380574e-04 to 7.323366e-01, avg 1.469503e-01
 Error of y : 1.621988e-04 to 1.845337e+00, avg 3.696818e-01
 Error of z : 0.037425 deg to 34.149620 deg, avg 6.890334 deg
---------------------------------------------
```

#### Log files

Log files from the simulations are stored in the [```docs/data```](../docs/data) folder. They are arranged into 4 :

- ```circ_rot```     : Circular rotation
- ```circ_vect```    : Circular vectoring
- ```hyp_rot```      : Hyperbolic rotation
- ```hyp_vect```     : Hyperbolic vectoring

Each file in the above forlders are named in the following format :

```
<c/h><r/v>_<num_cordic_iter>_<log_tests>_<log_iter>_x<num_tests>.txt
```

For example, ```hr_10_off_off_x500.txt``` can be decoded as

- ```h``` : Hyperbolic
- ```r``` : Rotation
- ```10``` : 10 CORDIC iterations
- ```off``` : No test wise logs
- ```off``` : Not CORDIC iteration wise logs
- ```500``` : 500 random tests
