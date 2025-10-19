vlib work
vlog ../rtl/mux.v
vlog mux_tb.sv
vsim mux_tb
add wave *
run -all
