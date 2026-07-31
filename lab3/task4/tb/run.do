vlib work

vlog -sv ../rtl/byte_inc.sv
vlog -sv amm_ctrl_if.sv
vlog -sv amm_rd_if.sv
vlog -sv amm_wr_if.sv
vlog -sv byte_inc_pkg.sv
vlog -sv byte_inc_tb.sv

vsim -sv_seed 12345 byte_inc_tb

add wave /byte_inc_tb/clk

add wave -group "Control IF"       \
  /byte_inc_tb/ctrl_if/srst        \
  /byte_inc_tb/ctrl_if/base_addr   \
  /byte_inc_tb/ctrl_if/length      \
  /byte_inc_tb/ctrl_if/run         \
  /byte_inc_tb/ctrl_if/waitrequest

add wave -group "Reading IF"          \
  /byte_inc_tb/rd_if/rd_address       \
  /byte_inc_tb/rd_if/rd_read          \
  /byte_inc_tb/rd_if/rd_readdata      \
  /byte_inc_tb/rd_if/rd_readdatavalid \
  /byte_inc_tb/rd_if/rd_waitrequest

add wave -group "Writing IF"        \
  /byte_inc_tb/wr_if/wr_address     \
  /byte_inc_tb/wr_if/wr_write       \
  /byte_inc_tb/wr_if/wr_writedata   \
  /byte_inc_tb/wr_if/wr_byteenable  \
  /byte_inc_tb/wr_if/wr_waitrequest

run -all