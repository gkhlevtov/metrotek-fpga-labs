module dc_fifo #(
  parameter DWIDTH             = 32,
  parameter AWIDTH             = 8,
  parameter ALMOST_FULL_VALUE  = ( AWIDTH > 2 ) ? ( 2 ** AWIDTH - 5 ) : ( 2 ** AWIDTH - 1 ),
  parameter ALMOST_EMPTY_VALUE = ( AWIDTH > 2 ) ? ( 5 ) : ( 2 ** ( AWIDTH - 1 ) ),
  parameter SHOWAHEAD          = 1,
  parameter REGISTER_OUTPUT    = 0
)(
  input  logic              wr_clk_i,
  input  logic              rd_clk_i,

  input  logic              wr_rst_i,
  input  logic              rd_rst_i,

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

  logic [AWIDTH:0]   wr_ptr_bin;
  logic [AWIDTH:0]   rd_ptr_bin;
  
  logic [AWIDTH:0]   rd_ptr_bin_next;

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

  logic [AWIDTH-1:0] ram_rd_ptr;
  logic [DWIDTH-1:0] ram_data_o;
  
  logic [AWIDTH:0]   wrusedw;
  logic [AWIDTH:0]   rdusedw;
  
  logic              rd_enable;

  simple_dual_two_clocks #(
    .DWIDTH  ( DWIDTH                 ),
    .AWIDTH  ( AWIDTH                 )
  ) ram_inst (
    .wr_clk  ( wr_clk_i               ),
    .rd_clk  ( rd_clk_i               ),
    .wr_en   ( wr_allowed             ),
    .rd_en   ( rd_enable              ),
    .wr_addr ( wr_ptr_bin[AWIDTH-1:0] ),
    .rd_addr ( ram_rd_ptr             ),
    .data_i  ( data_i                 ),
    .data_o  ( ram_data_o             )
  );
 
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
  
  assign rd_enable = ( SHOWAHEAD ) ? ( 1'b1 ) : rd_allowed;

  // bin to gray
  assign wr_ptr_gray = bin2gray(wr_ptr_bin);
  assign rd_ptr_gray = bin2gray(rd_ptr_bin);

  // sync
  always_ff @( posedge rd_clk_i )
    begin
      if( rd_rst_i )
        begin
          wr_ptr_gray_s1 <= (AWIDTH+1)'(0);
          wr_ptr_gray_s2 <= (AWIDTH+1)'(0);
        end
      else
        begin
          wr_ptr_gray_s1 <= wr_ptr_gray;
          wr_ptr_gray_s2 <= wr_ptr_gray_s1;
        end
    end

  always_ff @( posedge wr_clk_i )
    begin
      if( wr_rst_i )
        begin
          rd_ptr_gray_s1 <= (AWIDTH+1)'(0);
          rd_ptr_gray_s2 <= (AWIDTH+1)'(0);
        end
      else
        begin
          rd_ptr_gray_s1 <= rd_ptr_gray;
          rd_ptr_gray_s2 <= rd_ptr_gray_s1;
        end
    end
  
  // gray to bin
  assign wr_ptr_bin_rd = gray2bin(wr_ptr_gray_s2);
  assign rd_ptr_bin_wr = gray2bin(rd_ptr_gray_s2);
 
  // allowed
  assign wr_allowed = wrreq_i && !full_o;
  assign rd_allowed = rdreq_i && !empty_o;

  // rd_ptr_bin_next
  assign rd_ptr_bin_next = rd_ptr_bin + ( ( rd_allowed ) ? ( 1'd1 ) : ( 1'd0 ) );
  
  // ram reading pointer
  assign ram_rd_ptr = ( SHOWAHEAD ) ? ( rd_ptr_bin_next[AWIDTH-1:0] ) : ( rd_ptr_bin[AWIDTH-1:0] );
  
  // wr_ptr_bin
  always_ff @( posedge wr_clk_i )
    begin
      if( wr_rst_i )
        wr_ptr_bin <= (AWIDTH+1)'(0);
      else if( wr_allowed )
        wr_ptr_bin <= wr_ptr_bin + 1'd1;
    end
  
  // rd_ptr_bin
  always_ff @( posedge rd_clk_i )
    begin
      if( rd_rst_i )
        rd_ptr_bin <= (AWIDTH+1)'(0);
      else if( rd_allowed )
        rd_ptr_bin <= rd_ptr_bin_next;
    end
  
  // memory read
  generate
    if( REGISTER_OUTPUT == 1'b0 )
      begin
        assign data_o = ram_data_o;
      end
    else
      begin
        always_ff @( posedge rd_clk_i )
          begin
            if( rd_rst_i )
              data_o <= DWIDTH'(0);
            else if( SHOWAHEAD || rd_allowed )
              data_o <= ram_data_o;
          end
      end
  endgenerate
  
  // usedw
  always_ff @( posedge wr_clk_i )
    begin
      if( wr_rst_i )
        wrusedw <= (AWIDTH+1)'(0);
      else
        wrusedw <= wr_ptr_bin - rd_ptr_bin_wr; 
    end

  always_ff @( posedge rd_clk_i )
    begin
      if( rd_rst_i )
        rdusedw <= (AWIDTH+1)'(0);
      else
        rdusedw <= wr_ptr_bin_rd - rd_ptr_bin;
    end

  assign wrusedw_o = wrusedw;
  assign rdusedw_o = rdusedw;

  // full & empty
  assign full_o  = ( wr_ptr_bin[AWIDTH]     != rd_ptr_bin_wr[AWIDTH]     ) &&
                   ( wr_ptr_bin[AWIDTH-1:0] == rd_ptr_bin_wr[AWIDTH-1:0] );
  assign empty_o = ( rd_ptr_bin == wr_ptr_bin_rd );
  
  // almost full & empty
  assign almost_full_o  = ( wrusedw >= ALMOST_FULL_VALUE  );
  assign almost_empty_o = ( rdusedw <= ALMOST_EMPTY_VALUE );
endmodule
