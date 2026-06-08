class Environment #(
  parameter int DATA_W    = 64,
  parameter int CHANNEL_W = 8,
  parameter int TX_DIR    = 4
);
  localparam int EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 );
  localparam int DIR_W   = ( TX_DIR == 1      ) ? ( 1 ) : ( $clog2( TX_DIR ) );

  Generator  #( DATA_W, EMPTY_W, CHANNEL_W, TX_DIR, DIR_W ) gen;
  Driver     #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W         ) drv;
  Monitor    #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W         ) mon [TX_DIR];
  Scoreboard #( DATA_W, EMPTY_W, CHANNEL_W, TX_DIR, DIR_W ) scb;

  mailbox #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) gen2drv;
  mailbox #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) mon2scb;

  virtual ast_in_if  #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) v_in_if;
  virtual ast_out_if #( DATA_W, EMPTY_W, CHANNEL_W        ) v_out_if [TX_DIR];

  function new(
    virtual ast_in_if  #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) v_in_if,
    virtual ast_out_if #( DATA_W, EMPTY_W, CHANNEL_W        ) v_out_if [TX_DIR]
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

  task run( int num_packets = 10 );
    $display("[ENV] @%0t: Starting testbench...", $time);
    foreach(mon[i])
      begin
        fork
          automatic int idx = i;
          mon[idx].run();
        join_none
      end

    fork
      gen.run( num_packets );
      drv.run();
      scb.run();
    join_any

    wait( gen2drv.num() == 0 );
    
    repeat(5)
      @( v_in_if.drv_cb );
    
    wait( mon2scb.num() == 0 );

    disable fork;

    scb.final_report();

    $display("[ENV] @%0t: Testbench finished.", $time);
  endtask
endclass