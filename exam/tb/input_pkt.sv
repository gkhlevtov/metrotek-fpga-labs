class Input_Packet #(
  parameter int DATA_W = 64
);
  string name;
  int    length;
  byte   bytes[$];

  function new(string pkt_name = "pkt");
    name   = pkt_name;
    length = 0;
  endfunction

  function Input_Packet #( DATA_W ) copy();
    Input_Packet #( DATA_W ) packet = new( this.name );

    packet.length = this.length;
    packet.bytes  = this.bytes;
    return packet;
  endfunction

  // Data randomization
  function void randomize_bytes( int len );
    bytes.delete();
    length = len;
    for( int i = 0; i < len; i++ )
      bytes.push_back($urandom());
  endfunction

  // Adding valid bytes from beat
  function void append_from_beat( AST_Beat #( DATA_W ) beat );
    int n = beat.get_valid_bytes();
    for( int i = 0; i < n; i++ )
      bytes.push_back(beat.data[i*8 +: 8]);
    length = bytes.size();
  endfunction

  // Splitting to beats
  function automatic void to_beats( ref AST_Beat #( DATA_W ) beats[$] );
    int bytes_per_beat = DATA_W/8;
    int total          = bytes.size();
    int num_beats      = ( total + bytes_per_beat - 1 ) / bytes_per_beat;

    beats.delete();
    for( int i = 0; i < num_beats; i++ )
      begin
        AST_Beat #( DATA_W ) beat = new();

        int start_idx = i * bytes_per_beat;
        int valid_cnt = total - start_idx;

        if( valid_cnt > bytes_per_beat )
          valid_cnt = bytes_per_beat;

        beat.data = '0;
        for( int j = 0; j < valid_cnt; j++ )
          beat.data[j*8 +: 8] = bytes[start_idx + j];

        beat.startofpacket = ( i == 0 );
        beat.endofpacket   = ( i == ( num_beats - 1 ) );
        beat.valid         = 1'b1;
        beat.empty         = ( beat.endofpacket ) ? ( bytes_per_beat - valid_cnt ) : ( '0 );

        beats.push_back(beat);
      end
  endfunction

  // Conversion to a string for logs
  function string convert2string();
    string s = $sformatf("%s: len=%0d bytes=[", name, length);
    int    n = (bytes.size() < 16) ? ( bytes.size() ) : ( 16 );
    
    for( int i = 0; i < n; i++ )
      s = { s, $sformatf("%02h ", bytes[i]) };
    if( bytes.size() > 16 )
      s = { s, "..." };
    s = { s, "]" };

    return s;
  endfunction
endclass