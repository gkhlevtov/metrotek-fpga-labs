class rd_driver #(
  parameter int DWIDTH = 32
);
  virtual rd_if #( DWIDTH ) vif;
  
  int prob = 90;

  function new( virtual rd_if #( DWIDTH ) vif );
    this.vif = vif;
  endfunction

  task run()
    forever
      begin
        @( posedge vif.clk )
        if( $urandom(1, 99) < prob )
          begin
            $display( "[@%0t][DRV_DRV] reading word", $time );
            vif.rdreq <= 1'b1;
          end
        else
          vif.rdreq <= 1'b0;
      end
  endtask
endclass
