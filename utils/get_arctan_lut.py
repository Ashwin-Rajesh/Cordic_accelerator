#!/usr/bin/env python3

import numpy as np
from conversions import *

fac = 1

for i in range(0, 10):
    angle = np.arctan(2**(-i))
    fac   = fac * np.cos(angle)
    print("32'h{0},".format(hex_from_fraction(fraction_from_rad(angle))))

print("Multiplication factor : 32'h{0}".format(hex_from_fraction(fac)))
