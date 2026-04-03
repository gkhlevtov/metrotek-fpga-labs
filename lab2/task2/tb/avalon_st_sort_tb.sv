module avalon_st_sort_tb;
  // DUT parameters
  parameter int DWIDTH            = 8;
  parameter int MAX_PKT_LEN       = 16;

  // Number of random tests 
  parameter int N                 = 100;

  // Pause probability
  // (1 - 50%, 2 - 33%, 3 - 25%, 4 - 20%, ...)
  parameter int PAUSE_P           = 4;

  // DUT ports
  bit                clk;
  bit                srst;
  
  logic [DWIDTH-1:0] snk_data_i;
  logic              snk_startofpacket_i;
  logic              snk_endofpacket_i;
  logic              snk_valid_i;
  logic              src_ready_i;

  logic              snk_ready_o;
  logic [DWIDTH-1:0] src_data_o;
  logic              src_startofpacket_o;
  logic              src_endofpacket_o;
  logic              src_valid_o;

  // Word and packet types
  typedef logic  [DWIDTH-1:0] word_t;
  typedef word_t              pkt_t[$];

  // Mailbox for generated data
  mailbox #( pkt_t ) gen_mbx = new();

  // Mailbox for expected data
  mailbox #( pkt_t ) exp_mbx = new();

  // Total amount of tests
  int total_n;

  // Simulation success flag
  bit pass_flag;

  // Reset event
  event rst_done;
  
  initial
    forever
      #5 clk = !clk;

  initial
    begin
      clk                 = 1'b0;
      srst                = 1'b0;
      snk_startofpacket_i = 1'b0;
      snk_endofpacket_i   = 1'b0;
      src_ready_i         = 1'b1;
      pass_flag           = 1'b1;

      @( posedge clk );
      srst                = 1'b1;

      @( posedge clk );
      srst                = 1'b0;
      -> rst_done;
    end

  avalon_st_sort #(
    .DWIDTH              ( DWIDTH              ),
    .MAX_PKT_LEN         ( MAX_PKT_LEN         )
  ) avalon_st_sort_inst (
    .clk_i               ( clk                 ),
    .srst_i              ( srst                ),
    .snk_data_i          ( snk_data_i          ),
    .snk_startofpacket_i ( snk_startofpacket_i ),
    .snk_endofpacket_i   ( snk_endofpacket_i   ),
    .snk_valid_i         ( snk_valid_i         ),
    .src_ready_i         ( src_ready_i         ),
    .snk_ready_o         ( snk_ready_o         ),
    .src_data_o          ( src_data_o          ),
    .src_startofpacket_o ( src_startofpacket_o ),
    .src_endofpacket_o   ( src_endofpacket_o   ),
    .src_valid_o         ( src_valid_o         )
  );

  function automatic pkt_t sort_pkt( pkt_t pkt );
    pkt_t s = pkt;
    s.sort();
    return s;
  endfunction

  task automatic generate_tests( int random_n, mailbox #( pkt_t ) gen_mbx, output int total_n );
    begin
      pkt_t pkt;
      
      // One word packet test
      pkt.delete();
      pkt.push_back( word_t'( $urandom ) );
      gen_mbx.put(pkt);
      total_n += 1;

      // Max len packet test
      pkt.delete();
      for( int i = 0; i < MAX_PKT_LEN; i++ ) 
        pkt.push_back( word_t'( $urandom ) );
      gen_mbx.put(pkt);
      total_n += 1;

      // Best case max len packet
      pkt.delete();
      for( int i = 0; i < MAX_PKT_LEN; i++ ) 
        pkt.push_back( word_t'( $urandom ) );
      pkt.sort();
      gen_mbx.put(pkt);
      total_n += 1;

      // Worst case max len packet
      pkt.delete();
      for( int i = 0; i < MAX_PKT_LEN; i++ ) 
        pkt.push_back( word_t'( $urandom ) );
      pkt.rsort();
      gen_mbx.put(pkt);
      total_n += 1;

      // Random tests
      for( int i = 0; i < random_n; i++ )
        begin
          int pkt_len = $urandom_range(1, MAX_PKT_LEN);
          pkt.delete();

          for( int j = 0; j < pkt_len; j++ )
            pkt.push_back( word_t'( $urandom ) );
          
          gen_mbx.put(pkt);
          total_n += 1;
        end
    end
  endtask

  task automatic send_pkt( pkt_t pkt );
    begin
      int pkt_size = pkt.size();

      for( int i = 0; i < pkt_size; i++ )
        begin
          if( $urandom_range(0, PAUSE_P) == 0 )
            begin
              snk_valid_i         = 1'b0;
              snk_data_i          = 'x;
              snk_startofpacket_i = 1'b0;
              snk_endofpacket_i   = 1'b0;
              repeat( $urandom_range(1, 3) )
                @( posedge clk );
            end
          
          while( !snk_ready_o )
            begin
              snk_valid_i = 1'b0;
              @( posedge clk );
            end
          
          snk_data_i          = pkt.pop_front;
          snk_valid_i         = 1'b1;
          snk_startofpacket_i = ( i == 0            );
          snk_endofpacket_i   = ( i == pkt_size - 1 );

          @( posedge clk );
        end
      
      snk_valid_i         = 1'b0;
      snk_data_i          = 'x;
      snk_startofpacket_i = 1'b0;
      snk_endofpacket_i   = 1'b0;
      @( posedge clk );
    end
  endtask

  task automatic receive_pkt( output pkt_t recv_pkt );
    begin
      recv_pkt.delete();

      while( !( src_valid_o && src_ready_i && src_startofpacket_o ) )
        @( posedge clk );

      forever
        begin
          if( src_valid_o && src_ready_i )
            begin
              recv_pkt.push_back( src_data_o );

              if( src_endofpacket_o )
                break;
            end
          
          @( posedge clk );
        end

      @( posedge clk );
    end
  endtask

  task automatic check_pkt( pkt_t recv_pkt, pkt_t exp_pkt, int pkt_num );
    begin
      if( recv_pkt.size() !== exp_pkt.size() )
        begin
          $error( "Error at %0t:\nPacket #%0d length mismatch\ngot: %0d\nexp: %0d",
                  $time, pkt_num, recv_pkt.size(), exp_pkt.size() );
          pass_flag = 1'b0;
        end

      for( int i = 0; i < exp_pkt.size(); i++ )
        begin
          if( recv_pkt[i] !== exp_pkt[i] )
            begin
              $error( "Error at %0t:\nPacket #%0d beat[%0d]\ngot: %b\nexp: %b",
                      $time, pkt_num, i, recv_pkt[i], exp_pkt[i] );
              pass_flag = 1'b0;
            end
        end
    end
  endtask

  task automatic send_inputs( mailbox #( pkt_t ) gen_mbx, mailbox #( pkt_t ) exp_mbx, int total_n );
    begin
      for( int test = 0; test < total_n; test++ )
        begin
          pkt_t pkt;
          gen_mbx.get(pkt);
          exp_mbx.put(sort_pkt(pkt));
          send_pkt(pkt);
        end
    end
  endtask

  task automatic verify_outputs( mailbox #( pkt_t ) exp_mbx, int total_n );
    for( int test = 0; test < total_n; test++ )
      begin
        pkt_t exp_pkt;
        pkt_t recv_pkt;

        exp_mbx.get(exp_pkt);
        receive_pkt(recv_pkt);
        check_pkt(recv_pkt, exp_pkt, test);
      end
  endtask

  initial
    begin
      wait(rst_done.triggered);
      @( posedge clk );
      $display( "Simulation start" );

      total_n = 0;
      generate_tests(N, gen_mbx, total_n);

      fork
        send_inputs(gen_mbx, exp_mbx, total_n);
        verify_outputs(exp_mbx, total_n);
      join
      
      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      $finish;
    end
endmodule
