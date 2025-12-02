module serializer(
  input  logic        clk_i,
  input  logic        srst_i,

  input  logic [15:0] data_i,
  input  logic [3:0]  data_mod_i,
  input  logic        data_val_i,

  output logic        ser_data_o,
  output logic        ser_data_val_o,
  output logic        busy_o
);

  logic [15:0] data_reg;

  logic [4:0]  bit_count;
  logic [3:0]  cur_bit;

  logic        start;

  assign start = data_val_i && ( !busy_o ) && ( data_mod_i != 4'd1 ) && ( data_mod_i != 4'd2 );

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        data_reg <= 16'b0;
      else if( start )
        data_reg <= data_i;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        busy_o <= 1'b0;
      else if( start )
        busy_o <= 1'b1;
      else if( bit_count == 5'd0 )
        busy_o <= 1'b0;
    end
  
  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        bit_count <= 5'd0;
      else if( start )
        bit_count <= ( data_mod_i == 4'd0 ) ? ( 5'd15 ) : ( data_mod_i - 4'd1 );
      else if( busy_o )
        bit_count <= bit_count - 1'd1;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        cur_bit <= 4'd0;
      else if( start )
        cur_bit <= 4'd14;
      else if( busy_o && ( bit_count != 5'd0 ) )
        cur_bit <= cur_bit - 4'd1;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        ser_data_val_o <= 1'b0;
      else if( start )
        ser_data_val_o <= 1'b1;
      else if( busy_o && ( bit_count != 5'd0 ) )
        ser_data_val_o <= 1'b1;
      else
        ser_data_val_o <= 1'b0;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        ser_data_o <= 1'b0;
      else if( start )
        ser_data_o <= data_i[15];
      else if( busy_o && ( bit_count != 5'd0 ) )
        ser_data_o <= data_reg[cur_bit];
      else
        ser_data_o <= 1'b0;
    end
endmodule
