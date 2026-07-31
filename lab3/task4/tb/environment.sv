class environment #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = DATA_WIDTH / 8
);
  generator          #( ADDR_WIDTH, BYTE_CNT             ) gen;
  driver             #( ADDR_WIDTH                       ) drv;
  ctrl_monitor       #( ADDR_WIDTH                       ) ctrl_mon;
  rd_monitor         #( DATA_WIDTH, ADDR_WIDTH           ) rd_mon;
  wr_monitor         #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) wr_mon;
  avalon_slave_model #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) slv;
  golden_model       #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) gm;
  scoreboard         #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) scb;

  mailbox #( ctrl_item #( ADDR_WIDTH )                       ) gen2drv;
  mailbox #( ctrl_item #( ADDR_WIDTH )                       ) ctrl2scb;
  mailbox #( rd_item   #( DATA_WIDTH, ADDR_WIDTH )           ) rd2scb;
  mailbox #( wr_item   #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) ) wr2scb;

  virtual amm_ctrl_if #( ADDR_WIDTH                       ) v_ctrl_if;
  virtual amm_rd_if   #( DATA_WIDTH, ADDR_WIDTH           ) v_rd_if;
  virtual amm_wr_if   #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) v_wr_if;

  function new(
    virtual amm_ctrl_if #( ADDR_WIDTH                       ) ctrl_if,
    virtual amm_rd_if   #( DATA_WIDTH, ADDR_WIDTH           ) rd_if,
    virtual amm_wr_if   #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) wr_if
  );
    v_ctrl_if = ctrl_if;
    v_rd_if   = rd_if;
    v_wr_if   = wr_if;

    gen2drv  = new();
    ctrl2scb = new();
    rd2scb   = new();
    wr2scb   = new();

    slv = new( rd_if, wr_if );
    gm  = new( slv );

    scb = new( ctrl2scb, rd2scb, wr2scb, gm );
    gen = new( gen2drv );
    drv = new( ctrl_if, gen2drv );

    ctrl_mon = new( ctrl_if, ctrl2scb );
    rd_mon   = new( rd_if, rd2scb     );
    wr_mon   = new( wr_if, wr2scb     );
  endfunction

  task drain();
    int          timeout = 150;
    int unsigned target;

    wait( gen2drv.num() == 0 );

    target = ctrl_mon.completed_jobs + 1;

    while( ( ctrl_mon.completed_jobs < target ) && ( timeout > 0 ) )
      begin
        @( v_ctrl_if.mon_cb );
        timeout--;
      end

    if( timeout == 0 )
      begin
        scb.error_count++;
        scb.clear_queues();
        $error("[ENV] drain: TIMEOUT waiting for job completion (target=%0d, completed=%0d)",
                target, ctrl_mon.completed_jobs);
      end
  endtask

  task run_byte_enable_test();
    bit [ADDR_WIDTH-1:0] base_addr;
    int unsigned         max_len;

    max_len   = BYTE_CNT * 2;
    base_addr = ( 1 << ADDR_WIDTH ) - 2;
    
    $display( "[ENV] @%0t:ByteEnable test: base_addr=%h, lengths 1..%0d ===",
              $time, base_addr, max_len );

    for( int len = 1; len <= max_len; len++ )
      begin
        gen.send_job( base_addr, ADDR_WIDTH'( len ) );
        drain();
      end
  endtask

  task run( int unsigned num_random_jobs = 20 );
    $display( "[ENV] @%0t: Starting testbench...", $time );

    fork
      ctrl_mon.run();
      rd_mon.run();
      wr_mon.run();
      slv.run_read();
      slv.run_write();
      drv.run();
      scb.run();
    join_none

    @( v_ctrl_if.drv_cb );
    drv.reset();

    @( v_ctrl_if.drv_cb );
    
    $display( "[ENV] @%0t: === Phase 1: no stalls, fixed read latency ===", $time );
    slv.set_rd_waitrequest_pct( 0 );
    slv.set_wr_waitrequest_pct( 0 );
    slv.set_rd_latency_range( 0, 0 );
    
    gen.test_length_one();
    drain();

    gen.test_full_word();
    drain();

    gen.test_partial_word();
    drain();

    gen.test_addr_overflow();
    drain();

    run_byte_enable_test();
    
    slv.set_range_value( 0, BYTE_CNT - 1, 8'hff );
    gen.test_wraparound();
    drain();

    gen.test_max_length();
    drain();
    
    $display( "[ENV] @%0t: === Phase 2: random waitrequest and variable latency ===", $time );
    slv.set_rd_waitrequest_pct( 30 );
    slv.set_wr_waitrequest_pct( 20 );
    slv.set_rd_latency_range( 0, 63 );

    @( v_ctrl_if.drv_cb );
    drv.reset();

    @( v_ctrl_if.drv_cb );

    gen.test_length_one();
    drain();

    gen.test_partial_word();
    drain();

    gen.test_addr_overflow();
    drain();

    /*
    repeat( RANDOM_JOBS )
      begin
        gen.test_random( 1 );
        drain();
      end
    */
    disable fork;

    scb.final_report();

    $display( "[ENV] @%0t: Testbench finished.", $time );
  endtask
endclass