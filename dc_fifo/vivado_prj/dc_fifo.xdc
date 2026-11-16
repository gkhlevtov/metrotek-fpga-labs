set WR_CLK_PERIOD 6.400
set RD_CLK_PERIOD 6.400
set MIN_PERIOD    [expr {min ( $WR_CLK_PERIOD, $RD_CLK_PERIOD )}]

create_clock -period $WR_CLK_PERIOD -name wr_clk [get_ports wr_clk_i]
create_clock -period $RD_CLK_PERIOD -name rd_clk [get_ports rd_clk_i]

set wr2rd_sync [get_cells -hierarchical -filter {NAME =~ *wr_ptr_gray_s1_reg*}]
set rd2wr_sync [get_cells -hierarchical -filter {NAME =~ *rd_ptr_gray_s1_reg*}]

set wr_ptr_src [get_cells -hierarchical -filter {NAME =~ *wr_ptr_gray_reg* }]
set rd_ptr_src [get_cells -hierarchical -filter {NAME =~ *rd_ptr_gray_reg* }]

set_max_delay -datapath_only -from $wr_ptr_src -to $wr2rd_sync $WR_CLK_PERIOD
set_max_delay -datapath_only -from $rd_ptr_src -to $rd2wr_sync $RD_CLK_PERIOD

set_bus_skew  -from $wr_ptr_src -to $wr2rd_sync $MIN_PERIOD
set_bus_skew  -from $rd_ptr_src -to $rd2wr_sync $MIN_PERIOD

set_property ram_style block [get_cells -hierarchical -filter { NAME =~ *ram_inst/mem* }]

set_property async_reg true [get_cells -hierarchical -filter { NAME =~ *gray_s1_reg* || NAME =~ *gray_s2_reg* }]   

set_property dont_touch true [get_cells -hierarchical -filter { NAME =~ *fifo_rd_ptr_bin_reg* || NAME =~ *wr_ptr_bin_reg* }]