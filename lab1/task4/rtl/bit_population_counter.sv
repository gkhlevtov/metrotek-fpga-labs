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

  localparam int BLOCK_LEN = 8;
  localparam int N_BLOCKS  = WIDTH / BLOCK_LEN;
  localparam int STAGES    = ( WIDTH + BLOCK_LEN - 1 ) / BLOCK_LEN;

  logic [$clog2(WIDTH):0] pipe_acc  [0:STAGES];
  logic [WIDTH-1:0]       pipe_data [0:STAGES];
  logic                   pipe_val  [0:STAGES];

  function automatic logic [$clog2(BLOCK_LEN):0] count_ones_block( input logic [BLOCK_LEN-1:0] b );
    logic [$clog2(BLOCK_LEN):0] sum;
    sum = '0;
    for( int i = 0; i < BLOCK_LEN; i++ )
      sum += b[i];
    return sum;
  endfunction

  always_comb
    begin
      pipe_acc[0]  = '0;
      pipe_data[0] = data_i;
      pipe_val[0]  = data_val_i;
    end

  genvar i;
  generate
    for( i = 0; i < STAGES; i++ )
      begin: stages
        localparam int CUR_WIDTH = ( ( i == STAGES-1 ) && ( WIDTH % BLOCK_LEN != 0 ) ) 
                                    ? ( WIDTH % BLOCK_LEN ) 
                                    : ( BLOCK_LEN );

        always_ff @( posedge clk_i )
          begin
            if( srst_i )
              begin
                pipe_val[i+1]  <= 1'b0;
                pipe_acc[i+1]  <= '0;
                pipe_data[i+1] <= '0;
              end
            else
              begin
                pipe_val[i+1] <= pipe_val[i];
                
                if( pipe_val[i] )
                  begin
                    pipe_acc[i+1]  <= pipe_acc[i] + count_ones_block(pipe_data[i][CUR_WIDTH-1:0]);
                    pipe_data[i+1] <= pipe_data[i] >> CUR_WIDTH;
                  end
              end
          end
      end
  endgenerate

  assign data_o     = pipe_acc[STAGES];
  assign data_val_o = pipe_val[STAGES];

endmodule
