vlib work

vlog -sv ../rtl/dc_fifo.sv
vlog -sv ../rtl/simple_dual_two_clocks.sv
vlog -sv wr_if.sv
vlog -sv rd_if.sv
vlog -sv rst_if.sv
vlog -sv dc_fifo_pkg.sv
vlog -sv dc_fifo_tb.sv

vsim -sv_seed 12345 dc_fifo_tb

radix -binary

add wave /dc_fifo_tb/rst_if_inst/rst
    
# write
add wave -group write /dc_fifo_tb/wr_if_inst/clk
add wave -radix hex -group write /dc_fifo_tb/wr_if_inst/data
add wave -group write /dc_fifo_tb/wr_if_inst/wrreq
add wave -radix uns -group write /dc_fifo_tb/wr_if_inst/usedw
add wave -group write /dc_fifo_tb/wr_if_inst/full
add wave -group write /dc_fifo_tb/wr_if_inst/almost_full

# read
add wave -group read /dc_fifo_tb/rd_if_inst/clk
add wave -radix hex -group read /dc_fifo_tb/rd_if_inst/data
add wave -group read /dc_fifo_tb/rd_if_inst/rdreq
add wave -radix uns -group read /dc_fifo_tb/rd_if_inst/usedw
add wave -group read /dc_fifo_tb/rd_if_inst/empty
add wave -group read /dc_fifo_tb/rd_if_inst/almost_empty

run -all
