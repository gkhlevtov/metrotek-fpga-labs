set proj_name "dc_fifo"
set proj_dir  "./vivado_prj"
set part_name "xcku035-ffva1156-1-c"

create_project $proj_name $proj_dir -part $part_name -force

add_files -norecurse {
    ./rtl/dc_fifo_top.sv
    ./rtl/dc_fifo.sv
    ./rtl/simple_dual_two_clocks.sv
}

add_files -fileset constrs_1 -norecurse $proj_dir/dc_fifo.xdc

set_property top dc_fifo_top [current_fileset]

file mkdir $proj_dir/ip

create_ip -name xxv_ethernet -vendor xilinx.com -library ip -module_name xxv_ethernet_0 -dir $proj_dir/ip

set_property -dict [list \
    CONFIG.NUM_OF_CORES {2} \
    CONFIG.CORE {Ethernet MAC+PCS/PMA 64-bit} \
    CONFIG.LINE_RATE {10} \
    CONFIG.DATA_PATH_INTERFACE {AXI Stream} \
    CONFIG.BASE_R_KR {BASE-R} \
    CONFIG.INCLUDE_AXI4_INTERFACE {0} \
    CONFIG.INCLUDE_STATISTICS_COUNTERS {0} \
    CONFIG.GT_REF_CLK_FREQ {156.25} \
    CONFIG.INCLUDE_SHARED_LOGIC {1} \
] [get_ips xxv_ethernet_0]

generate_target all [get_files xxv_ethernet_0.xci]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project $proj_name succesfully built at $proj_dir"
