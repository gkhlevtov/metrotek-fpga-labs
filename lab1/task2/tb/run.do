vlib work
vlog -sv ../rtl/deserializer.sv
vlog -sv deserializer_tb.sv
vsim deserializer_tb
add wave *
run -all