class wr_monitor #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
);
  virtual wr_if #( DWIDTH, AWIDTH ) vif;
  golden_model  #( DWIDTH         ) gm;

  function new(
    virtual wr_if #( DWIDTH, AWIDTH ) vif,
    golden_model  #( DWIDTH         ) gm
  );
    this.vif = vif;
    this.gm  = gm;
  endfunction
   
  task run();
    forever
      begin
        @( posedge vif.clk );
        if( !vif.rst && vif.wrreq && !vif.full )
          gm.push(vif.data);
      end
  endtask
endclass
