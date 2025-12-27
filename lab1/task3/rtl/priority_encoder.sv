module priority_encoder #(
  parameter WIDTH
)(
  input  logic             clk_i,
  input  logic             srst_i,

  input  logic [WIDTH-1:0] data_i,
  input  logic             data_val_i,

  output logic [WIDTH-1:0] data_left_o,
  output logic [WIDTH-1:0] data_right_o,
  output logic             data_val_o
);
  
  logic [WIDTH-1:0] left_one;
  logic [WIDTH-1:0] right_one;

  always_comb
    begin
      left_one  = '0;
      right_one = '0;

      for( int i = WIDTH - 1; i >= 0; i-- )
        begin
          if( data_i[i] )
            begin
              left_one[i] = 1'b1;
              break;
            end
        end
      
      for( int i = 0; i < WIDTH; i++ )
        begin
          if( data_i[i] )
            begin
              right_one[i] = 1'b1;
              break;
            end
        end
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          data_left_o  <= '0;
          data_right_o <= '0;
          data_val_o   <= '0;
        end
      else if( data_val_i )
        begin
          data_left_o  <= left_one;
          data_right_o <= right_one;
          data_val_o   <= 1'b1;
        end
      else
        data_val_o <= 1'b0;
    end
endmodule