class driver #(
  parameter int ADDR_WIDTH = 10
);

  virtual amm_ctrl_if #( ADDR_WIDTH ).DRIVER vif;
  mailbox #( ctrl_item #( ADDR_WIDTH ) )     gen2drv;

  function new(
    virtual amm_ctrl_if #( ADDR_WIDTH ).DRIVER vif,
    mailbox #( ctrl_item #( ADDR_WIDTH ) )     gen2drv
  );
    this.vif     = vif;
    this.gen2drv = gen2drv;
  endfunction

  task reset();
    vif.drv_cb.srst      <= 1'b1;
    vif.drv_cb.base_addr <= '0;
    vif.drv_cb.length    <= '0;
    vif.drv_cb.run       <= 1'b0;

    @( vif.drv_cb );

    vif.drv_cb.srst <= 1'b0;

    @( vif.drv_cb );
  endtask

  task run();
    ctrl_item #( ADDR_WIDTH ) job;

    forever
      begin
        gen2drv.get( job );

        wait( vif.drv_cb.waitrequest == 1'b0 );

        vif.drv_cb.base_addr <= job.base_addr;
        vif.drv_cb.length    <= job.length;
        vif.drv_cb.run       <= 1'b1;

        @( vif.drv_cb );

        vif.drv_cb.run       <= 1'b0;
        vif.drv_cb.base_addr <= 'x;
        vif.drv_cb.length    <= 'x;
        
        $display( "[DRV] @%0t issued job: base_addr=%h length=%0d",
                    $time, job.base_addr, job.length );

        @( vif.drv_cb );
      end
  endtask
endclass