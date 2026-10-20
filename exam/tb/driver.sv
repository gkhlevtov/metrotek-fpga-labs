class driver #(
  parameter int DATA_W  = 64,
  parameter int EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 )
);
  virtual ast_in_if #( DATA_W, EMPTY_W          ) vif;
  mailbox           #( Input_Packet #( DATA_W ) ) gen2drv;

  // Output sending settings
  int unsigned delay_max = 0;
  int unsigned gap_prob  = 0;
  int unsigned gap_max   = 3;

  // data/empty = 'x
  bit idle_x         = 1'b1;

  // random sop/eop while valid = 0
  bit idle_junk_ctrl = 1'b0;

  // Logging setting
  bit verbose = 1'b1;

  // Statistics
  int unsigned pkt_cnt    = 0;
  int unsigned beat_cnt   = 0;
  int unsigned gap_cycles = 0;

  function new(
    virtual ast_in_if #( DATA_W, EMPTY_W          ) vif,
    mailbox           #( Input_Packet #( DATA_W ) ) gen2drv
  );
    this.vif     = vif;
    this.gen2drv = gen2drv;
  endfunction

  // Idle state values driver
  task drive_idle_values();
    vif.drv_cb.valid <= 1'b0;

    if( idle_x )
      begin
        vif.drv_cb.data  <= 'x;
        vif.drv_cb.empty <= 'x;
      end
    else
      begin
        vif.drv_cb.data  <= '0;
        vif.drv_cb.empty <= '0;
      end

    if( idle_junk_ctrl )
      begin
        vif.drv_cb.sop <= 1'( $urandom_range( 0, 1 ) );
        vif.drv_cb.eop <= 1'( $urandom_range( 0, 1 ) );
      end
    else
      begin
        vif.drv_cb.sop <= 1'b0;
        vif.drv_cb.eop <= 1'b0;
      end
  endtask

  task reset();
    drive_idle_values();
  endtask

  // One idle cycle
  task automatic idle_cycle();
    drive_idle_values();
    @( vif.drv_cb );
    gap_cycles++;
  endtask

  task run();
    Input_Packet #( DATA_W ) pkt;

    forever
      begin
        gen2drv.get( pkt );
        drive_packet( pkt );
      end
  endtask

  task automatic drive_packet( Input_Packet #( DATA_W ) pkt );
    AST_Beat #( DATA_W, EMPTY_W ) beats[$];
    int unsigned                  delay = 0;

    pkt.to_beats( beats );

    if( delay_max > 0 )
      delay = $urandom_range( 0, delay_max );

    repeat( delay )
      idle_cycle();

    pkt_cnt++;
    if( verbose )
      $display( "[DRV] @%0t sending %s packet #%0d: len=%0d beats=%0d start_delay=%0d",
                $time, pkt.name, pkt_cnt, pkt.length, beats.size(), delay );

    foreach( beats[i] )
      begin
        // valid gap in the middle of packet
        if( ( i > 0 ) && ( gap_prob > 0 ) && ( $urandom_range( 0, 99 ) < gap_prob ) )
          repeat( $urandom_range( 1, gap_max ) )
            idle_cycle();

        drive_beat( beats[i] );
      end
  endtask

  task automatic drive_beat( AST_Beat #( DATA_W, EMPTY_W ) b );
    vif.drv_cb.data  <= b.data;
    vif.drv_cb.valid <= 1'b1;
    vif.drv_cb.sop   <= b.startofpacket;
    vif.drv_cb.eop   <= b.endofpacket;
    vif.drv_cb.empty <= b.empty;

    do
      @( vif.drv_cb );
    while( vif.drv_cb.ready !== 1'b1 );

    beat_cnt++;

    drive_idle_values();
  endtask
endclass