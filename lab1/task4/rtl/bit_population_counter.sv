module bit_population_counter #(
  parameter int WIDTH = 8
)(
  input  logic                   clk_i,
  input  logic                   srst_i,

  input  logic [WIDTH-1:0]       data_i,
  input  logic                   data_val_i,

  output logic [$clog2(WIDTH):0] data_o,
  output logic                   data_val_o
);

  localparam int N_BLOCKS  = WIDTH / 8;
  localparam int TAIL_LEN  = WIDTH % 8;
  localparam int CNT_WIDTH = ( N_BLOCKS > 0 ) ? $clog2(N_BLOCKS+1) : 1;

  logic [WIDTH-1:0]       data_reg;
  logic [$clog2(WIDTH):0] acc;
  logic [CNT_WIDTH-1:0]   idx;
  logic                   busy;

  function automatic logic [$clog2(WIDTH):0] sum_block( input logic [7:0] b );
    return b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + b[7];
  endfunction

  function automatic logic [$clog2(WIDTH):0] sum_tail( input logic [TAIL_LEN-1:0] b );
    logic [$clog2(WIDTH):0] sum;
    sum = '0;
    for( int i = 0; i < TAIL_LEN; i++ )
      sum += b[i];
    return sum;
  endfunction

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        begin
          acc        <= '0;
          idx        <= '0;
          busy       <= 1'b0;
          data_o     <= '0;
          data_val_o <= 1'b0;
        end
      else
        begin
          data_val_o <= 1'b0;

          if( ( !busy ) && ( data_val_i ) )
            begin
              data_reg <= data_i;
              acc      <= '0;
              idx      <= '0;
              busy     <= 1'b1;
            end
          else if( busy )
            begin
              if( idx < N_BLOCKS )
                begin
                  acc <= acc + sum_block(data_reg[idx*8 +: 8]);
                  idx <= idx + 1'b1;
                end
              else
                begin
                  if( TAIL_LEN != 0 )
                    data_o <= acc + sum_tail(data_reg[WIDTH-1 -: TAIL_LEN]);
                  else
                    data_o <= acc;
                  data_val_o <= 1'b1;
                  busy       <= 1'b0;
                end
            end
        end
    end

endmodule
