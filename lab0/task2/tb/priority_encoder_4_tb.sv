module priority_encoder_4_tb;
  // DUT inputs and ouputs
  logic       data_val_i;
  logic [3:0] data_i;

  logic       data_val_o;
  logic [3:0] data_left_o;
  logic [3:0] data_right_o;
  
  // Simulation success flag
  logic       pass_flag;

  // Left/Right output shift
  int         pos_l;
  int         pos_r;

  struct packed {
    logic       d_v_i;
    logic [3:0] d_i;
    logic       exp_v;
    logic [3:0] exp_l;
    logic [3:0] exp_r;
  } task_input;

  priority_encoder_4 dut (
    .data_val_i   ( data_val_i   ),
    .data_i       ( data_i       ),
    .data_val_o   ( data_val_o   ),
    .data_left_o  ( data_left_o  ),
    .data_right_o ( data_right_o )
  );

  task run_one_check();
    begin
      data_val_i = task_input.d_v_i;
      data_i     = task_input.d_i;
      
      #10;

      if( data_val_o != task_input.exp_v )
        begin
          $error( "Validation mismatch: expected = %b, got = %b", task_input.exp_v, data_val_o );
          pass_flag = 1'b0;
        end
      else if( data_val_o == 1'b1 )
        begin
          if( ( data_left_o != task_input.exp_l ) || ( data_right_o != task_input.exp_r ) )
            begin
              $error( "Output mismatch: expected = (%b; %b), got = (%b; %b)", task_input.exp_l, task_input.exp_r, data_left_o, data_right_o );
              pass_flag = 1'b0;
            end
        end
    end
  endtask

  initial
    begin
      $display( "Simulation start" );

      task_input = '{
        d_v_i: 0,
        d_i:   4'b0000,
        exp_v: 0,
        exp_l: 4'b0000,
        exp_r: 4'b0000
      };

      data_val_i = 0;
      data_i     = 0;
      pass_flag  = 1'b1;
      

      //Boundary input values test
      for( int i = 0; i < 2; i = i + 1 )
        begin
          task_input.d_v_i = i[0];
          task_input.d_i   = 4'b0000;

          task_input.exp_v = i[0];
          task_input.exp_l = 4'b0000;
          task_input.exp_r = 4'b0000;;

          run_one_check();

          task_input.d_i   = 4'b1111;

          task_input.exp_l = 4'b1000;
          task_input.exp_r = 4'b0001;

          run_one_check();
        end

      // Random test
      for( int r = 0; r < 100; r = r + 1 )
        begin
          if( $urandom_range( 0, 4 ) == 0 )
            begin
              task_input.exp_l = 4'b0000;
              task_input.exp_r = 4'b0000;
              task_input.d_i   = 4'b0000;
            end
          else
            begin
              pos_l = $urandom_range( 0,     3 );
              pos_r = $urandom_range( pos_l, 3 );

              task_input.exp_l = 4'b0001 << (3 - pos_l);
              task_input.exp_r = 4'b0001 << (3 - pos_r);
              task_input.d_i   = 4'b0000;

              for( int i = pos_l; i <= pos_r; i = i + 1 )
                begin
                  task_input.d_i[3 - i] = $urandom_range( 0, 1 );
                end

              task_input.d_i = task_input.d_i | task_input.exp_l | task_input.exp_r;
            end

          task_input.d_v_i = $urandom_range(0, 1);
          task_input.exp_v = task_input.d_v_i;
          
          run_one_check();
        end

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      
      $stop();
    end
endmodule