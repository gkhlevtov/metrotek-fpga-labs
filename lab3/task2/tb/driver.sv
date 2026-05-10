class Driver #(
  parameter int DATA_W    = 64,
  parameter int EMPTY_W   = $clog2(DATA_W/8) ? $clog2(DATA_W/8) : 1,
  parameter int CHANNEL_W = 10
);
  virtual ast_in_if #( DATA_W, EMPTY_W, CHANNEL_W                      ) v_if;
  mailbox           #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W ) ) gen2drv;

  function new(
    virtual ast_in_if #( DATA_W, EMPTY_W, CHANNEL_W                      ) v_if,
    mailbox           #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W ) ) gen2drv
  );
    this.v_if    = v_if;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W ) tr;

    forever
      begin
        gen2drv.get( tr );

        @( v_if.drv_cb );
        v_if.drv_cb.srst          <= tr.srst;
        v_if.drv_cb.data          <= tr.data;
        v_if.drv_cb.startofpacket <= tr.startofpacket;
        v_if.drv_cb.endofpacket   <= tr.endofpacket;
        v_if.drv_cb.valid         <= tr.valid;
        v_if.drv_cb.empty         <= tr.empty;
        v_if.drv_cb.channel       <= tr.channel;

        /*
        $display("[DRV] @%0t: valid=%b sop=%b eop=%b empty=%0d ch=%0d data=%h",
         $time, tr.valid, tr.startofpacket, tr.endofpacket, tr.empty, tr.channel, tr.data);
        */
        
        if( tr.valid && !tr.srst )
          begin
            while ( !v_if.drv_cb.ready )
              begin
                v_if.drv_cb.valid <= 0;
                @( v_if.drv_cb );
              end
          end
      end
  endtask
endclass
