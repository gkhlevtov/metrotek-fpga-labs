class wr_driver #(
  parameter int DWIDTH = 32
);
  virtual wr_if #( DWIDTH ) vif;
  mailbox       #( word_t ) gen2drv;
  
  bit have = 1'b0;
  int prob = 90;

  function new(
    virtual wr_if #( DWIDTH ) vif,
    mailbox       #( word_t ) gen2drv
  )
    this.vif     = vif;
    this.gen2drv = gen2drv;
  endfunction
   
  task run()
    word_t d;
    forever
      begin
	@( posedge vif.clk );
        if( vif.wrreq && !vif.full )
          have = 1'b0;
        if( !have )
          begin
            if( ( $urandom_range(1, 99) < prob ) && mbx.try_get(d) )
	      begin
		$display(" [@%0t][WR_DRV] sending word: %0h", $time, d );
                vif.data  <= d;
                vif.wrreq <= 1'b1;

	        have      = 1'b1;  
            else
	      begin
                vif.data  <= word_r'($urandom);
                vif.wrreq <= 1'b0;  
	      end
          end
      end
  endtask
endclass
