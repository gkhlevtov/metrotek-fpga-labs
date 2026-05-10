class Scoreboard #(
  parameter int IN_DATA_W  = 64,
  parameter int OUT_DATA_W = 256,
  parameter int CHANNEL_W  = 10
);
  localparam int IN_BYTES    = IN_DATA_W  / 8;
  localparam int OUT_BYTES   = OUT_DATA_W / 8;
  localparam int IN_EMPTY_W  = $clog2(IN_BYTES)  ? $clog2(IN_BYTES)  : 1;
  localparam int OUT_EMPTY_W = $clog2(OUT_BYTES) ? $clog2(OUT_BYTES) : 1;

  bit  [CHANNEL_W-1:0] expected_channels[$];
  byte                 expected_bytes[$];
  int                  pkt_sizes[$];

  int  pkt_acc_bytes     = 0;
  bit  partial_sop_seen  = 0;
  int  out_pkt_popped    = 0;
  bit  in_packet_now     = 0;
  int  error_count       = 0;
  int  check_count       = 0;

  mailbox #( AST_Transaction #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W ) ) mon2scb;

  function new(
    mailbox #( AST_Transaction #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W ) ) mon2scb
  );
    this.mon2scb = mon2scb;
  endfunction

  function void add_expected_data(
    AST_Transaction #( IN_DATA_W, IN_EMPTY_W, CHANNEL_W ) tr
  );
    int valid_bytes;

    if( tr.startofpacket )
    begin
      partial_sop_seen = 1;
      expected_channels.push_back( tr.channel );
    end

    valid_bytes    = IN_BYTES - ( ( tr.endofpacket ) ? ( int'(tr.empty) ) : ( 0 ) );
    pkt_acc_bytes += valid_bytes;

    for( int i = 0; i < valid_bytes; i++ )
      expected_bytes.push_back( tr.data[IN_DATA_W-1-i*8 -: 8] );

    if( tr.endofpacket )
      begin
        pkt_sizes.push_back( pkt_acc_bytes );
        pkt_acc_bytes    = 0;
        partial_sop_seen = 0;
      end
  endfunction

  function void flush_partial_packet();
    repeat( pkt_acc_bytes )
      if( expected_bytes.size() > 0 )
        void'( expected_bytes.pop_back() );

    if( partial_sop_seen && ( expected_channels.size() > 0 ) )
      void'( expected_channels.pop_back() );

    pkt_acc_bytes    = 0;
    partial_sop_seen = 0;
    in_packet_now    = 0;
    out_pkt_popped   = 0;
  endfunction

  task run();
    AST_Transaction #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W ) out_tr;
    forever
      begin
        mon2scb.get( out_tr );
        check_beat( out_tr );
      end
  endtask

  task check_beat(
    AST_Transaction #( OUT_DATA_W, OUT_EMPTY_W, CHANNEL_W ) tr
  );
    int curr_pkt_total;
    int remaining;
    bit is_last_word;
    int current_beat_valid;
    int exp_empty_val       = 0;
    bit beat_ok             = 1;

    check_count++;

    if( tr.startofpacket )
      begin
        if( in_packet_now )
          begin
            $error("[SCB] @%0t: Unexpected SOP! Previous packet not finished.", $time);
            error_count++;
          end
        in_packet_now = 1;

        // Channel
        if( expected_channels.size() > 0 )
          begin
            bit [CHANNEL_W-1:0] exp_ch = expected_channels.pop_front();
            if( tr.channel !== exp_ch )
              begin
                $error("[SCB] @%0t beat #%0d: CHANNEL mismatch! Got=%0d Exp=%0d",
                      $time, check_count, tr.channel, exp_ch);
                beat_ok = 0;
              end
          end
      end
    else if( !in_packet_now )
      begin
        $error("[SCB] @%0t: Data received outside of SOP/EOP window!", $time);
        error_count++;
        return;
      end

    if( pkt_sizes.size() == 0 )
      begin
        $error("[SCB] @%0t: Output received but no completed packet expected!", $time);
        error_count++;
        return;
      end

    curr_pkt_total = pkt_sizes[0];
    remaining      = curr_pkt_total - out_pkt_popped;
    is_last_word   = ( remaining <= OUT_BYTES );

    if( is_last_word )
      begin
        current_beat_valid = remaining;
        exp_empty_val      = OUT_BYTES - remaining;

        if( !tr.endofpacket )
          begin
            $error("[SCB] @%0t beat #%0d: Expected EOP not received!", $time, check_count);
            beat_ok = 0;
          end
        if( tr.empty !== exp_empty_val )
          begin
            $error("[SCB] @%0t beat #%0d: EMPTY mismatch! Got=%0d Exp=%0d",
                  $time, check_count, tr.empty, exp_empty_val);
            beat_ok = 0;
          end
      end
    else
      begin
        current_beat_valid = OUT_BYTES;
        if( tr.endofpacket )
          begin
            $error("[SCB] @%0t beat #%0d: Early EOP! %0d bytes still expected.",
                  $time, check_count, remaining - OUT_BYTES);
            beat_ok = 0;
          end
      end

    for( int i = 0; i < current_beat_valid; i++ )
      begin
        byte actual_byte;
        byte exp_byte;
        int  beat_num     = i / IN_BYTES;
        int  byte_in_beat = i % IN_BYTES;

        actual_byte = tr.data[beat_num*IN_DATA_W + IN_DATA_W-1 - byte_in_beat*8 -: 8];

        if( expected_bytes.size() == 0 )
          begin
            $error("[SCB] @%0t beat #%0d byte %0d: expected queue empty!",
                  $time, check_count, i);
            beat_ok = 0;
            break;
          end

        exp_byte = expected_bytes.pop_front();

        if( actual_byte !== exp_byte )
          begin
            $error("[SCB] @%0t beat #%0d byte %0d: DATA mismatch! Got=%h Exp=%h",
                  $time, check_count, i, actual_byte, exp_byte);
            beat_ok = 0;
          end
      end

    out_pkt_popped += current_beat_valid;
    if( is_last_word )
      begin
        void'( pkt_sizes.pop_front() );
        out_pkt_popped = 0;
        in_packet_now  = 0;
      end

    if( !beat_ok )
      error_count++;

    if( is_last_word )
      $display("[SCB] @%0t beat #%0d: %s  eop empty=%0d (%0d valid bytes)",
               $time, check_count, ( ( beat_ok ) ? ( "PASSED" ) : ( "FAILED" ) ),
               exp_empty_val, current_beat_valid);
    else
      $display("[SCB] @%0t beat #%0d: %s  (%0d bytes)",
               $time, check_count, ( ( beat_ok ) ? ( "PASSED" ) : ( "FAILED" ) ),
               current_beat_valid);
  endtask

  function void final_report();
    $display("\n==============================================");
    $display("\tAST WIDTH EXTENDER TB - FINAL REPORT");
    $display("\tChecks       : %0d", check_count);
    $display("\tErrors       : %0d", error_count);
    $display("\tPending Chan : %0d", expected_channels.size());
    $display("\tPending Data : %0d bytes", expected_bytes.size());
    $display("\tPending Pkts : %0d", pkt_sizes.size());
    if( ( error_count == 0 ) && ( expected_bytes.size() == 0 ) )
      $display("\tOVERALL STATUS : PASSED");
    else
      $display("\tOVERALL STATUS : FAILED");
    $display("==============================================\n");
  endfunction

endclass