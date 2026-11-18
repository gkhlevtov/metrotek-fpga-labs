file mkdir logs

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
set any_failed 0
set summary_report {}

foreach cfg $test_configs {
    lassign $cfg dw aw showahead reg_out wr_per wr_phs rd_per rd_phs seed

    set run_name "run${run_idx}_dw${dw}_aw${aw}_sa${showahead}_reg${reg_out}_wr_per${wr_per}_wr_phs${wr_phs}_rd_per${rd_per}_rd_phs${rd_phs}"
    puts "\n=================================================================="
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

    onbreak {
      if {![catch {assertion count -fails -r /} fail_cnt]} {
          set fail_cnt [string trim $fail_cnt]
          if {[string is integer -strict $fail_cnt] && $fail_cnt > 0} {
             puts "ERROR: Found $fail_cnt failed assertions!"
             assertion report -failed -r /
         }
      }
      resume
    }


    onfinish stop
    run -all

    set questa_err 0
    if {![catch {coverage attribute -name TESTSTATUS -concise} tstatus]} {
        if {$tstatus >= 2} {
            set questa_err 1
        }
    }

    quit -sim

    set fp [open "logs/${run_name}.log" r]
    set log_data [read $fp]
    close $fp

    if {[regexp -line {^#?\s*(\*\* (?:Error|Fatal).*)$} $log_data -> err_line]} {
        set status "FAILED: [string trim $err_line]"
        set any_failed 1
    } elseif {[regexp -line {^#?\s*(TEST FAILED.*)$} $log_data -> result_line]} {
        set status [string trim $result_line]
        set any_failed 1
    } elseif {$questa_err} {
        set status "FAILED (TESTSTATUS >= 2)"
        set any_failed 1
    } elseif {[regexp -line {^#?\s*(TEST PASSED.*)$} $log_data -> result_line]} {
        set status [string trim $result_line]
    } else {
        set status "FAILED (No PASSED message)"
        set any_failed 1
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

if {$any_failed} {
    puts "REGRESSION FAILED!"
    quit -f -code 1
} else {
    puts "ALL TESTS PASSED!"
    quit -f -code 0
}
