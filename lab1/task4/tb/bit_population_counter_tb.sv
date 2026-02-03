module bit_population_counter_tb;
  // Data size
  parameter WIDTH = 32;

  // Number of random tests 
  parameter N     = 50;

  // DUT ports
  bit clk;
  bit srst;

  logic [WIDTH-1:0]       data_i;
  logic                   data_val_i;

  logic [$clog2(WIDTH):0] data_o;
  logic                   data_val_o;

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
    logic [WIDTH-1:0]       d_i;
    logic                   valid;
    logic [$clog2(WIDTH):0] exp_o;
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
  
  bit_population_counter #(
    .WIDTH      ( WIDTH      )
  ) dut (
    .clk_i      ( clk        ),
    .srst_i     ( srst       ),
    .data_i     ( data_i     ),
    .data_val_i ( data_val_i ),
    .data_o     ( data_o     ),
    .data_val_o ( data_val_o )
  );
  
  function automatic logic [WIDTH-1:0] get_random_input();
    logic [WIDTH-1:0] result;
    result = '0;
    
    for( int i = 0; i < WIDTH; i += 32 )
      begin
        result = result | ( WIDTH'($urandom) << i );
      end
    
    return result;
  endfunction

  function automatic task_input generate_input;
    task_input generated_data;

    generated_data.d_i   = get_random_input();
    generated_data.valid = ( $urandom_range(100) >= 20 );
    generated_data.exp_o = $countones(generated_data.d_i);  

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
      test_data.valid = 1'b1;
      test_data.exp_o = '0;
      mbx.put(test_data);
      total_tests++;
      expected_tests++;

      // Ones test
      test_data.d_i   = '1;
      test_data.valid = 1'b1;
      test_data.exp_o = ($clog2(WIDTH) + 1)'(WIDTH);
      mbx.put(test_data);
      total_tests++;
      expected_tests++;

      // Invalid input data test
      test_data.d_i   = get_random_input();
      test_data.valid = 1'b0;
      test_data.exp_o = '0;
      mbx.put(test_data);
      total_tests++;

      // Random tests
      repeat( random_n )
        begin
          test_data = generate_input();
          mbx.put(test_data);
          total_tests++;
          if( test_data.valid )
            expected_tests++;
        end
      
      $display("Generator: %0d test inputs queued", total_tests);
    end
  endtask

  task automatic send_inputs(
    mailbox #( task_input ) gen_mbx,
    mailbox #( task_input ) exp_mbx
  );
    task_input tx_data;

    forever
      begin
        gen_mbx.get(tx_data);

        @( posedge clk );
        data_i     <= ( tx_data.valid ) ? ( tx_data.d_i ) : ( 'x );
        data_val_i <= tx_data.valid;

        if( tx_data.valid )
          exp_mbx.put(tx_data);
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
              if( !exp_mbx.try_get(exp_data) )
                begin
                  $error( "Unexpected valid output!\n" );
                  pass_flag = 1'b0;
                end
              else
                begin
                  if( data_o != exp_data.exp_o )
                    begin
                      $error( "Data mismatch:\ninp_d = %b\nexp_o = %d\ngot_o = %d\n",
                        exp_data.d_i, exp_data.exp_o, data_o
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
      wait(rst_done);

      $display( "Simulation start" );
      
      generate_tests( N, gen_mbx );

      fork
        send_inputs( gen_mbx, exp_mbx );
        verify_outputs( exp_mbx );
      join_none

      wait(tests_done);
      disable fork;

      repeat(5)
        @( posedge clk );

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      $finish;
    end

endmodule
