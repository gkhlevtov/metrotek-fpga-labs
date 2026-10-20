vlib work

vlog -sv ../rtl/pkt_merge.sv
vlog -sv ast_in_if.sv
vlog -sv ast_out_if.sv
vlog -sv ctrl_if.sv
vlog -sv pkt_merge_pkg.sv
vlog -sv pkt_merge_tb.sv

vsim -sv_seed 12345 pkt_merge_tb

# ctrl
add wave -group pkt_merge_tb -group ctrl \
    /pkt_merge_tb/clk
add wave -group pkt_merge_tb -group ctrl \
    /pkt_merge_tb/ctrl_if_inst/rst
add wave -radix uns -group pkt_merge_tb -group ctrl \
    /pkt_merge_tb/ctrl_if_inst/offset

# snk_base
add wave -radix hex -group pkt_merge_tb -group snk_base \
    /pkt_merge_tb/snk_base_if/data
add wave -group pkt_merge_tb -group snk_base \
    /pkt_merge_tb/snk_base_if/valid
add wave -group pkt_merge_tb -group snk_base \
    /pkt_merge_tb/snk_base_if/ready
add wave -group pkt_merge_tb -group snk_base \
    /pkt_merge_tb/snk_base_if/sop
add wave -group pkt_merge_tb -group snk_base \
    /pkt_merge_tb/snk_base_if/eop
add wave -radix uns -group pkt_merge_tb -group snk_base \
    /pkt_merge_tb/snk_base_if/empty

# snk_to_insert
add wave -radix hex -group pkt_merge_tb -group snk_to_insert \
    /pkt_merge_tb/snk_to_insert_if/data
add wave -group pkt_merge_tb -group snk_to_insert \
    /pkt_merge_tb/snk_to_insert_if/valid
add wave -group pkt_merge_tb -group snk_to_insert \
    /pkt_merge_tb/snk_to_insert_if/ready
add wave -group pkt_merge_tb -group snk_to_insert \
    /pkt_merge_tb/snk_to_insert_if/sop
add wave -group pkt_merge_tb -group snk_to_insert \
    /pkt_merge_tb/snk_to_insert_if/eop
add wave -radix uns -group pkt_merge_tb -group snk_to_insert \
    /pkt_merge_tb/snk_to_insert_if/empty

# src
add wave -radix hex -group pkt_merge_tb -group src \
    /pkt_merge_tb/src_if/data
add wave -group pkt_merge_tb -group src \
    /pkt_merge_tb/src_if/valid
add wave -group pkt_merge_tb -group src \
    /pkt_merge_tb/src_if/ready
add wave -group pkt_merge_tb -group src \
    /pkt_merge_tb/src_if/sop
add wave -group pkt_merge_tb -group src \
    /pkt_merge_tb/src_if/eop
add wave -radix uns -group pkt_merge_tb -group src \
    /pkt_merge_tb/src_if/empty

# FSM
add wave -group pkt_merge_tb -group FSM \
    /pkt_merge_tb/dut/state

run -all