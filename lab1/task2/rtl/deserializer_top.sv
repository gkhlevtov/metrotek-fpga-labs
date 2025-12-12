module deserializer_top(
  input  logic        clk_150m,
  input  logic        srst_i,

  input  logic        data_i,
  input  logic        data_val_i,

  output logic [15:0] deser_data_o,
  output logic        deser_data_val_o
);

  logic        srst_reg;
  logic        data_i_reg;
  logic        data_val_i_reg;

  logic [15:0] data_o_reg;
  logic        data_val_o_reg;

  always_ff @( posedge clk_150m )
    begin
      srst_reg       <= srst_i;
      data_i_reg     <= data_i; 
      data_val_i_reg <= data_val_i;
    end

  always_ff @( posedge clk_150m )
    begin
      deser_data_o     <= data_o_reg;
      deser_data_val_o <= data_val_o_reg;
    end

  deserializer deser_inst(
    .clk_i            ( clk_150m       ),
    .srst_i           ( srst_reg       ),
    .data_i           ( data_i_reg     ),
    .data_val_i       ( data_val_i_reg ),
    .deser_data_o     ( data_o_reg     ),
    .deser_data_val_o ( data_val_o_reg )
  );
endmodule