class Environment #(
  parameter int IN_DATA_W  = 64,
  parameter int CHANNEL_W  = 10,
  parameter int OUT_DATA_W = 256
);
  localparam int IN_EMPTY_W  = ( $clog2(IN_DATA_W/8)  ) ? ( $clog2(IN_DATA_W/8)  ) : ( 1 );
  localparam int OUT_EMPTY_W = ( $clog2(OUT_DATA_W/8) ) ? ( $clog2(OUT_DATA_W/8) ) : ( 1 );
  localparam int N           = OUT_DATA_W / IN_DATA_W;

  Generator  #( IN_DATA_W,  IN_EMPTY_W,  OUT_DATA_W, CHANNEL_W ) gen;
  Driver     #( IN_DATA_W,  IN_EMPTY_W,  CHANNEL_W             ) drv;
  Monitor    #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W             ) mon;
  Scoreboard #( IN_DATA_W,  OUT_DATA_W,  CHANNEL_W             ) scb;

  mailbox #( AST_Transaction #( IN_DATA_W,  IN_EMPTY_W,  CHANNEL_W ) ) gen2drv;
  mailbox #( AST_Transaction #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W ) ) mon2scb;

  virtual ast_in_if  #( IN_DATA_W,  IN_EMPTY_W,  CHANNEL_W ) v_in_if;
  virtual ast_out_if #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W ) v_out_if;

  function new(
    virtual ast_in_if  #( IN_DATA_W,  IN_EMPTY_W,  CHANNEL_W ) v_in_if,
    virtual ast_out_if #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W ) v_out_if
  );
    this.v_in_if  = v_in_if;
    this.v_out_if = v_out_if;

    gen2drv = new();
    mon2scb = new();

    scb = new( mon2scb );
    gen = new( gen2drv, scb );
    drv = new( v_in_if,  gen2drv );
    mon = new( v_out_if, mon2scb );
  endfunction

  task run( int num_packets = 10 );
    $display("[ENV] @%0t: Starting (IN=%0d, OUT=%0d, N=%0d, packets=%0d)",
             $time, IN_DATA_W, OUT_DATA_W, N, num_packets);

    fork
      gen.run( num_packets );
      drv.run();
      mon.run();
      scb.run();
    join_any

    $display("[ENV] @%0t: Generator is done.", $time);

    wait( gen2drv.num() == 0 );

    repeat(5)
      @( v_in_if.drv_cb );

    wait( mon2scb.num() == 0 );

    disable fork;

    scb.final_report();
    $display("[ENV] @%0t: Testbench finished.", $time);
  endtask
endclass
