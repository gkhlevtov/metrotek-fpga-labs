class AST_Beat #(
  parameter int DATA_W  = 64,
  parameter int EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 )
);
  bit [DATA_W-1:0]  data;
  bit               valid;
  bit               startofpacket;
  bit               endofpacket;
  bit [EMPTY_W-1:0] empty;
  bit               ready;

  function new();
    data          = '0;
    valid         = 1'b0;
    startofpacket = 1'b0;
    endofpacket   = 1'b0;
    empty         = '0;
    ready         = 1'b0;
  endfunction
  
  // data randomization
  function void randomize_manual();
    for( int i = 0; i < DATA_W/8; i++ )
      data[i*8 +: 8] = $urandom();
  endfunction

  function AST_Beat #( DATA_W, EMPTY_W ) copy();
    AST_Beat #( DATA_W, EMPTY_W ) copy_tr = new();

    copy_tr.data          = this.data;
    copy_tr.valid         = this.valid;
    copy_tr.startofpacket = this.startofpacket;
    copy_tr.endofpacket   = this.endofpacket;
    copy_tr.empty         = this.empty;
    copy_tr.ready         = this.ready;

    return copy_tr;
  endfunction

  // Valid bytes in beat getter
  function int get_valid_bytes();
    if( !endofpacket )
      return ( DATA_W/8 );
    return ( ( DATA_W/8 ) - empty );
  endfunction

  // Valid bytes extraction to queue
  function automatic void extract_bytes( ref byte bytes[$] );
    int n = get_valid_bytes();
    for( int i = 0; i < n; i++ )
      bytes.push_back( data[i*8 +: 8] );
  endfunction

  // Conversion to a string for logs
  function string convert2string();
    return $sformatf("data=0x%h sop=%0b eop=%0b empty=%0d vld=%0b rdy=%0b",
                      data, startofpacket, endofpacket, empty, valid, ready);
  endfunction
endclass