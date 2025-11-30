set_time_format -unit ns -decimal_places 3

create_clock -add -name clk_150 -period 6.667 [get_ports {clk_150m}]

derive_clock_uncertainty

set_input_delay  -clock clk_150 -max 0.0  [get_ports {srst_i data_i[*] data_mod_i[*] data_val_i}]
set_input_delay  -clock clk_150 -min 0.0  [get_ports {srst_i data_i[*] data_mod_i[*] data_val_i}]

set_output_delay -clock clk_150 -max 0.0  [get_ports {ser_data_o ser_data_val_o busy_o}]
set_output_delay -clock clk_150 -min 0.0  [get_ports {ser_data_o ser_data_val_o busy_o}]
