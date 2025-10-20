module mux_tb;

  logic [1:0] data0_i;
  logic [1:0] data1_i;
  logic [1:0] data2_i;
  logic [1:0] data3_i;
  logic [1:0] direction_i;
  logic [1:0] data_o;

  logic [1:0] expected;
  logic       pass_flag;
  
  mux tb_mux (
    .data0_i     ( data0_i     ),
    .data1_i     ( data1_i     ),
    .data2_i     ( data2_i     ),
    .data3_i     ( data3_i     ),

    .direction_i ( direction_i ),

    .data_o      ( data_o      )
  );

  initial
    begin
      $display( "Simulation start" );

      pass_flag   = 1'b1;

      data0_i     = 2'b00;
      data1_i     = 2'b01;
      data2_i     = 2'b10;
      data3_i     = 2'b11;
      
      for ( int i = 0; i < 4; i = i + 1 )
        begin
          direction_i = i[1:0];

          case( direction_i )
            2'b00: expected = data0_i;
            2'b01: expected = data1_i;
            2'b10: expected = data2_i;
            2'b11: expected = data3_i;
          endcase

          #10;

          if( data_o != expected )
            begin
              $error( "direction = %b, expected = %b, got = %b", direction_i, expected, data_o );
              pass_flag = 1'b0;
            end
        end

      if ( pass_flag == 1'b1 )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      
      $stop();
    end

endmodule
