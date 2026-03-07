vlib work
vmap altera_mf /opt/fpga/quartus/18.1/modelsim_ase/altera/vhdl/altera_mf
vlog -sv ../rtl/fifo.sv
vlog -sv ../rtl/simple_dual_port_ram.sv
vlog -sv fifo_tb.sv
vsim -L altera_mf -onfinish stop fifo_tb
add wave *
run -all