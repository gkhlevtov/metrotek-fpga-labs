class rst_driver #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
);
  virtual wr_if #( DWIDTH, AWIDTH ) wr_vif;
  virtual rd_if #( DWIDTH, AWIDTH ) rd_vif;

  function new(
    virtual wr_if #( DWIDTH, AWIDTH ) wr_vif,
    virtual rd_if #( DWIDTH, AWIDTH ) rd_vif
  );
    this.wr_vif = wr_vif;
    this.rd_vif = rd_vif;
  endfunction

  task pulse_rst( int wr_cycles, int rd_cycles );
    $display( "[@%0t][RST_DRV] reset asserted, wr_cycles: %0d, rd_cycles: %0d",
	       $time, wr_cycles, rd_cycles );
    fork
      begin
        @( posedge wr_vif.clk );
	wr_vif.rst <= 1'b1;
	repeat( wr_cycles )
	  @( posedge wr_vif.clk );
	wr_vif.rst <= 1'b0;
      end
      begin
        @( posedge rd_vif.clk );
	rd_vif.rst <= 1'b1;
	repeat( rd_cycles )
	  @( posedge rd_vif.clk );
	rd_vif.rst <= 1'b0;
      end
    join
  endtask
endclass
