class Environment #(
  parameter int DWIDTH        = 16,
  parameter int AWIDTH        = 8,
  parameter int ALMOST_FULL   = 2,
  parameter int ALMOST_EMPTY  = 2
);
  Generator  #( DWIDTH, AWIDTH                            ) gen;
  Driver     #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) drv;
  Monitor    #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) mon;
  Scoreboard #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) scb;

  mailbox #( Transaction #( DWIDTH, AWIDTH ) ) gen2drv;
  mailbox #( Transaction #( DWIDTH, AWIDTH ) ) mon2scb;

  virtual lifo_if #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) v_if;

  function new(
    virtual lifo_if #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) v_if
  );
    this.v_if = v_if;
    gen2drv   = new();
    mon2scb   = new();

    gen = new( gen2drv );
    drv = new( v_if, gen2drv );
    mon = new( v_if, mon2scb );
    scb = new( mon2scb );
  endfunction

  task run( int num_tr = 100 );
    fork
      gen.run( num_tr );
      drv.run();
      mon.run();
      scb.run();
    join_any

    $display("[ENV] @%0t: Generator is done.", $time);

    wait( gen2drv.num() == 0 )
    
    repeat(10)
      @( v_if.drv_cb );

    wait( mon2scb.num() == 0 );

    disable fork;

    $display("[ENV] @%0t: Testbench finished.", $time);
  endtask

endclass