vlib work
vlog -sv ../rtl/traffic_lights.sv
vlog -sv traffic_lights_tb.sv
vsim -onfinish stop traffic_lights_tb
add wave *
run -all