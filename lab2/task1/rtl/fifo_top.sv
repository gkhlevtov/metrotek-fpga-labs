module fifo_top #(
  parameter DWIDTH             = 8,
  parameter AWIDTH             = 8,
  parameter SHOWAHEAD          = 1,
  parameter ALMOST_FULL_VALUE  = 250,
  parameter ALMOST_EMPTY_VALUE = 5,
  parameter REGISTER_OUTPUT    = 0
)(
  input  logic              clk_150m,
  input  logic              srst_i,
  input  logic [DWIDTH-1:0] data_i,
  input  logic              wrreq_i,
  input  logic              rdreq_i,
  
  output logic [DWIDTH-1:0] q_o,
  output logic              empty_o,
  output logic              full_o,
  output logic [AWIDTH:0]   usedw_o,
  output logic              almost_full_o,
  output logic              almost_empty_o
);

  logic              srst_i_reg;
  logic [DWIDTH-1:0] data_i_reg;
  logic              wrreq_i_reg;
  logic              rdreq_i_reg;

  logic [DWIDTH-1:0] q_o_reg;
  logic              empty_o_reg;
  logic              full_o_reg;
  logic [AWIDTH:0]   usedw_o_reg;
  logic              almost_full_o_reg;
  logic              almost_empty_o_reg;

  always_ff @( posedge clk_150m )
    begin
      srst_i_reg  <= srst_i;
      data_i_reg  <= data_i; 
      wrreq_i_reg <= wrreq_i;
      rdreq_i_reg <= rdreq_i;
    end

  always_ff @( posedge clk_150m )
    begin
      q_o            <= q_o_reg;
      empty_o        <= empty_o_reg;
      full_o         <= full_o_reg;
      usedw_o        <= usedw_o_reg;
      almost_full_o  <= almost_full_o_reg;
      almost_empty_o <= almost_empty_o_reg;
    end

  fifo #(
    .DWIDTH             ( DWIDTH             ),
    .AWIDTH             ( AWIDTH             ),
    .SHOWAHEAD          ( SHOWAHEAD          ),
    .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE  ),
    .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE ),
    .REGISTER_OUTPUT    ( REGISTER_OUTPUT    )
  ) fifo_inst (
    .clk_i              ( clk_150m           ),
    .srst_i             ( srst_i_reg         ),
    .data_i             ( data_i_reg         ),
    .wrreq_i            ( wrreq_i_reg        ),
    .rdreq_i            ( rdreq_i_reg        ),
    .q_o                ( q_o_reg            ),
    .empty_o            ( empty_o_reg        ),
    .full_o             ( full_o_reg         ),
    .usedw_o            ( usedw_o_reg        ),
    .almost_full_o      ( almost_full_o_reg  ),
    .almost_empty_o     ( almost_empty_o_reg )
  );
endmodule
