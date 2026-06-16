class Generator #(
  parameter int DATA_W    = 64,
  parameter int EMPTY_W   = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 ),
  parameter int CHANNEL_W = 8,
  parameter int TX_DIR    = 4,
  parameter int DIR_W     = ( TX_DIR == 1      ) ? ( 1 ) : ( $clog2(TX_DIR)   )
);
  AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W                      ) blueprint;
  mailbox         #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) gen2drv;
  Scoreboard      #( DATA_W, EMPTY_W, CHANNEL_W, TX_DIR, DIR_W              ) scb;

  function new(
    mailbox    #( AST_Transaction #( DATA_W, EMPTY_W, CHANNEL_W, DIR_W ) ) gen2drv,
    Scoreboard #( DATA_W, EMPTY_W, CHANNEL_W, TX_DIR, DIR_W              ) scb
  );
    this.gen2drv   = gen2drv;
    this.scb       = scb;
    this.blueprint = new();
  endfunction

  task send_beat(
    bit                 vld,
    bit                 sop,
    bit                 eop,
    bit [EMPTY_W-1:0  ] emp,
    bit [CHANNEL_W-1:0] chan,
    bit [DIR_W-1:0    ] dir = '0,
    bit                 rst = 0
  );
    blueprint.valid         = vld;
    blueprint.startofpacket = sop;
    blueprint.endofpacket   = eop;
    blueprint.empty         = emp;
    blueprint.channel       = chan;
    blueprint.dir           = dir;
    blueprint.srst          = rst;
    
    blueprint.randomize_manual();

    gen2drv.put( blueprint.copy() );

    if( vld && !rst )
      scb.add_expected_data( blueprint.copy() );
  endtask

  task send_idle( int count );
    repeat( count )
      send_beat(0, 0, 0, 0, 0, 0, 0);
  endtask

  task send_reset();
    $display("[GEN] @%0t: Reset issued", $time);
    //scb.reset();
    send_beat(0, 0, 0, 0, 0, 0, 1);
  endtask

  task send_packet(
    int                 len,
    bit [CHANNEL_W-1:0] chan = $urandom(),
    bit [DIR_W-1:0    ] dir  = $urandom()
  );
    for( int i = 0; i < len; i++ )
      begin
        bit               sop;
        bit               eop;
        bit [EMPTY_W-1:0] emp;

        sop = ( i == 0       );
        eop = ( i == len - 1 );
        emp = ( eop ) ? ( $urandom_range(0, DATA_W/8 - 1) ) : ( 0 );
        send_beat(1, sop, eop, emp, chan, dir);
      end
  endtask

  task send_invalid_packet(
    int                 len,
    bit [CHANNEL_W-1:0] chan = $urandom(),
    bit [DIR_W-1:0    ] dir  = $urandom()
  );
    for( int i = 0; i < len; i++ )
      begin
        bit               sop;
        bit               eop;
        bit [EMPTY_W-1:0] emp;

        sop = ( i == 0       );
        eop = ( i == len - 1 );
        emp = ( eop ) ? ( $urandom_range(0, DATA_W/8 - 1) ) : ( 0 );
        send_beat(0, sop, eop, emp, chan, dir);
      end
  endtask

  task test_directions();
    $display("[GEN] @%0t: Scenario - Directions test", $time);
    for( int p = 0; p < TX_DIR; p++ )
      begin
        send_packet( $urandom_range(1, 20), $urandom(), p );
        send_idle(1);
      end
  endtask

  task test_empty();
    $display("[GEN] @%0t: Scenario - Empty test", $time);
    for( int p = 0; p < TX_DIR; p++ )
      begin
        for( int emp = 0; emp < DATA_W/8; emp++ )
          begin
            send_beat(1, 1, 1, emp, 1, p);
          end
        send_idle(1);
      end
  endtask

  task test_max_len_packet();
    $display("[GEN] @%0t: Scenario - Max len packet test", $time);
    send_packet(65536, 1, $urandom_range(TX_DIR - 1));
  endtask
  
  /*
  task test_mid_packet_dir_change();
    $display("[GEN] @%0t: Scenario - Mid-packet dir change test", $time);
    send_beat(1, 1, 0, 0, 1, 0);
    send_beat(1, 0, 0, 0, 1, 0);
    send_beat(1, 0, 0, 0, 1, TX_DIR - 1);
    send_beat(1, 0, 1, 0, 1, TX_DIR - 1);
  endtask
  */

  task test_invalid_sop_dir();
    $display("[GEN] @%0t: Scenario - Invalid SOP with valid=0 and dir", $time);
    for( int p = 0; p < TX_DIR; p++ )
      begin
        send_beat(0, 1, 0, 0, 1, p);
        send_idle(2);
        send_packet(4, 1, p);
        send_idle(2);
      end
    
  endtask

  task test_valid_interruption();
    $display("[GEN] @%0t: Scenario - Valid interruption", $time);
    for( int p = 0; p < TX_DIR; p++ )
      begin
        send_beat(1, 1, 0, 0, 4, p);
        send_idle($urandom_range(1, 3));
        repeat($urandom_range(1, 3))
          send_beat(1, 0, 0, 0, 4, p);
        send_idle($urandom_range(1, 3));
        repeat($urandom_range(1, 3))
          send_beat(1, 0, 0, 0, 4, p);
        send_beat(1, 0, 1, 0, 4, p);
        send_idle(1);
      end
  endtask

  task test_invalid_packets();
    $display("[GEN] @%0t: Scenario - Invalid packets test", $time);
    for( int p = 0; p < TX_DIR; p++ )
      send_invalid_packet($urandom_range(1, 8), $urandom(), p);
  endtask

  task test_random( int num_packets );
    $display("[GEN] @%0t: Scenario - Random test (%0d packets)", $time, num_packets);
    repeat( num_packets )
      begin
        send_packet( $urandom_range(1, 20), $urandom(), $urandom() );
        send_idle( $urandom_range(0, 3) );
      end
  endtask

  task run( int num_packets, bit random_mode = 0 );
    if( random_mode == 0 )
      begin
        $display("[GEN] @%0t: Starting test sequences, random_mode=%0d...", $time, random_mode);
        send_reset();
        send_idle(5);

        test_directions();
        send_reset();

        test_valid_interruption();
        send_reset();
        
        test_invalid_packets();
        send_reset();

        test_invalid_sop_dir();
        send_reset();

        //test_max_len_packet();
        //send_reset();
        
        test_empty();
        send_reset();

        test_random( num_packets );
        send_reset();
        
        $display("[GEN] @%0t: All phase 1 tests sent", $time);
      end
    else
      begin
        $display("[GEN] @%0t: Starting test sequences, random_mode=%0d...", $time, random_mode);
        send_reset();
        send_idle(15);

        test_directions();
        send_reset();

        //test_random( num_packets );
        //send_reset();

        $display("[GEN] @%0t: All phase 2 tests sent", $time);
      end
  endtask
endclass