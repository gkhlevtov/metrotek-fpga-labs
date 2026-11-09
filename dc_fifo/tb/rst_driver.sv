class rst_driver #(
  parameter bit RESET_LOW = 1
);
  virtual rst_if #( RESET_LOW ) vif;

  function new( virtual rst_if #( RESET_LOW ) vif );
    this.vif = vif;
  endfunction

  task pulse_rst( int hold_time )
    $display( "[@%0t][RST_DRV] reset asserted", $time );
    vif.assert_rst();
    #( hold_time );
    vif.release_rst();
  endtask
endclass
