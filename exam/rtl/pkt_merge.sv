module pkt_merge #(
  parameter DATA_W  = 64,
  parameter EMPTY_W = ( $clog2( DATA_W / 8 ) ) ? ( $clog2( DATA_W / 8 ) ) : ( 1 )
)(
  input  logic                clk_i,

  input  logic                rst_i,

  input  logic [15:0]         offset_i,

  input  logic [DATA_W-1:0]   snk_base_data_i,
  input  logic                snk_base_valid_i,
  input  logic                snk_base_startofpacket_i,
  input  logic                snk_base_endofpacket_i,
  input  logic [EMPTY_W-1:0]  snk_base_empty_i,
  output logic                snk_base_ready_o,

  input  logic [DATA_W-1:0]   snk_to_insert_data_i,
  input  logic                snk_to_insert_valid_i,
  input  logic                snk_to_insert_startofpacket_i,
  input  logic                snk_to_insert_endofpacket_i,
  input  logic [EMPTY_W-1:0]  snk_to_insert_empty_i,
  output logic                snk_to_insert_ready_o,

  output logic [DATA_W-1:0]   src_data_o,
  output logic                src_valid_o,
  output logic                src_startofpacket_o,
  output logic                src_endofpacket_o,
  output logic [EMPTY_W-1:0]  src_empty_o,
  input  logic                src_ready_i
);

  localparam int N        = DATA_W / 8;
  localparam int SHIFT_W  = $clog2( N );
  localparam int CNT_W    = $clog2( N * 2 );
  localparam int OFFSET_W = 16;

  // Base and Insert input words
  typedef struct packed {
    logic [DATA_W-1:0] data;
    logic [CNT_W-1:0]  cnt;  
    logic              eop;
  } in_word_t;

  in_word_t            base;
  in_word_t            ins;

  // Word is stored
  logic                base_vld;
  logic                ins_vld;

  // Previous base word to shift tail
  logic [DATA_W-1:0]   base_prev;
  // Previous insert word to shift insert
  logic [DATA_W-1:0]   ins_prev;

  // Input word captured
  logic                base_capture;
  logic                ins_capture;

  // Word is consumed by the output word being built
  logic                base_pop;
  logic                ins_pop;

  // Output word is built in this clock
  logic                go;

  // Permission to use the word
  logic                base_pop_go;
  logic                ins_pop_go;

  // Head bytes still to be sent
  logic [OFFSET_W-1:0] head_left;
  // Next head word is full
  logic                head_full;
  // Next output word is the first one in packet
  logic                pkt_first;

  logic [SHIFT_W-1:0]  ins_shift;
  logic [SHIFT_W-1:0]  tail_shift;

  logic                has_tail;
  logic [CNT_W-1:0]    ins_flush_cnt;

  logic                base_fin;
  logic [CNT_W-1:0]    base_last_cnt;

  // Number of valid bytes in base input word
  logic [CNT_W-1:0]    in_cnt;
  // Clamp insertion position when incoming last base word is accepted at SOP
  logic                clamp_sop;
  // Clamp insertion position after a full head word is consumed
  logic                clamp_dec;
  // Clamp insertion position when head position does not advance
  logic                clamp_hold;

  // go = 0: no output word, base word can be accepted only into an empty base
  // Base word can be accepted while no output word is built
  logic                capture_idle;
  // Next head distance when no output word is built
  logic [OFFSET_W-1:0] left_idle;
  // Next full-head flag when no output word is built
  logic                full_idle;

  // go = 1: output word is built, base word can be accepted if base is empty or is consumed
  // Base word can be accepted while an output word is built
  logic                capture_go;
  // Next head distance when an output word is built
  logic [OFFSET_W-1:0] left_go;
  // Next full-head flag when an output word is built
  logic                full_go;

  // Next insertion shift if no output word is built
  logic [SHIFT_W-1:0]  r_idle;
  // Next insertion shift if an output word is built
  logic [SHIFT_W-1:0]  r_go;
  // Next insertion shift register value
  logic [SHIFT_W-1:0]  ins_shift_next;

  // Output register
  logic [DATA_W-1:0]   out_data;
  logic                out_valid;
  logic                out_sop;
  logic                out_eop;
  logic [EMPTY_W-1:0]  out_empty;

  logic                out_can_load;

  // Plan of the next output word
  // Number of bytes taken by head in this word
  logic [CNT_W-1:0]    head_raw;
  logic [CNT_W-1:0]    head_cnt;    
  
  // All bytes are from head word
  logic                head_word;
  // Head ends and insert starts in this word
  logic                joint_word;
  // ins is used as the current insert word
  logic                ins_word;

  // There is tail after insert
  logic                cur_has_tail;
  // Tail shift
  logic [SHIFT_W-1:0]  s_use;
  // Insert shift + number of bytes in the last insert word
  logic [CNT_W-1:0]    e_sum;
  // Current insert word is the last one
  logic                ins_last_cur;
  // End of insert goes to the next output word
  logic                ins_spill;
  // Insert ends inside this output word
  logic                ins_end_here;

  // Last base word is used in this tail output word
  logic                t_cur_last;     
  // End of the last base word in tail goes to the next output word
  logic                t_spill;
  // Output word is the last one in tail
  logic                t_last_word;
  // Number of valid bytes in the last tail word
  logic [CNT_W-1:0]    t_nvalid;

  // Last word of the output packet
  logic                last_word;

  // Empty values
  logic [EMPTY_W-1:0]  empty_from_insert;
  logic [EMPTY_W-1:0]  empty_from_tail;
  logic [EMPTY_W-1:0]  empty_from_flush;
  logic [EMPTY_W-1:0]  empty_next;

  // Number of output data bytes from head
  logic [CNT_W-1:0]    head_bytes;

  // Input words needed for this output are in place
  logic                src_ok;

  // Current and previous insert words concatenation
  logic [2*DATA_W-1:0] ins_cat;
  // Shifted insert concatenation
  logic [2*DATA_W-1:0] ins_shifted;
  // Shifted insert concatenation fragment
  logic [DATA_W-1:0]   ins_fun;

  // Current and previous tail words concatenation
  logic [2*DATA_W-1:0] tail_cat;
  // Shifted tail concatenation
  logic [2*DATA_W-1:0] tail_shifted;
  // Shifted tail concatenation fragment
  logic [DATA_W-1:0]   tail_fun;

  // Final output data word
  logic [DATA_W-1:0]   word_data;

  // Number of valid bytes in input word
  function automatic logic [CNT_W-1:0] word_cnt(
    input logic               eop,
    input logic [EMPTY_W-1:0] empty
  );
    return ( eop ) ? ( CNT_W'( N ) - CNT_W'( empty ) ) : ( CNT_W'( N ) );
  endfunction

  // FSM
  enum logic [1:0] { HEAD_S,
                    INS_S,
                    IFLUSH_S,
                    TAIL_S } state, next_state;

  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      state <= HEAD_S;
    else
      state <= next_state;

  always_comb
    begin
      next_state = state;

      if( go )
        begin
          if( last_word )
            next_state = HEAD_S;
          else
            case( state )
              HEAD_S:
                begin
                  if( head_word )
                    next_state = HEAD_S;
                  else
                    if( !ins_last_cur )
                      next_state = INS_S;
                    else
                      if( ins_spill )
                        next_state = IFLUSH_S;
                      else
                        next_state = TAIL_S;
                end

              INS_S:
                begin
                  if( head_word )
                    next_state = HEAD_S;
                  else
                    if( !ins_last_cur )
                      next_state = INS_S;
                    else
                      if( ins_spill )
                        next_state = IFLUSH_S;
                      else
                        next_state = TAIL_S;
                end

              IFLUSH_S:
                begin
                  next_state = TAIL_S;
                end

              TAIL_S:
                begin
                  next_state = TAIL_S;
                end

              default:
                begin
                  next_state = HEAD_S;
                end

            endcase
        end
    end

  // Head
  assign head_raw     = ( head_full ) ? ( CNT_W'( N ) ) : ( CNT_W'( head_left[SHIFT_W-1:0] ) );
  assign head_cnt     = ( base_fin  ) ? ( '0          ) : ( head_raw                         );

  assign head_word    = ( state == HEAD_S ) && ( head_cnt == CNT_W'( N ) );
  assign joint_word   = ( state == HEAD_S ) && ( head_cnt != CNT_W'( N ) );
  assign ins_word     = joint_word || ( state == INS_S );

  // cur_has_tail
  always_comb
    begin
      if( joint_word )
        cur_has_tail = ( !base_fin ) && ( !( base.eop && ( base.cnt == head_cnt ) ) );
      else
        cur_has_tail = has_tail;
    end

  // Insert and tail boundaries
  assign e_sum        = CNT_W'( ins_shift ) + ins.cnt;
  assign ins_last_cur = ins_word && ins.eop;
  assign ins_spill    = ins_last_cur && ( e_sum >  CNT_W'( N ) );
  assign ins_end_here = ins_last_cur && ( e_sum <= CNT_W'( N ) );

  // s_use
  always_comb
    begin
      if( ( state == IFLUSH_S ) || ( state == TAIL_S ) )
        s_use = tail_shift;
      else
        s_use = ins.cnt[SHIFT_W-1:0];
    end

  assign t_cur_last   = ( !base_fin ) && base.eop;
  assign t_spill      = t_cur_last && ( ( CNT_W'( s_use ) + base.cnt ) > CNT_W'( N ) );
  assign t_last_word  = base_fin || ( t_cur_last && ( !t_spill ) );
  
  // t_nvalid
  always_comb
    begin
      if( base_fin )
        t_nvalid = CNT_W'( s_use ) + base_last_cnt - CNT_W'( N );
      else
        t_nvalid = CNT_W'( s_use ) + base.cnt;
    end

  // Empty values
  assign empty_from_insert = EMPTY_W'( CNT_W'( N ) - e_sum         );
  assign empty_from_tail   = EMPTY_W'( CNT_W'( N ) - t_nvalid      );
  assign empty_from_flush  = EMPTY_W'( CNT_W'( N ) - ins_flush_cnt );

  // last_word and empty_next
  always_comb
    begin
      last_word  = 1'b0;
      empty_next = 'x;

      case( state )
        HEAD_S,
        INS_S:
          begin
            if( ins_end_here )
              begin
                if( !cur_has_tail )
                  begin
                    last_word  = 1'b1;
                    empty_next = empty_from_insert;
                  end
                else
                  if( ( e_sum < CNT_W'( N ) ) && t_last_word )
                    begin
                      last_word  = 1'b1;
                      empty_next = empty_from_tail;
                    end
              end
          end

        IFLUSH_S:
          begin
            if( !has_tail )
              begin
                last_word  = 1'b1;
                empty_next = empty_from_flush;
              end
            else
              if( t_last_word )
                begin
                  last_word  = 1'b1;
                  empty_next = empty_from_tail;
                end
          end

        TAIL_S:
          begin
            last_word  = t_last_word;
            if (t_last_word)
              empty_next = empty_from_tail;
          end

        default: ;
      endcase
    end

  // Data of the output word
  assign head_bytes = ( state == HEAD_S ) ? ( head_cnt ) : ( '0 );

  // Funnel
  assign ins_cat      = { ins.data, ins_prev };
  assign ins_shifted  = ins_cat << { ins_shift, 3'b000 };
  assign ins_fun      = ins_shifted[2*DATA_W-1:DATA_W];

  assign tail_cat     = { base.data, base_prev };
  assign tail_shifted = tail_cat << { s_use, 3'b000 };
  assign tail_fun     = tail_shifted[2*DATA_W-1:DATA_W];

  // Source of each byte: head, insert or tail
  genvar g;
  generate
    for( g = 0; g < N; g++ )
      begin : byte_mux
        logic use_insert_byte;

        assign use_insert_byte = ( ins_word && ( ( !ins_last_cur ) || ( e_sum > CNT_W'( g ) ) ) ) ||
                            ( ( state == IFLUSH_S ) && ( CNT_W'( g ) < ins_flush_cnt ) );

        always_comb
          begin
            if( g < head_bytes )
              word_data[g*8 +: 8] = base.data[g*8 +: 8];
            else if( use_insert_byte )
              word_data[g*8 +: 8] = ins_fun[g*8 +: 8];
            else
              word_data[g*8 +: 8] = tail_fun[g*8 +: 8];
          end
        end
  endgenerate

  // src_ok
  always_comb
    begin
      case( state )
        HEAD_S:
          begin
            if( head_word )
              src_ok = base_vld && ( ( !pkt_first ) || ins_vld );
            else
              src_ok = ins_vld && ( base_fin || base_vld );
          end

        INS_S:
          begin
            src_ok = ins_vld;
          end
        
        IFLUSH_S:
          begin
            src_ok = ( !has_tail ) || base_fin || base_vld;
          end
        
        TAIL_S:
          begin
            src_ok = base_fin || base_vld;
          end
        
        default:
          begin
            src_ok = 1'b0;
          end
        
      endcase
    end

  assign out_can_load = ( !out_valid ) || src_ready_i;
  assign go           = out_can_load && src_ok;

  // ins_pop and base_pop
  always_comb
    begin
      ins_pop  = 1'b0;
      base_pop = 1'b0;

      case( state )
        HEAD_S,
        INS_S:
          begin
            if( head_word )
              base_pop = 1'b1;
            else
              begin
                ins_pop = 1'b1;

                if( !cur_has_tail )
                  base_pop = !base_fin;
                else
                  base_pop = ins_last_cur && ( ins.cnt != CNT_W'( N ) );
              end
          end

        IFLUSH_S:
          begin
            base_pop = has_tail && ( !base_fin );
          end
        
        TAIL_S:
          begin
            base_pop = !base_fin;
          end
        
        default: ;
      
      endcase
    end

  assign base_pop_go = go && base_pop;
  assign ins_pop_go  = go && ins_pop;

  assign snk_base_ready_o      = ( !base_vld ) || base_pop_go;
  assign snk_to_insert_ready_o = ( !ins_vld  ) || ins_pop_go;

  assign base_capture = snk_base_valid_i      && snk_base_ready_o;
  assign ins_capture  = snk_to_insert_valid_i && snk_to_insert_ready_o;

  // Input registers
  // base_vld
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      base_vld <= 1'b0;
    else
      if( base_capture )
        base_vld <= 1'b1;
      else
        if( base_pop_go )
          base_vld <= 1'b0;

  // base
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      begin
        base.cnt <= '0;
        base.eop <= 1'b0;
      end
    else
      if( base_capture )
        base <= { snk_base_data_i,
                  word_cnt( snk_base_endofpacket_i, snk_base_empty_i ),
                  snk_base_endofpacket_i };

  // ins_vld
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      ins_vld <= 1'b0;
    else
      if( ins_capture )
        ins_vld <= 1'b1;
      else
        if( ins_pop_go )
          ins_vld <= 1'b0;

  // ins
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      begin
        ins.cnt <= '0;
        ins.eop <= 1'b0;
      end
    else
      if( ins_capture )
        ins <= { snk_to_insert_data_i,
                 word_cnt( snk_to_insert_endofpacket_i, snk_to_insert_empty_i ),
                 snk_to_insert_endofpacket_i };

  // base_prev and ins_prev
  always_ff @( posedge clk_i )
    begin
      if( base_pop_go )
        base_prev <= base.data;

      if( ins_pop_go )
        ins_prev <= ins.data;
    end

  assign in_cnt = word_cnt( snk_base_endofpacket_i, snk_base_empty_i );

  assign clamp_sop  = snk_base_endofpacket_i &&
                      ( ( offset_i >= OFFSET_W'( N ) ) ? ( in_cnt != CNT_W'( N )                    ):
                                                         ( CNT_W'( offset_i[SHIFT_W-1:0] ) > in_cnt ) );

  assign clamp_dec  = snk_base_endofpacket_i &&
                      ( ( head_left[OFFSET_W-1:SHIFT_W+1] != '0 ) ? ( in_cnt != CNT_W'( N )                     ):
                                                                    ( CNT_W'( head_left[SHIFT_W-1:0] ) > in_cnt ) );

  assign clamp_hold = snk_base_endofpacket_i &&
                      ( ( head_full ) ? ( in_cnt != CNT_W'( N )                     ):
                                        ( CNT_W'( head_left[SHIFT_W-1:0] ) > in_cnt ) );

  // go = 0: no output word is built
  always_comb
    begin
      capture_idle = snk_base_valid_i && ( !base_vld );
      left_idle    = head_left;
      full_idle    = head_full;

      if( capture_idle )
        begin
          if( snk_base_startofpacket_i )
            begin
              if( clamp_sop )
                begin
                  left_idle  = OFFSET_W'( in_cnt ) ;
                  full_idle  = 1'b0;
                end
              else
                begin
                  left_idle = offset_i;
                  full_idle = ( offset_i >= OFFSET_W'( N ) );
                end
            end
          else if( clamp_hold )
            begin
              left_idle  = OFFSET_W'( in_cnt );
              full_idle  = 1'b0;
            end
        end
    end

  // go = 1: an output word is built
  always_comb
    begin
      capture_go = snk_base_valid_i && ( ( !base_vld ) || base_pop );
      left_go    = head_left;
      full_go    = head_full;

      if( capture_go )
        begin
          if( snk_base_startofpacket_i )
            begin
              if( clamp_sop )
                begin
                  left_go  = OFFSET_W'( in_cnt );
                  full_go  = 1'b0;
                end
              else
                begin
                  left_go = offset_i;
                  full_go = ( offset_i >= OFFSET_W'( N ) );
                end
            end
          else if( head_word )
            begin
              if( clamp_dec )
                begin
                  left_go  = OFFSET_W'( in_cnt );
                  full_go  = 1'b0;
                end
              else
                begin
                  left_go = head_left - OFFSET_W'( N );
                  full_go = ( head_left[OFFSET_W-1:SHIFT_W+1] != '0 );
                end
            end
          else if( clamp_hold )
            begin
              left_go  = OFFSET_W'( in_cnt ) ;
              full_go  = 1'b0;
            end
        end
      else if( head_word )
        begin
          left_go = head_left - OFFSET_W'( N );
          full_go = ( head_left[OFFSET_W-1:SHIFT_W+1] != '0 );
        end
    end

  // head_left
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      head_left <= '0;
    else
      head_left <= ( go ) ? ( left_go ) : ( left_idle );

  // head_full
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      head_full <= 1'b0;
    else
      head_full <= ( go ) ? ( full_go ) : ( full_idle );

  // Packet state registers
  // pkt_first
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      pkt_first <= 1'b1;
    else
      if( go )
        pkt_first <= last_word;

  // base_fin
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      base_fin <= 1'b0;
    else
      if( go )
        if( last_word )
          base_fin <= 1'b0;
        else
          if( base_pop && base.eop )
            base_fin <= 1'b1;

  // base_last_cnt
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      base_last_cnt <= '0;
    else
      if( go && base_pop && base.eop )
        base_last_cnt <= base.cnt;

  assign r_idle = ( full_idle ) ? ( '0 ) : ( left_idle[SHIFT_W-1:0] );
  assign r_go   = ( full_go   ) ? ( '0 ) : ( left_go[SHIFT_W-1:0]   );

  // ins_shift_next
  always_comb
    begin
      if( !go )
        begin
          if( state == HEAD_S )
            ins_shift_next = ( base_fin ) ? ( '0 ) : ( r_idle );
          else
            ins_shift_next = ins_shift;
        end
      else
        if( last_word )
          ins_shift_next = r_go;
        else
          if( head_word )
            ins_shift_next = ( base.eop ) ? ( '0 ) : ( r_go );
          else
            ins_shift_next = ins_shift;
    end

  // ins_shift
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      ins_shift <= '0;
    else
      ins_shift <= ins_shift_next;

  // has_tail
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      has_tail <= 1'b0;
    else
      if( go && joint_word )
        has_tail <= cur_has_tail;

  // tail_shift
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      tail_shift <= '0;
    else
      if( go && ins_last_cur )
        tail_shift <= ins.cnt[SHIFT_W-1:0];

  // ins_flush_cnt
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      ins_flush_cnt <= '0;
    else
      if( go && ins_spill )
        ins_flush_cnt <= e_sum - CNT_W'( N );

  // Output registers
  // out_valid
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      out_valid <= 1'b0;
    else
      if( go )
        out_valid <= 1'b1;
      else
        if( src_ready_i )
          out_valid <= 1'b0;

  // out_data
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      out_data <= 'x;
    else
      if( go )
        out_data <= word_data;
      else
        if( src_ready_i )
          out_data <= 'x;

  // out_sop
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      out_sop <= 1'b0;
    else
      if( go )
        out_sop <= pkt_first;
      else
        if( src_ready_i )
          out_sop <= 1'b0;

  // out_eop
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      out_eop <= 1'b0;
    else
      if( go )
        out_eop <= last_word;
      else
        if( src_ready_i )
          out_eop <= 1'b0;

  // out_empty
  always_ff @( posedge clk_i or posedge rst_i )
    if( rst_i )
      out_empty <= 'x;
    else
      if( go )
        out_empty <= empty_next;
      else
        if( src_ready_i )
          out_empty <= 'x;

  // Output
  assign src_data_o          = out_data;
  assign src_valid_o         = out_valid;
  assign src_startofpacket_o = out_sop;
  assign src_endofpacket_o   = out_eop;
  assign src_empty_o         = out_empty;

endmodule