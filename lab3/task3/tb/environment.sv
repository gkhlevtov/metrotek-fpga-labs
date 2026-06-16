class Environment #(
  parameter int DATA_W    = 64,
  parameter int CHANNEL_W = 8,
  parameter int TX_DIR    = 4
);
  localparam int EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 );
  localparam int DIR_W   = ( TX_DIR == 1      ) ? ( 1 ) : ( $clog2( TX_DIR ) );

  Generator  #( DATA_W, EMPTY_W, CHANNEL_W, TX_DIR, DIR_W ) gen;
  Driver     #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W         ) drv;
  Monitor    #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W         ) mon [TX_DIR-1:0];
  Scoreboard #( DATA_W, EMPTY_W, CHANNEL_W, TX_DIR, DIR_W ) scb;

  mailbox #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) gen2drv;
  mailbox #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) mon2scb;

  virtual ast_in_if  #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) v_in_if;
  virtual ast_out_if #( DATA_W, EMPTY_W, CHANNEL_W        ) v_out_if [TX_DIR-1:0];

  int ready_prob = 100;
  bit sim_done   = 0;

  function new(
    virtual ast_in_if  #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) v_in_if,
    virtual ast_out_if #( DATA_W, EMPTY_W, CHANNEL_W        ) v_out_if [TX_DIR-1:0]
  );
    this.v_in_if  = v_in_if;
    this.v_out_if = v_out_if;

    gen2drv = new();
    mon2scb = new();

    scb = new( mon2scb );
    gen = new( gen2drv, scb );
    drv = new( v_in_if, gen2drv );

    foreach( v_out_if[i] )
      mon[i] = new( v_out_if[i], mon2scb, i );
  endfunction

  task run_ready_randomizer();
    bit prev_ready [TX_DIR-1:0];
    bit new_ready;

    foreach( prev_ready[i] )
      prev_ready[i] = 1'b1;

    forever
      begin
        @( v_out_if[0].drv_cb );
        if( sim_done )
          begin
            foreach( v_out_if[i] )
              begin
                v_out_if[i].drv_cb.ready <= 1'b1;

                /*
                if( prev_ready[i] !== 1'b1 )
                begin
                  $display("[READY_CTRL] @%0t: port %0d ready -> 1", $time, i);
                  prev_ready[i] = 1'b1;
                end
                */
              end
            break;
          end
        
        foreach( v_out_if[i] )
          begin
            new_ready = ( $urandom_range(0,99) < ready_prob ) ? 1'b1 : 1'b0;
            v_out_if[i].drv_cb.ready <= new_ready;

            /*
            if( new_ready !== prev_ready[i] )
              begin
                $display("[READY_CTRL] @%0t: port %0d ready -> %b", $time, i, new_ready);
                prev_ready[i] = new_ready;
              end
            */
          end
      end
  endtask

  task drain();
    wait( gen2drv.num() == 0 );

    repeat(5)
      @( v_in_if.drv_cb );

    wait( mon2scb.num() == 0 );
  endtask

  task run( int num_packets = 10 );
    $display("[ENV] @%0t: Starting testbench...", $time);

    sim_done = 0;
    foreach(mon[i])
      begin
        fork
          automatic int idx = i;
          mon[idx].run();
        join_none
      end

    fork
      run_ready_randomizer();
      drv.run();
      scb.run();
    join_none

    $display("[ENV] @%0t: === Phase 1: ready=1 always ===", $time);
    ready_prob = 100;
    gen.run( num_packets, 0 );
    drain();
    
    $display("[ENV] @%0t: === Phase 2: random ready=1 ===", $time);
    ready_prob = 50;
    gen.run( num_packets, 1 );
    drain();
    
    sim_done = 1;
    ready_prob = 100;
    repeat(5)
      @( v_in_if.drv_cb );

    disable fork;

    scb.final_report();

    $display("[ENV] @%0t: Testbench finished.", $time);
  endtask
endclass