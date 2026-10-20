class Golden_Model #(
  parameter int DATA_W = 64
);
  static function Output_Packet predict( Merge_Pair #( DATA_W ) pair );
    Output_Packet result     = new();
    int           base_len   = pair.base.bytes.size();
    // Offset without the base's excess length
    int           offset_cut = ( pair.offset < base_len ) ? ( pair.offset ) : ( base_len );

    // Filling with bytes from base to offset
    for( int i = 0; i < offset_cut; i++ )
      result.append_byte( pair.base.bytes[i] );

    // Filling with bytes from insert
    foreach( pair.insert.bytes[i] )
      result.append_byte( pair.insert.bytes[i] );

    // Filling with the remainder base bytes
    for( int i = offset_cut; i < base_len; i++ )
      result.append_byte( pair.base.bytes[i] );
    
    return result;
  endfunction
endclass