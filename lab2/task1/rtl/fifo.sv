module fifo #(
  parameter DWIDTH             = 8,
  parameter AWIDTH             = 8,
  parameter SHOWAHEAD          = 1,
  parameter ALMOST_FULL_VALUE  = 250,
  parameter ALMOST_EMPTY_VALUE = 5,
  parameter REGISTER_OUTPUT    = 0
)(
  input  logic              clk_i,
  input  logic              srst_i,
  input  logic [DWIDTH-1:0] data_i,
  input  logic              wrreq_i,
  input  logic              rdreq_i,
  
  output logic [DWIDTH-1:0] q_o,
  output logic              empty_o,
  output logic              full_o,
  output logic [AWIDTH:0]   usedw_o,
  output logic              almost_full_o,
  output logic              almost_empty_o
);

  localparam int MAX_WORDS = 2**AWIDTH;

  logic [DWIDTH-1:0] ram_data_o;

  logic [AWIDTH:0]   usedw;
  
  logic [AWIDTH-1:0] wr_ptr;
  logic [AWIDTH-1:0] rd_ptr;
  logic [AWIDTH-1:0] next_rd_ptr;
  
  logic              wr_allowed;
  logic              rd_allowed;

  logic              ram_after_rst;

  simple_dual_port_ram #(
    .ADDR_WIDTH(AWIDTH),
    .DATA_WIDTH(DWIDTH)
  ) ram_i (
    .clk   ( clk_i       ),
    .we    ( wr_allowed  ),
    .waddr ( wr_ptr      ),
    .raddr ( next_rd_ptr ),
    .wdata ( data_i      ),
    .q     ( ram_data_o  )
  );

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        ram_after_rst <= 1'b1;
      else if( usedw != '0 )
        ram_after_rst <= 1'b0;
    end

  always_comb
    begin
      if( empty_o )
        begin
          if( ram_after_rst )
            q_o = 'x;
          else
            q_o = '0;
        end
      else
        q_o = ram_data_o;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        usedw <= '0;
      else if( ( wr_allowed  ) && ( !rd_allowed ) )
        usedw <= usedw + 1'd1;
      else if( ( !wr_allowed ) && ( rd_allowed  ) )
        usedw <= usedw - 1'd1;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        wr_ptr <= '0;
      else if( wr_allowed )
        wr_ptr <=  wr_ptr + 1'd1;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        rd_ptr <= '0;
      else if( rd_allowed )
        rd_ptr <= rd_ptr + 1'd1;
    end

  assign next_rd_ptr = rd_ptr + ( ( rd_allowed ) ? ( 1'd1 ) : ( 1'd0 ) );

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        full_o <= 1'b0;
      else if( ( wr_allowed  ) && ( !rd_allowed ) )
        full_o <= ( usedw == MAX_WORDS - 1'd1 );
      else if( ( !wr_allowed ) && ( rd_allowed  ) )
        full_o <= 1'b0;
      else
        full_o <= full_o;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        empty_o <= 1'b1;
      else if( ( rd_allowed ) && ( usedw == (AWIDTH+1)'(1) ) )
        empty_o <= 1'b1;
      else if( ( wr_allowed ) && ( usedw == '0             ) )
        empty_o <= 1'b1;
      else if( usedw > 0 )
        empty_o <= 1'b0;
      else
        empty_o <= empty_o;
    end
  
  assign usedw_o        = usedw;
  
  assign wr_allowed     = ( ( wrreq_i ) && ( !full_o  ) );
  assign rd_allowed     = ( ( rdreq_i ) && ( !empty_o ) );

  assign almost_empty_o = ( usedw < ALMOST_EMPTY_VALUE  );
  assign almost_full_o  = ( usedw >= ALMOST_FULL_VALUE  );

endmodule
