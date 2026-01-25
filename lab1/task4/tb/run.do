vlib work
vlog -sv ../rtl/bit_population_counter.sv
vlog -sv bit_population_counter_tb.sv
vsim -onfinish stop bit_population_counter_tb
add wave *
run -all