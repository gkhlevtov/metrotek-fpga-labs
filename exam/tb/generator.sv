class generator #( parameter int DATA_W = 64 );
  localparam int N       = DATA_W / 8;
  localparam int MAX_PKT = 65535;

  mailbox    #( Input_Packet #( DATA_W ) ) base2drv;
  mailbox    #( Input_Packet #( DATA_W ) ) ins2drv;
  mailbox    #( Merge_Pair   #( DATA_W ) ) gen2scb;
  semaphore                                pair_done_sem;
  virtual ctrl_if                          ctrl_vif;

  // Settings
  int unsigned max_len        = 40;
  bit          offset_gt_base = 1'b1;
  bit          verbose        = 1'b1;

  // Counters
  int unsigned pairs_sent  = 0;
  int unsigned outstanding = 0;

  function new(
    mailbox #( Input_Packet #( DATA_W ) ) base2drv,
    mailbox #( Input_Packet #( DATA_W ) ) ins2drv,
    mailbox #( Merge_Pair   #( DATA_W ) ) gen2scb,
    semaphore                             pair_done_sem,
    virtual ctrl_if                       ctrl_vif
  );
    this.base2drv      = base2drv;
    this.ins2drv       = ins2drv;
    this.gen2scb       = gen2scb;
    this.pair_done_sem = pair_done_sem;
    this.ctrl_vif      = ctrl_vif;
  endfunction

  // Wait for the scoreboard
  task drain();
    while( outstanding > 0 )
      begin
        pair_done_sem.get( 1 );
        outstanding--;
      end
  endtask

  // offset setter
  task set_offset( int off );
    ctrl_vif.drv_cb.offset <= 16'( off );
    @( ctrl_vif.drv_cb );
  endtask

  // Make merge pair and put to mailboxes
  task put_pair( int off, int base_len, int ins_len );
    Input_Packet #( DATA_W ) base_pkt = new( "base"   );
    Input_Packet #( DATA_W ) ins_pkt  = new( "insert" );
    Merge_Pair   #( DATA_W ) pair     = new();

    base_pkt.randomize_bytes( base_len );
    ins_pkt.randomize_bytes( ins_len );

    pair.base   = base_pkt.copy();
    pair.insert = ins_pkt.copy();
    pair.offset = off;

    gen2scb.put( pair );
    base2drv.put( base_pkt );
    ins2drv.put( ins_pkt );

    pairs_sent++;
    outstanding++;

    if( verbose )
      $display( "[GEN] @%0t pair #%0d: off=%0d base_len=%0d ins_len=%0d",
                $time, pairs_sent, off, base_len, ins_len );
  endtask

  // Single pair send
  task send_single( int off, int base_len, int ins_len );
    drain();
    set_offset( off );
    put_pair( off, base_len, ins_len );
  endtask

  // Series of pairs send
  task send_series( int off, int count, int min_base, int max_base, int min_ins, int max_ins );
    int base_len, ins_len;

    drain();
    set_offset( off );

    if( min_base < off )
      min_base = off;
    if( max_base < min_base )
      max_base = min_base;

    repeat( count )
      begin
        base_len = rand_len( min_base, max_base );
        ins_len = rand_len( min_ins,  max_ins  );
        put_pair( off, base_len, ins_len );
      end
  endtask

  // Add value to queue if it's unique
  function void add_unique( ref int q[$], input int value );
    if( value < 1 )
      return;

    foreach( q[i] )
      if( q[i] == value )
        return;

    q.push_back( value );
  endfunction

  // Packet lengths around the word boundaries
  function void edge_lengths( ref int q[$] );
    q.delete();
    add_unique( q, 1 );
    add_unique( q, N - 1 );
    add_unique( q, N );
    add_unique( q, N + 1 );
    add_unique( q, 2 * N - 1 );
    add_unique( q, 2 * N );
    add_unique( q, 2 * N + 1 );
    add_unique( q, 3 * N + 1 );
  endfunction

  // offsets for base packet with base_len length
  function void edge_offsets( ref int q[$], input int base_len );
    q.delete();
    add_unique( q, 1 );
    add_unique( q, N - 1 );
    add_unique( q, N );
    add_unique( q, N + 1 );
    add_unique( q, 2 * N );
    add_unique( q, base_len - 1 );
    add_unique( q, base_len );

    for( int i = q.size() - 1; i >= 0; i-- )
      if( q[i] > base_len )
        q.delete( i );

    if( offset_gt_base )
      begin
        add_unique( q, base_len + 1 );
        add_unique( q, base_len + N );
      end
  endfunction

  // Random length from [low, high] + edge lenghts
  function int rand_len( int low, int high );
    int q[$];
    int lens[$];

    if( high < low )
      high = low;

    if( $urandom_range( 0, 99 ) < 50 )
      begin
        edge_lengths( q );
        foreach( q[i] )
          if( ( q[i] >= low ) && ( q[i] <= high ) )
            lens.push_back( q[i] );

        lens.push_back( low );
        lens.push_back( high );
        return lens[ $urandom_range( 0, lens.size() - 1 ) ];
      end

    return $urandom_range( low, high );
  endfunction

  // Random offset from [1, base_len] + edge offsets
  function int rand_off( int base_len );
    int q[$];

    if( $urandom_range( 0, 99 ) < 50 )
      begin
        edge_offsets( q, base_len );
        return q[ $urandom_range( 0, q.size() - 1 ) ];
      end

    return $urandom_range( 1, base_len );
  endfunction

  /*
  Tests
  */

  // Basic test
  task test_basic();
    $display( "\n[GEN] @%0t: Scenario - basic", $time );
    send_single( 2, 19, 10 );
    send_single( 4, 8,  8  );
  endtask

  // Minimal packets test
  task test_min_packets();
    $display( "\n[GEN] @%0t: Scenario - minimal packets (1 byte)", $time );
    send_single( 1, 1,     1     );
    send_single( 1, 1,     N     );
    send_single( 1, N,     1     );
    send_single( 1, 1,     N + 1 );
    send_single( 1, N + 1, 1     );
  endtask

  // base length x insert length x offset full iteration
  task test_boundary();
    int base_lens[$];
    int ins_lens[$];
    int offs[$];

    $display( "[GEN] @%0t: Scenario - boundary lengths/offsets (N=%0d)", $time, N );

    edge_lengths( base_lens );
    edge_lengths( ins_lens );

    foreach( base_lens[i] )
      begin
        edge_offsets( offs, base_lens[i] );
        foreach( ins_lens[j] )
          foreach( offs[k] )
            send_single( offs[k], base_lens[i], ins_lens[j] );
      end
  endtask

  // offset > base_len test
  task test_offset_gt_base();
    $display( "[GEN] @%0t: Scenario - offset > base_len", $time );
    send_single( 100,   8, 8 );
    send_single( N + 1, N, 5 );
    send_single( 1000,  1, 1 );
  endtask

  // Back‑to‑back series test
  task test_back_to_back( int unsigned series_per_offset = 3 );
    int offs[$];

    $display( "[GEN] @%0t: Scenario - back-to-back series", $time );

    add_unique( offs, 1     );
    add_unique( offs, N - 1 );
    add_unique( offs, N     );
    add_unique( offs, N + 1 );
    add_unique( offs, 2 * N );

    foreach( offs[i] )
      repeat( series_per_offset )
        send_series( offs[i], 8, offs[i], offs[i] + 3 * N, 1, 3 * N );
  endtask

  // Max length packets test
  task test_max_len();
    $display( "[GEN] @%0t: Scenario - max length (%0d bytes per input)", $time, MAX_PKT );
    send_single( 1,           MAX_PKT, MAX_PKT );
    send_single( MAX_PKT,     MAX_PKT, MAX_PKT );
    send_single( 32768,       MAX_PKT, MAX_PKT );
    send_single( 1,           MAX_PKT, 1       );
    send_single( MAX_PKT,     MAX_PKT, 1       );
    send_single( 1,           1,       MAX_PKT );
    send_single( N + 1,       3 * N,   MAX_PKT );
    send_single( MAX_PKT - 1, MAX_PKT, MAX_PKT );
  endtask

  // Random test
  task test_random( int unsigned num );
    int done_cnt = 0;
    int base_len;
    int ins_len;
    int off;
    int cnt;

    $display( "[GEN] @%0t: Scenario - random (%0d pairs, max_len=%0d)", $time, num, max_len );

    while( done_cnt < num )
      begin
        if( $urandom_range( 0, 99 ) < 70 )
          begin
            base_len = rand_len( 1, max_len );
            ins_len  = rand_len( 1, max_len );
            off      = rand_off( base_len   );
            send_single( off, base_len, ins_len );
            done_cnt++;
          end
        else
          begin
            cnt      = $urandom_range( 2, 6 );
            base_len = rand_len( 1, max_len );
            off      = rand_off( base_len   );
            send_series( off, cnt, base_len, max_len + off, 1, max_len );
            done_cnt += cnt;
          end
      end
  endtask

  // test runner
  task run( string test = "all", int unsigned num_random = 100 );
    case( test )
      "basic":
        begin
          test_basic();
        end
      "min":
        begin
          test_min_packets();
        end
      "boundary":
        begin
          test_boundary();
        end
      "offset_gt":
        begin
          test_offset_gt_base();
        end
      "b2b":
        begin
          test_back_to_back();
        end
      "maxlen":
        begin
          test_max_len();
        end
      "random":
        begin
          test_random( num_random );
        end
      "all":
        begin
          test_basic();
          test_min_packets();
          test_boundary();
          if( offset_gt_base )
            test_offset_gt_base();
          test_back_to_back();
          test_random( num_random );
        end
      default:
        begin
          $display( "[GEN] unknown test '%s' ", test );
        end
    endcase

    drain();
    $display( "[GEN] @%0t: test '%s' finished, %0d pairs sent", $time, test, pairs_sent );
  endtask
endclass