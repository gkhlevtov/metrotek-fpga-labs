class environment #(
  parameter int DATA_W  = 64,
  parameter int EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 )
);
  localparam int TIMEOUT = 20000;

  generator  #( DATA_W          ) gen;
  driver     #( DATA_W, EMPTY_W ) base_drv;
  driver     #( DATA_W, EMPTY_W ) insert_drv;
  monitor    #( DATA_W, EMPTY_W ) src_mon;
  scoreboard #( DATA_W          ) scb;

  mailbox #( Input_Packet  #( DATA_W ) ) base_mbx;
  mailbox #( Input_Packet  #( DATA_W ) ) ins_mbx;
  mailbox #( Merge_Pair    #( DATA_W ) ) scb_pair_mbx;
  mailbox #( Output_Packet             ) scb_out_mbx;
  
  semaphore pair_done_sem = new( 0 );

  virtual ast_in_if  #( DATA_W, EMPTY_W ) base_drv_vif;
  virtual ast_in_if  #( DATA_W, EMPTY_W ) ins_drv_vif;
  virtual ast_out_if #( DATA_W, EMPTY_W ) src_mon_vif;
  virtual ctrl_if                         ctrl_vif;

  // Run settings
  int unsigned num_random   = 100;
  int unsigned ready_prob   = 100;
  int unsigned reset_cycles = 2;

  // Watchdog settings
  // Cycles without new words at the output
  int unsigned idle_limit  = 20000;
  // Overall duration limit
  int unsigned max_cycles  = 200000000;
  // Wait cycles for extra packets after the test ends
  int unsigned settle_time = 20;

  bit          timed_out   = 1'b0;
  int unsigned stage_cnt   = 0;
  int unsigned stage_fails = 0;

  function new(
    virtual ast_in_if  #( DATA_W, EMPTY_W ) base_drv_vif,
    virtual ast_in_if  #( DATA_W, EMPTY_W ) ins_drv_vif,
    virtual ast_out_if #( DATA_W, EMPTY_W ) src_mon_vif,
    virtual ctrl_if                         ctrl_vif
  );
    this.base_drv_vif = base_drv_vif;
    this.ins_drv_vif  = ins_drv_vif;
    this.src_mon_vif  = src_mon_vif;
    this.ctrl_vif     = ctrl_vif;

    base_mbx     = new();
    ins_mbx      = new();
    scb_pair_mbx = new();
    scb_out_mbx  = new();

    scb        = new( scb_pair_mbx, scb_out_mbx, pair_done_sem                 ); 
    gen        = new( base_mbx, ins_mbx, scb_pair_mbx, pair_done_sem, ctrl_vif );
    base_drv   = new( base_drv_vif, base_mbx                                   );
    insert_drv = new( ins_drv_vif,  ins_mbx                                    );
    src_mon    = new( src_mon_vif,  scb_out_mbx                                );
  endfunction

  task set_parameters(
    int unsigned ready   = 100,
    int unsigned gap     = 0,
    int unsigned gap_max = 3,
    int unsigned start   = 0
  );
    ready_prob = ready;

    base_drv.gap_prob    = gap;
    base_drv.gap_max     = gap_max;
    base_drv.delay_max   = start;

    insert_drv.gap_prob  = gap;
    insert_drv.gap_max   = gap_max;
    insert_drv.delay_max = start;

    $display( "[ENV] @%0t: New parameters: ready_prob=%0d%% gap_prob=%0d%% gap_max=%0d delay_max=%0d",
              $time, ready, gap, gap_max, start );
  endtask

  task run_ready_randomizer();
    forever
      begin
        @( src_mon_vif.drv_cb );
        src_mon_vif.drv_cb.ready <= ( $urandom_range( 0, 99 ) < ready_prob ) ? ( 1'b1 ) : ( 1'b0 );
      end
  endtask

  task watchdog();
    int unsigned idle  = 0;
    int unsigned total = 0;
    int unsigned last  = src_mon.beat_cnt;

    forever
      begin
        @( posedge ctrl_vif.clk );
        total++;

        if( src_mon.beat_cnt != last )
          begin
            last = src_mon.beat_cnt;
            idle = 0;
          end
        else
          idle++;

        if( ( idle >= idle_limit ) || ( total >= max_cycles ) )
          begin
            timed_out = 1'b1;
            $error( "[ENV] @%0t WATCHDOG: no output for %0d cycles (stage %0d cycles), checked %0d of %0d pairs",
                    $time, idle, total, scb.check_count, gen.pairs_sent );
            return;
          end
      end
  endtask

  task run_stage( string stage_name, string test, int unsigned num_random = 100 );
    int unsigned pairs_before   = gen.pairs_sent;
    int unsigned errors_before  = scb.error_count + src_mon.protocol_err;
    int unsigned bubbles_before = src_mon.total_bubbles;
    int unsigned beats_before   = src_mon.beat_cnt;
    bit          fail;

    if( timed_out )
      return;

    stage_cnt++;
    $display( "\n[ENV] @%0t: ===== STAGE %0d: %s (test=%s) =====", $time, stage_cnt, stage_name, test );

    fork
      begin
        fork
          gen.run( test, num_random );
          watchdog();
        join_any
        disable fork;
      end
    join

    if( !timed_out )
      repeat( settle_time )
        @( posedge ctrl_vif.clk );

    fail = timed_out
        || ( scb.check_count != gen.pairs_sent )
        || ( ( scb.error_count + src_mon.protocol_err ) != errors_before )
        || ( scb_out_mbx.num() != 0 )
        || src_mon.in_pkt;

    if( fail )
      stage_fails++;

    $display( "[ENV] @%0t: STAGE %0d %s: pairs=%0d out_beats=%0d bubbles_inside_pkt=%0d",
              $time, stage_cnt, ( fail ) ? ( "FAILED" ) : ( "ok" ),
              gen.pairs_sent - pairs_before,
              src_mon.beat_cnt - beats_before,
              src_mon.total_bubbles - bubbles_before );
  endtask

  task reset();
    ctrl_vif.drv_cb.rst      <= 1'b1;
    ctrl_vif.drv_cb.offset   <= 16'd1;
    src_mon_vif.drv_cb.ready <= 1'b1;

    base_drv.reset();
    insert_drv.reset();

    repeat( reset_cycles )
      @( ctrl_vif.drv_cb );

    ctrl_vif.drv_cb.rst <= 1'b0;

    repeat( 2 )
      @( ctrl_vif.drv_cb );

    $display( "[ENV] @%0t: Reset done", $time );
  endtask

  task run();
    bit pass;

    $display( "[ENV] @%0t: Starting testbench: DATA_W=%0d (N=%0d)", $time, DATA_W, DATA_W/8 );

    reset();

    fork
      base_drv.run();
      insert_drv.run();
      src_mon.run();
      scb.run();
      run_ready_randomizer();
    join_none
    
    // Stage 1: Ideal conditions tests
    set_parameters( .ready( 100 ), .gap( 0 ), .gap_max( 1 ), .start( 0 ) );
    run_stage( "ideal conditions", "all", 100 );
    
    // Stage 2: Output backpressure tests
    set_parameters( .ready( 50 ), .gap( 0 ), .gap_max( 1 ), .start( 0 ) );
    run_stage( "output backpressure", "all", 100 );
    
    // Stage 3: Valid stalls and random base/insert tests
    set_parameters( .ready( 100 ), .gap( 30 ), .gap_max( 3 ), .start( 5 ) );
    run_stage( "input gaps + random start", "all", 100 );
    
    // Stage 4: Bad conditions boundary tests
    set_parameters( .ready( 10 ), .gap( 50 ), .gap_max( 8 ), .start( 10 ) );
    run_stage( "bad conditions: boundary", "boundary" );

    // Stage 5: Bad conditions back-to-back tests
    run_stage( "bad conditions: back-to-back", "b2b" );

    // Stage 6: Bad conditions random tests
    run_stage( "bad conditions: random", "random", 300 );
    
    // Stage 7: Long random packets with stalls tests
    gen.max_len = 200;
    set_parameters( .ready( 70 ), .gap( 10 ), .gap_max( 2 ), .start( 2 ) );
    run_stage( "long random", "random", 200 );

    // Stage 8: Max lenght packets tests
    set_parameters( .ready( 100 ), .gap( 0 ), .gap_max( 1 ), .start( 0 ) );
    run_stage( "max length", "maxlen" );

    // Stage 9: Max lenght packets with stalls tests
    set_parameters( .ready( 60 ), .gap( 5 ), .gap_max( 2 ), .start( 3 ) );
    run_stage( "max length with stalls", "maxlen" );
    
    pass = scb.final_report( gen.pairs_sent, src_mon.protocol_err, timed_out, src_mon.in_pkt )
            && ( stage_fails == 0 );

    $display( "[ENV] drv base   : packets=%0d beats=%0d gaps=%0d",
              base_drv.pkt_cnt, base_drv.beat_cnt, base_drv.gap_cycles );
    $display( "[ENV] drv insert : packets=%0d beats=%0d gaps=%0d",
              insert_drv.pkt_cnt, insert_drv.beat_cnt, insert_drv.gap_cycles );
    $display( "[ENV] monitor    : packets=%0d beats=%0d bubbles_inside_pkt=%0d",
              src_mon.pkt_cnt, src_mon.beat_cnt, src_mon.total_bubbles );
    $display( "[ENV] stages     : %0d run, %0d failed",
              stage_cnt, stage_fails );
    $display( "[RESULT] N=%0d   : %s",
              DATA_W/8, ( pass ) ? ( "PASSED" ) : ( "FAILED" ) );
    $display( "[ENV] @%0t: Testbench finished.", $time );
  endtask
endclass