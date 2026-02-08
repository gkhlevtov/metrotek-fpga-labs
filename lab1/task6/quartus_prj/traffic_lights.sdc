set_time_format -decimal_places 3 -unit ns

create_clock -name clk_0m002 -period 500000 [get_ports {clk_0m002}]

derive_clock_uncertainty

set_input_delay  -clock clk_0m002 -max 0.0  [get_ports {srst_i cmd_type_i[*] cmd_valid_i cmd_data_i[*]}]
set_input_delay  -clock clk_0m002 -min 0.0  [get_ports {srst_i cmd_type_i[*] cmd_valid_i cmd_data_i[*]}]

set_output_delay -clock clk_0m002 -max 0.0  [get_ports {red_o yellow_o green_o}]
set_output_delay -clock clk_0m002 -min 0.0  [get_ports {red_o yellow_o green_o}]