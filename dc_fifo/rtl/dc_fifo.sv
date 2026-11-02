module dc_fifo(
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

  logic [DWIDTH-1:0] memory [(2**AWIDTH-1):0];

  logic [AWIDTH:0] wr_ptr;
  logic [AWIDTH:0] rd_ptr;

  logic [AWIDTH:0] g_wr_ptr;
  logic [AWIDTH:0] g_rd_ptr;

  logic [AWIDTH:0] s1_wr_ptr;
  logic [AWIDTH:0] s2_wr_ptr;

  logic [AWIDTH:0] s1_rd_ptr;
  logic [AWIDTH:0] s2_rd_ptr;

  logic [AWIDTH:0] bin_wr_ptr;
  logic [AWIDTH:0] bin_rd_ptr;

  logic              full;
  logic              almost_full;
  logic              empty;
  logic              almost_empty;

  logic [AWIDTH:0]   wrusedw;
  logic [AWIDTH:0]   rdusedw;

  logic              rd_allowed;
  logic              wr_allowed;

  // to gray
  always_ff @( posedge wr_clk_i );
    begin
      g_wr_ptr <= wr_ptr ^ ( wr_ptr >> 1 );
    end

  always_ff @( posedge rd_clk_i );
    begin
      g_rd_ptr <= rd_ptr ^ ( rd_ptr >> 1 );
    end

  // sync
  always_ff @( posedge rd_clk_i or posedge rst_i )
    begin
      if ( rst_i )
        begin
          s1_wr_ptr <= '0;
          s2_wr_ptr <= '0;
        end
      else
        begin
          s1_wr_ptr <= g_wr_ptr;
          s2_wr_ptr <= s1_wr_ptr;
        end
    end

  always_ff @( posedge wr_clk_i or posedge rst_i )
    begin
      if ( rst_i )
        begin
          s1_rd_ptr <= '0;
          s2_rd_ptr <= '0;
        end
      else
        begin
          s1_rd_ptr <= g_rd_ptr;
          s2_rd_ptr <= s1_rd_ptr;
        end
    end
  
  // to bin
  always_comb
    begin
      bin_rd_ptr[AWIDTH-1] = s2_rd_ptr[AWIDTH-1];
      for( int i = AWIDTH-2; i >= 0; i = i - 1 )
        bin_rd_ptr[i] = bin_rd_ptr[i+1] ^ s2_rd_ptr[i];
    end

  always_comb
    begin
      bin_wr_ptr[AWIDTH-1] = s2_wr_ptr[AWIDTH-1];
      for( int i = AWIDTH-2; i >= 0; i = i - 1 )
        bin_wr_ptr[i] = bin_wr_ptr[i+1] ^ s2_wr_ptr[i];
    end
  
  // usedw
  always_ff @( posedge wr_clk_i or posedge rst )
    begin
      if( rst_i )
        wrusedw <= '0;
      else
        wrusedw <= wr_ptr - bin_rd_ptr; 
    end

  always_ff @( posedge rd_clk_i or posedge rst )
    begin
      if( rst_i )
        rdusedw <= '0;
      else
        rdusedw <= bin_wr_ptr - rd_ptr;
    end

  assign wrusedw_o = wrusedw;
  assign rdusedw_o = rdusedw;

  // wr_ptr
  always_ff @( posedge wr_clk_i or posedge rst_i )
    begin
      if( rst )
        wr_ptr <= '0;
      else if( wrreq_i && !full )
        wr_ptr <= wr_ptr + 1'd1;
    end
  
  // rd_ptr
  always_ff @( posedge rd_clk_i or posedge rst_i )
    begin
      if( rst )
        rd_ptr <= '0;
      else if( rdreq_i && !empty )
        rd_ptr <= rd_ptr + 1'd1;
    end
  
  // Memory
  always_ff @( posedge wr_clk_i )
    begin
      if( wr_allowed )
        memory[wr_ptr[AWIDTH-1:0]] <= data_i;
    end
  
  always_ff @( posedge rd_clk_i )
    begin
      if( rd_allowed )
        data_o <= memory[rd_ptr[AWIDTH-1:0]];
    end
  
  assign wr_allowed = ( ( wrreq_i ) && ( !full_o  ) );
  assign rd_allowed = ( ( rdreq_i ) && ( !empty_o ) );

  // outputs
  assign empty_o = ( g_rd_ptr == s2_wr_ptr );

  assign full_o  = ( g_wr_ptr[AWIDTH]     != s2_rd_ptr[AWIDTH]     ) &&
                   ( g_wr_ptr[AWIDTH-1]   != s2_rd_ptr[AWIDTH-1]   ) &&
                   ( g_wr_ptr[AWIDTH-2:0] == s2_rd_ptr[AWIDTH-2:0] );

  assign almost_full_o  = ( wrusedw >= ALMOST_FULL_VALUE  );
  assign almost_empty_o = ( rdusedw <= ALMOST_EMPTY_VALUE );
endmodule