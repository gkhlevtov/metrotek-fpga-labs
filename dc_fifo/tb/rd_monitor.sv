class rd_monitor #(
  paramater int DWIDTH = 32
);
  virtual rd_if #( DWIDTH ) vif;
  golden_model              gm;
  
  bit pending         = 1'b0;
  // SHOWAHEAD = 0 && REGISTER_OUTPUT = 1
  bit data_next_cycle = 1'b0;
  
  function new(
    virtual rd_if #( DWIDTH ) vif,
    golden_model              gm
  )
    this.vif = vif;
    this.gm  = gm;
  endfunction
  
  function void reset()
    pending = 1'b0;
  endfunction
  
  task run()
    forever
      begin
        @( posedge vif.clk );
        if( data_next_cycle && pending )
          begin
            gm.check(vif.data);
            pending = 1'b0;
          end
        if( vif.rdreq && !vif.empty )
          begin
           if( data_next_cycle )
             pending = 1'b1;
           else
             gm.check(vif.data);
          end
      end
  endtask
endclass
