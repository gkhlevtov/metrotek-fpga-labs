module debouncer_tb;
  // DUT parameters
  parameter CLK_FREQ_MHZ   = 150;
  parameter GLITCH_TIME_NS = 20;

  // Equivalent glitch time in cycles
  parameter GLITCH_CYCLES = ( GLITCH_TIME_NS * CLK_FREQ_MHZ + 999 ) / 1000;
  
  // Number of random tests 
  parameter N = 50;

  // Length of input sequence
  parameter T = 40;

  // Time before sending new test 
  parameter WAIT_TIME = 5;

  // DUT ports
  bit   clk;
  logic key_i;
  logic key_stb_o;

  // Tests counters and flag
  int total_tests;
  int checked_tests;
  bit tests_done;

  // Simulation success flag
  bit pass_flag;

  // Reset flag
  bit rst_done;

  typedef struct packed {
    logic [T-1:0]             key_seq;
    logic [$clog2(T/2+1)-1:0] n_stb;
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
      key_i      = '1;
      pass_flag  = '1;
      tests_done = '0;

      @( posedge clk );
      rst_done   = '1;
    end
  
  debouncer #(
    .CLK_FREQ_MHZ      ( CLK_FREQ_MHZ   ),
    .GLITCH_TIME_NS    ( GLITCH_TIME_NS )
  ) debouncer_inst (
    .clk_i             ( clk            ),
    .key_i             ( key_i          ),
    .key_pressed_stb_o ( key_stb_o      )
  );

  function automatic int count_presses(
    logic [T-1:0] data,
    int n
  );
    int cnt     = 0;
    int zeros   = 0;
    bit pressed = 0;

    for( int i = 0; i < T; i++ )
      begin
        if( data[i] == 1'b0 ) 
          begin
            zeros++;
            if( ( zeros == n ) && ( !pressed ) ) 
              begin
                cnt++;
                pressed = 1'b1;
              end
          end 
        else 
          begin
            zeros   = 0;
            pressed = 0;
          end
      end

    return cnt;
  endfunction

  function automatic task_input generate_input;
    task_input generated_data;

    generated_data.key_seq = $urandom();
    generated_data.n_stb = count_presses(generated_data.key_seq, GLITCH_CYCLES);

    return generated_data;
  endfunction
  
  task automatic generate_tests(
    int random_n,
    mailbox #( task_input ) mbx
  );
    begin
      task_input test_data;

      // Zeroes test
      test_data.key_seq = '0;
      test_data.n_stb   = 1;
      mbx.put(test_data);
      total_tests++;

      // Ones test
      test_data.key_seq = '1;
      test_data.n_stb   = 0;
      mbx.put(test_data);
      total_tests++;

      // Random tests
      repeat( random_n )
        begin
          test_data = generate_input();
          mbx.put(test_data);
          total_tests++;
          //$display("Test #%0d: %b %0d\n", total_tests, test_data.key_seq, test_data.n_stb);
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
        exp_mbx.put(tx_data);
        
        @( posedge clk );
        
        for( int i = 0; i < T; i++ )
          begin
            key_i <= tx_data.key_seq[i];
            @( posedge clk );
          end

        key_i <= 1'b1;

        repeat(WAIT_TIME)
          @( posedge clk );
      end
  endtask

  task automatic verify_outputs( mailbox #( task_input ) exp_mbx );
    task_input exp_data;
    int observed;

    repeat(total_tests)
      begin
        exp_mbx.get(exp_data);
        observed = 0;

        repeat(T + WAIT_TIME)
          begin
            @( posedge clk );
            if( key_stb_o == 1'b1 )
              observed++;
          end

        if( observed != exp_data.n_stb )
          begin
            $error("FAILURE at Test #%0d\nInput: %b\nExpected: %0d, Observed: %0d", 
              ( checked_tests + 1 ), exp_data.key_seq, exp_data.n_stb, observed);
            pass_flag = 1'b0;
          end

        checked_tests++;
      end

    tests_done = 1'b1;
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

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );

      @( posedge clk );

      $display( "Simulation end" );
      $finish;
    end
endmodule
