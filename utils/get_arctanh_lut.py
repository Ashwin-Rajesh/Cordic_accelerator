#!/usr/bin/env python3

import numpy as np
from conversions import *

num_iter    = 20        # Number of iterations

fac         = 1         # To maintain multiplication factor to compensate

for i in range(0, num_iter):
    if(i == 0):
        print("32'h00000000")               # Cant rotate for 0th iteration because arctanh(1) = inf
    else:
        angle = np.arctanh(2**(-i))         # Get rotation angle for that iteration
        fac   = fac * np.cosh(angle)        # Get compensation factor for that iteration
        print("32'h{0},".format(hex_from_fraction(fraction_from_rad(angle))))   # Output the hex format of the rotation angle for that iteration

print("Multiplication factor : 32'h{0} ({1})".format(hex_from_fraction(fac), (fac)))    # Output the compensation multplication factor at the end
