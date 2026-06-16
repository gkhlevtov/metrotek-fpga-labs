class Scoreboard #(
  parameter int DATA_W    = 64,
  parameter int EMPTY_W   = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 ),
  parameter int CHANNEL_W = 8,
  parameter int TX_DIR    = 4,
  parameter int DIR_W     = ( TX_DIR == 1 ) ? ( 1 ) : ( $clog2(TX_DIR) )
);
  AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) expected_tr [TX_DIR-1:0][$];

  logic [CHANNEL_W-1:0] sop_channel [TX_DIR-1:0];
  logic                 in_packet   [TX_DIR-1:0];

  int error_count = 0;
  int check_count = 0;

  mailbox #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) mon2scb;

  function new(
    mailbox #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) mon2scb
  );
    this.mon2scb = mon2scb;
    foreach( in_packet[i] )
      in_packet[i] = 0;
  endfunction

  function void add_expected_data(
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) tr
  );
    int port = tr.dir;
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) exp = tr.copy();
    /*
    $display("[SCB ADD] port=%0d, data=%h, sop=%b, eop=%b, empty=%0d",
              port, tr.data, tr.startofpacket, tr.endofpacket, tr.empty);
    */

    if( tr.startofpacket )
      sop_channel[port] = tr.channel;

    exp.channel = sop_channel[port];
    expected_tr[port].push_back( exp );
  endfunction

  function void reset();
    for ( int p = 0; p < TX_DIR; p++ )
      begin
        if ( expected_tr[p].size() > 0 )
          begin
            $error("[SCB] @%0t: LOST PACKETS on port %0d - %0d beat(s) sent but never received by DUT output!",
                    $time, p, expected_tr[p].size());
            error_count++;
            expected_tr[p] = {};
          end
        sop_channel[p] = '0;
        in_packet[p]   = 0;
      end
  endfunction

  task run();
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) out_tr;
    forever
      begin
        mon2scb.get( out_tr );
        check_beat( out_tr );
      end
  endtask

  task check_beat(
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) tr
  );
    int  port    = tr.dir;
    bit  beat_ok = 1;
    AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) exp_tr;

    check_count++;

    if( expected_tr[port].size() == 0 )
      begin
        $error("[SCB] @%0t beat #%0d: Port %0d received SPURIOUS OUTPUT (not expected)! sop=%b eop=%b ch=%0d data=%h",
                $time, check_count, port, tr.startofpacket, tr.endofpacket, tr.channel, tr.data);
        error_count++;
        return;
      end

    exp_tr = expected_tr[port].pop_front();

    if( tr.startofpacket )
      begin
        if ( in_packet[port] )
          begin
            $error("[SCB] @%0t port %0d: Unexpected SOP - previous packet not finished!",
                   $time, port);
            error_count++;
          end
        in_packet[port] = 1;
      end
    else if( !in_packet[port] )
      begin
        $error("[SCB] @%0t port %0d: Beat received outside SOP/EOP window!",
                $time, port);
        error_count++;
        return;
      end

    if( tr.startofpacket )
      if( tr.channel !== exp_tr.channel )
        begin
          $error("[SCB] @%0t beat #%0d port %0d: CHANNEL mismatch! Got=%0b Exp=%0b",
                  $time, check_count, port, tr.channel, exp_tr.channel);
          beat_ok = 0;
        end

    if( tr.startofpacket !== exp_tr.startofpacket )
      begin
        $error("[SCB] @%0t beat #%0d port %0d: SOP mismatch! Got=%b Exp=%b",
                $time, check_count, port, tr.startofpacket, exp_tr.startofpacket);
        beat_ok = 0;
      end

    if( tr.endofpacket !== exp_tr.endofpacket )
      begin
        $error("[SCB] @%0t beat #%0d port %0d: EOP mismatch! Got=%b Exp=%b",
                $time, check_count, port, tr.endofpacket, exp_tr.endofpacket);
        beat_ok = 0;
      end

    if( tr.endofpacket )
      if( tr.empty !== exp_tr.empty )
        begin
          $error("[SCB] @%0t beat #%0d port %0d: EMPTY mismatch! Got=%0d Exp=%0d",
                  $time, check_count, port, tr.empty, exp_tr.empty);
          beat_ok = 0;
        end

    if( tr.data !== exp_tr.data )
      begin
        $error("[SCB] @%0t beat #%0d port %0d: DATA mismatch! Got=%h Exp=%h",
                $time, check_count, port, tr.data, exp_tr.data);
        beat_ok = 0;
      end

    if( tr.endofpacket )
      in_packet[port] = 0;

    if( !beat_ok )
      error_count++;
    else
      $display("[SCB] @%0t beat #%0d port %0d: PASSED sop=%b eop=%b empty=%0d",
                $time, check_count, port, tr.startofpacket, tr.endofpacket, tr.empty);
  endtask

  function void final_report();
    int total_pending = 0;

    for( int p = 0; p < TX_DIR; p++ )
      begin
        if( expected_tr[p].size() > 0 )
          begin
            $error("[SCB] Port %0d has %0d pending beat(s) never received - LOST PACKETS!",
                    p, expected_tr[p].size());
            error_count++;
            total_pending += expected_tr[p].size();
          end
      end

    $display("\n==============================================");
    $display("\tAST DMX TB - FINAL REPORT");
    $display("\tChecks         : %0d", check_count);
    $display("\tErrors         : %0d", error_count);
    $display("\tPending beats  : %0d", total_pending);
    if( ( error_count == 0 ) && ( total_pending == 0 ) )
      $display("\tOVERALL STATUS : PASSED");
    else
      $display("\tOVERALL STATUS : FAILED");
    $display("==============================================\n");
  endfunction
endclass