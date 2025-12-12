module deserializer_tb;
  // Max gap size
  parameter int GAP_SIZE = 4;

  // DUT inputs and output
  bit clk;
  bit srst;

  logic        data_i;
  logic        data_val_i;

  logic [15:0] deser_data_o;
  logic        deser_data_val_o;

  // Trancieved and recieved data
  logic [15:0] tx_data;
  logic [15:0] rx_data;

  // Simulation success flag
  bit pass_flag;

  // Random gaps during trancieving flag
  bit random_gaps;

  initial
    forever
      #5 clk = !clk;
  
  initial
    begin
      clk         = '0;
      srst        = '0;
      data_i      = '0;
      data_val_i  = '0;
      tx_data     = '0;
      rx_data     = '0;
      pass_flag   = '1;
      random_gaps = '0;

      @( posedge clk );
      srst        = '1;

      @( posedge clk );
      srst        = '0;
    end

  deserializer dut(
    .clk_i            ( clk              ),
    .srst_i           ( srst             ),
    .data_i           ( data_i           ),
    .data_val_i       ( data_val_i       ),
    .deser_data_o     ( deser_data_o     ),
    .deser_data_val_o ( deser_data_val_o )
  );

  task automatic reset();
    begin
      data_i     = '0;
      data_val_i = '0;
      srst       = '0;

      @( posedge clk );
      srst       = '1;

      @( posedge clk );
      srst       = '0;
    end
  endtask

  task automatic send_bit( bit value, bit valid );
    begin
      data_i     = value;
      data_val_i = valid;
      @( posedge clk );
      data_val_i = 1'b0;
    end
  endtask

  task automatic send_data( logic [15:0] tx, bit random_gaps );
    begin
      for( int i = 0; i < 16; i++ )
        begin
          if ( random_gaps )
            begin
              if( $urandom_range(0, 2) == 0 )
                begin
                  repeat( $urandom_range(0, GAP_SIZE) )
                    send_bit($urandom_range(0, 1), 1'b0);
                end
            end
          send_bit(tx[15 - i], 1'b1);
        end
    end
  endtask

  task automatic receive_data( output logic [15:0] rx );
    begin
      rx = '0;
      do
        @(posedge clk);
      while ( !deser_data_val_o );
      rx = deser_data_o;
    end
  endtask

  task automatic run_one_check();
    begin
      reset();
      fork
        send_data(tx_data, random_gaps);
        receive_data(rx_data);
      join

      if (rx_data != tx_data)
        begin
          $error( "Data mismatch:\nexp=%h\ngot=%h\n", tx_data, rx_data );
          pass_flag = 1'b0;
        end
    end
  endtask

  initial
    begin
      $display( "Simulation start" );
      
      #20;
      // Boundary input values without gaps test
      random_gaps = 1'b0;
      tx_data = 16'hFFFF;
      run_one_check();
      tx_data = 16'h0000;
      run_one_check();

      // Boundary input values with gaps test
      random_gaps = 1'b1;
      tx_data = 16'hFFFF;
      run_one_check();
      tx_data = 16'h0000;
      run_one_check();

      // Random tests
      repeat(50)
        begin
          tx_data = $urandom();
          random_gaps = $urandom_range(0, 1);
          run_one_check();
        end

      #20;

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
    
      $display( "Simulation end" );
      $stop();
    end
endmodule