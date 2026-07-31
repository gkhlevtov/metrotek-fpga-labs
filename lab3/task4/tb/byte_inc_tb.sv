module byte_inc_tb;
  localparam int DATA_WIDTH  = 64;
  localparam int ADDR_WIDTH  = 10;
  localparam int BYTE_CNT    = DATA_WIDTH / 8;
  localparam int RANDOM_JOBS = 10;

  import byte_inc_pkg::*;

  bit clk;

  initial
    forever
      #5 clk = !clk;

  amm_ctrl_if #(
    .ADDR_WIDTH ( ADDR_WIDTH )
  ) ctrl_if ( clk );

  amm_rd_if #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH )
  ) rd_if ( clk );

  amm_wr_if #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH ),
    .BYTE_CNT   ( BYTE_CNT   )
  ) wr_if ( clk );

  byte_inc #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH ),
    .BYTE_CNT   ( BYTE_CNT   )
  ) dut (
    .clk_i                  ( clk                    ),
    .srst_i                 ( ctrl_if.srst           ),

    .base_addr_i            ( ctrl_if.base_addr      ),
    .length_i               ( ctrl_if.length         ),
    .run_i                  ( ctrl_if.run            ),
    .waitrequest_o          ( ctrl_if.waitrequest    ),

    .amm_rd_address_o       ( rd_if.rd_address       ),
    .amm_rd_read_o          ( rd_if.rd_read          ),
    .amm_rd_readdata_i      ( rd_if.rd_readdata      ),
    .amm_rd_readdatavalid_i ( rd_if.rd_readdatavalid ),
    .amm_rd_waitrequest_i   ( rd_if.rd_waitrequest   ),

    .amm_wr_address_o       ( wr_if.wr_address       ),
    .amm_wr_write_o         ( wr_if.wr_write         ),
    .amm_wr_writedata_o     ( wr_if.wr_writedata     ),
    .amm_wr_byteenable_o    ( wr_if.wr_byteenable    ),
    .amm_wr_waitrequest_i   ( wr_if.wr_waitrequest   )
  );

  environment #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH ),
    .BYTE_CNT   ( BYTE_CNT   )
  ) env;

  initial
    begin
      env = new( ctrl_if, rd_if, wr_if );
      env.slv.init_random_mem();
      env.run( RANDOM_JOBS );
      $stop;
    end
endmodule