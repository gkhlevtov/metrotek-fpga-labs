class rd_monitor #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
);
  virtual rd_if #( DWIDTH, AWIDTH ) vif;
  golden_model  #( DWIDTH         ) gm;

  int       latency = 0;
  bit [3:0] rd_pipe = 4'b0;

  function new(
    virtual rd_if #( DWIDTH, AWIDTH ) vif,
    golden_model  #( DWIDTH         ) gm
  );
    this.vif = vif;
    this.gm  = gm;
  endfunction

  function void reset();
    rd_pipe = 4'b0;
  endfunction

  task run();
    bit rd_now;
    forever
      begin
        @( posedge vif.clk );
        rd_now = !vif.rst && vif.rdreq && !vif.empty;
        if( latency == 0 )
          begin
            if( rd_now )
              gm.check(vif.data);
          end
        else
          begin
           if( rd_pipe[latency-1] )
             gm.check(vif.data);
           rd_pipe = { rd_pipe[2:0], rd_now };
          end
      end
  endtask
endclass
