vlib work

vlog -sv ../rtl/ast_width_extender.sv
vlog -sv ast_in_if.sv
vlog -sv ast_out_if.sv
vlog -sv ast_width_extender_pkg.sv
vlog -sv ast_width_extender_tb.sv

vsim -sv_seed 12345 ast_width_extender_tb

add wave /ast_width_extender_tb/clk

add wave -group "Input IF" \
  /ast_width_extender_tb/in_if/srst          \
  /ast_width_extender_tb/in_if/valid         \
  /ast_width_extender_tb/in_if/ready         \
  /ast_width_extender_tb/in_if/startofpacket \
  /ast_width_extender_tb/in_if/endofpacket   \
  /ast_width_extender_tb/in_if/empty         \
  /ast_width_extender_tb/in_if/channel       \
  /ast_width_extender_tb/in_if/data

add wave -group "Output IF" \
  /ast_width_extender_tb/out_if/valid         \
  /ast_width_extender_tb/out_if/ready         \
  /ast_width_extender_tb/out_if/startofpacket \
  /ast_width_extender_tb/out_if/endofpacket   \
  /ast_width_extender_tb/out_if/empty         \
  /ast_width_extender_tb/out_if/channel       \
  /ast_width_extender_tb/out_if/data

run -all
