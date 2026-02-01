vlib work
vlog -sv ../rtl/debouncer.sv
vlog -sv debouncer_tb.sv
vsim -onfinish stop debouncer_tb
add wave *
run -all