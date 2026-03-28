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

  task automatic generate_tests( int random_n, mailbox #( pkt_t ) gen_mbx );
    begin
      pkt_t pkt;
      
      // One word packet test
      pkt.delete();
      pkt.push_back( word_t'( $urandom ) );
      gen_mbx.put(pkt);

      // Max len packet test
      pkt.delete();
      for( int i = 0; i < MAX_PKT_LEN; i++ ) 
        pkt.push_back( word_t'( $urandom ) );
      gen_mbx.put(pkt);

      // Best case max len packet
      pkt.delete();
      for( int i = 0; i < MAX_PKT_LEN; i++ ) 
        pkt.push_back( word_t'( $urandom ) );
      pkt.sort();
      gen_mbx.put(pkt);

      // Worst case max len packet
      pkt.delete();
      for( int i = 0; i < MAX_PKT_LEN; i++ ) 
        pkt.push_back( word_t'( $urandom ) );
      pkt.rsort();
      gen_mbx.put(pkt);

      // Random tests
      for( int i = 0; i < random_n; i++ )
        begin
          int pkt_len = $urandom_range(1, MAX_PKT_LEN);
          pkt.delete();

          for( int j = 0; j < pkt_len; j++ )
            pkt.push_back( word_t'( $urandom ) );
          
          gen_mbx.put(pkt);
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

  task automatic recv_and_check_pkt( pkt_t exp_pkt, int pkt_num );
    begin
      int beat_idx = 0;
      bit eop_found = 0;

      while( !( src_valid_o && src_ready_i && src_startofpacket_o ) )
        @( posedge clk );

      while( !eop_found )
        begin
          if( src_valid_o && src_ready_i )
            begin
              if( beat_idx == 0 && !src_startofpacket_o )
                begin
                  $error("Error at %0t:\nSOP expected at beat 0 of packet #%0d", $time, pkt_num );
                  pass_flag = 1'b0;
                end

              if( beat_idx < exp_pkt.size() )
                begin
                  if( src_data_o !== exp_pkt[beat_idx] )
                    begin
                      $error("Error at %0t:\nPacket #%0d beat[%0d]\ngot: %b\nexp: %b\n",
                            $time, pkt_num, beat_idx, src_data_o, exp_pkt[beat_idx]);
                      pass_flag = 1'b0;
                    end
                end
              else
                begin
                  $error("Error at %0t:\nPacket #%0d\n- Extra word after position %0d\n",
                        $time, pkt_num, exp_pkt.size());
                  pass_flag = 1'b0;
                end
              
              if( src_endofpacket_o )
                begin
                  eop_found = 1'b1;
                  if( beat_idx !== exp_pkt.size() - 1 )
                    begin
                      $error("Error at %0t:\nPacket #%0d\n- EOP at wrong position %0d\nexpected: %0d\n",
                            $time, pkt_num, beat_idx, exp_pkt.size() - 1 );
                      pass_flag = 1'b0;
                    end
                  break;
                end
              
              beat_idx++;
            end
            
            if( !eop_found )
              @( posedge clk );
        end

        @( posedge clk );
    end
  endtask

  task automatic send_inputs( mailbox #( pkt_t ) gen_mbx, mailbox #( pkt_t ) exp_mbx );
    begin
      for( int test = 0; test < N; test++ )
        begin
          pkt_t pkt;
          gen_mbx.get(pkt);
          exp_mbx.put(sort_pkt(pkt));
          send_pkt(pkt);
        end
    end
  endtask

  task automatic verify_outputs( mailbox #( pkt_t ) exp_mbx );
    begin
      for( int test = 0; test < N; test++ )
        begin
          pkt_t expected;
          exp_mbx.get(expected);
          recv_and_check_pkt(expected, test);
        end
    end
  endtask

  initial
    begin
      wait(rst_done.triggered);
      @( posedge clk );
      $display( "Simulation start" );

      generate_tests(N, gen_mbx);

      fork
        send_inputs(gen_mbx, exp_mbx);
        verify_outputs(exp_mbx);
      join
      
      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      $finish;
    end
endmodule
