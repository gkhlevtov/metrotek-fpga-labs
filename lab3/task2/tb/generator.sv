class Generator #(
  parameter int IN_DATA_W  = 64,
  parameter int IN_EMPTY_W = $clog2(IN_DATA_W/8) ? $clog2(IN_DATA_W/8) : 1,
  parameter int OUT_DATA_W = 256,
  parameter int CHANNEL_W  = 10
);
  localparam int N         = OUT_DATA_W / IN_DATA_W;
  
  AST_Transaction #( IN_DATA_W, IN_EMPTY_W, CHANNEL_W ) blueprint;
  mailbox #( AST_Transaction #( IN_DATA_W, IN_EMPTY_W, CHANNEL_W ) ) gen2drv;
  Scoreboard #( IN_DATA_W, OUT_DATA_W, CHANNEL_W ) scb;

  function new(
    mailbox #( AST_Transaction #( IN_DATA_W, IN_EMPTY_W, CHANNEL_W ) ) gen2drv,
    Scoreboard #( IN_DATA_W, OUT_DATA_W, CHANNEL_W ) scb
  );
    this.gen2drv   = gen2drv;
    this.scb       = scb;
    this.blueprint = new();
  endfunction

  task send_beat(
    bit                  vld,
    bit                  sop,
    bit                  eop,
    bit [IN_EMPTY_W-1:0] emp,
    bit [CHANNEL_W-1:0]  chan,
    bit                  rst = 0
  );
    blueprint.valid         = vld;
    blueprint.startofpacket = sop;
    blueprint.endofpacket   = eop;
    blueprint.empty         = emp;
    blueprint.channel       = chan;
    blueprint.srst          = rst;
    
    blueprint.randomize_manual();

    gen2drv.put(blueprint.copy());

    if( vld && !rst )
      scb.add_expected_data(blueprint.copy());
  endtask

  task send_idle( int count );
    repeat( count )
      send_beat(0, 0, 0, 0, 0);
  endtask

  task send_reset();
    $display("[GEN] @%0t: Reset issued", $time);
    scb.flush_partial_packet();
    send_beat(0, 0, 0, 0, 0, 1);
  endtask

  task send_packet( int len, bit [CHANNEL_W-1:0] chan = $urandom() );
    for( int i = 0; i < len; i++ )
      begin
        bit                  sop;
        bit                  eop;
        bit [IN_EMPTY_W-1:0] emp;
        
        sop = ( i == 0 );
        eop = ( i == len - 1 );
        emp = ( eop ) ? ( $urandom_range(0, IN_DATA_W/8 - 1) ) : ( 0 );
        send_beat(1, sop, eop, emp, chan);
      end
  endtask

  task test_empty();
    $display("[GEN] @%0t: Scenario - Empty test", $time);

    for( int e = 0; e < IN_DATA_W / 8; e++ )
      begin
          send_beat(1, 1, 0, 0, 1);
          for( int i = 0; i < N - 2; i++ )
              send_beat(1, 0, 0, 0, 1);
          send_beat(1, 0, 1, e, 1);
          send_idle(1);
      end
  endtask

  task test_channel();
    $display("[GEN] @%0t: Scenario - Channel test", $time);
    for( int ch = 0; ch < 4; ch++ )
      begin
          send_beat(1, 1, 0, 0, ch);
          for( int i = 0; i < N-2; i++ )
              send_beat(1, 0, 0, 0, ch);
          send_beat(1, 0, 1, $urandom_range(1, IN_DATA_W / 8), ch);
          send_idle(1);
      end
  endtask

  task test_reset();
    $display("[GEN] @%0t: Scenario - Reset test", $time);

    send_beat(1, 1, 0, 0, 1);
    for( int i = 0; i < N-2; i++ )
        send_beat(1, 0, 0, 0, 1);
    send_beat(1, 0, 1, $urandom_range(1, IN_DATA_W / 8), 1);

    send_reset();

    send_beat(1, 1, 0, 0, 1);
    for( int i = 0; i < N-2; i++ )
        send_beat(1, 0, 0, 0, 1);
    send_beat(1, 0, 1, $urandom_range(1, IN_DATA_W / 8), 1);

    send_idle(1);
  endtask

  task test_short_packets();
    $display("[GEN] @%0t: Scenario - Short packets test", $time);
    for( int len = 1; len < N; len++ )
      begin
          send_packet(len);
          send_idle(1);
      end
  endtask

  task test_ready( int num_packets = 1 );
    $display("[GEN] @%0t: Scenario - Ready/Backpressure test (%0d packets)", $time, num_packets);
    repeat( num_packets )
      begin
          send_packet(N * $urandom_range(2, 4));
          send_idle(1);
      end
  endtask

  task test_gapped_packet();
    bit [CHANNEL_W-1:0] chan = $urandom();
    $display("[GEN] @%0t: Scenario - Gapped packet test", $time);
    for( int i = 1; i <= N; i++ )
      begin
        if( ( i > 1 ) && ( $urandom_range(8) > 0 ) )
          send_idle($urandom_range(1, 3));
        send_beat(1, ( i == 1 ), ( i == N ), ( (i == N ) ? ( $urandom_range(0, IN_DATA_W/8 - 1) ) : ( 0 ) ), chan);
      end
    send_idle(1);
  endtask

  task test_mid_packet_reset();
    $display("[GEN] @%0t: Scenario - Mid-packet reset test", $time);

    send_beat(1, 1, 0, 0, 1);
    send_beat(1, 0, 0, 0, 1);

    send_reset();
    send_idle(1);

    send_beat(1, 1, 0, 0, 1);
    for( int i = 0; i < N-2; i++ )
      send_beat(1, 0, 0, 0, 1);
    send_beat(1, 0, 1, 1, 1);
  endtask

  task run_random( int count );
    $display("[GEN] @%0t: Scenario - Random tests", $time);
    while( count != 0 )
      begin
        int action = $urandom_range(0, 10);
        if( action < 8 )
          begin
            send_packet($urandom_range(1, N*4));
            count -= 1;
          end
        else
          send_idle($urandom_range(1, 4));
      end
  endtask

  task run( int num_packets );
    $display("[GEN] @%0t: Starting test sequences...", $time);
    
    // Initial reset
    send_reset();

    // Border tests
    test_empty();
    send_reset();

    test_channel();
    send_reset();
    
    test_reset();
    send_reset();
    
    test_mid_packet_reset();
    send_reset();

    test_short_packets();
    send_reset();

    test_ready();
    send_reset();

    test_gapped_packet();
    send_reset();

    // Random tests
    run_random(num_packets);
  
    $display("[GEN] @%0t: All tests sent", $time);
  endtask

endclass