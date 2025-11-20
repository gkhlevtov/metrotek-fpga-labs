vlib work
vlog ../rtl/crc_16_ansi.v
vlog -sv crc_16_ansi_tb.sv
vsim crc_16_ansi_tb
add wave *
run -all