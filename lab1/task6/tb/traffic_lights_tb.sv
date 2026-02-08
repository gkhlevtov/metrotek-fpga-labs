`timescale 1us/1us

module traffic_lights_tb;
  // DUT parameters
  parameter int          BLINK_HALF_PERIOD_MS  = 10;
  parameter int          BLINK_GREEN_TIME_TICK = 3;
  parameter int          RED_YELLOW_MS         = 20;

  // Ticks multiplier 
  parameter int          TICKS_PER_MS          = 2;

  // Default time presets
  parameter logic [15:0] DEFAULT_RED_TIME      = 16'd2000;
  parameter logic [15:0] DEFAULT_YELLOW_TIME   = 16'd1000;
  parameter logic [15:0] DEFAULT_GREEN_TIME    = 16'd2000;

  // Max and min random light time
  parameter int          MAX_RANDOM_TIME_MS    = 1000;
  parameter int          MIN_RANDOM_TIME_MS    = 10;

  // Number of random tests 
  parameter int          N                     = 20;

  // DUT ports
  bit          clk;
  bit          srst;
  logic [2:0]  cmd_type_i;
  logic        cmd_valid_i;
  logic [15:0] cmd_data_i;
  logic        red_o;
  logic        yellow_o;
  logic        green_o;

  // Timings preset struct
  typedef struct packed {
    logic [15:0] red_time;
    logic [15:0] yellow_time;
    logic [15:0] green_time;
  } time_preset;

  time_preset default_preset;

  // Simulation success flag
  bit pass_flag;

  // Reset flag
  bit rst_done;

  // Command types
  typedef enum logic [2:0] {CMD_ENABLE,
                            CMD_DISABLE,
                            CMD_NOTRANSITION,
                            CMD_SET_GREEN_MS,
                            CMD_SET_RED_MS,
                            CMD_SET_YELLOW_MS} cmd_t;

  // Color type
  typedef enum logic [2:0] {OFF        = 3'b000,
                            RED        = 3'b100,
                            YELLOW     = 3'b010,
                            GREEN      = 3'b001,
                            RED_YELLOW = 3'b110} color_t;

  initial
    forever
      #250 clk = !clk;

  initial
    begin
      clk         = '0;
      srst        = '0;
      cmd_type_i  = '0;
      cmd_valid_i = '0;
      pass_flag   = '1;

      @( posedge clk );
      srst        = '1;

      @( posedge clk );
      srst        = '0;
      rst_done    = '1;
    end
  
  traffic_lights #(
    .BLINK_HALF_PERIOD_MS  ( BLINK_HALF_PERIOD_MS  ),
    .BLINK_GREEN_TIME_TICK ( BLINK_GREEN_TIME_TICK ),
    .RED_YELLOW_MS         ( RED_YELLOW_MS         )
  ) traffic_lights_inst (
    .clk_i                 ( clk                   ),
    .srst_i                ( srst                  ),
    .cmd_type_i            ( cmd_type_i            ),
    .cmd_valid_i           ( cmd_valid_i           ),
    .cmd_data_i            ( cmd_data_i            ),
    .red_o                 ( red_o                 ),
    .yellow_o              ( yellow_o              ),
    .green_o               ( green_o               )
  );

  task automatic send_cmd( cmd_t cmd_type, logic [15:0] cmd_data = 15'd0 );
    begin
      @( posedge clk );
      cmd_type_i  <= cmd_type;
      cmd_valid_i <= 1'b1;
      cmd_data_i  <= cmd_data;
      @( posedge clk );
      cmd_type_i  <= 'x;
      cmd_valid_i <= 1'b0;
      cmd_data_i  <= 'x;
    end
  endtask

  task automatic set_lights_time( time_preset preset );
    begin
      send_cmd(CMD_SET_RED_MS,    preset.red_time   );
      send_cmd(CMD_SET_YELLOW_MS, preset.yellow_time); 
      send_cmd(CMD_SET_GREEN_MS,  preset.green_time );
    end
  endtask
  
  task automatic check_lights( color_t color );
    begin
      if( {red_o, yellow_o, green_o} != color )
        begin
          $error("Error at %0t: Expected RYG=%b, Got %b%b%b", 
                $time, color, red_o, yellow_o, green_o);
          pass_flag = 1'b0;
        end
    end
  endtask

  task automatic check_state_duration( int ms, color_t color);
    begin
      repeat(ms * TICKS_PER_MS)
        begin
          @( posedge clk ); 
          check_lights(color);
        end
    end
  endtask

  task automatic check_green_blink( int half_period_ms, int blink_periods );
    begin
      color_t color;
      bit     is_on;
      is_on = 1'b0; 
      
      repeat(blink_periods * 2)
        begin
          color = color_t'{ 1'b0, 1'b0, is_on };
          check_state_duration(half_period_ms , color);
          is_on = !is_on;
        end
    end
  endtask

  task automatic check_yellow_blink( int half_period_ms, int periods_to_check );
    begin
      color_t color;
      bit     is_on;
      is_on = 1'b0;

      send_cmd(CMD_NOTRANSITION);
      
      repeat(periods_to_check * 2)
        begin
          color = color_t'{ 1'b0, is_on, 1'b0 };
          check_state_duration(half_period_ms, color);
          is_on = !is_on;
        end
    end
  endtask

  task automatic check_standart_cycle( bit change_preset, bit random, time_preset preset = default_preset );
    begin
      if( change_preset )
        begin
          if( random )
            begin
              preset.red_time    = $urandom_range(MIN_RANDOM_TIME_MS, MAX_RANDOM_TIME_MS);
              preset.yellow_time = $urandom_range(MIN_RANDOM_TIME_MS, MAX_RANDOM_TIME_MS);
              preset.green_time  = $urandom_range(MIN_RANDOM_TIME_MS, MAX_RANDOM_TIME_MS);
            end

          send_cmd(CMD_NOTRANSITION);

          set_lights_time(preset);
        end

      send_cmd(CMD_ENABLE);
      
      check_state_duration(preset.red_time, RED);
      check_state_duration(RED_YELLOW_MS, RED_YELLOW);
      check_state_duration(preset.green_time, GREEN);
      check_green_blink(BLINK_HALF_PERIOD_MS, BLINK_GREEN_TIME_TICK);
      check_state_duration(preset.yellow_time, YELLOW);
      check_state_duration(preset.red_time, RED);
    end
  endtask

  initial
    begin
      default_preset = {DEFAULT_RED_TIME,
                        DEFAULT_YELLOW_TIME,
                        DEFAULT_GREEN_TIME};

      wait(rst_done);
      
      $display( "Simulation start" );

      // Standart cycle defult values check
      check_standart_cycle(1'b0, 1'b0);

      // Standart cycle random checks
      repeat(N)
        check_standart_cycle(1'b1, 1'b1);

      // Yellow blink mode check
      check_yellow_blink(BLINK_HALF_PERIOD_MS, 5);

      // Disable check
      send_cmd(CMD_DISABLE);
      check_state_duration(100, OFF);

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );
      
      $display( "Simulation end" );
      $finish;
    end
endmodule
