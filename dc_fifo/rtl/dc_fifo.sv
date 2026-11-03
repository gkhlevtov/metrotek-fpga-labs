module dc_fifo #(
  parameter DWIDTH             = 32,
  parameter AWIDTH             = 8,
  parameter ALMOST_FULL_VALUE  = 2 ** AWIDTH - 5,
  parameter ALMOST_EMPTY_VALUE = 5
)(
  input  logic              wr_clk_i,
  input  logic              rd_clk_i,

  input  logic              rst_i,

  input  logic [DWIDTH-1:0] data_i,
  input  logic              wrreq_i,
  input  logic              rdreq_i,

  output logic [DWIDTH-1:0] data_o,

  output logic [AWIDTH:0]   wrusedw_o,
  output logic [AWIDTH:0]   rdusedw_o,

  output logic              full_o,
  output logic              almost_full_o,
  output logic              empty_o,
  output logic              almost_empty_o
);

  logic [DWIDTH-1:0] memory [2**AWIDTH-1:0];

  logic [AWIDTH:0]   wr_ptr_bin;
  logic [AWIDTH:0]   rd_ptr_bin;

  logic [AWIDTH:0]   wr_ptr_gray;
  logic [AWIDTH:0]   rd_ptr_gray;

  logic [AWIDTH:0]   wr_ptr_gray_s1;
  logic [AWIDTH:0]   wr_ptr_gray_s2;

  logic [AWIDTH:0]   rd_ptr_gray_s1;
  logic [AWIDTH:0]   rd_ptr_gray_s2;

  logic [AWIDTH:0]   wr_ptr_bin_rd;
  logic [AWIDTH:0]   rd_ptr_bin_wr;

  logic              rd_allowed;
  logic              wr_allowed;

  logic [AWIDTH:0]   wrusedw;
  logic [AWIDTH:0]   rdusedw;

  logic              full;
  logic              empty;
  logic              almost_full;
  logic              almost_empty;
  
  function automatic logic [AWIDTH:0] bin2gray( input logic [AWIDTH:0] bin );
    return ( bin >> 1) ^ bin;
  endfunction
  
  function automatic logic [AWIDTH:0] gray2bin( input logic [AWIDTH:0] gray );
    logic [AWIDTH:0] bin;
    bin[AWIDTH] = gray[AWIDTH];
    for( int i = AWIDTH - 1; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
    return bin;
  endfunction

  // to gray
  assign wr_ptr_gray = bin2gray(wr_ptr_bin);
  assign rd_ptr_gray = bin2gray(rd_ptr_bin);

  // sync
  always_ff @( posedge rd_clk_i or posedge rst_i )
    begin
      if ( rst_i )
        begin
          wr_ptr_gray_s1 <= '0;
          wr_ptr_gray_s2 <= '0;
        end
      else
        begin
          wr_ptr_gray_s1 <= wr_ptr_gray;
          wr_ptr_gray_s2 <= wr_ptr_gray_s1;
        end
    end

  always_ff @( posedge wr_clk_i or posedge rst_i )
    begin
      if ( rst_i )
        begin
          rd_ptr_gray_s1 <= '0;
          rd_ptr_gray_s2 <= '0;
        end
      else
        begin
          rd_ptr_gray_s1 <= rd_ptr_gray;
          rd_ptr_gray_s2 <= rd_ptr_gray_s1;
        end
    end
  
  // to bin
  assign wr_ptr_bin_rd = gray2bin(rd_ptr_gray_s2);
  assign rd_ptr_bin_wr = gray2bin(wr_ptr_gray_s2);
  
  // wr_ptr_bin
  always_ff @( posedge wr_clk_i or posedge rst_i )
    begin
      if( rst_i )
        wr_ptr_bin <= '0;
      else if( wrreq_i && !full )
        wr_ptr_bin <= wr_ptr_bin + 1'd1;
    end
  
  // rd_ptr_bin
  always_ff @( posedge rd_clk_i or posedge rst_i )
    begin
      if( rst_i )
        rd_ptr_bin <= '0;
      else if( rdreq_i && !empty )
        rd_ptr_bin <= rd_ptr_bin + 1'd1;
    end
  
  // memory
  always_ff @( posedge wr_clk_i )
    begin
      if( wr_allowed )
        memory[wr_ptr_bin[AWIDTH-1:0]] <= data_i;
    end
  
  always_ff @( posedge rd_clk_i )
    begin
      if( rd_allowed )
        data_o <= memory[rd_ptr_bin[AWIDTH-1:0]];
    end
  
  // allowed
  assign wr_allowed = wrreq_i && !full_o;
  assign rd_allowed = rdreq_i && !empty_o;
  
  // usedw
  always_ff @( posedge wr_clk_i or posedge rst_i )
    begin
      if( rst_i )
        wrusedw <= '0;
      else
        wrusedw <= wr_ptr_bin - rd_ptr_bin_wr; 
    end

  always_ff @( posedge rd_clk_i or posedge rst_i )
    begin
      if( rst_i )
        rdusedw <= '0;
      else
        rdusedw <= wr_ptr_bin_rd - rd_ptr_bin;
    end

  assign wrusedw_o = wrusedw;
  assign rdusedw_o = rdusedw;

  // full & empty
  assign full_o  = ( wr_ptr_bin[AWIDTH]     != rd_ptr_bin_wr[AWIDTH]     ) &&
                   ( wr_ptr_bin[AWIDTH-1:0] == rd_ptr_bin_wr[AWIDTH-1:0] );
  assign empty_o = ( rd_ptr_bin == wr_ptr_bin_rd );
  
  // almost
  assign almost_full_o  = ( wrusedw >= ALMOST_FULL_VALUE  );
  assign almost_empty_o = ( rdusedw <= ALMOST_EMPTY_VALUE );
endmodule
