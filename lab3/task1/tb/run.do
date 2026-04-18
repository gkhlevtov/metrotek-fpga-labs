vlib work
vlog -sv ../rtl/lifo.sv
vlog -sv lifo_if.sv
vlog -sv lifo_pkg.sv
vlog -sv lifo_tb.sv
vsim -sv_seed 12345 lifo_tb
add wave -r /*
run -all
