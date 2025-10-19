module mux_tb;

  logic [1:0] data0_i;
  logic [1:0] data1_i;
  logic [1:0] data2_i;
  logic [1:0] data3_i;
  logic [1:0] direction_i;
  logic [1:0] data_o;
  
  mux tb_mux(
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
    $monitor( $time, " dir = %b -> out = %b", direction_i, data_o );

    data0_i = 2'b00;
    data1_i = 2'b01;
    data2_i = 2'b10;
    data3_i = 2'b11;

    direction_i = 2'b00;
    #10;
    direction_i = 2'b01;
    #10;
    direction_i = 2'b10;
    #10;
    direction_i = 2'b11;
    #10;

    $display( "Simulation end" );
    
    $stop();
    $finish;
    end

endmodule
