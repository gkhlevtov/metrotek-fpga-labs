module serializer_tb;
  // DUT inputs and output
  bit clk;
  bit srst;

  logic [15:0] data_i;
  logic [3:0]  data_mod_i;
  logic        data_val_i;

  logic        ser_data_o;
  logic        ser_data_val_o;
  logic        busy_o;

  // Simulation success flag
  logic        pass_flag;

  // DUT input packet
  typedef struct packed
  {
    logic [15:0] data;
    logic [3:0]  data_mod;
    logic        data_valid;
  } input_packet_t;

  input_packet_t pkt;

  // Expected outputs
  logic [15:0] exp_o;
  int          exp_o_len;

  // Recieved outputs
  logic [15:0] rx_data;
  int          rx_len;
  
  initial
    forever
      #5 clk <= !clk;
  
  initial
    begin
      clk            <= '0;
      srst           <= '0;
      data_i         <= '0;
      data_mod_i     <= '0;
      data_val_i     <= '0;
      pass_flag      <= '1;
      pkt            <= '0;

      @( posedge clk );
      srst           <= '1;

      @( posedge clk );
      srst           <= '0;
    end

  serializer_top dut(
    .clk_150m       ( clk            ),
    .srst_i         ( srst           ),
    .data_i         ( data_i         ),
    .data_mod_i     ( data_mod_i     ),
    .data_val_i     ( data_val_i     ),
    .ser_data_o     ( ser_data_o     ),
    .ser_data_val_o ( ser_data_val_o ),
    .busy_o         ( busy_o         )
  );

  task automatic reset();
    begin
        data_i     <= '0;
        data_mod_i <= '0;
        data_val_i <= '0;
        exp_o      <= '0;
        exp_o_len  <= '0;
        srst       <= '0;

        @( posedge clk );
        srst       <= '1;

        @( posedge clk );
        srst       <= '0;
    end
  endtask

  task automatic send_packet( input_packet_t pkt );
    begin
      data_i     <= pkt.data;
      data_mod_i <= pkt.data_mod;

      data_val_i <= pkt.data_valid;
      @( posedge clk );

      data_val_i <= 1'b0;
    end
  endtask

  task automatic receive_bits(
    output logic [15:0] data_out,
    output int          bit_count
  );
    int wait_cycles = 0;
    bit_count = '0;
    data_out  = '0;

    @( posedge clk );

    while( !busy_o )
      begin
        @(posedge clk);
        wait_cycles = wait_cycles + 1;
        if ( wait_cycles > 3 )
          return;
      end

    while( busy_o )
      begin
        @( posedge clk );

        if( ser_data_val_o )
          begin
            data_out[15 - bit_count] = ser_data_o;
            bit_count = bit_count + 1;
          end
      end
  endtask

  task run_one_check();
    reset();
    @( posedge clk );

    if( pkt.data_valid )
      begin
        if( pkt.data_mod == 0 )
          exp_o_len = 16;
        else if (pkt.data_mod <= 2)
          exp_o_len = 0;
        else
          exp_o_len = pkt.data_mod;

        for( int i = 0; i < exp_o_len; i = i + 1 )
          exp_o[15 - i] = pkt.data[15 - i];
      end

    fork
      send_packet(pkt);
      receive_bits(rx_data, rx_len);
    join
    
    if ( rx_len != exp_o_len )
      begin
        $error( "Length mismatch at %0t: exp=%h\ngot=%h", $time, exp_o_len, rx_len );
        pass_flag = 0'b0;
      end
    else if ( rx_data != exp_o )
      begin
        $error( "Data mismatch at %0t: exp=%h\ngot=%h\n", $time, exp_o, rx_data );
        pass_flag = 0'b0;
      end
  endtask

  initial
    begin
      $display( "Simulation start" );
      #20;

      // Full valid packet test
      pkt = {16'hAAAA, 4'd0, 1'b1};
      run_one_check();

      // mod = 1, mod = 2 ignore test
      pkt = {16'hFEDC, 4'd1, 1'b1};
      run_one_check();
      pkt = {16'h1357, 4'd2, 1'b1};
      run_one_check();

      // Invalid input data test
      pkt = {16'hAAAA, 4'd1, 1'b0};
      run_one_check();

      // Boundary input values test
      pkt = {16'hFFFF, 4'd0, 1'b1};
      run_one_check();
      pkt = {16'h0, 4'd0, 1'b1};
      run_one_check();

      // Random tests
      repeat (50)
        begin
          pkt.data       = $urandom();
          pkt.data_mod   = $urandom_range(0, 15);
          pkt.data_valid = $urandom_range(0, 1);
          run_one_check();
        end

      #20;

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
    
    $display( "Simulation end" );
    $stop();
    end
endmodule