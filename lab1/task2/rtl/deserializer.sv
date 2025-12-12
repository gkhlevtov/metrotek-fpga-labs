module deserializer(
  input  logic        clk_i,
  input  logic        srst_i,

  input  logic        data_i,
  input  logic        data_val_i,

  output logic [15:0] deser_data_o,
  output logic        deser_data_val_o
);
  
  logic [3:0] bit_count;

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        deser_data_val_o <= 1'b0;
      else if( data_val_i && ( bit_count == 4'd15 ) )
        deser_data_val_o <= 1'b1;
      else
        deser_data_val_o <= 1'b0;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        deser_data_o <= 16'b0;
      else if ( data_val_i )
        deser_data_o[15 - bit_count] <= data_i;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        bit_count <= 4'd0;
      else if( data_val_i && ( bit_count == 4'd15 ) )
        bit_count <= 4'd0;
      else if( data_val_i )
        bit_count <= bit_count + 4'd1;
    end
endmodule