class Merge_Pair #(
  parameter int DATA_W = 64
);
  Input_Packet #( DATA_W ) base;
  Input_Packet #( DATA_W ) insert;
  int                      offset;

  function new();
    base   = new("base");
    insert = new("insert");
    offset = 1;
  endfunction

  function Merge_Pair #( DATA_W ) copy();
    Merge_Pair #( DATA_W ) pair = new();
    pair.base   = this.base.copy();
    pair.insert = this.insert.copy();
    pair.offset = this.offset;
    
    return pair;
  endfunction

  // Packages and offsets randomization
  function void randomize_pair(
    int off      = -1,
    int base_len = -1,
    int ins_len  = -1,
    int max_len  = 65535
  );
    if( base_len < 0 )
      base_len = $urandom_range(1, max_len);
    if( ins_len  < 0 )
      ins_len  = $urandom_range(1, max_len);
    if( off      < 0 )
      off      = $urandom_range(1, base_len);

    base.randomize_bytes(base_len);
    insert.randomize_bytes(ins_len);
    offset = off;
  endfunction

  // Conversion to a string for logs
  function string convert2string();
    return $sformatf("offset=%0d | %s | %s",
                      offset, base.convert2string(), insert.convert2string());
  endfunction
endclass