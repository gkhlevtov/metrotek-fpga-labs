vlib work
vlog -sv ../rtl/avalon_st_sort.sv
vlog -sv ../rtl/simple_dual_port_ram.sv
vlog -sv avalon_st_sort_tb.sv
vsim -onfinish stop avalon_st_sort_tb
add wave *
run -all