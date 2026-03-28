set_time_format -decimal_places 3 -unit ns

create_clock -add -name clk_150 -period 6.667 [get_ports {clk_150m}]

derive_clock_uncertainty

set_input_delay  -clock clk_150 -max 0.0  [get_ports {srst_i snk_data_i[*] snk_startofpacket_i snk_endofpacket_i snk_valid_i src_ready_i}]
set_input_delay  -clock clk_150 -min 0.0  [get_ports {srst_i snk_data_i[*] snk_startofpacket_i snk_endofpacket_i snk_valid_i src_ready_i}]

set_output_delay -clock clk_150 -max 0.0  [get_ports {snk_ready_o src_data_o[*] src_startofpacket_o src_endofpacket_o src_valid_o}]
set_output_delay -clock clk_150 -min 0.0  [get_ports {snk_ready_o src_data_o[*] src_startofpacket_o src_endofpacket_o src_valid_o}]