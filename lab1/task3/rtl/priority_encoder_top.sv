module priority_encoder_top #(
  parameter WIDTH = 5
)(
  input  logic             clk_150m,
  input  logic             srst_i,

  input  logic [WIDTH-1:0] data_i,
  input  logic             data_val_i,

  output logic [WIDTH-1:0] data_left_o,
  output logic [WIDTH-1:0] data_right_o,
  output logic             data_val_o
);

  logic             srst_reg;
  logic [WIDTH-1:0] data_i_reg;
  logic             data_val_i_reg;

  logic [WIDTH-1:0] data_left_o_reg;
  logic [WIDTH-1:0] data_right_o_reg;
  logic             data_val_o_reg;

  always_ff @( posedge clk_150m )
    begin
      srst_reg       <= srst_i;
      data_i_reg     <= data_i; 
      data_val_i_reg <= data_val_i;
    end

  always_ff @( posedge clk_150m )
    begin
      data_left_o  <= data_left_o_reg;
      data_right_o <= data_right_o_reg;
      data_val_o   <= data_val_o_reg;
    end

  priority_encoder #(
    .WIDTH        ( WIDTH            )
  ) priority_encoder_inst (
    .clk_i        ( clk_150m         ),
    .srst_i       ( srst_reg         ),
    .data_i       ( data_i_reg       ),
    .data_val_i   ( data_val_i_reg   ),
    .data_left_o  ( data_left_o_reg  ),
    .data_right_o ( data_right_o_reg ),
    .data_val_o   ( data_val_o_reg   )
  );

endmodule