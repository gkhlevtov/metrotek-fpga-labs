class Output_Packet;
  byte bytes[$];
  int  length;

  function new();
    length = 0;
  endfunction

  function void append_byte(byte b);
    bytes.push_back(b);
    length += 1;
  endfunction

  // Conversion to a string for logs
  function string convert2string();
    string s = $sformatf("len=%0d bytes=[", length);
    int    n = (bytes.size() < 16) ? ( bytes.size() ) : ( 16 );

    for( int i = 0; i < n; i++ )
      s = { s, $sformatf("%02h ", bytes[i]) };
    if( bytes.size() > 16 )
      s = { s, "..." };
    s = { s, "]" };

    return s;
  endfunction
endclass