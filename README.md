# Cordic_accelerator
Accelerator IP for computing transcendental functions using CORDIC algorithm.

As part of final year project for APJ Abdul Kalam Technological University B Tech Electronics and Communication Program.

Department of Electronics and Communication Engineering

Government Engineering College Thrissur

---

## Index

- ```docs``` : Documentation
  - ```data``` : Logfiles generated from tests
  - ```diagrams``` : Flowcharts and diagrams
  - ```plots``` : Plots generated from jupyter notebooks
  - [```cordic_circular.ipynb```](docs/cordic_circular.ipynb) : Jupyter notebook characterizing circular mode performance
  - [```cordic_hyperbolic.ipynb```](docs/cordic_hyperbolic.ipynb) : Jupyter notebook characterizing hyperbolic mode performance
  - [```cordic.md```](docs/cordic.md) : Compute unit documentation
  - [```cordic_test.md```](docs/cordic_test.md) : Testbench documentation
- ```incl``` : ```.svh``` files included in RTL or TB code
- ```rtl``` : Synthesizable components written in system verilog
- ```tb``` : Testbenches written in system verilog
- ```test``` : Test code to be run on the processor
- ```utils``` : Python scripts for generating lookup tables, helper functions for jupyter notebook, etc


---

## Coding guidelines

For synthesizable verilog code and testbench code thats not inside classes, use the following conventions

| Prefix | Meaning
| -----|-------
| ```i_```| Input port
| ```o_```| Output port
| ```p_```| Parameter (or localparam)
| ```r_```| Register
| ```w_```| Wire
| ```s_```| State definitions (as localparam)
| ```e_```| Event

| Type                  | Case
|---                    |---
| Variable name         | *camelCase*
| Function name         | *camelCase*
| Type name             | *PascalCase*
| ``` `define``` macro  | *UPPERCASE*
| Parameters            | *UPPERCASE*

Indentation must be done using spaces, with 2 spaces for each level

---

## Contributors

- *Harith Manoj* <harithpub@gmail.com>
- *Ashwin Rajesh*
- *Akin Mary*
- *Abhishek K*
