class monitor #(
  parameter int DATA_W  = 64,
  parameter int EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 )
);
  localparam int N = DATA_W / 8;

  virtual ast_out_if #( DATA_W, EMPTY_W ) vif;
  mailbox            #( Output_Packet   ) mon2scb;

  // Logging settings
  bit verbose_pkt   = 1'b1;
  bit verbose_beats = 1'b0;

  // Statistics
  int unsigned beat_cnt      = 0;
  int unsigned pkt_cnt       = 0;
  int unsigned total_bubbles = 0;
  int unsigned protocol_err  = 0;

  // Current in packet status
  bit in_pkt = 1'b0;

  function new(
    virtual ast_out_if #( DATA_W, EMPTY_W ) vif,
    mailbox            #( Output_Packet   ) mon2scb
  );
    this.vif     = vif;
    this.mon2scb = mon2scb;
  endfunction

  // Universal error message
  function void report_error( string msg );
    protocol_err++;
    $error( "[MON] @%0t protocol error: %s", $time, msg );
  endfunction

  task run();
    Output_Packet pkt         = null;
    int unsigned  pkt_beats   = 0;
    int unsigned  pkt_bubbles = 0;
    int           n;
    bit           x_in_data;

    forever
      begin
        @( vif.mon_cb );

        if( $isunknown( vif.mon_cb.valid ) )
          begin
            report_error( "valid is X/Z" );
            continue;
          end

        // Bubbles count
        if( !vif.mon_cb.valid )
          begin
            if( in_pkt && ( vif.mon_cb.ready === 1'b1 ) )
              begin
                pkt_bubbles++;
                total_bubbles++;
              end
            continue;
          end

        // Word proposed, but not accepted
        if( vif.mon_cb.ready !== 1'b1 )
          continue;

        // Word transmitted
        if( $isunknown( vif.mon_cb.sop ) || $isunknown( vif.mon_cb.eop ) )
          report_error( "sop/eop is X/Z on a valid beat" );

        // Packet starts
        if( !in_pkt )
          begin
            if( vif.mon_cb.sop !== 1'b1 )
              report_error( "first beat of a packet without sop" );

            pkt         = new();
            in_pkt      = 1'b1;
            pkt_beats   = 0;
            pkt_bubbles = 0;
          end
        else if( vif.mon_cb.sop === 1'b1 )
          begin
            report_error( "sop in the middle of a packet, previous packet dropped" );

            pkt         = new();
            pkt_beats   = 0;
            pkt_bubbles = 0;
          end

        n = N;
        
        // The number of valid bytes in a word + empty check
        if( vif.mon_cb.eop === 1'b1 )
          begin
            if( $isunknown( vif.mon_cb.empty ) )
              report_error( "empty is X/Z on the last beat" );
            else if( int'( vif.mon_cb.empty ) >= N )
              report_error( $sformatf( "empty=%0d is not less than N=%0d on the last beat",
                                        vif.mon_cb.empty, N ) );
            else
              n = N - int'( vif.mon_cb.empty );
          end

        // Byte assembly
        x_in_data = 1'b0;
        for( int i = 0; i < n; i++ )
          begin
            if( $isunknown( vif.mon_cb.data[i*8 +: 8] ) )
              x_in_data = 1'b1;
            pkt.append_byte( vif.mon_cb.data[i*8 +: 8] );
          end

        if( x_in_data )
          report_error( "X/Z in valid data bytes" );

        pkt_beats++;
        beat_cnt++;

        if( verbose_beats )
          $display( "[MON] @%0t beat: data=%h sop=%0b eop=%0b empty=%0d",
                    $time, vif.mon_cb.data, vif.mon_cb.sop, vif.mon_cb.eop, vif.mon_cb.empty );

        // End of packet
        if( vif.mon_cb.eop === 1'b1 )
          begin
            pkt_cnt++;

            if( verbose_pkt )
              $display( "[MON] @%0t captured packet #%0d: len=%0d beats=%0d bubbles=%0d",
                        $time, pkt_cnt, pkt.length, pkt_beats, pkt_bubbles );

            mon2scb.put( pkt );
            in_pkt = 1'b0;
            pkt    = null;
          end
      end
  endtask
endclass