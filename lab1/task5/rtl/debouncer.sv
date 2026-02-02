module debouncer #(
  parameter CLK_FREQ_MHZ   = 150,
  parameter GLITCH_TIME_NS = 20
)(
  input  logic clk_i,
  input  logic key_i,

  output logic key_pressed_stb_o
);
  localparam int GLITCH_CYCLES = ( GLITCH_TIME_NS * CLK_FREQ_MHZ + 999 ) / 1000;
  localparam int COUNTER_WIDTH = $clog2(GLITCH_CYCLES + 1);

  logic [COUNTER_WIDTH-1:0] counter;
  logic                     key_reg_0;
  logic                     key_reg_1;
  logic                     key_prev;
  wire                      key_fall;

  enum logic [1:0] {IDLE_S,
                    COUNT_S,
                    HOLD_S} state, next_state;

  always_ff @( posedge clk_i )
    begin
      state <= next_state;
    end

  always_comb
    begin
      next_state = state;

      case ( state )
        IDLE_S: 
          begin
            if( key_fall )
              next_state = COUNT_S;
          end

        COUNT_S: 
          begin
            if( key_reg_1 == 1'b1 )
              next_state = IDLE_S;
            else if( counter == '0 )
              next_state = HOLD_S;
          end

        HOLD_S:
          begin
            if( key_reg_1 == 1'b1 )
              next_state = IDLE_S;
          end

        default:
          next_state = IDLE_S;
      endcase
    end

  assign key_fall = ( key_prev == 1'b1 ) && ( key_reg_1 == 1'b0 );

  always_ff @( posedge clk_i )
    begin
      key_reg_0 <= key_i;
      key_reg_1 <= key_reg_0;
      key_prev  <= key_reg_1;
    end
  
  always_ff @( posedge clk_i )
    begin
      if ( key_fall )
        counter <= $size(counter)'(GLITCH_CYCLES - 1);
      else if ( ( state == COUNT_S ) && ( counter != '0 ) )
        counter <= counter - 1'b1;
    end

  always_ff @( posedge clk_i )
    begin
      key_pressed_stb_o <= ( ( state == COUNT_S ) && ( counter == '0 ) );
    end

endmodule
