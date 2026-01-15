module priority_encoder_tb;
  // Data size
  parameter WIDTH = 8;

  // Number of random tests 
  parameter N     = 50;

  // DUT inputs and output
  bit clk;
  bit srst;

  logic [WIDTH-1:0] data_i;
  logic             data_val_i;

  logic [WIDTH-1:0] data_left_o;
  logic [WIDTH-1:0] data_right_o;
  logic             data_val_o;

  // Tests counters and flag
  int total_tests;
  int expected_tests;
  int checked_tests;
  bit tests_done;

  // Simulation success flag
  bit pass_flag;

  // Reset flag
  bit rst_done;

  typedef struct packed {
    logic [WIDTH-1:0] d_i;
    logic             d_v_i;
    logic             exp_v;
    logic [WIDTH-1:0] exp_l;
    logic [WIDTH-1:0] exp_r;
  } task_input;

  // Mailbox for generated data
  mailbox #( task_input ) gen_mbx = new();

  // Mailbox for expected data
  mailbox #( task_input ) exp_mbx = new();

  initial
    forever
      #5 clk = !clk;

  initial
    begin
      clk        = '0;
      srst       = '0;
      data_i     = '0;
      data_val_i = '0;
      pass_flag  = '1;
      tests_done = '0;

      @( posedge clk );
      srst       = '1;

      @( posedge clk );
      srst       = '0;
      rst_done   = '1;
    end
  
  priority_encoder #(
    .WIDTH        ( WIDTH        )
  ) dut (
    .clk_i        ( clk          ),
    .srst_i       ( srst         ),
    .data_i       ( data_i       ),
    .data_val_i   ( data_val_i   ),
    .data_left_o  ( data_left_o  ),
    .data_right_o ( data_right_o ),
    .data_val_o   ( data_val_o   )
  );

  function automatic task_input generate_input;
    task_input generated_data;
    int pos_l;
    int pos_r;

    generated_data = '0;

    pos_r = $urandom_range( 0,     WIDTH - 1 );
    pos_l = $urandom_range( pos_r, WIDTH - 1 );

    generated_data.exp_l = ( 1 << ( pos_l ) );
    generated_data.exp_r = ( 1 << ( pos_r ) );

    for( int i = pos_r; i <= pos_l; i++ )
      generated_data.d_i[i] = $urandom_range( 0, 1 );

    generated_data.d_i |= generated_data.exp_l;
    generated_data.d_i |= generated_data.exp_r;

    generated_data.d_v_i = $urandom_range( 0, 1 );
    generated_data.exp_v = generated_data.d_v_i;

    return generated_data;
  endfunction

  task automatic generate_tests(
    int random_n,
    mailbox #( task_input ) mbx
  );
    begin
      task_input test_data;

      // Zeroes test
      test_data.d_i   = '0;
      test_data.d_v_i = 1'b1;
      test_data.exp_v = 1'b1;
      test_data.exp_l = '0;
      test_data.exp_r = '0;
      mbx.put(test_data);
      total_tests++;
      expected_tests++;

      // Ones test
      test_data.d_i   = '1;
      test_data.d_v_i = 1'b1;
      test_data.exp_v = 1'b1;
      test_data.exp_l = ( 1 << ( WIDTH - 1 ) );
      test_data.exp_r = 1;
      mbx.put(test_data);
      total_tests++;
      expected_tests++;

      // Invalid input data test
      test_data.d_i   = $urandom();
      test_data.d_v_i = 1'b0;
      test_data.exp_v = 1'b0;
      test_data.exp_l = '0;
      test_data.exp_r = '0;
      mbx.put(test_data);
      total_tests++;

      // Single bit test
      test_data.d_i   = ( 1 << ( WIDTH / 2 ) );
      test_data.d_v_i = 1'b1;
      test_data.exp_v = 1'b1;
      test_data.exp_l = test_data.d_i;
      test_data.exp_r = test_data.d_i;
      mbx.put(test_data);
      total_tests++;
      expected_tests++;

      // Random tests
      repeat( random_n )
        begin
          test_data = generate_input();
          mbx.put(test_data);

          total_tests++;
          if ( test_data.exp_v )
            expected_tests++;
        end
      
      $display("Generator: %0d test inputs queued", total_tests);
    end
  endtask

  task automatic send_inputs(
    mailbox #( task_input ) gen_mbx,
    mailbox #( task_input ) exp_mbx
  );
    begin
      task_input tx_data;

      forever
        begin
          gen_mbx.get( tx_data );

          data_i     <= tx_data.d_i;
          data_val_i <= tx_data.d_v_i;
          @( posedge clk );
          data_val_i <= 1'b0;

          if( tx_data.exp_v )
            exp_mbx.put( tx_data );
        end
    end
  endtask

  task automatic verify_outputs( mailbox #( task_input ) exp_mbx );
    begin
      task_input exp_data;

      forever
        begin
          @( posedge clk );

          if( data_val_o )
            begin
              if( !exp_mbx.try_get( exp_data ) )
                begin
                  $error( "Unexpected valid output!\n" );
                  pass_flag = 1'b0;
                end
              else
                begin
                  if( ( data_left_o != exp_data.exp_l ) || ( data_right_o != exp_data.exp_r ) )
                    begin
                      $error( "Data mismatch:\ninp_d=%b\nexp_l=%b\ngot_l=%b\nexp_r=%b\ngot_r=%b\n",
                        exp_data.d_i,
                        exp_data.exp_l, data_left_o,
                        exp_data.exp_r, data_right_o
                      );
                      pass_flag = 1'b0;
                    end
                end

              checked_tests++;
              if( checked_tests == expected_tests )
                tests_done = 1'b1;
            end
        end
    end
  endtask

  initial
    begin
      wait( rst_done );

      $display( "Simulation start" );
      
      generate_tests( N, gen_mbx );

      fork
        send_inputs( gen_mbx, exp_mbx );
        verify_outputs( exp_mbx );
      join_none

      wait( tests_done );

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );

      #20;

      $display( "Simulation end" );
      $finish;
    end
endmodule