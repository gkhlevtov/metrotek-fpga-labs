module ast_width_extender_tb;
  localparam int IN_DATA_W   = 64;
  localparam int OUT_DATA_W  = 256;
  localparam int CHANNEL_W   = 10;
  localparam int PACKETS     = 100;

  localparam int IN_EMPTY_W  = ( $clog2(IN_DATA_W/8)  ) ? ( $clog2(IN_DATA_W/8)  ) : ( 1 );
  localparam int OUT_EMPTY_W = ( $clog2(OUT_DATA_W/8) ) ? ( $clog2(OUT_DATA_W/8) ) : ( 1 );

  import ast_width_extender_pkg::*;

  bit clk;
  
  initial
    forever
      #5 clk = !clk;

  ast_in_if #(
    .DATA_W    ( IN_DATA_W  ),
    .EMPTY_W   ( IN_EMPTY_W ),
    .CHANNEL_W ( CHANNEL_W  )
  ) in_if ( clk );

  ast_out_if #(
    .DATA_W    ( OUT_DATA_W  ),
    .EMPTY_W   ( OUT_EMPTY_W ),
    .CHANNEL_W ( CHANNEL_W   )
  ) out_if ( clk );

  assign out_if.ready = 1'b1;

  ast_width_extender #(
    .DATA_IN_W           ( IN_DATA_W            ),
    .DATA_OUT_W          ( OUT_DATA_W           ),
    .CHANNEL_W           ( CHANNEL_W            )
  ) dut (
    .clk_i               ( clk                  ),

    .srst_i              ( in_if.srst           ),
    .ast_data_i          ( in_if.data           ),
    .ast_valid_i         ( in_if.valid          ),
    .ast_startofpacket_i ( in_if.startofpacket  ),
    .ast_endofpacket_i   ( in_if.endofpacket    ),
    .ast_empty_i         ( in_if.empty          ),
    .ast_channel_i       ( in_if.channel        ),
    .ast_ready_o         ( in_if.ready          ),

    .ast_data_o          ( out_if.data          ),
    .ast_valid_o         ( out_if.valid         ),
    .ast_startofpacket_o ( out_if.startofpacket ),
    .ast_endofpacket_o   ( out_if.endofpacket   ),
    .ast_empty_o         ( out_if.empty         ),
    .ast_channel_o       ( out_if.channel       ),
    .ast_ready_i         ( out_if.ready         )
  );

  Environment #(
    .IN_DATA_W  ( IN_DATA_W  ),
    .CHANNEL_W  ( CHANNEL_W  ),
    .OUT_DATA_W ( OUT_DATA_W )
  ) env;

  initial
    begin
      env = new( in_if, out_if );
      env.run( PACKETS );
      $stop;
    end
endmodule
