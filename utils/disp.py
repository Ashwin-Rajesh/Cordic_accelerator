#!/usr/bin/env python3

import matplotlib.pyplot as plt
import math

from numpy import linspace

num_iter = int(input())

# inp_str = input()

# x_act = float(inp_str.split(',')[0])
# y_act = float(inp_str.split(',')[1])

num_ang = float(input())

x_act = math.cos(num_ang * math.pi / 180)
y_act = math.sin(num_ang * math.pi / 180)

x_ls = []
y_ls = []
z_ls = []

x_norm_ls = []
y_norm_ls = []

x_err = []
y_err = []

for i in range(num_iter):
    inp_str = input()

    inp_ls  = inp_str.split(',')

    x = float(inp_ls[0])
    y = float(inp_ls[1])
    z = float(inp_ls[2])

    r = math.sqrt(x ** 2 + y ** 2)

    x_norm = x / r
    y_norm = y / r

    x_ls.append(x)
    y_ls.append(y)
    z_ls.append(z)

    x_norm_ls.append(x_norm)
    y_norm_ls.append(y_norm)

    x_err.append(x - x_act)
    y_err.append(y - y_act)

x_unitcirc = [math.cos(x) for x in linspace(0, math.pi, 100)]
y_unitcirc = [math.sin(x) for x in linspace(0, math.pi, 100)]

plt.subplot(221)
plt.scatter(x_norm_ls, y_norm_ls, c=[i for i in range(num_iter)], marker='o', label="Normalized variables")
plt.plot(x_norm_ls, y_norm_ls, color="green")
plt.plot(x_unitcirc, y_unitcirc, ':', linewidth = 0.5, color="blue", label="Unit circle")

plt.xlim([0, 1.5])
plt.ylim([0, 1.5])
plt.legend()

plt.subplot(222)
plt.scatter(x_ls, y_ls, c=[i for i in range(num_iter)], marker='o', label="CORDIC variables")
plt.plot(x_ls, y_ls, color="orange")
plt.plot(x_unitcirc, y_unitcirc, ':', linewidth = 0.5, color="blue", label="Unit circle")
plt.xlim([0, 1.5])
plt.ylim([0, 1.5])
plt.legend()

plt.subplot(223)
plt.plot(z_ls, marker='o', label="Residual angle")
plt.legend()

plt.subplot(224)
plt.plot(x_err, marker='o', label="x error")
plt.plot(y_err, marker='o', label="y error")
plt.legend()
plt.show()
