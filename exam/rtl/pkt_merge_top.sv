module pkt_merge_top #(
  parameter DATA_W  = 64,
  parameter EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 )
)(
  input  logic               clk_125m,

  input  logic               rst_i,

  input  logic [15:0]        offset_i,

  input  logic [DATA_W-1:0]  snk_base_data_i,
  input  logic               snk_base_valid_i,
  input  logic               snk_base_startofpacket_i,
  input  logic               snk_base_endofpacket_i,
  input  logic [EMPTY_W-1:0] snk_base_empty_i,
  output logic               snk_base_ready_o,

  input  logic [DATA_W-1:0]  snk_to_insert_data_i,
  input  logic               snk_to_insert_valid_i,
  input  logic               snk_to_insert_startofpacket_i,
  input  logic               snk_to_insert_endofpacket_i,
  input  logic [EMPTY_W-1:0] snk_to_insert_empty_i,
  output logic               snk_to_insert_ready_o,

  output logic [DATA_W-1:0]  src_data_o,
  output logic               src_valid_o,
  output logic               src_startofpacket_o,
  output logic               src_endofpacket_o,
  output logic [EMPTY_W-1:0] src_empty_o,
  input  logic               src_ready_i
);

  logic [15:0]        offset_i_reg;

  logic [DATA_W-1:0]  snk_base_data_i_reg;
  logic               snk_base_valid_i_reg;
  logic               snk_base_startofpacket_i_reg;
  logic               snk_base_endofpacket_i_reg;
  logic [EMPTY_W-1:0] snk_base_empty_i_reg;
  logic               snk_base_ready_o_reg;

  logic [DATA_W-1:0]  snk_to_insert_data_i_reg;
  logic               snk_to_insert_valid_i_reg;
  logic               snk_to_insert_startofpacket_i_reg;
  logic               snk_to_insert_endofpacket_i_reg;
  logic [EMPTY_W-1:0] snk_to_insert_empty_i_reg;
  logic               snk_to_insert_ready_o_reg;

  logic [DATA_W-1:0]  src_data_o_reg;
  logic               src_valid_o_reg;
  logic               src_startofpacket_o_reg;
  logic               src_endofpacket_o_reg;
  logic [EMPTY_W-1:0] src_empty_o_reg;
  logic               src_ready_i_reg;

  always_ff @( posedge clk_125m )
    begin
      offset_i_reg                      <= offset_i;

      snk_base_data_i_reg               <= snk_base_data_i;
      snk_base_valid_i_reg              <= snk_base_valid_i;
      snk_base_startofpacket_i_reg      <= snk_base_startofpacket_i;
      snk_base_endofpacket_i_reg        <= snk_base_endofpacket_i;
      snk_base_empty_i_reg              <= snk_base_empty_i;
      
      snk_to_insert_data_i_reg          <= snk_to_insert_data_i;
      snk_to_insert_valid_i_reg         <= snk_to_insert_valid_i;
      snk_to_insert_startofpacket_i_reg <= snk_to_insert_startofpacket_i;
      snk_to_insert_endofpacket_i_reg   <= snk_to_insert_endofpacket_i;
      snk_to_insert_empty_i_reg         <= snk_to_insert_empty_i;
      src_ready_i_reg                   <= src_ready_i;
    end
  
  always_ff @( posedge clk_125m )
    begin
      snk_base_ready_o      <= snk_base_ready_o_reg;
      snk_to_insert_ready_o <= snk_to_insert_ready_o_reg;
      src_data_o            <= src_data_o_reg;
      src_valid_o           <= src_valid_o_reg;
      src_startofpacket_o   <= src_startofpacket_o_reg;
      src_endofpacket_o     <= src_endofpacket_o_reg;
      src_empty_o           <= src_empty_o_reg;
    end

  pkt_merge #(
    .DATA_W                        ( DATA_W                            ),
    .EMPTY_W                       ( EMPTY_W                           )
  ) pkt_merge_inst (
    .clk_i                         ( clk_125m                          ),
    .rst_i                         ( rst_i                             ),
    .offset_i                      ( offset_i_reg                      ),
    .snk_base_data_i               ( snk_base_data_i_reg               ),
    .snk_base_valid_i              ( snk_base_valid_i_reg              ),
    .snk_base_startofpacket_i      ( snk_base_startofpacket_i_reg      ),
    .snk_base_endofpacket_i        ( snk_base_endofpacket_i_reg        ),
    .snk_base_empty_i              ( snk_base_empty_i_reg              ),
    .snk_base_ready_o              ( snk_base_ready_o_reg              ),
    .snk_to_insert_data_i          ( snk_to_insert_data_i_reg          ),
    .snk_to_insert_valid_i         ( snk_to_insert_valid_i_reg         ),
    .snk_to_insert_startofpacket_i ( snk_to_insert_startofpacket_i_reg ),
    .snk_to_insert_endofpacket_i   ( snk_to_insert_endofpacket_i_reg   ),
    .snk_to_insert_empty_i         ( snk_to_insert_empty_i_reg         ),
    .snk_to_insert_ready_o         ( snk_to_insert_ready_o_reg         ),
    .src_data_o                    ( src_data_o_reg                    ),
    .src_valid_o                   ( src_valid_o_reg                   ),
    .src_startofpacket_o           ( src_startofpacket_o_reg           ),
    .src_endofpacket_o             ( src_endofpacket_o_reg             ),
    .src_empty_o                   ( src_empty_o_reg                   ),
    .src_ready_i                   ( src_ready_i_reg                   )
  );
endmodule
