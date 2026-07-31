class scoreboard #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = DATA_WIDTH / 8
);
  golden_model #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) gm;

  wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) exp_wr_q      [$];
  bit [ADDR_WIDTH-1:0]                          exp_rd_addr_q [$];

  int unsigned rd_next_seq = 0;

  int unsigned check_count = 0;
  int unsigned error_count = 0;

  mailbox #( ctrl_item #( ADDR_WIDTH                       ) ) ctrl2scb;
  mailbox #( rd_item   #( DATA_WIDTH, ADDR_WIDTH           ) ) rd2scb;
  mailbox #( wr_item   #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) ) wr2scb;

  function new(
    mailbox #( ctrl_item #( ADDR_WIDTH                     ) ) ctrl2scb,
    mailbox #( rd_item #( DATA_WIDTH, ADDR_WIDTH           ) ) rd2scb,
    mailbox #( wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) ) wr2scb,
    golden_model #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT )         gm
  );
    this.ctrl2scb = ctrl2scb;
    this.rd2scb   = rd2scb;
    this.wr2scb   = wr2scb;
    this.gm       = gm;
  endfunction

  function void clear_queues();
    exp_wr_q.delete();
    exp_rd_addr_q.delete();
  endfunction
  
  task run();
    fork
      run_ctrl();
      run_rd();
      run_wr();
    join_none
  endtask

  task run_ctrl();
    ctrl_item #( ADDR_WIDTH )                       job;
    wr_item   #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) job_wr_q [$];

    forever
      begin
        ctrl2scb.get( job );

        gm.predict( job, job_wr_q );

        foreach( job_wr_q[i] )
          begin
            exp_wr_q.push_back( job_wr_q[i] );
            exp_rd_addr_q.push_back( job_wr_q[i].address );
          end

        $display( "[SCB ADD] @%0t job base_addr=%h length=%0d -> %0d expected word(s)",
                    $time, job.base_addr, job.length, job_wr_q.size() );
      end
  endtask

  task run_rd();
    rd_item #( DATA_WIDTH, ADDR_WIDTH ) tr;

    forever
      begin
        rd2scb.get( tr );
        check_beat_rd( tr );
      end
  endtask

  task run_wr();
    wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) tr;

    forever
      begin
        wr2scb.get( tr );
        check_beat_wr( tr );
      end
  endtask

  task check_beat_rd( rd_item #( DATA_WIDTH, ADDR_WIDTH ) tr );
    bit [ADDR_WIDTH-1:0] exp_addr;
    int unsigned         latency;
    bit                  beat_ok = 1'b1;

    check_count++;

    if( exp_rd_addr_q.size() == 0 )
      begin
        $error( "[SCB] @%0t beat #%0d: read to addr=%h was NOT EXPECTED (no pending job)!",
                $time, check_count, tr.address );
        error_count++;
        return;
      end

    if( tr.seq_num !== rd_next_seq )
      begin
        $error( "[SCB] @%0t beat #%0d: READ RESPONSE ORDER VIOLATION! Got seq=%0d Exp seq=%0d",
                $time, check_count, tr.seq_num, rd_next_seq );
        beat_ok = 1'b0;
      end
    rd_next_seq++;

    exp_addr = exp_rd_addr_q.pop_front();
    latency  = tr.resp_time - tr.req_time;

    if( tr.address !== exp_addr )
      begin
        $error( "[SCB] @%0t beat #%0d: READ ADDRESS mismatch! Got=%h Exp=%h",
                $time, check_count, tr.address, exp_addr );
        beat_ok = 1'b0;
      end

    if( ( latency < 1 ) || ( latency > 64 ) )
      begin
        $error( "[SCB] @%0t beat #%0d: READ LATENCY out of range! addr=%h latency=%0d",
                $time, check_count, tr.address, latency );
        beat_ok = 1'b0;
      end

    if( beat_ok )
      $display( "[SCB] @%0t beat #%0d: read addr=%h data=%h latency=%0d seq=%0d PASSED",
                $time, check_count, tr.address, tr.readdata, latency, tr.seq_num );
    else
      error_count++;
  endtask

  task check_beat_wr( wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) tr );
    wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) exp_tr;
    bit                                           beat_ok = 1'b1;

    check_count++;

    if( exp_wr_q.size() == 0 )
      begin
        $error( "[SCB] @%0t beat #%0d: write to addr=%h was NOT EXPECTED (no pending job)!",
                $time, check_count, tr.address );
        error_count++;
        return;
      end

    exp_tr = exp_wr_q.pop_front();

    if( tr.address !== exp_tr.address )
      begin
        $error( "[SCB] @%0t beat #%0d: WRITE ADDRESS mismatch! Got=%h Exp=%h",
                $time, check_count, tr.address, exp_tr.address );
        beat_ok = 1'b0;
      end

    if( tr.byteenable !== exp_tr.byteenable )
      begin
        $error( "[SCB] @%0t beat #%0d: BYTEENABLE mismatch! addr=%h Got=%b Exp=%b",
                $time, check_count, tr.address, tr.byteenable, exp_tr.byteenable );
        beat_ok = 1'b0;
      end

    for( int b = 0; b < BYTE_CNT; b++ )
      if( exp_tr.byteenable[b] )
        if( tr.writedata[ b*8 +: 8 ] !== exp_tr.writedata[ b*8 +: 8 ] )
          begin
            $error( "[SCB] @%0t beat #%0d: WRITEDATA mismatch! addr=%h byte=%0d Got=%h Exp=%h",
                    $time, check_count, tr.address, b,
                    tr.writedata[ b*8 +: 8 ], exp_tr.writedata[ b*8 +: 8 ] );
            beat_ok = 1'b0;
          end

    if( beat_ok )
      $display( "[SCB] @%0t beat #%0d: write addr=%h data=%h be=%b PASSED",
                  $time, check_count, tr.address, tr.writedata, tr.byteenable );
    else
      error_count++;
  endtask

  function void final_report();
    if( exp_wr_q.size() > 0 )
      begin
        $error( "[SCB] final_report: %0d expected write(s) never observed - LOST TRANSACTIONS!",
                exp_wr_q.size() );
        error_count++;
      end

    if( exp_rd_addr_q.size() > 0 )
      begin
        $error( "[SCB] final_report: %0d expected read(s) never observed - LOST TRANSACTIONS!",
                exp_rd_addr_q.size() );
        error_count++;
      end

    $display( "\n==============================================" );
    $display( "\tBYTE_INC TB - FINAL REPORT" );
    $display( "\tChecks         : %0d", check_count );
    $display( "\tErrors         : %0d", error_count );
    if( error_count == 0 )
      $display( "\tOVERALL STATUS : PASSED" );
    else
      $display( "\tOVERALL STATUS : FAILED" );
    $display( "==============================================\n" );
  endfunction

endclass