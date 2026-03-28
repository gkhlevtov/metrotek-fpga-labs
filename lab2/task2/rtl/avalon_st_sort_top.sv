module avalon_st_sort_top #(
  parameter DWIDTH      = 8,
  parameter MAX_PKT_LEN = 16
)(
  input  logic              clk_150m,
  input  logic              srst_i,

  input  logic [DWIDTH-1:0] snk_data_i,
  input  logic              snk_startofpacket_i,
  input  logic              snk_endofpacket_i,
  input  logic              snk_valid_i,
  input  logic              src_ready_i,

  output logic              snk_ready_o,
  output logic [DWIDTH-1:0] src_data_o,
  output logic              src_startofpacket_o,
  output logic              src_endofpacket_o,
  output logic              src_valid_o
);

  logic              srst_i_reg;
  logic [DWIDTH-1:0] snk_data_i_reg;
  logic              snk_startofpacket_i_reg;
  logic              snk_endofpacket_i_reg;
  logic              snk_valid_i_reg;
  logic              src_ready_i_reg;

  logic              snk_ready_o_reg;
  logic [DWIDTH-1:0] src_data_o_reg;
  logic              src_startofpacket_o_reg;
  logic              src_endofpacket_o_reg;
  logic              src_valid_o_reg;

  always_ff @( posedge clk_150m )
    begin
      srst_i_reg              <= srst_i;
      snk_data_i_reg          <= snk_data_i; 
      snk_startofpacket_i_reg <= snk_startofpacket_i;
      snk_endofpacket_i_reg   <= snk_endofpacket_i;
      snk_valid_i_reg         <= snk_valid_i;
      src_ready_i_reg         <= src_ready_i;
    end

  always_ff @( posedge clk_150m )
    begin
      snk_ready_o         <= snk_ready_o_reg;
      src_data_o          <= src_data_o_reg;
      src_startofpacket_o <= src_startofpacket_o_reg;
      src_endofpacket_o   <= src_endofpacket_o_reg;
      src_valid_o         <= src_valid_o_reg;
    end

  avalon_st_sort #(
    .DWIDTH              ( DWIDTH                  ),
    .MAX_PKT_LEN         ( MAX_PKT_LEN             )
  ) avalon_st_sort_inst (
    .clk_i               ( clk_150m                ),
    .srst_i              ( srst_i_reg              ),
    .snk_data_i          ( snk_data_i_reg          ),
    .snk_startofpacket_i ( snk_startofpacket_i_reg ),
    .snk_endofpacket_i   ( snk_endofpacket_i_reg   ),
    .snk_valid_i         ( snk_valid_i_reg         ),
    .src_ready_i         ( src_ready_i_reg         ),
    .snk_ready_o         ( snk_ready_o_reg         ),
    .src_data_o          ( src_data_o_reg          ),
    .src_startofpacket_o ( src_startofpacket_o_reg ),
    .src_endofpacket_o   ( src_endofpacket_o_reg   ),
    .src_valid_o         ( src_valid_o_reg         )
  );
endmodule
