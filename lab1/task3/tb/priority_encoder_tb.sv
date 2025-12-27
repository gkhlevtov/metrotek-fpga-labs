module priority_encoder_tb;
  // Data size
  parameter WIDTH = 8;

  // DUT inputs and output
  bit clk;
  bit srst;

  logic [WIDTH-1:0] data_i;
  logic             data_val_i;

  logic [WIDTH-1:0] data_left_o;
  logic [WIDTH-1:0] data_right_o;
  logic             data_val_o;

  // Recieved data
  logic [WIDTH-1:0] rx_left;
  logic [WIDTH-1:0] rx_right;
  logic             rx_valid;

  // Simulation success flag
  bit pass_flag;

  typedef struct packed {
    logic [WIDTH-1:0] d_i;
    logic             d_v_i;
    logic             exp_v;
    logic [WIDTH-1:0] exp_l;
    logic [WIDTH-1:0] exp_r;
  } task_input;

  task_input test_data;

  initial
    forever
      #5 clk = !clk;

  initial
    begin
      clk        = '0;
      srst       = '0;
      data_i     = '0;
      data_val_i = '0;
      test_data  = '0;
      rx_left    = '0;
      rx_right   = '0;
      pass_flag  = '1;

      @( posedge clk );
      srst       = '1;

      @( posedge clk );
      srst       = '0;
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

  task automatic send_data( logic [WIDTH-1:0] tx, bit valid );
    begin
      data_i     = tx;
      data_val_i = valid;
      @( posedge clk );
      data_val_i = 1'b0;
    end
  endtask

  task automatic receive_data(
    output logic [WIDTH-1:0] rx_left,
    output logic [WIDTH-1:0] rx_right,
    output bit               rx_valid
  );
    begin
      int wait_cycles;

      rx_left     = '0;
      rx_right    = '0;
      rx_valid    = 1'b0;
      wait_cycles = 0;

      while( wait_cycles < 2 )
        begin
          @( posedge clk );
          if( data_val_o )
            begin
              rx_left  = data_left_o;
              rx_right = data_right_o;
              rx_valid = 1'b1;
              return;
            end
          wait_cycles++;
        end
    end
  endtask

  task automatic run_one_check( task_input test_data );
    begin
      reset();
      fork
        send_data(test_data.d_i, test_data.d_v_i);
        receive_data(rx_left, rx_right, rx_valid);
      join

      if( rx_valid != test_data.exp_v )
        begin
          $error( "Valid mismatch:\nexp=%b\ngot=%b\n", test_data.exp_v, rx_valid);
          pass_flag = 1'b0;
        end
      else if( rx_valid )
        begin
          if( ( rx_left != test_data.exp_l ) || ( rx_right != test_data.exp_r ) )
            begin
              $error( "Data mismatch:\ninp_d=%b\nexp_l=%b\ngot_l=%b\nexp_r=%b\ngot_r=%b\n",
                      test_data.d_i, test_data.exp_l, rx_left, test_data.exp_r, rx_right );
              pass_flag = 1'b0;
            end
        end
    end
  endtask

  initial
    begin
      $display( "Simulation start" );
      
      #20;

      // Zeroes test
      test_data.d_i   = '0;
      test_data.d_v_i = 1'b1;
      test_data.exp_v = 1'b1;
      test_data.exp_l = '0;
      test_data.exp_r = '0;
      run_one_check(test_data);

      // Ones test
      test_data.d_i   = '1;
      test_data.d_v_i = 1'b1;
      test_data.exp_v = 1'b1;
      test_data.exp_l = ( 1 << ( WIDTH - 1 ) );
      test_data.exp_r = 1;
      run_one_check(test_data);

      // Invalid input data test
      test_data.d_i   = $urandom();
      test_data.d_v_i = 1'b0;
      test_data.exp_v = 1'b0;
      test_data.exp_l = '0;
      test_data.exp_r = '0;
      run_one_check(test_data);

      // Single bit test
      test_data.d_i   = ( 1 << ( WIDTH / 2 ) );
      test_data.d_v_i = 1'b1;
      test_data.exp_v = 1'b1;
      test_data.exp_l = test_data.d_i;
      test_data.exp_r = test_data.d_i;
      run_one_check(test_data);

      // Random tests
      repeat(50)
        begin
          test_data = generate_input();
          run_one_check(test_data);
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