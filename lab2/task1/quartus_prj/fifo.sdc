set_time_format -decimal_places 3 -unit ns

create_clock -add -name clk_150 -period 6.667 [get_ports {clk_150m}]

derive_clock_uncertainty

set_input_delay  -clock clk_150 -max 0.0  [get_ports {srst_i data_i[*] wrreq_i rdreq_i}]
set_input_delay  -clock clk_150 -min 0.0  [get_ports {srst_i data_i[*] wrreq_i rdreq_i}]

set_output_delay -clock clk_150 -max 0.0  [get_ports {q_o[*] empty_o full_o usedw_o[*] almost_full_o almost_empty_o}]
set_output_delay -clock clk_150 -min 0.0  [get_ports {q_o[*] empty_o full_o usedw_o[*] almost_full_o almost_empty_o}]