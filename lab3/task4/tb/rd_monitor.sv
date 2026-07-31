class rd_monitor #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
);

  virtual amm_rd_if #( DATA_WIDTH, ADDR_WIDTH ).MONITOR vif;
  mailbox #( rd_item #( DATA_WIDTH, ADDR_WIDTH ) )      mon2scb;

  function new(
    virtual amm_rd_if #( DATA_WIDTH, ADDR_WIDTH ).MONITOR vif,
    mailbox #( rd_item #( DATA_WIDTH, ADDR_WIDTH ) )      mon2scb
  );
    this.vif     = vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    int unsigned cycle_cnt = 0;
    int unsigned seq_cnt   = 0;

    rd_item #( DATA_WIDTH, ADDR_WIDTH ) pending_q [$];

    forever
      begin
        @( vif.mon_cb );
        cycle_cnt++;

        if( vif.mon_cb.rd_read && !vif.mon_cb.rd_waitrequest )
          begin
            rd_item #( DATA_WIDTH, ADDR_WIDTH ) item;

            item          = new();
            item.address  = vif.mon_cb.rd_address;
            item.req_time = cycle_cnt;
            item.seq_num  = seq_cnt++;

            pending_q.push_back( item );

            $display( "[RD_MON] @%0t captured request: addr=%h seq=%0d",
                       $time, item.address, item.seq_num );
          end

        if( vif.mon_cb.rd_readdatavalid )
          begin
            rd_item #( DATA_WIDTH, ADDR_WIDTH ) item;

            item           = pending_q.pop_front();
            item.readdata  = vif.mon_cb.rd_readdata;
            item.resp_time = cycle_cnt;

            $display( "[RD_MON] @%0t captured response: addr=%h seq=%0d data=%h latency=%0d",
                       $time, item.address, item.seq_num, item.readdata, ( item.resp_time - item.req_time ) );

            mon2scb.put( item );
          end
      end
  endtask
endclass