radix -binary
add wave -group write /dc_fifo_tb/wr_if_inst/clk
add wave -group write /dc_fifo_tb/wr_if_inst/rst
add wave -radix hex -group write /dc_fifo_tb/wr_if_inst/data
add wave -group write /dc_fifo_tb/wr_if_inst/wrreq
add wave -radix uns -group write /dc_fifo_tb/wr_if_inst/usedw
add wave -group write /dc_fifo_tb/wr_if_inst/full
add wave -group write /dc_fifo_tb/wr_if_inst/almost_full

add wave -group read /dc_fifo_tb/rd_if_inst/clk
add wave -group read /dc_fifo_tb/rd_if_inst/rst
add wave -radix hex -group read /dc_fifo_tb/rd_if_inst/data
add wave -group read /dc_fifo_tb/rd_if_inst/rdreq
add wave -radix uns -group read /dc_fifo_tb/rd_if_inst/usedw
add wave -group read /dc_fifo_tb/rd_if_inst/empty
add wave -group read /dc_fifo_tb/rd_if_inst/almost_empty

wave refresh
