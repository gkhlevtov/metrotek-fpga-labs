class avalon_slave_model #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = DATA_WIDTH / 8
);

  virtual amm_rd_if #( DATA_WIDTH, ADDR_WIDTH ).SLAVE           rd_vif;
  virtual amm_wr_if #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ).SLAVE wr_vif;

  byte mem [];

  // waitrequest random chance percent
  int unsigned rd_waitrequest_pct = 0;
  int unsigned wr_waitrequest_pct = 0;

  // read latency range
  int unsigned rd_latency_min = 0;
  int unsigned rd_latency_max = 63;

  function new(
    virtual amm_rd_if #( DATA_WIDTH, ADDR_WIDTH ).SLAVE           rd_if,
    virtual amm_wr_if #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ).SLAVE wr_if
  );
    rd_vif = rd_if;
    wr_vif = wr_if;

    mem = new[ ( 1 << ADDR_WIDTH ) * BYTE_CNT ];
  endfunction

  function void init_random_mem();
    foreach( mem[i] )
      mem[i] = $urandom_range( 0, 255 );
  endfunction

  function bit [DATA_WIDTH-1:0] read_word( bit [ADDR_WIDTH-1:0] addr );
    bit [DATA_WIDTH-1:0] data;

    for( int b = 0; b < BYTE_CNT; b++ )
      data[ b*8 +: 8 ] = mem[ addr * BYTE_CNT + b ];

    return data;
  endfunction

  function void set_rd_waitrequest_pct( int unsigned pct );
    rd_waitrequest_pct = pct;
  endfunction

  function void set_wr_waitrequest_pct( int unsigned pct );
    wr_waitrequest_pct = pct;
  endfunction

  function void set_rd_latency_range( int unsigned min_lat, int unsigned max_lat );
    rd_latency_min = min_lat;
    rd_latency_max = max_lat;
  endfunction

  function void set_byte_value( int unsigned byte_addr, byte value );
    mem[byte_addr] = value;
  endfunction

  function void set_range_value( int unsigned byte_addr_start, int unsigned byte_addr_end, byte value );
    for( int unsigned a = byte_addr_start; a <= byte_addr_end; a++ )
      mem[a] = value;
  endfunction

  function void write_word(
    bit [ADDR_WIDTH-1:0] addr,
    bit [DATA_WIDTH-1:0] data,
    bit [BYTE_CNT-1:0]   byteenable
  );
    for( int b = 0; b < BYTE_CNT; b++ )
      if( byteenable[b] )
        mem[ addr * BYTE_CNT + b ] = data[ b*8 +: 8 ];
  endfunction

  function byte peek_byte( int unsigned byte_addr );
    return mem[ byte_addr ];
  endfunction
  
  task run_read();
    int unsigned         cycle_cnt = 0;
    bit                  cur_waitrequest;

    bit [ADDR_WIDTH-1:0] pending_addr [$];
    int unsigned         pending_due  [$];

    cur_waitrequest = 1'b0;
    rd_vif.slv_cb.rd_waitrequest <= cur_waitrequest;

    forever
      begin
        @( rd_vif.slv_cb );
        cycle_cnt++;

        if( rd_vif.slv_cb.rd_read && !cur_waitrequest )
          begin
            int unsigned due;

            due = cycle_cnt + $urandom_range( rd_latency_min, rd_latency_max );

            if( ( pending_due.size() > 0 ) && ( due <= pending_due[$] ) )
              due = pending_due[$] + 1;

            pending_addr.push_back( rd_vif.slv_cb.rd_address );
            pending_due.push_back( due );
          end

        cur_waitrequest = ( $urandom_range( 0, 99 ) < rd_waitrequest_pct );
        rd_vif.slv_cb.rd_waitrequest <= cur_waitrequest;

        if( ( pending_due.size() > 0 ) && ( pending_due[0] == cycle_cnt ) )
          begin
            bit [ADDR_WIDTH-1:0] addr;

            addr = pending_addr.pop_front();
            void'(pending_due.pop_front());

            rd_vif.slv_cb.rd_readdata      <= read_word( addr );
            rd_vif.slv_cb.rd_readdatavalid <= 1'b1;
          end
        else
          begin
            rd_vif.slv_cb.rd_readdata      <= 'x;
            rd_vif.slv_cb.rd_readdatavalid <= 1'b0;
          end
      end
  endtask

  task run_write();
    bit cur_waitrequest;

    cur_waitrequest = 1'b0;
    wr_vif.slv_cb.wr_waitrequest <= cur_waitrequest;

    forever
      begin
        @( wr_vif.slv_cb );

        if( wr_vif.slv_cb.wr_write && !cur_waitrequest )
          write_word(
            wr_vif.slv_cb.wr_address,
            wr_vif.slv_cb.wr_writedata,
            wr_vif.slv_cb.wr_byteenable
          );

        cur_waitrequest = ( $urandom_range( 0, 99 ) < wr_waitrequest_pct );
        wr_vif.slv_cb.wr_waitrequest <= cur_waitrequest;
      end
  endtask
endclass