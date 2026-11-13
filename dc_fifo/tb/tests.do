vlib work

vlog -sv ../rtl/dc_fifo.sv
vlog -sv ../rtl/simple_dual_two_clocks.sv
vlog -sv wr_if.sv
vlog -sv rd_if.sv
vlog -sv dc_fifo_pkg.sv
vlog -sv dc_fifo_tb.sv

# { DWIDTH  AWIDTH  SHOWAHEAD  REG_OUT  WR_PER  WR_PHS  RD_PER  RD_PHS  SEED }
set test_configs {
    { 32      8       1          0        6.4     0.0     5.0   0.6    12345 }
    { 32      8       1          1        6.4     0.0     5.0   0.6    12345 }
    { 32      8       0          0        6.4     0.0     5.0   0.6    12345 }
    { 32      8       0          1        6.4     0.0     5.0   0.6    12345 }
    { 16      10      1          1        10.0    1.0     5.0   1.2    12345 }
    { 64      12      1          1        10.0    1.0     5.0   1.2    12345 }
    { 32      16      1          1        10.0    1.0     5.0   1.2    12345 }
    { 8       18      0          0        3.2     0.4     3.0   0.0    54321 }
    { 32      4       1          0        4.0     0.1     9.0   0.2    54321 }
    { 16      9       1          1        3.6     1.0     3.0   3.3    54321 }
    { 48      7       0          1        12.2    1.0     4.8   0.9    54321 }
}

set run_idx 1
foreach cfg $test_configs {
    lassign $cfg dw aw showahead reg_out wr_per wr_phs rd_per rd_phs seed

    set run_name "run${run_idx}_dw${dw}_aw${aw}_sa${showahead}_reg${reg_out}_wr_per${wr_per}_wr_phs${wr_phs}_rd_per${rd_per}_rd_phs${rd_phs}"
    puts ""
    puts "=================================================================="
    puts "RUN #$run_idx: $run_name"
    puts "=================================================================="

    vsim -voptargs=+acc \
         -sv_seed $seed \
         -gDWIDTH=$dw \
         -gAWIDTH=$aw \
         -gSHOWAHEAD=$showahead \
         -gREGISTER_OUTPUT=$reg_out \
         -gWR_CLK_PERIOD=$wr_per \
         -gWR_CLK_PHASE=$wr_phs \
         -gRD_CLK_PERIOD=$rd_per \
         -gRD_CLK_PHASE=$rd_phs \
         -l "logs/${run_name}.log" \
         work.dc_fifo_tb

    log -r /*

    radix -binary
    add wave -group write /dc_fifo_tb/wr_if_inst/clk
    add wave -group write /dc_fifo_tb/wr_if_inst/rst
    add wave -radix hex -group write /dc_fifo_tb/wr_if_inst/data
    add wave -group write /dc_fifo_tb/wr_if_inst/wrreq
    add wave -radix uns -group write /dc_fifo_tb/wr_if_inst/usedw
    add wave -group write /dc_fifo_tb/wr_if_inst/full
    add wave -group write /dc_fifo_tb/wr_if_inst/almost_full

    add wave -group read /dc_fifo_tb/rd_if_inst/clk
    add wave -group read /dc_fifo_tb/rd_if_inst/rst
    add wave -radix hex -group read /dc_fifo_tb/rd_if_inst/data
    add wave -group read /dc_fifo_tb/rd_if_inst/rdreq
    add wave -radix uns -group read /dc_fifo_tb/rd_if_inst/usedw
    add wave -group read /dc_fifo_tb/rd_if_inst/empty
    add wave -group read /dc_fifo_tb/rd_if_inst/almost_empty

    onfinish stop
    run -all

    quit -sim

    set fp [open logs/${run_name}.log r]
    set log_data [read $fp]
    close $fp

    if {[regexp -line {^#?\s*(TEST (?:PASSED|FAILED).*)$} $log_data -> result_line]} {
        set status [string trim $result_line]
    } elseif {[regexp -line {^#?\s*(\*\* (?:Error|Fatal).*)$} $log_data -> err_line]} {
        set status "FAILED: [string trim $err_line]"
    } else {
        set status "FAILED"
    }

    puts ">>> Run #$run_idx result: $status <<<"
    lappend summary_report [format "Run #%-2d | %-45s | %s" $run_idx $run_name $status]

    incr run_idx
}

puts "\n=================================================================="
puts "                     FINAL TESTBENCH REPORT                  "
puts "=================================================================="
foreach line $summary_report {
    puts $line
}
puts "=================================================================="
