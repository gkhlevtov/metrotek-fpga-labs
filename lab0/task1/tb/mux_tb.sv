module mux_tb;
  // DUT inputs and ouput
  logic [1:0] data0_i;
  logic [1:0] data1_i;
  logic [1:0] data2_i;
  logic [1:0] data3_i;
  logic [1:0] direction_i;
  logic [1:0] data_o;

  // Inputs for task
  logic [1:0] d0;
  logic [1:0] d1;
  logic [1:0] d2;
  logic [1:0] d3;
  logic [1:0] select;
  logic [1:0] expected;

  // Simulation success flag
  logic       pass_flag;
  
  mux dut (
    .data0_i     ( data0_i     ),
    .data1_i     ( data1_i     ),
    .data2_i     ( data2_i     ),
    .data3_i     ( data3_i     ),

    .direction_i ( direction_i ),

    .data_o      ( data_o      )
  );

  task run_one_check (
    input logic [1:0] d0_i,
    input logic [1:0] d1_i,
    input logic [1:0] d2_i,
    input logic [1:0] d3_i,
    input logic [1:0] dir_i,
    input logic [1:0] exp
  );
    begin
      data0_i     = d0_i;
      data1_i     = d1_i;
      data2_i     = d2_i;
      data3_i     = d3_i;
      direction_i = dir_i;
      
      #10;

      if( data_o != exp )
        begin
          $error( "Mismatch: direction = %b, expected = %b, got = %b", dir_i, exp, data_o );
          pass_flag = 1'b0;
        end
    end
  endtask

  initial
    begin
      $display( "Simulation start" );

      pass_flag   = 1'b1;
      d0          = 2'b00;
      d1          = 2'b01;
      d2          = 2'b10;
      d3          = 2'b11;
      
      // Iterating over input data value changes
      for( int i = 0; i < 4; i = i + 1 )
        begin
          // Iterating over input number signal
          for( int j = 0; j < 4; j = j + 1 )
            begin
              select = j;
              case( select )
                2'b00: expected = d0;
                2'b01: expected = d1;
                2'b10: expected = d2;
                2'b11: expected = d3;
              endcase

              run_one_check( d0, d1, d2, d3, select, expected );
            end

          d0 = d0 + 1;
          d1 = d1 + 1;
          d2 = d2 + 1;
          d3 = d3 + 1;

        end

      // Random test
      for( int r = 0; r < 100; r = r + 1 )
        begin
            d0     = $urandom_range( 0, 3 );
            d1     = $urandom_range( 0, 3 );
            d2     = $urandom_range( 0, 3 );
            d3     = $urandom_range( 0, 3 );
            select = $urandom_range( 0, 3 );

            case( select )
              2'b00: expected = d0;
              2'b01: expected = d1;
              2'b10: expected = d2;
              2'b11: expected = d3;
            endcase

            run_one_check( d0, d1, d2, d3, select, expected );
        end

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      
      $stop();
    end

endmodule
