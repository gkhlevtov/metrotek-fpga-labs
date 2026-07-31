class ctrl_monitor #(
  parameter int ADDR_WIDTH = 10
);

  virtual amm_ctrl_if #( ADDR_WIDTH ).MONITOR vif;
  mailbox #( ctrl_item #( ADDR_WIDTH ) )      mon2scb;

  int unsigned completed_jobs = 0;

  function new(
    virtual amm_ctrl_if #( ADDR_WIDTH ).MONITOR vif,
    mailbox #( ctrl_item #( ADDR_WIDTH ) )      mon2scb
  );
    this.vif     = vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    bit prev_waitrequest = 1'b0;

    forever
      begin
        @( vif.mon_cb );

        if( vif.mon_cb.run )
          begin
            ctrl_item #( ADDR_WIDTH ) item;

            item           = new();
            item.base_addr = vif.mon_cb.base_addr;
            item.length    = vif.mon_cb.length;

            $display( "[CTRL_MON] @%0t captured job: base_addr=%h length=%0d",
                       $time, item.base_addr, item.length );

            mon2scb.put( item );
          end

        if( prev_waitrequest && !vif.mon_cb.waitrequest )
          begin
            completed_jobs++;
            $display( "[CTRL_MON] @%0t job completed (waitrequest 1->0), total=%0d",
                      $time, completed_jobs );
          end

        prev_waitrequest = vif.mon_cb.waitrequest;
      end
  endtask
endclass