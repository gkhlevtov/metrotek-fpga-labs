class environment #(
  parameter int  DWIDTH          = 32,
  parameter int  AWIDTH          = 8,
  parameter bit  SHOWAHEAD       = 1,
  parameter bit  REGISTER_OUTPUT = 0,
  parameter bit  RESET_LOW       = 1
);
  localparam FIFO_SIZE = 2 ** AWIDTH;
  
  typedef logic [DWIDTH-1:0] word_t;

  generator    #( DWIDTH         ) gen;
  wr_driver    #( DWIDTH, AWIDTH ) wr_drv;
  rd_driver    #( DWIDTH, AWIDTH ) rd_drv;
  rst_driver   #( RESET_LOW      ) rst_drv;
  wr_monitor   #( DWIDTH, AWIDTH ) wr_mon;
  rd_monitor   #( DWIDTH, AWIDTH ) rd_mon;
  golden_model #( DWIDTH         ) gm;
  
  mailbox #( word_t ) gen2drv;

  virtual wr_if  #( DWIDTH, AWIDTH ) wr_vif;
  virtual rd_if  #( DWIDTH, AWIDTH ) rd_vif;
  virtual rst_if #( RESET_LOW      ) rst_vif;

  // Run settings
  int unsigned num_random = 100;
  time         reset_time = 50ns;

  function new(
    virtual wr_if  #( DWIDTH, AWIDTH ) wr_vif,
    virtual rd_if  #( DWIDTH, AWIDTH ) rd_vif,
    virtual rst_if #( RESET_LOW      ) rst_vif
  );
    this.wr_vif  = wr_vif;
    this.rd_vif  = rd_vif;
    this.rst_vif = rst_vif;
    
    gen2drv      = new();
    gm           = new( FIFO_SIZE       );
    
    gen          = new( gen2drv         );
    wr_drv       = new( wr_vif, gen2drv );
    rd_drv       = new( rd_vif          );
    rst_drv      = new( rst_vif         );
    wr_mon       = new( wr_vif, gm      );
    rd_mon       = new( rd_vif, gm      );

    rd_mon.data_next_cycle = ( !SHOWAHEAD && REGISTER_OUTPUT );
  endfunction

  task drain();
    int timeout = 1500;

    while( ( ( gen2drv.num != 0 ) || ( gm.checked < gen.idx ) ) && ( timeout > 0 ) )
      begin
        @( posedge rd_vif.clk );
        timeout--;
      end

    if( gm.checked < gen.idx  )
      begin
	gm.errors++;
        $error("[@%0t][ENV] drain: TIMEOUT (expecte: %0d, checked: %0d)",
		$time, gm.checked, gen.idx);
      end

    repeat(20)
      @( posedge rd_vif.clk );
  endtask
 
  task scenario( string name, int wr_prob, int rd_prob, int n );
    wr_drv.prob = wr_prob;
    rd_drv.prob = rd_prob;
    gen.run_simple_test( n );
    drain();
    $display( "[@%0t][ENV] Scenario '%s', checked: %0d, errors: %0d",
	       $time, name, gm.checked, gm.errors ); 
  endtask

  task run();
    $display( "[@%0t][ENV]: Starting testbench:\nDWIDTH=%0d,\nSHOWAHEAD=%1b,\nREGISTER_OUTPUT=%1b,\nRESET_LOW=%1b",
              $time, DWIDTH, SHOWAHEAD, REGISTER_OUTPUT, RESET_LOW );

    rst_drv.pulse_rst(reset_time);
    
    repeat(10)
      @( posedge wr_vif.clk );
    repeat(10)
      @( posedge rd_vif.clk );

    fork
      wr_drv.run();
      rd_drv.run();
      wr_mon.run();
      rd_mon.run();
    join_none
    
    scenario("full speed", 100, 100, num_random);
    drain();
    
    gm.finish( gen.idx );
    $display( "[@%0t][ENV]: Testbench finished.", $time );
  endtask
endclass
