set_time_format -decimal_places 3 -unit ns

create_clock -add -name clk_150 -period 6.667 [get_ports {clk_150m}]

derive_clock_uncertainty

set_input_delay  -clock clk_150 -max 0.0  [get_ports {srst_i data_i[*] data_val_i}]
set_input_delay  -clock clk_150 -min 0.0  [get_ports {srst_i data_i[*] data_val_i}]

set_output_delay -clock clk_150 -max 0.0  [get_ports {data_o[*] data_val_o}]
set_output_delay -clock clk_150 -min 0.0  [get_ports {data_o[*] data_val_o}]