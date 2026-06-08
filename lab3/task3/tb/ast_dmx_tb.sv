module ast_dmx_tb;
  localparam int DATA_W    = 64;
  localparam int CHANNEL_W = 8;
  localparam int TX_DIR    = 4;
  localparam int PACKETS   = 10;

  localparam int EMPTY_W   = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 );
  localparam int DIR_W     = ( TX_DIR == 1      ) ? ( 1 ) : ( $clog2(TX_DIR)   );

  import ast_dmx_pkg::*;

  bit clk;

  initial
    forever
      #5 clk = !clk;

  ast_in_if  #(
    .DATA_W    ( DATA_W    ),
    .EMPTY_W   ( EMPTY_W   ),
    .CHANNEL_W ( CHANNEL_W ),
    .DIR_W     ( DIR_W      )
  ) in_if  ( clk );

  ast_out_if #( 
    .DATA_W    ( DATA_W    ),
    .EMPTY_W   ( EMPTY_W   ),
    .CHANNEL_W ( CHANNEL_W )
  )
  out_if [TX_DIR] ( clk );

  logic [DATA_W-1:0]    data_o    [TX_DIR];
  logic                 sop_o     [TX_DIR];
  logic                 eop_o     [TX_DIR];
  logic                 valid_o   [TX_DIR];
  logic [EMPTY_W-1:0]   empty_o   [TX_DIR];
  logic [CHANNEL_W-1:0] channel_o [TX_DIR];
  logic                 ready_i   [TX_DIR];

  generate
    for( genvar i = 0; i < TX_DIR; i++ )
      begin
        assign out_if[i].data          = data_o[i];
        assign out_if[i].startofpacket = sop_o[i];
        assign out_if[i].endofpacket   = eop_o[i];
        assign out_if[i].valid         = valid_o[i];
        assign out_if[i].empty         = empty_o[i];
        assign out_if[i].channel       = channel_o[i];
        assign ready_i[i]              = out_if[i].ready;
      end
  endgenerate

  generate
    for( genvar i = 0; i < TX_DIR; i++ )
      assign out_if[i].ready = 1'b1;
  endgenerate

  ast_dmx #(
    .DATA_WIDTH          ( DATA_W              ),
    .CHANNEL_WIDTH       ( CHANNEL_W           ),
    .TX_DIR              ( TX_DIR              )
  ) dut (
    .clk_i               ( clk                 ),
    .srst_i              ( in_if.srst          ),
    .dir_i               ( in_if.dir           ),
    .ast_data_i          ( in_if.data          ),
    .ast_startofpacket_i ( in_if.startofpacket ),
    .ast_endofpacket_i   ( in_if.endofpacket   ),
    .ast_valid_i         ( in_if.valid         ),
    .ast_empty_i         ( in_if.empty         ),
    .ast_channel_i       ( in_if.channel       ),
    .ast_ready_o         ( in_if.ready         ),

    .ast_data_o          ( data_o              ),
    .ast_startofpacket_o ( sop_o               ),
    .ast_endofpacket_o   ( eop_o               ),
    .ast_valid_o         ( valid_o             ),
    .ast_empty_o         ( empty_o             ),
    .ast_channel_o       ( channel_o           ),
    .ast_ready_i         ( ready_i             )
  );

  Environment #(
    .DATA_W    ( DATA_W    ),
    .CHANNEL_W ( CHANNEL_W ),
    .TX_DIR    ( TX_DIR    )
  ) env;

  initial
    begin
      env = new( in_if, out_if );
      env.run( PACKETS );
      $stop;
    end
endmodule