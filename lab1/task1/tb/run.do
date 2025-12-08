vlib work
vlog -sv ../rtl/serializer.sv
vlog -sv serializer_tb.sv
vsim serializer_tb
add wave *
run -all