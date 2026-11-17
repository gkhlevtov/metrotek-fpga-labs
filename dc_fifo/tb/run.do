onerror {
    puts "ERROR: Compilation or simulation failed!"
    if {[batch_mode]} { quit -f -code 1 }
}

if {![file exists work]} {
    vlib work
}

vlog -sv ../rtl/dc_fifo.sv
vlog -sv ../rtl/simple_dual_two_clocks.sv
vlog -sv wr_if.sv
vlog -sv rd_if.sv
vlog -sv dc_fifo_pkg.sv
vlog -sv dc_fifo_tb.sv

if {[batch_mode]} {
    puts ">>> Running in BATCH mode: executing tests (tests.do) <<<"
    do tests.do
} else {
    puts ">>> Running in GUI mode: executing single run with waves (run.do) <<<"

    vsim -voptargs=+acc work.dc_fifo_tb
    vsim -sv_seed 12345 work.dc_fifo_tb

    log -r /*
    if {[file exists wave.do]} {
        do wave.do
    }

    onfinish stop
    run -all
}

