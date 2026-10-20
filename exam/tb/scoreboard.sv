class scoreboard #( parameter int DATA_W = 64 );
  mailbox #( Merge_Pair    #( DATA_W ) ) gen2scb;
  mailbox #( Output_Packet             ) mon2scb;
  semaphore                              pair_done_sem;

  int unsigned check_count = 0;
  int unsigned error_count = 0;

  // Print PASS for each pair
  bit          print_pass  = 1'b1;

  function new(
    mailbox #( Merge_Pair    #( DATA_W ) ) gen2scb,
    mailbox #( Output_Packet             ) mon2scb,
    semaphore                              pair_done_sem
  );
    this.gen2scb       = gen2scb;
    this.mon2scb       = mon2scb;
    this.pair_done_sem = pair_done_sem;
  endfunction

  // Index of the first non‑matching byte
  function int find_mismatch( Output_Packet exp, Output_Packet act );
    int n = ( exp.bytes.size() < act.bytes.size() ) ? ( exp.bytes.size() ) : ( act.bytes.size() );

    for( int i = 0; i < n; i++ )
      if( exp.bytes[i] !== act.bytes[i] )
        return i;

    return -1;
  endfunction

  // Bytes around the idx 
  function string bytes_window( Output_Packet p, int idx );
    string s  = "";
    int    lo = ( idx > 4                      ) ? ( idx - 4 ) : ( 0                  );
    int    hi = ( ( idx + 4 ) < p.bytes.size() ) ? ( idx + 4 ) : ( p.bytes.size() - 1 );

    for( int i = lo; i <= hi; i++ )
      begin
        if( i == idx )
          s = { s, $sformatf( "[%02h] ", p.bytes[i] ) };
        else
          s = { s, $sformatf( "%02h ", p.bytes[i] ) };
      end

    return s;
  endfunction

  task run();
    Merge_Pair #( DATA_W ) pair;
    Output_Packet          expected;
    Output_Packet          actual;
    int                    idx;

    forever
      begin
        gen2scb.get( pair );
        expected = Golden_Model #( DATA_W )::predict( pair );
        mon2scb.get( actual );

        check_count++;
        idx = find_mismatch( expected, actual );

        if( ( expected.length != actual.length ) || ( idx >= 0 ) )
          begin
            error_count++;
            $error( "[SCB] @%0t pair #%0d FAILED: exp_len=%0d act_len=%0d first_diff_idx=%0d",
                    $time, check_count, expected.length, actual.length, idx );
            $display( "\tpair: %s", pair.convert2string() );
            $display( "\texp:  %s", expected.convert2string() );
            $display( "\tact:  %s", actual.convert2string() );

            if( idx >= 0 )
              begin
                $display( "\texp around idx: %s", bytes_window( expected, idx ) );
                $display( "\tact around idx: %s", bytes_window( actual,   idx ) );
              end
          end
        else if( print_pass )
          $display( "[SCB] @%0t pair #%0d: PASS (len=%0d)", $time, check_count, actual.length );

        pair_done_sem.put( 1 );
      end
  endtask

  function bit final_report(
    int unsigned pairs_sent,
    int unsigned protocol_errors,
    bit          timed_out,
    bit          incomplete_pkt
  );
    int unsigned extra_pkts  = mon2scb.num();
    int unsigned unprocessed = gen2scb.num();

    bit          pass       = 1'b1;

    $display( "\n==============================================" );
    $display( "\tPKT_MERGE TB - FINAL REPORT" );
    $display( "\tPairs sent         : %0d", pairs_sent      );
    $display( "\tPairs checked      : %0d", check_count     );
    $display( "\tData mismatches    : %0d", error_count     );
    $display( "\tProtocol errors    : %0d", protocol_errors );
    $display( "\tUnexpected packets : %0d", extra_pkts      );

    if( error_count != 0 )
      pass = 1'b0;

    if( protocol_errors != 0 )
      pass = 1'b0;

    if( check_count != pairs_sent )
      begin
        $display( "\t[!] checked %0d of %0d pairs", check_count, pairs_sent );
        pass = 1'b0;
      end

    if( extra_pkts != 0 )
      begin
        $display( "\t[!] DUT produced %0d packets that nobody expected", extra_pkts );
        pass = 1'b0;
      end

    if( unprocessed != 0 )
      begin
        $display( "\t[!] %0d pairs left unprocessed", unprocessed );
        pass = 1'b0;
      end

    if( timed_out )
      begin
        $display( "\t[!] simulation stopped by watchdog timeout" );
        pass = 1'b0;
      end

    if( incomplete_pkt )
      begin
        $display( "\t[!] output packet was not finished (no eop)" );
        pass = 1'b0;
      end

    if( pairs_sent == 0 )
      begin
        $display( "\t[!] no pairs were sent, nothing was checked" );
        pass = 1'b0;
      end

    $display( "\tOVERALL STATUS     : %s", ( pass ) ? ( "PASSED" ) : ( "FAILED" ) );
    $display( "==============================================\n" );

    return pass;
  endfunction
endclass