module traffic_lights #(
  parameter BLINK_HALF_PERIOD_MS  = 500,
  parameter BLINK_GREEN_TIME_TICK = 3,
  parameter RED_YELLOW_MS         = 1000
)(
  input  logic        clk_i,
  input  logic        srst_i,
  input  logic [2:0]  cmd_type_i,
  input  logic        cmd_valid_i,
  input  logic [15:0] cmd_data_i,

  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o
);
  localparam logic [15:0] DEFAULT_RED_TIME       = 16'd2000;
  localparam logic [15:0] DEFAULT_YELLOW_TIME    = 16'd1000;
  localparam logic [15:0] DEFAULT_GREEN_TIME     = 16'd2000;
  
  localparam int          MS_TO_TICKS_MULT       = 2;
  localparam int          RED_YELLOW_TICKS       = RED_YELLOW_MS        * MS_TO_TICKS_MULT;
  localparam int          BLINK_HALF_TICKS       = BLINK_HALF_PERIOD_MS * MS_TO_TICKS_MULT;
  localparam int          BLINK_GREEN_HALF_TICKS = BLINK_GREEN_TIME_TICK * 2;

  localparam int          MAX_TIME_MS            = 65535;
  localparam int          TIMER_WIDTH            = $clog2(MAX_TIME_MS * MS_TO_TICKS_MULT + 1);
  localparam int          BLINK_TIMER_WIDTH      = $clog2(BLINK_HALF_TICKS+1);
  localparam int          BLINK_GREEN_HALF_WIDTH = $clog2(BLINK_GREEN_HALF_TICKS+1);

  enum logic [2:0] {OFF_S,
                    RED_S,
                    RED_YELLOW_S,
                    GREEN_S,
                    GREEN_BLINK_S,
                    YELLOW_S,
                    NOTRANSITION_S} state, next_state;

  logic [TIMER_WIDTH-1:0]            red_ticks;
  logic [TIMER_WIDTH-1:0]            yellow_ticks;
  logic [TIMER_WIDTH-1:0]            green_ticks;
  
  logic [TIMER_WIDTH-1:0]            timer_cnt;
  logic [BLINK_TIMER_WIDTH-1:0]      blink_timer_cnt;
  logic [BLINK_GREEN_HALF_WIDTH-1:0] blink_half_cnt;

  logic                              timer_done;
  logic                              blink_timer_done;

  assign timer_done       = ( timer_cnt       == 0 );
  assign blink_timer_done = ( blink_timer_cnt == 0 );

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          red_ticks    <= TIMER_WIDTH'(DEFAULT_RED_TIME    * MS_TO_TICKS_MULT);
          yellow_ticks <= TIMER_WIDTH'(DEFAULT_YELLOW_TIME * MS_TO_TICKS_MULT);
          green_ticks  <= TIMER_WIDTH'(DEFAULT_GREEN_TIME  * MS_TO_TICKS_MULT);
        end
      else
        begin
          if( ( cmd_valid_i ) && ( state == NOTRANSITION_S ) )
            begin
              case( cmd_type_i )
                3'd3: green_ticks  <= TIMER_WIDTH'(cmd_data_i * MS_TO_TICKS_MULT);
                3'd4: red_ticks    <= TIMER_WIDTH'(cmd_data_i * MS_TO_TICKS_MULT);
                3'd5: yellow_ticks <= TIMER_WIDTH'(cmd_data_i * MS_TO_TICKS_MULT);
                default: ;
              endcase
            end
      end
    end
  
  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          timer_cnt       <= '0;
          blink_timer_cnt <= '0;
          blink_half_cnt  <= '0;
        end
      else
        begin
          if( state != next_state )
            begin
              blink_timer_cnt  <= BLINK_TIMER_WIDTH'(BLINK_HALF_TICKS - 1);
              blink_half_cnt   <= '0;
              
              case( next_state )
                RED_S:        timer_cnt <= TIMER_WIDTH'(red_ticks        - 1);
                RED_YELLOW_S: timer_cnt <= TIMER_WIDTH'(RED_YELLOW_TICKS - 1);
                GREEN_S:      timer_cnt <= TIMER_WIDTH'(green_ticks      - 1);
                YELLOW_S:     timer_cnt <= TIMER_WIDTH'(yellow_ticks     - 1);
                default:      timer_cnt <= '0; 
              endcase
            end
          else
            begin
              if( timer_cnt > 0 )
                timer_cnt <= TIMER_WIDTH'(timer_cnt - 1);

              if( blink_timer_cnt > 0 )
                blink_timer_cnt <= BLINK_TIMER_WIDTH'(blink_timer_cnt - 1);
              else
                begin
                  blink_timer_cnt <= BLINK_TIMER_WIDTH'(BLINK_HALF_TICKS - 1);
                  blink_half_cnt  <= BLINK_GREEN_HALF_WIDTH'(blink_half_cnt + 1);
                end
            end
        end
    end
  
  always_comb
    begin
      next_state = state;

      if( cmd_valid_i )
        begin
          case( cmd_type_i )
            3'd0: next_state = RED_S;
            3'd1: next_state = OFF_S;
            3'd2: next_state = NOTRANSITION_S;
            default: ;
          endcase
        end 
      else
        begin
          case( state )
            OFF_S:
              begin
                next_state = OFF_S;
              end

            RED_S:
              begin
                if( timer_done )
                  next_state = RED_YELLOW_S;
              end

            RED_YELLOW_S:
              begin
                if( timer_done )
                  next_state = GREEN_S;
              end

            GREEN_S:
              begin
                if( timer_done )
                  next_state = GREEN_BLINK_S;
              end

            GREEN_BLINK_S:
              begin
                if( ( blink_half_cnt >= BLINK_GREEN_HALF_TICKS - 1 ) && ( blink_timer_done ) ) 
                  next_state = YELLOW_S;
              end

            YELLOW_S:
              begin
                if( timer_done )
                  next_state = RED_S;
              end

            NOTRANSITION_S:
              begin
                next_state = NOTRANSITION_S;
              end
                
            default:
              next_state = OFF_S;
            endcase
        end
    end
  
  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        state <= OFF_S;
      else
        state <= next_state;
    end

  always_comb
    begin
      red_o    = 1'b0;
      yellow_o = 1'b0;
      green_o  = 1'b0;

      case( state )
        RED_S:
          begin
            red_o = 1'b1;
          end
        
        RED_YELLOW_S:  
          begin
            red_o    = 1'b1;
            yellow_o = 1'b1;
          end

        GREEN_S:
          begin
            green_o = 1'b1;
          end
        
        GREEN_BLINK_S: 
          begin
            green_o = blink_half_cnt[0];
          end
        
        YELLOW_S:       
          begin
            yellow_o = 1'b1;
          end
        
        NOTRANSITION_S:
          begin
            yellow_o = blink_half_cnt[0];
          end
        
        default: ;
      endcase
    end
endmodule
