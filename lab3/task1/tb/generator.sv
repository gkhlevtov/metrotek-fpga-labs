class Generator #( parameter DWIDTH = 16, AWIDTH = 8 );
  Transaction #( DWIDTH, AWIDTH                  ) blueprint;
  mailbox     #( Transaction #( DWIDTH, AWIDTH ) ) gen2drv;

  function new( mailbox #( Transaction #( DWIDTH, AWIDTH ) ) gen2drv );
    this.gen2drv   = gen2drv;
    this.blueprint = new();
  endfunction

  task run( int num_tr );
    $display("[GEN] @%0t: Starting test sequences...", $time);
    
    // Initial reset
    send_reset();
    
    // Empty test
    test_empty(2);
    send_reset();

    // Underflow test
    test_underflow(5);
    send_reset();
    
    // Overflow test
    test_overflow(5);
    send_reset();

    // Almost empty test
    test_almost_empty(5);
    send_reset();

    // Read-Write test
    test_write(1);
    test_read_write(5);
    test_read(1);
    test_idle(2);
    send_reset();
    
    // Half filling
    test_write(2**(AWIDTH-1));

    // Idle test
    test_idle(10);

    // Random tests
    random_stress(num_tr);
    
  endtask

  task send_reset();
    $display("[GEN] @%0t: Reset issued", $time);
    blueprint.srst = 1;
    blueprint.wr   = 0;
    blueprint.rd   = 0;
    gen2drv.put(blueprint.copy());
    blueprint.srst = 0;
  endtask

  task test_write( int count );
    repeat(count)
      begin
        blueprint.randomize_manual();
        blueprint.srst = 0;
        blueprint.wr   = 1;
        blueprint.rd   = 0;
        gen2drv.put(blueprint.copy());
      end
  endtask

  task test_read( int count );
    repeat(count)
      begin
        blueprint.srst = 0;
        blueprint.wr   = 0;
        blueprint.rd   = 1;
        gen2drv.put(blueprint.copy());
      end
  endtask

  task test_read_write( int count );
    repeat(count)
      begin
        blueprint.randomize_manual();
        blueprint.srst = 0;
        blueprint.wr   = 1;
        blueprint.rd   = 1;
        gen2drv.put(blueprint.copy());
      end
  endtask

  task test_idle( int count );
    repeat(count)
      begin
        blueprint.srst = 0;
        blueprint.wr   = 0;
        blueprint.rd   = 0;
        gen2drv.put(blueprint.copy());
      end
  endtask

  task test_empty( int count );
    $display("[GEN] @%0t: Scenario - Empty Test", $time);
    blueprint.wr   = 0;
    blueprint.rd   = 0;
    gen2drv.put(blueprint.copy());
    repeat(count)
      begin
        test_write(1);
        test_read(1);
      end
  endtask

  task test_almost_empty( int count );
    $display("[GEN] @%0t: Scenario - Almost Empty Test", $time);
    test_write(count);
    test_read(count);
  endtask

  task test_underflow( int count );
    $display("[GEN] @%0t: Scenario - Underflow Test", $time);
    repeat(count)
      test_read(1);
  endtask

  task test_overflow( int extra );
    $display("[GEN] @%0t: Scenario - Overflow Test", $time);
    repeat((2**AWIDTH) + extra)
      test_write(1);
  endtask

  task random_stress( int count );
    $display("[GEN] @%0t: Scenario - Random Stress", $time);
    repeat(count)
      begin
        //blueprint.randomize()
        blueprint.randomize_manual();
        blueprint.srst = 0;
        gen2drv.put(blueprint.copy());
      end
  endtask
endclass