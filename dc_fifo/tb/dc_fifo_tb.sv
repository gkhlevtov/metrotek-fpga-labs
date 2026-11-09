module dc_fifo_tb;
  localparam int  DWIDTH          = 32,
  localparam int  AWIDTH          = 8,
  localparam bit  SHOWAHEAD       = 1,
  localparam bit  REGISTER_OUTPUT = 0,
  localparam bit  RESET_LOW       = 1
  
  localparam time WR_CLK_PERIOD   = 6.4ns;
  localparam time WR_CLK_PHASE    = 0ns;
  localparam time RD_CLK_PERIOD   = 6.4ns;
  localparam time RD_CLK_PHASE    = 1ns;
  
  typedef logic [DWIDTH-1:0] word_t;
  
  import dc_fifo_pkg::*;

  bit wr_clk;
  bit rd_clk;
  
  // wr_clk
  initial
    begin
      #( WR_CLK_PHASE );
      forever
        #( WR_CLK_PERIOD / 2.0 ) wr_clk = ~wr_clk;
    end
  
  // rd_clk
  initial
    begin
      #( RD_CLK_PHASE );
      forever
        #( RD_CLK_PERIOD / 2.0 ) rd_clk = ~rd_clk;
    end
  
  wr_if  #( DWIDTH    ) wr_if_inst  ( wr_clk );
  rd_if  #( DWIDTH    ) rd_if_inst  ( rd_clk );
  rst_if #( RESET_LOW ) rst_if_inst;
  
  dc_fifo #(
    .DWIDTH          ( DWIDTH                  ),
    .AWIDTH          ( AWIDTH                  ),
    .SHOWAHEAD       ( SHOWAHEAD               ),
    .REGISTER_OUTPUT ( REGISTER_OUTPUT         ),
    .RESET_LOW       ( RESET_LOW               )
  ) dut (
    .wr_clk_i        ( wr_clk                  ),
    .rd_clk_i        ( rd_clk                  ),
    .rst_i           ( rst_if_inst.rst         ),
    .data_i          ( wr_if_inst.data         ),
    .wrreq_i         ( wr_if_inst.wrreq        ),
    .rdreq_i         ( rd_if_inst.rdreq        ),
    .data_o          ( rd_if_inst.data         ),
    .wrusedw_o       ( wr_if_inst.usedw        ),
    .rdusedw_o       ( rd_if_inst.usedw        ),
    .full_o          ( wr_if_inst.full         ),
    .almost_full_o   ( wr_if_inst.almost_full  ),
    .empty_o         ( rd_if_inst.empty        ),
    .almost_empty_o  ( rd_if_inst.almost_empty )
  );
  
  environment #(
    .DWIDTH          ( DWIDTH          ),
    .AWIDTH          ( AWIDTH          ),
    .SHOWAHEAD       ( SHOWAHEAD       ),
    .REGISTER_OUTPUT ( REGISTER_OUTPUT ),
    .RESET_LOW       ( RESET_LOW       )
  ) env;
  
  initial
    begin
      env = new( wr_if_inst, rd_if_inst, rst_if_inst );
      env.run( );
      $stop;
    end
endmodule
