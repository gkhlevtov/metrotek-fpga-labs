module debouncer_top #(
  parameter CLK_FREQ_MHZ   = 150,
  parameter GLITCH_TIME_NS = 20
)(
  input  logic clk_150m,
  input  logic key_i,

  output logic key_pressed_stb_o
);

  logic key_i_reg;
  logic key_stb_o_reg;

  always_ff @( posedge clk_150m )
    begin
      key_i_reg <= key_i;
    end

  always_ff @( posedge clk_150m )
    begin
      key_pressed_stb_o <= key_stb_o_reg;
    end

  debouncer #(
    .CLK_FREQ_MHZ      ( CLK_FREQ_MHZ   ),
    .GLITCH_TIME_NS    ( GLITCH_TIME_NS )
  ) debouncer_inst (
    .clk_i             ( clk_150m       ),
    .key_i             ( key_i_reg      ),
    .key_pressed_stb_o ( key_stb_o_reg  )
  );
endmodule
