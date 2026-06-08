vlib work

vlog -sv ../rtl/ast_dmx.sv
vlog -sv ast_in_if.sv
vlog -sv ast_out_if.sv
vlog -sv ast_dmx_pkg.sv
vlog -sv ast_dmx_tb.sv

vsim -sv_seed 12345 ast_dmx_tb

add wave /ast_dmx_tb/clk

add wave -group "Input IF" \
  /ast_dmx_tb/in_if/srst          \
  /ast_dmx_tb/in_if/dir           \
  /ast_dmx_tb/in_if/valid         \
  /ast_dmx_tb/in_if/ready         \
  /ast_dmx_tb/in_if/startofpacket \
  /ast_dmx_tb/in_if/endofpacket   \
  /ast_dmx_tb/in_if/empty         \
  /ast_dmx_tb/in_if/channel       \
  /ast_dmx_tb/in_if/data

for {set i 0} {$i < 4} {incr i} {
  add wave -group "Output IF $i" \
    /ast_dmx_tb/out_if\[$i\]/valid         \
    /ast_dmx_tb/out_if\[$i\]/ready         \
    /ast_dmx_tb/out_if\[$i\]/startofpacket \
    /ast_dmx_tb/out_if\[$i\]/endofpacket   \
    /ast_dmx_tb/out_if\[$i\]/empty         \
    /ast_dmx_tb/out_if\[$i\]/channel       \
    /ast_dmx_tb/out_if\[$i\]/data
}

run -all
