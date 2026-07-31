class wr_monitor #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = DATA_WIDTH / 8
);

  virtual amm_wr_if #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ).MONITOR vif;
  mailbox #( wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) )      mon2scb;

  function new(
    virtual amm_wr_if #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ).MONITOR vif,
    mailbox #( wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) )      mon2scb
  );
    this.vif     = vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    int unsigned cycle_cnt = 0;

    forever
      begin
        @( vif.mon_cb );
        cycle_cnt++;

        if( vif.mon_cb.wr_write && !vif.mon_cb.wr_waitrequest )
          begin
            wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) item;

            item            = new();
            item.address    = vif.mon_cb.wr_address;
            item.writedata  = vif.mon_cb.wr_writedata;
            item.byteenable = vif.mon_cb.wr_byteenable;
            item.req_time   = cycle_cnt;

            $display( "[WR_MON] @%0t captured write: addr=%h data=%h be=%b",
                       $time, item.address, item.writedata, item.byteenable );

            mon2scb.put( item );
          end
      end
  endtask
endclass