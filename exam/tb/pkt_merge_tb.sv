module pkt_merge_tb;
  localparam int N            = 8;
  localparam int DATA_W       = 8 * N;
  localparam int EMPTY_W      = ( DATA_W/8 > 1 ) ? ( $clog2( DATA_W/8 ) ) : ( 1 );

  import pkt_merge_pkg::*;

  bit clk;

  initial
    forever
      #5 clk = !clk;

  ctrl_if ctrl_if_inst ( clk );

  ast_in_if #(
    .DATA_W  ( DATA_W  ),
    .EMPTY_W ( EMPTY_W )
  ) snk_base_if ( clk );

  ast_in_if #(
    .DATA_W  ( DATA_W  ),
    .EMPTY_W ( EMPTY_W )
  ) snk_to_insert_if ( clk );

  ast_out_if #(
    .DATA_W  ( DATA_W  ),
    .EMPTY_W ( EMPTY_W )
  ) src_if ( clk );

  pkt_merge #(
    .DATA_W                        ( DATA_W                 ),
    .EMPTY_W                       ( EMPTY_W                )
  ) dut (
    .clk_i                         ( clk                    ),
    .rst_i                         ( ctrl_if_inst.rst       ),
    .offset_i                      ( ctrl_if_inst.offset    ),

    .snk_base_data_i               ( snk_base_if.data       ),
    .snk_base_valid_i              ( snk_base_if.valid      ),
    .snk_base_startofpacket_i      ( snk_base_if.sop        ),
    .snk_base_endofpacket_i        ( snk_base_if.eop        ),
    .snk_base_empty_i              ( snk_base_if.empty      ),
    .snk_base_ready_o              ( snk_base_if.ready      ),

    .snk_to_insert_data_i          ( snk_to_insert_if.data  ),
    .snk_to_insert_valid_i         ( snk_to_insert_if.valid ),
    .snk_to_insert_startofpacket_i ( snk_to_insert_if.sop   ),
    .snk_to_insert_endofpacket_i   ( snk_to_insert_if.eop   ),
    .snk_to_insert_empty_i         ( snk_to_insert_if.empty ),
    .snk_to_insert_ready_o         ( snk_to_insert_if.ready ),

    .src_data_o                    ( src_if.data            ),
    .src_valid_o                   ( src_if.valid           ),
    .src_startofpacket_o           ( src_if.sop             ),
    .src_endofpacket_o             ( src_if.eop             ),
    .src_empty_o                   ( src_if.empty           ),
    .src_ready_i                   ( src_if.ready           )
  );

  environment #(
    .DATA_W  ( DATA_W  ),
    .EMPTY_W ( EMPTY_W )
  ) env;

  initial
    begin
      env = new( snk_base_if, snk_to_insert_if, src_if, ctrl_if_inst );
      env.run( );
      $stop;
    end
endmodule