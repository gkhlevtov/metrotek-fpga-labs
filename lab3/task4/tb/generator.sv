class generator #(
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = 8
);
  ctrl_item #( ADDR_WIDTH                ) blueprint;
  mailbox   #( ctrl_item #( ADDR_WIDTH ) ) gen2drv;

  function new( mailbox #( ctrl_item #( ADDR_WIDTH ) ) gen2drv );
    this.gen2drv   = gen2drv;
    this.blueprint = new();
  endfunction

  task send_job( bit [ADDR_WIDTH-1:0] base_addr, bit [ADDR_WIDTH-1:0] length );
    blueprint.base_addr = base_addr;
    blueprint.length    = length;

    gen2drv.put( blueprint.copy() );

    $display( "[GEN] @%0t sent job: base_addr=%h length=%0d",
                $time, blueprint.base_addr, blueprint.length );
  endtask

  // single byte test
  task test_length_one();
    bit [ADDR_WIDTH-1:0] base_addr;
    $display("[GEN] @%0t: Scenario - Single byte test", $time);

    base_addr = $urandom_range( 0, ( ( 1 << ADDR_WIDTH ) - 1 ) );

    send_job( base_addr, 10'h001 );
  endtask

  // partial word test
  task test_partial_word();
    $display("[GEN] @%0t: Scenario - Partial word test", $time);
    send_job( 10'h00f, 10'h00a );
  endtask

  // full word test
  task test_full_word();
    bit [ADDR_WIDTH-1:0] base_addr;
    $display("[GEN] @%0t: Scenario - Full word test", $time);

    base_addr = $urandom_range( 0, ( ( 1 << ADDR_WIDTH ) - 1 ) );

    send_job( base_addr, ADDR_WIDTH'( BYTE_CNT ) );
  endtask

  // maximum address overflow test
  task test_addr_overflow();
    bit [ADDR_WIDTH-1:0] base_addr;
    $display("[GEN] @%0t: Scenario - Maximum address overflow test", $time);

    base_addr = ( ( 1 << ADDR_WIDTH ) - 1 ) - 2;

    send_job( base_addr, 10'h100 );
  endtask

  // maximum possible length job test
  task test_max_length();
    $display("[GEN] @%0t: Scenario - Maximum possible length job test", $time);
    send_job( '0, ( ( 1 << ADDR_WIDTH ) - 1 ) );
  endtask

  // wraparound test
  task test_wraparound();
    $display("[GEN] @%0t: Scenario - Wraparound test", $time);
    send_job( 10'h000, 10'h001 );
  endtask

  task test_random( int unsigned num_jobs );
    $display("[GEN] @%0t: Scenario - Random test (%0d jobs)", $time, num_jobs);
    repeat( num_jobs )
      begin
        blueprint.randomize_manual();

        gen2drv.put( blueprint.copy() );

        $display( "[GEN] @%0t sent random job: base_addr=%h length=%0d",
                    $time, blueprint.base_addr, blueprint.length );
      end
  endtask

endclass