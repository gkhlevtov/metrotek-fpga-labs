class environment #(
  parameter int  DWIDTH          = 32,
  parameter int  AWIDTH          = 8,
  parameter bit  SHOWAHEAD       = 1,
  parameter bit  REGISTER_OUTPUT = 0,
  parameter bit  RESET_LOW       = 1
);
  localparam FIFO_SIZE = 2 ** AWIDTH;
  
  typedef logic [DWIDTH-1:0] word_t;

  generator    #( DWIDTH    ) gen;
  wr_driver    #( DWIDTH    ) wr_drv;
  rd_driver    #( DWIDTH    ) rd_drv;
  rst_driver   #( RESET_LOW ) rst_drv;
  wr_monitor   #( DWIDTH    ) wr_mon;
  rd_monitor   #( DWIDTH    ) rd_mon;
  golden_model #( DWIDTH    ) gm;
  
  mailbox #( word_t ) gen2drv;

  virtual wr_if  #( DWIDTH, AWIDTH ) wr_vif;
  virtual rd_if  #( DWIDTH, AWIDTH ) rd_vif;
  virtual rst_if #( RESET_LOW      ) rst_vif;

  // Run settings
  int unsigned num_random = 100;
  //int unsigned ready_prob = 100;
  time         reset_time = 10ns;

  function new(
    virtual wr_if  #( DWIDTH, AWIDTH ) wr_vif,
    virtual rd_if  #( DWIDTH, AWIDTH ) rd_vif,
    virtual rst_if #( RESET_LOW      ) rst_vif
  );
    this.wr_vif  = wr_vif;
    this.rd_vif  = rd_vif;
    this.rst_vif = rst_vif;
    
    gen2drv      = new();
    gm           = new(FIFO_SIZE);
    
    gen          = new( gen2drv    );
    wr_drv       = new( wr_vif, gm );
    rd_drv       = new( rd_vif     );
    rst_drv      = new( rst_vif    );
    wr_mon       = new( wr_vif, gm );
    rd_mon       = new( rd_vif, gm );
  endfunction

  task drain();
    int timeout = 150;
    int target;
    int completed;

    wait( gen2drv.num() == 0 );

    target    = gm.pushed;
    completed = gm.checked;
    
    while( ( completed < target ) && ( timeout > 0 ) )
      begin
        @( wr_vif.clk );
        timeout--;
      end

    if( timeout == 0 )
      begin
        $error("[ENV] drain: TIMEOUT (target=%0d, completed=%0d)", target, completed);
      end
  endtask
  
  task run();
    $display( "[@%0t][ENV]: Starting testbench:\nDWIDTH=%0d,\nSHOWAHEAD=%1b,\nREGISTER_OUTPUT=%1b,\nRESET_LOW=%1b",
              $time, DWIDTH, SHOWAHEAD, REGISTER_OUTPUT, RESET_LOW );

    rst_drv.pulse_rst(reset_time);
    #( reset_time )
    
    fork
      wr_drv.run();
      rd_drv.run();
      wr_mon.run();
      rd_mon.run();
    join_none
    
    
    gen.run_simple_test(num_random);
    drain();
    
    gm.finish();
    $display( "[@%0t][ENV]: Testbench finished.", $time );
  endtask
endclass
