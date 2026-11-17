module dc_fifo_top #(
  parameter DWIDTH             = 74,
  parameter AWIDTH             = 12,
  parameter ALMOST_FULL_VALUE  = ( AWIDTH > 2 ) ? ( 2 ** AWIDTH - 5 ) : ( 2 ** AWIDTH - 1 ),
  parameter ALMOST_EMPTY_VALUE = ( AWIDTH > 2 ) ? ( 5 ) : ( 2 ** ( AWIDTH - 1 ) ),
  parameter SHOWAHEAD          = 1,
  parameter REGISTER_OUTPUT    = 0
)(
  input  logic              wr_clk_i,
  input  logic              rd_clk_i,

  input  logic              wr_rst_i,
  input  logic              rd_rst_i,

  input  logic [DWIDTH-1:0] data_i,
  input  logic              wrreq_i,
  input  logic              rdreq_i,

  output logic [DWIDTH-1:0] data_o,

  output logic [AWIDTH:0]   wrusedw_o,
  output logic [AWIDTH:0]   rdusedw_o,

  output logic              full_o,
  output logic              almost_full_o,
  output logic              empty_o,
  output logic              almost_empty_o
);

  logic              wr_rst_i_reg;
  logic              rd_rst_i_reg;

  logic [DWIDTH-1:0] data_i_reg;
  logic              wrreq_i_reg;
  logic              rdreq_i_reg;

  logic [DWIDTH-1:0] data_o_reg;

  logic [AWIDTH:0]   wrusedw_o_reg;
  logic [AWIDTH:0]   rdusedw_o_reg;

  logic              full_o_reg;
  logic              almost_full_o_reg;
  logic              empty_o_reg;
  logic              almost_empty_o_reg;

  always_ff @( posedge wr_clk_i )
    begin
      wr_rst_i_reg   <= wr_rst_i;
      data_i_reg     <= data_i;
      wrreq_i_reg    <= wrreq_i;
    end

  always_ff @( posedge rd_clk_i )
    begin
      rd_rst_i_reg   <= rd_rst_i;
      rdreq_i_reg    <= rdreq_i;
    end

  always_ff @( posedge wr_clk_i )
    begin
      wrusedw_o      <= wrusedw_o_reg;
      full_o         <= full_o_reg;
      almost_full_o  <= almost_full_o_reg;
    end

  always_ff @( posedge rd_clk_i )
    begin
      data_o         <= data_o_reg;
      rdusedw_o      <= rdusedw_o_reg;
      empty_o        <= empty_o_reg;
      almost_empty_o <= almost_empty_o_reg;
    end

  dc_fifo #(
    .DWIDTH             ( DWIDTH             ),
    .AWIDTH             ( AWIDTH             ),
    .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE  ),
    .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE ),
    .SHOWAHEAD          ( SHOWAHEAD          ),
    .REGISTER_OUTPUT    ( REGISTER_OUTPUT    )
  ) dc_fifo_inst (
    .wr_clk_i           ( wr_clk_i           ),
    .rd_clk_i           ( rd_clk_i           ),
    .wr_rst_i           ( wr_rst_i_reg       ),
    .rd_rst_i           ( rd_rst_i_reg       ),
    .data_i             ( data_i_reg         ),
    .wrreq_i            ( wrreq_i_reg        ),
    .rdreq_i            ( rdreq_i_reg        ),
    .data_o             ( data_o_reg         ),
    .wrusedw_o          ( wrusedw_o_reg      ),
    .rdusedw_o          ( rdusedw_o_reg      ),
    .full_o             ( full_o_reg         ),
    .almost_full_o      ( almost_full_o_reg  ),
    .empty_o            ( empty_o_reg        ),
    .almost_empty_o     ( almost_empty_o_reg )
  );
endmodule
