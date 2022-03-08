import numpy as np

def fraction_from_hex(inp):
    num = int(inp, 16)
    num = float(num) * (2 ** -31)
    if(num > 1):
        num = num - 2
    return num

def rad_from_fraction(inp):
    return inp * np.pi

def degree_from_fraction(inp):
    return inp * 180

def degree_from_hex(inp):
    return degree_from_fraction(fraction_from_hex(inp))

def fraction_from_rad(inp):
    return inp / np.pi

def fraction_from_degree(inp):
    return inp / 180

def hex_from_fraction(inp):
    val = int(inp * (2 ** 31))
    return '{0:0{1}X}'.format(val,8)
