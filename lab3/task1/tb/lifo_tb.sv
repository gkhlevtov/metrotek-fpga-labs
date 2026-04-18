module lifo_tb;
  localparam int DWIDTH        = 16;
  localparam int AWIDTH        = 8;
  localparam int ALMOST_FULL   = 2;
  localparam int ALMOST_EMPTY  = 2;
  localparam int RANDOM_TESTS  = 100;

  import lifo_pkg::*;

  bit clk;
  
  initial
    forever
      #5 clk = !clk;

  lifo_if #(
    .DWIDTH       ( DWIDTH        ),
    .AWIDTH       ( AWIDTH        ),
    .ALMOST_FULL  ( ALMOST_FULL   ),
    .ALMOST_EMPTY ( ALMOST_EMPTY  )
  ) itf( clk );

  lifo #(
    .DWIDTH         ( DWIDTH             ),
    .AWIDTH         ( AWIDTH             ),
    .ALMOST_FULL    ( ALMOST_FULL        ),
    .ALMOST_EMPTY   ( ALMOST_EMPTY       )
  ) dut (
    .clk_i          ( clk                ),
    .srst_i         ( itf.srst_i         ),
    .wrreq_i        ( itf.wrreq_i        ),
    .data_i         ( itf.data_i         ),
    .rdreq_i        ( itf.rdreq_i        ),
    .q_o            ( itf.q_o            ),
    .almost_empty_o ( itf.almost_empty_o ),
    .empty_o        ( itf.empty_o        ),
    .almost_full_o  ( itf.almost_full_o  ),
    .full_o         ( itf.full_o         ),
    .usedw_o        ( itf.usedw_o        )
  );

  Environment #(
    .DWIDTH       ( DWIDTH        ),
    .AWIDTH       ( AWIDTH        ),
    .ALMOST_FULL  ( ALMOST_FULL   ),
    .ALMOST_EMPTY ( ALMOST_EMPTY  )
  ) env;

  initial
    begin
      env = new( itf );
      env.run( RANDOM_TESTS );
      $stop;
    end
endmodule