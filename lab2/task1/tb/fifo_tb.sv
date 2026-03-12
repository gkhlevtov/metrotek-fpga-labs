module fifo_tb;
  // FIFO parameters
  parameter int DWIDTH             = 8;
  parameter int AWIDTH             = 8;
  parameter int SHOWAHEAD          = 1;
  parameter int ALMOST_FULL_VALUE  = 250;
  parameter int ALMOST_EMPTY_VALUE = 5;
  parameter int REGISTER_OUTPUT    = 0;

  // Number of random tests 
  parameter int N                  = 200;

  bit                clk;
  bit                srst;
  logic [DWIDTH-1:0] data_i;
  logic              wrreq_i;
  logic              rdreq_i;
  
  // Golden model and DUT output ports
  logic [DWIDTH-1:0] gm_q_o;
  logic [DWIDTH-1:0] dut_q_o;

  logic              gm_empty_o;
  logic              dut_empty_o;

  logic              gm_full_o;
  logic              dut_full_o;

  logic [AWIDTH-1:0] gm_usedw_o;
  logic [AWIDTH:0]   dut_usedw_o;

  logic              gm_almost_full_o;
  logic              dut_almost_full_o;

  logic              gm_almost_empty_o;
  logic              dut_almost_empty_o;

  logic [1:0]        gm_eccstatus_o;

  // Simulation success flag
  bit pass_flag;

  // Reset event
  event rst_done;

  initial
    forever
      #5 clk = !clk;

  initial
    begin
      clk       = '0;
      srst      = '0;
      data_i    = '0;
      wrreq_i   = '0;
      rdreq_i   = '0;
      pass_flag = '1;

      @( posedge clk );
      srst      = '1;

      @( posedge clk );
      srst      = '0;
      -> rst_done;
    end
  
  scfifo #(
    .lpm_width               ( DWIDTH                ),
    .lpm_widthu              ( AWIDTH                ),
    .lpm_numwords            ( 2 ** AWIDTH           ),
    .lpm_showahead           ( "ON"                  ),
    .lpm_type                ( "scfifo"              ),
    .lpm_hint                ( "RAM_BLOCK_TYPE=M10K" ),
    .intended_device_family  ( "Cyclone V"           ),
    .underflow_checking      ( "ON"                  ),
    .overflow_checking       ( "ON"                  ),
    .allow_rwcycle_when_full ( "OFF"                 ),
    .use_eab                 ( "ON"                  ),
    .add_ram_output_register ( "OFF"                 ),
    .almost_full_value       ( ALMOST_FULL_VALUE     ),
    .almost_empty_value      ( ALMOST_EMPTY_VALUE    ),
    .maximum_depth           ( 0                     ),
    .enable_ecc              ( "FALSE"               )
  ) golden_model (
    .clock                   ( clk                   ),
    .sclr                    ( srst                  ),
    .aclr                    ( 1'b0                  ),
    .data                    ( data_i                ),
    .wrreq                   ( wrreq_i               ),
    .rdreq                   ( rdreq_i               ),
    .q                       ( gm_q_o                ),
    .full                    ( gm_full_o             ),
    .almost_full             ( gm_almost_full_o      ),
    .empty                   ( gm_empty_o            ),
    .almost_empty            ( gm_almost_empty_o     ),
    .usedw                   ( gm_usedw_o            ),
    .eccstatus               ( gm_eccstatus_o        )
  );

  fifo #(
    .DWIDTH             ( DWIDTH             ),
    .AWIDTH             ( AWIDTH             ),
    .SHOWAHEAD          ( SHOWAHEAD          ),
    .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE  ),
    .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE ),
    .REGISTER_OUTPUT    ( REGISTER_OUTPUT    )
  ) fifo_inst (
    .clk_i              ( clk                ),
    .srst_i             ( srst               ),
    .data_i             ( data_i             ),
    .wrreq_i            ( wrreq_i            ),
    .rdreq_i            ( rdreq_i            ),
    .q_o                ( dut_q_o            ),
    .empty_o            ( dut_empty_o        ),
    .full_o             ( dut_full_o         ),
    .usedw_o            ( dut_usedw_o        ),
    .almost_full_o      ( dut_almost_full_o  ),
    .almost_empty_o     ( dut_almost_empty_o )
  );

  task automatic write(logic [DWIDTH-1:0] data);
    begin
      if( ( dut_full_o == 0 ) && ( gm_full_o == 0 ) )
        begin
          wrreq_i <= 1'b1;
          data_i  <= data;
          @( posedge clk );
          wrreq_i <= 1'b0;
        end
    end
  endtask

  task automatic read();
    begin
      if( ( dut_empty_o == 0 ) && ( gm_empty_o == 0 ) )
        begin
          rdreq_i <= 1'b1;
          @( posedge clk );
          rdreq_i <= 1'b0;
        end
    end
  endtask

  task automatic run_test_full_empty();
    begin
      // Full test
      repeat(2**AWIDTH + 1) 
        write($urandom());
      
      @( posedge clk );

      if( dut_full_o != 1'b1 )
        begin
          $error("Error at %0t: DUT is not full!", $time);
          pass_flag = 1'b0;
        end
      
      // Empty test
      repeat(2**AWIDTH) 
        read();
      
      @( posedge clk );

      if( dut_empty_o !== 1'b1 )
        begin
          $error("Error at %0t: DUT is not empty!", $time);
          pass_flag = 1'b0;
        end
    end
  endtask

  task automatic run_test_simultaneous(int cycles);
    begin
      repeat(10)
        write($urandom());
      
      repeat(cycles)
        begin
          @( posedge clk );
          if( ( !dut_full_o ) && ( !dut_empty_o ) )
            begin
              wrreq_i <= 1'b1;
              rdreq_i <= 1'b1;
              data_i  <= $urandom();
            end
        end
      
      @(posedge clk);
      wrreq_i <= 1'b0;
      rdreq_i <= 1'b0;
    end
  endtask

  task automatic run_test_reset();
    begin 
      repeat(5)
        write($urandom());
      
      srst <= 1'b1;
      @( posedge clk );
      srst <= 1'b0;
      @( posedge clk );
      
      if( dut_empty_o !== 1'b1 )
        $error("Error at %0t: empty_o is not 1 after reset!", $time);
      if( dut_full_o !== 1'b0 )
        $error("Error at %0t: full_o is not 0 after reset!", $time);  
      if( dut_q_o !== 'x )
        $error("Error at %0t: q_o is not 'x after reset!", $time);
    end
  endtask

  task automatic run_random_tests(int num_cycles);
    begin
      repeat(num_cycles)
        begin
          @( posedge clk );
          wrreq_i <= ( ( $urandom_range(0, 99) < 40 ) && ( !gm_full_o  ) ); 
          rdreq_i <= ( ( $urandom_range(0, 99) < 30 ) && ( !gm_empty_o ) );
          data_i  <= $urandom();
        end
      
      @( posedge clk );
      wrreq_i <= 1'b0;
      rdreq_i <= 1'b0;
    end
  endtask

  task automatic run_random_filling_test();
    begin
      while( !gm_full_o )
        begin
          @( posedge clk );
          wrreq_i <= ( $urandom_range(0, 99) < 80 ); 
          rdreq_i <= ( ( $urandom_range(0, 99) < 20 ) && ( !gm_empty_o ) );
          data_i  <= $urandom();
        end
      
      wrreq_i <= 1'b0;
      rdreq_i <= 1'b0;
      @( posedge clk );
    end
  endtask

  task automatic run_random_emptying_test();
    begin
      while( !gm_empty_o )
        begin
          @( posedge clk );
          wrreq_i <= ( ( $urandom_range(0, 99) < 40 ) && ( !gm_full_o  ) ); 
          rdreq_i <= ( $urandom_range(0, 99) < 80 );
          data_i  <= $urandom();
        end
      
      @( posedge clk );
      wrreq_i <= 1'b0;
      rdreq_i <= 1'b0;
    end
  endtask

  task automatic monitor_q_o();
    begin
      forever
        begin
          @( posedge clk );
          if( !srst )
            begin
              if( ( dut_q_o ) !== ( gm_q_o ) )
                begin
                  $error("Error at %0t: Data mismatch:\nDUT: %h\nGM: %h",
                          $time, dut_q_o, gm_q_o);
                  pass_flag = 1'b0;
                end
            end
        end
    end
  endtask

  task automatic monitor_usedw_o();
    begin
      forever
        begin
          @( posedge clk );
          if( !srst )
            begin
              if( ( dut_usedw_o[AWIDTH-1:0] ) !== ( gm_usedw_o[AWIDTH-1:0] ) )
                begin
                  $error("Error at %0t: usedw mismatch:\nDUT: %d\nGM: %d", $time, dut_usedw_o, gm_usedw_o);
                  pass_flag = 1'b0;
                end
            end
        end
    end
  endtask

  task automatic monitor_full_flags();
    begin
      forever
        begin
          @( posedge clk );
          if( !srst )
            begin
              if( ( dut_full_o !== gm_full_o ) || ( dut_almost_full_o !== gm_almost_full_o ) )
                begin
                  $error("Error at %0t: Full flags mismatch:\nFull(%b/%b),\nAlmost full(%b/%b)", 
                          $time, dut_full_o, gm_full_o, dut_almost_full_o, gm_almost_full_o);
                  pass_flag = 1'b0;
                end
            end
        end
    end
  endtask

  task automatic monitor_empty_flags();
    begin
      forever
        begin
          @( posedge clk );
          if( !srst )
            begin
              if( ( dut_empty_o !== gm_empty_o ) || ( dut_almost_empty_o !== gm_almost_empty_o ) )
                begin
                  $error("Error at %0t: Empty flags mismatch:\nEmpty(%b/%b),\nAlmost empty(%b/%b)", 
                          $time, dut_empty_o, gm_empty_o, dut_almost_empty_o, gm_almost_empty_o);
                  pass_flag = 1'b0;
                end
            end
        end
    end
  endtask
  
  initial
    begin
      wait(rst_done.triggered);
      @( posedge clk );
      $display( "Simulation start" );
      
      fork: monitoring
        monitor_q_o();
        monitor_usedw_o();
        monitor_full_flags();
        monitor_empty_flags();
      join_none
      
      run_test_full_empty();
      run_test_simultaneous(N);
      run_test_reset();
      run_random_filling_test();
      run_random_emptying_test();
      run_random_tests(N);

      disable monitoring;

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      $finish;
    end
endmodule
