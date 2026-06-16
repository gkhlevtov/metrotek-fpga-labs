class Monitor #(
  parameter int DATA_W    = 64,
  parameter int EMPTY_W   = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 ),
  parameter int CHANNEL_W = 8,
  parameter int DIR_W     = 2
);
  virtual ast_out_if #( DATA_W, EMPTY_W, CHANNEL_W                             ) v_if;
  mailbox            #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) mon2scb;
  int                                                                            port_id;

  function new(
    virtual ast_out_if #( DATA_W, EMPTY_W, CHANNEL_W                             ) v_if,
    mailbox            #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) mon2scb,
    int                                                                            port_id
  );
    this.v_if    = v_if;
    this.mon2scb = mon2scb;
    this.port_id = port_id;
  endfunction

  task run();
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) tr;

    forever
      begin
        if( v_if.mon_cb.valid && v_if.mon_cb.ready )
          begin
            tr               = new();
            tr.data          = v_if.mon_cb.data;
            tr.startofpacket = v_if.mon_cb.startofpacket;
            tr.endofpacket   = v_if.mon_cb.endofpacket;
            tr.valid         = v_if.mon_cb.valid;
            tr.empty         = v_if.mon_cb.empty;
            tr.channel       = v_if.mon_cb.channel;
            tr.dir           = port_id;

            mon2scb.put( tr );
            $display("[MON %0d] @%0t captured beat: sop=%b eop=%b empty=%0d ch=%0d\ndata=%h",
                    port_id, $time, tr.startofpacket, tr.endofpacket, tr.empty, tr.channel, tr.data);
          end
        @( v_if.mon_cb );
    end
  endtask
endclass