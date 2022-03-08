# Name of project
proj_name 	= cordic

# Source files used
source 		= rtl/design.v

# Testbench code
testbench	= tb/testbench.sv

# Lookup tables
data 		= data/arctan_lookup.txt

# Result of compilation
object		= out/$(proj_name).out

# Waveform file
wave		= out/$(proj_name).vcd

compile: $(object)
.PHONY: compile

$(object): $(source) $(testbench) $(data)
	iverilog -g2005-sv $(testbench) $(source) -o $(object)

$(wave): $(object) $(data)
	./$(object)

view: $(wave)
	gtkwave $(wave)
.PHONY: simulate

run: $(object)
	./$(object)
.PHONY:run

daisy: spi_daisy.vcd
	gtkwave spi_daisy.vcd
