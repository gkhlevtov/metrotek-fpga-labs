module avalon_st_sort #(
  parameter DWIDTH      = 8,
  parameter MAX_PKT_LEN = 16
)(
  input  logic              clk_i,
  input  logic              srst_i,

  input  logic [DWIDTH-1:0] snk_data_i,
  input  logic              snk_startofpacket_i,
  input  logic              snk_endofpacket_i,
  input  logic              snk_valid_i,
  input  logic              src_ready_i,

  output logic              snk_ready_o,
  output logic [DWIDTH-1:0] src_data_o,
  output logic              src_startofpacket_o,
  output logic              src_endofpacket_o,
  output logic              src_valid_o
);

  localparam int ADDR_W = $clog2(MAX_PKT_LEN);

  logic              src_valid_pipe;
  logic              src_sop_pipe;
  logic              src_eop_pipe;

  logic [ADDR_W:0]   pkt_cnt;
  logic [ADDR_W:0]   pkt_size;

  logic [ADDR_W:0]   i_cnt;
  logic [ADDR_W:0]   j_cnt;
  logic [DWIDTH-1:0] val_a;
  logic [DWIDTH-1:0] val_b;
  logic              swapped;
  logic              sort_done;

  logic              mem_we;
  logic [ADDR_W-1:0] mem_waddr;
  logic [ADDR_W-1:0] mem_raddr;
  logic [DWIDTH-1:0] mem_wdata;
  logic [DWIDTH-1:0] mem_q;

  simple_dual_port_ram #(
    .ADDR_WIDTH ( ADDR_W    ),
    .DATA_WIDTH ( DWIDTH    )
  ) ram_i (
    .clk        ( clk_i     ),
    .we         ( mem_we    ),
    .waddr      ( mem_waddr ),
    .raddr      ( mem_raddr ),
    .wdata      ( mem_wdata ),
    .q          ( mem_q     )
  );

  enum logic [1:0] { IDLE_S,
                     SINK_S,
                     SORT_S,
                     SOURCE_S } state, next_state;

  enum logic [2:0] { SORT_IDLE_S,
                     SORT_INIT_S,
                     SORT_RD_A_S,
                     SORT_RD_B_S,
                     SORT_CMP_S,
                     SORT_SWAP_W1_S,
                     SORT_SWAP_W2_S,
                     SORT_NEXT_S } sort_state, next_sort_state;
  
  // Main FSM states
  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        state <= IDLE_S;
      else
        state <= next_state;
    end
  
  always_comb
    begin
      next_state = state;

      case( state )
        IDLE_S:
          begin
            if( snk_valid_i && snk_startofpacket_i && snk_ready_o )
              begin
                if( snk_endofpacket_i )
                  next_state = SORT_S;
                else
                  next_state = SINK_S;
              end
          end

        SINK_S:
          begin
            if( snk_valid_i && snk_endofpacket_i && snk_ready_o )
              next_state = SORT_S;
          end

        SORT_S:
          begin
            if( sort_done )
              next_state = SOURCE_S;
          end

        SOURCE_S:
          begin
            if( src_valid_o && src_ready_i && src_endofpacket_o )
              next_state = IDLE_S;
          end

        default: next_state = IDLE_S;
        endcase
    end
  
  // Sort FSM states
  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        sort_state <= SORT_IDLE_S;
      else
        sort_state <= next_sort_state;
    end
  
  always_comb
    begin
      next_sort_state = sort_state;

      case( sort_state )
        SORT_IDLE_S:    
          begin
            if( state == SORT_S )
              next_sort_state = SORT_INIT_S;
          end
        
        SORT_INIT_S:    
          begin
            next_sort_state = ( pkt_size <= 1 ) ? SORT_IDLE_S : SORT_RD_A_S;
          end
        
        SORT_RD_A_S:    
          begin
            next_sort_state = SORT_RD_B_S;
          end
        
        SORT_RD_B_S:    
          begin
            next_sort_state = SORT_CMP_S;
          end
        
        SORT_CMP_S:     
          begin
            if( val_a > mem_q )
              next_sort_state = SORT_SWAP_W1_S;
            else
              next_sort_state = SORT_NEXT_S;
          end
        
        SORT_SWAP_W1_S: 
          begin
            next_sort_state = SORT_SWAP_W2_S;
          end
        
        SORT_SWAP_W2_S: 
          begin
            next_sort_state = SORT_NEXT_S;
          end
        
        SORT_NEXT_S:    
          begin
            if( ( pkt_size > 1 ) && ( j_cnt < ( pkt_size - i_cnt - 2 ) ) )
              next_sort_state = SORT_RD_A_S;
            else if( ( pkt_size > 1 ) && ( i_cnt < ( pkt_size - 2 ) ) && swapped )
                next_sort_state = SORT_INIT_S;
            else
              next_sort_state = SORT_IDLE_S;
          end
        default: next_sort_state = SORT_IDLE_S;
      endcase
    end

  assign sort_done = ( state == SORT_S ) && (
                     ( ( sort_state == SORT_NEXT_S ) && ( next_sort_state == SORT_IDLE_S ) ) ||
                     ( ( sort_state == SORT_INIT_S ) && ( pkt_size <= 1                  ) ) );

  always_comb
    begin
      snk_ready_o         = 1'b0;
      src_valid_o         = src_valid_pipe;
      src_startofpacket_o = src_sop_pipe;
      src_endofpacket_o   = src_eop_pipe;
      src_data_o          = 'x;

      mem_we    = 1'b0;
      mem_waddr = '0;
      mem_wdata = '0;
      mem_raddr = '0;

      case( state )
        IDLE_S:
          begin
            snk_ready_o = 1'b1;
            mem_we      = snk_valid_i;
            mem_waddr   = pkt_cnt[ADDR_W-1:0];
            mem_wdata   = snk_data_i;
          end
        
        SINK_S:
          begin
            snk_ready_o = 1'b1;
            mem_we      = snk_valid_i;
            mem_waddr   = pkt_cnt[ADDR_W-1:0];
            mem_wdata   = snk_data_i;
          end

        SORT_S:
          begin
            case( sort_state )
              SORT_RD_A_S:
                begin
                  mem_raddr = j_cnt[ADDR_W-1:0];
                end
              
              SORT_RD_B_S:
                begin
                  mem_raddr = j_cnt[ADDR_W-1:0] + 1'b1;
                end
              
              SORT_SWAP_W1_S:
                begin
                  mem_we    = 1'b1;
                  mem_waddr = j_cnt[ADDR_W-1:0];
                  mem_wdata = val_b;
                end
              
              SORT_SWAP_W2_S:
                begin
                  mem_we    = 1'b1;
                  mem_waddr = j_cnt[ADDR_W-1:0] + 1'b1;
                  mem_wdata = val_a;
                end
              default: ;
            endcase
          end
        
        SOURCE_S:
          begin
            mem_raddr   = pkt_cnt[ADDR_W-1:0];
            src_data_o  = mem_q;
          end
      endcase
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          pkt_cnt        <= '0;
          pkt_size       <= '0;
          i_cnt          <= '0;
          j_cnt          <= '0;
          val_a          <= '0;
          val_b          <= '0;
          swapped        <= 1'b0;
          src_valid_pipe <= 1'b0;
          src_sop_pipe   <= 1'b0;
          src_eop_pipe   <= 1'b0;
        end
      else
        begin
          src_valid_pipe <= 1'b0;
          src_sop_pipe   <= 1'b0;
          src_eop_pipe   <= 1'b0;

          case( state )
            IDLE_S:
              begin
                i_cnt <= '0;
                if( snk_valid_i && snk_ready_o )
                  begin
                    if( snk_startofpacket_i && snk_endofpacket_i )
                      begin
                        pkt_size <= (ADDR_W+1)'(1);
                        pkt_cnt  <= '0;
                      end
                    else
                      pkt_cnt  <= (ADDR_W+1)'(1);
                  end
                else
                  pkt_cnt <= '0;
              end
            SINK_S:
              begin
                if( snk_valid_i && snk_ready_o )
                  begin
                    pkt_cnt <= pkt_cnt + 1'b1;
                    if( snk_endofpacket_i )
                      begin
                        pkt_size <= pkt_cnt + 1'b1;
                        pkt_cnt  <= '0;
                      end
                  end
              end

            SORT_S:
              begin
                case( sort_state )
                  SORT_INIT_S:
                    begin
                      j_cnt   <= '0;
                      swapped <= 1'b0;
                    end
                  
                  SORT_RD_B_S:
                    begin
                      val_a <= mem_q;
                    end

                  SORT_CMP_S:
                    begin
                      val_b <= mem_q;
                    end
                  
                  SORT_SWAP_W1_S:
                    begin
                      swapped <= 1'b1;
                    end
                  
                  SORT_NEXT_S:
                    begin
                      if( j_cnt < ( pkt_size - i_cnt - 2 ) )
                        j_cnt <= j_cnt + 1'b1;
                      else
                        i_cnt <= i_cnt + 1'b1;
                    end
                  default: ;
                endcase
              end

            SOURCE_S:
              begin
                if( src_ready_i )
                  begin
                    src_valid_pipe <= ( pkt_cnt < pkt_size );
                    src_sop_pipe   <= ( pkt_cnt == 0 );
                    src_eop_pipe   <= ( pkt_cnt == ( pkt_size - 1 ) );
                    if( pkt_cnt < pkt_size )
                      pkt_cnt <= pkt_cnt + 1'b1;
                  end
              end
          endcase
        end
    end
endmodule