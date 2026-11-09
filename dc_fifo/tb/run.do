vlib work

vlog -sv ../rtl/dc_fifo.sv
vlog -sv wr_if.sv
vlog -sv rd_if.sv
vlog -sv rst_if.sv
vlog -sv dc_fifo_pkg.sv
vlog -sv dc_fifo_tb.sv

vsim -sv_seed 12345 dc_fifo_tb

add wave /pkt_merge_tb/rst_if_inst/rst
    
# write
add wave -group dc_fifo_tb -group write /dc_fifo_tb/wr_clk
add wave -radix hex -group dc_fifo_tb -group write /dc_fifo_tb/wr_if_inst/data
add wave -group dc_fifo_tb -group write /dc_fifo_tb/wr_if_inst/wrreq
add wave -radix uns -group dc_fifo_tb -group write /dc_fifo_tb/wr_if_inst/usedw
add wave -group dc_fifo_tb -group write /dc_fifo_tb/wr_if_inst/full
add wave -group dc_fifo_tb -group write /dc_fifo_tb/wr_if_inst/almost_full

# read
add wave -group dc_fifo_tb -group read /dc_fifo_tb/wr_clk
add wave -radix hex -group dc_fifo_tb -group read /dc_fifo_tb/rd_if_inst/data
add wave -group dc_fifo_tb -group read /dc_fifo_tb/rd_if_inst/rdreq
add wave -radix uns -group dc_fifo_tb -group read /dc_fifo_tb/rd_if_inst/usedw
add wave -group dc_fifo_tb -group read /dc_fifo_tb/rd_if_inst/empty
add wave -group dc_fifo_tb -group read /dc_fifo_tb/rd_if_inst/almost_empty

run -all
