class rd_driver #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
);
  virtual rd_if #( DWIDTH, AWIDTH ) vif;
  
  int prob = 90;

  function new( virtual rd_if #( DWIDTH, AWIDTH ) vif );
    this.vif = vif;
  endfunction

  task run();
    forever
      begin
        @( posedge vif.clk )
        //$display( "[@%0t][RD_DRV] reading word", $time );
        vif.rdreq <= ( $urandom_range(99) < prob );
      end
  endtask
endclass
