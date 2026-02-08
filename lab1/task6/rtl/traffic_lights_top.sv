module traffic_lights_top #(
  parameter BLINK_HALF_PERIOD_MS  = 500,
  parameter BLINK_GREEN_TIME_TICK = 3,
  parameter RED_YELLOW_MS         = 1000
)(
  input  logic        clk_0m002,
  input  logic        srst_i,
  input  logic [2:0]  cmd_type_i,
  input  logic        cmd_valid_i,
  input  logic [15:0] cmd_data_i,

  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o
);
  
  logic        srst_i_reg;
  logic [2:0]  cmd_type_i_reg;
  logic        cmd_valid_i_reg;
  logic [15:0] cmd_data_i_reg;

  logic        red_o_reg;
  logic        yellow_o_reg;
  logic        green_o_reg;

  always_ff @( posedge clk_0m002 )
    begin
      srst_i_reg      <= srst_i;
      cmd_type_i_reg  <= cmd_type_i; 
      cmd_valid_i_reg <= cmd_valid_i;
      cmd_data_i_reg  <= cmd_data_i;
    end

  always_ff @( posedge clk_0m002 )
    begin
      red_o    <= red_o_reg;
      yellow_o <= yellow_o_reg;
      green_o  <= green_o_reg;
    end

  traffic_lights #(
    .BLINK_HALF_PERIOD_MS  ( BLINK_HALF_PERIOD_MS  ),
    .BLINK_GREEN_TIME_TICK ( BLINK_GREEN_TIME_TICK ),
    .RED_YELLOW_MS         ( RED_YELLOW_MS         )
  ) traffic_lights_inst (
    .clk_i                 ( clk_0m002             ),
    .srst_i                ( srst_i_reg            ),
    .cmd_type_i            ( cmd_type_i_reg        ),
    .cmd_valid_i           ( cmd_valid_i_reg       ),
    .cmd_data_i            ( cmd_data_i_reg        ),
    .red_o                 ( red_o_reg             ),
    .yellow_o              ( yellow_o_reg          ),
    .green_o               ( green_o_reg           )
  );
endmodule
