module delay_15_tb;
  parameter MAX_CYCLES = 1000;
  
  // DUT inputs and ouput
  bit clk;
  bit rst;

  logic         data_i;
  logic [3:0]   data_delay_i;

  logic         data_o;

  // Expected output
  logic         data_o_exp;

  // Delay change control
  logic [3:0]   prev_delay;

  // Simulation success flag
  logic         pass_flag;

  // Input data history
  logic [MAX_CYCLES-1:0] data_history;
  
  // Cycle counter
  int cycle = 0;

  // Array index
  int index;

  initial
    forever
      #5 clk = !clk;

  default clocking cb @ (posedge clk);
  endclocking

  initial
    begin
      clk          <= 1'b0;
      rst          <= 1'b1;
      data_i       <= 1'b0;
      data_delay_i <= 1'b0;
      pass_flag    <= 1'b1;
      prev_delay   <= 1'b0;
      data_history <= 1'b0;
      cycle        <= 1'b0;

      ##1;
      rst          <= 1'b0;
      ##1;
      rst          <= 1'b1;
    end
  
  always @( posedge clk )
    begin
      if( cycle < MAX_CYCLES )
        begin
          data_history[cycle] <= data_i;
          cycle <= cycle + 1;
        end
    end

  delay_15 dut (
    .clk_i        ( clk          ),
    .rst_i        ( rst          ),
    .data_i       ( data_i       ),
    .data_delay_i ( data_delay_i ),
    .data_o       ( data_o       )
  );

  task run_one_check ();
    begin
      index      = cycle - data_delay_i;
      data_o_exp = data_history[index];

      if( data_o_exp != data_o )
        begin
          $error( "Mismatch: delay = %0d, expected = %b, got = %b", data_delay_i, data_history[index], data_o );
          pass_flag <= 1'b0;
        end
    end
  endtask
  
  initial
    begin
      $display( "Simulation start" );

      // Random test
      for( int i = 0; i < 100; i = i + 1 )
        begin
          if( $urandom_range( 0, 4 ) == 0 )
            begin
              data_delay_i = $urandom_range( 0, 15 );
            end
          
          if( data_delay_i != prev_delay )
            begin
              prev_delay <= data_delay_i;
              ##16;
            end
          
          data_i <= $urandom_range( 0, 1 );
          run_one_check();
          ##1;
        end

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      
      $stop();
    end
endmodule