class AST_Transaction #(
  parameter int DATA_W    = 64,
  parameter int EMPTY_W   = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 ),
  parameter int CHANNEL_W = 8,
  parameter int DIR_W     = 2
);
  logic                 srst;
  logic [DIR_W-1:0    ] dir;
  logic [DATA_W-1:0   ] data;
  logic                 startofpacket;
  logic                 endofpacket;
  logic                 valid;
  logic [EMPTY_W-1:0  ] empty;
  logic [CHANNEL_W-1:0] channel;

  function void randomize_manual();
    for( int i = 0; i < DATA_W/8; i++ )
      data[i*8 +: 8] = $urandom();
  endfunction

  function AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) copy();
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) copy_tr = new();
    copy_tr.srst          = this.srst;
    copy_tr.dir           = this.dir;
    copy_tr.data          = this.data;
    copy_tr.startofpacket = this.startofpacket;
    copy_tr.endofpacket   = this.endofpacket;
    copy_tr.valid         = this.valid;
    copy_tr.empty         = this.empty;
    copy_tr.channel       = this.channel;
    return copy_tr;
  endfunction
endclass