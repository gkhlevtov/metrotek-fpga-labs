vlib work
vlog ../rtl/delay_15.v
vlog -sv delay_15_tb.sv
vsim delay_15_tb
add wave *
run -all