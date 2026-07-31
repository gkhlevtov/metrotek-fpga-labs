class golden_model #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = DATA_WIDTH / 8
);

  avalon_slave_model #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) slv;

  function new( avalon_slave_model #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) slv );
    this.slv = slv;
  endfunction

  function void predict(
    ctrl_item #( ADDR_WIDTH )                             job,
    ref wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) exp_q[$]
  );
    int unsigned total_bytes;
    int unsigned byte_start;
    int unsigned byte_end;
    int unsigned word_start;
    int unsigned word_end;

    total_bytes = ( 1 << ADDR_WIDTH ) * BYTE_CNT;
    byte_start  = job.base_addr * BYTE_CNT;

    exp_q.delete();

    if( byte_start >= total_bytes )
      return;

    byte_end = byte_start + job.length;
    if( byte_end > total_bytes )
      byte_end = total_bytes;

    word_start = byte_start / BYTE_CNT;
    word_end   = ( byte_end - 1 ) / BYTE_CNT;

    for( int unsigned w = word_start; w <= word_end; w++ )
      begin
        wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) item;
        bit [BYTE_CNT-1:0]                            be;
        bit [DATA_WIDTH-1:0]                          data;

        be   = '0;
        data = '0;

        for( int b = 0; b < BYTE_CNT; b++ )
          begin
            int unsigned cur_byte_addr;

            cur_byte_addr = w * BYTE_CNT + b;

            if( ( cur_byte_addr >= byte_start ) && ( cur_byte_addr < byte_end ) )
              begin
                byte orig_byte;

                orig_byte        = slv.peek_byte( cur_byte_addr );
                data[ b*8 +: 8 ] = orig_byte + 8'd1;
                be[b]            = 1'b1;
              end
          end

        item            = new();
        item.address    = w;
        item.writedata  = data;
        item.byteenable = be;

        exp_q.push_back( item );
      end
  endfunction
endclass