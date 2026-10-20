set_time_format -decimal_places 3 -unit ns

create_clock -name clk_125m -period 8.000 [get_ports {clk_125m}]

derive_clock_uncertainty

set_input_delay  -clock clk_125m -max 0.0 [get_ports {rst_i offset_i[*] snk_base_data_i[*] snk_base_valid_i snk_base_startofpacket_i snk_base_endofpacket_i snk_base_empty_i[*] snk_to_insert_data_i[*] snk_to_insert_valid_i snk_to_insert_startofpacket_i snk_to_insert_endofpacket_i snk_to_insert_empty_i[*] src_ready_i}]
set_input_delay  -clock clk_125m -min 0.0 [get_ports {rst_i offset_i[*] snk_base_data_i[*] snk_base_valid_i snk_base_startofpacket_i snk_base_endofpacket_i snk_base_empty_i[*] snk_to_insert_data_i[*] snk_to_insert_valid_i snk_to_insert_startofpacket_i snk_to_insert_endofpacket_i snk_to_insert_empty_i[*] src_ready_i}]

set_output_delay -clock clk_125m -max 0.0 [get_ports {snk_base_ready_o snk_to_insert_ready_o src_data_o[*] src_valid_o src_startofpacket_o src_endofpacket_o src_empty_o[*]}]
set_output_delay -clock clk_125m -min 0.0 [get_ports {snk_base_ready_o snk_to_insert_ready_o src_data_o[*] src_valid_o src_startofpacket_o src_endofpacket_o src_empty_o[*]}]