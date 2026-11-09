class wr_monitor #(
  parameter int DWIDTH = 32
);
  virtual wr_if #( DWIDTH ) vif;
  golden_model              gm;

  function new(
    virtual wr_if #( DWIDTH ) vif,
    golden_model              gm
  );
    this.vif = vif;
    this.gm  = gm;
  endfunction
   
  task run();
    forever
      begin
        @( posedge vif.clk );
        if( vif.wrreq && !vif.full )
          gm.push(vif.data);
      end
  endtask
endclass
