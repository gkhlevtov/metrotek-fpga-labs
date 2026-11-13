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
  logic [AWIDTH:0]   ram_rd_ptr_bin;
  logic [AWIDTH:0]   fifo_rd_ptr_bin;

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

  logic              ram_empty;
  logic              ram_rd_en;
  logic              ram_reg_en;

  logic [AWIDTH:0]   wrusedw;
  logic [AWIDTH:0]   rdusedw;

  simple_dual_two_clocks #(
    .DWIDTH      ( DWIDTH                     ),
    .AWIDTH      ( AWIDTH                     ),
    .OUT_REG     ( REGISTER_OUTPUT            )
  ) ram_inst (
    .wr_clk_i    ( wr_clk_i                   ),
    .rd_clk_i    ( rd_clk_i                   ),
    .rd_rst_i    ( rd_rst_i                   ),
    .wr_en_i     ( wr_allowed                 ),
    .rd_en_i     ( ram_rd_en                  ),
    .rd_reg_en_i ( ram_reg_en                 ),
    .wr_addr_i   ( wr_ptr_bin[AWIDTH-1:0]     ),
    .rd_addr_i   ( ram_rd_ptr_bin[AWIDTH-1:0] ),
    .data_i      ( data_i                     ),
    .data_o      ( data_o                     )
  );

  function automatic logic [AWIDTH:0] bin2gray( input logic [AWIDTH:0] bin );
    return ( bin >> 1 ) ^ bin;
  endfunction

  function automatic logic [AWIDTH:0] gray2bin( input logic [AWIDTH:0] gray );
    logic [AWIDTH:0] bin;
    bin[AWIDTH] = gray[AWIDTH];

    for( int i = AWIDTH - 1; i >= 0; i = i - 1 )
      bin[i] = bin[i+1] ^ gray[i];
    return bin;
  endfunction

  assign wr_ptr_gray = bin2gray(wr_ptr_bin);
  assign rd_ptr_gray = bin2gray(fifo_rd_ptr_bin);

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

  assign wr_ptr_bin_rd = gray2bin(wr_ptr_gray_s2);
  assign rd_ptr_bin_wr = gray2bin(rd_ptr_gray_s2);

  assign wr_allowed = wrreq_i && !full_o;
  assign rd_allowed = rdreq_i && !empty_o;

  always_ff @( posedge wr_clk_i )
    begin
      if( wr_rst_i )
        wr_ptr_bin <= (AWIDTH+1)'(0);
      else if( wr_allowed )
        wr_ptr_bin <= wr_ptr_bin + 1'd1;
    end

  always_ff @( posedge rd_clk_i )
    begin
      if( rd_rst_i )
        ram_rd_ptr_bin <= (AWIDTH+1)'(0);
      else if( ram_rd_en )
        ram_rd_ptr_bin <= ram_rd_ptr_bin + 1'd1;
    end

  always_ff @( posedge rd_clk_i )
    begin
      if( rd_rst_i )
        fifo_rd_ptr_bin <= (AWIDTH+1)'(0);
      else if( rd_allowed )
        fifo_rd_ptr_bin <= fifo_rd_ptr_bin + 1'd1;
    end

  generate
    case( { 1'(SHOWAHEAD), 1'(REGISTER_OUTPUT) } )
    2'b00:
      begin
        assign ram_rd_en  = rd_allowed;
        assign empty_o    = ram_empty;
        assign ram_reg_en = 1'b0;
      end

    2'b01:
      begin
        assign ram_rd_en = rd_allowed;
        assign empty_o   = ram_empty;

        always_ff @( posedge rd_clk_i )
          begin
            if( rd_rst_i )
              ram_reg_en <= 1'b0;
            else
              ram_reg_en <= ram_rd_en;
          end
      end

    2'b10:
      begin
        logic  stage1_valid;

        assign ram_rd_en  = !ram_empty && ( !stage1_valid || rd_allowed );
        assign ram_reg_en = 1'b0;
        assign empty_o    = !stage1_valid;

        always_ff @( posedge rd_clk_i )
          begin
            if( rd_rst_i )
              stage1_valid <= 1'b0;
            else if( ram_rd_en )
              stage1_valid <= 1'b1;
            else if( rd_allowed )
              stage1_valid <= 1'b0;
          end
      end

    2'b11:
      begin
        logic stage1_valid;
        logic stage2_valid;

        assign ram_rd_en  = !ram_empty   && ( !stage1_valid || ram_reg_en );
        assign ram_reg_en = stage1_valid && ( !stage2_valid || rd_allowed );
        assign empty_o    = !stage2_valid;

        always_ff @( posedge rd_clk_i )
          begin
            if( rd_rst_i )
              begin
                stage1_valid <= 1'b0;
                stage2_valid <= 1'b0;
              end
            else
              begin
                if( ram_rd_en )
                  stage1_valid <= 1'b1;
                else if( ram_reg_en )
                  stage1_valid <= 1'b0;

                if( ram_reg_en )
                  stage2_valid <= 1'b1;
                else if( rd_allowed )
                  stage2_valid <= 1'b0;
              end
          end
      end
    endcase
  endgenerate

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
        rdusedw <= wr_ptr_bin_rd - fifo_rd_ptr_bin;
    end

  assign wrusedw_o = wrusedw;
  assign rdusedw_o = rdusedw;

  assign full_o    = ( wr_ptr_bin[AWIDTH]     != rd_ptr_bin_wr[AWIDTH]     ) &&
                     ( wr_ptr_bin[AWIDTH-1:0] == rd_ptr_bin_wr[AWIDTH-1:0] );
  assign ram_empty = ( ram_rd_ptr_bin == wr_ptr_bin_rd );

  assign almost_full_o  = ( wrusedw >= ALMOST_FULL_VALUE  );
  assign almost_empty_o = ( rdusedw <= ALMOST_EMPTY_VALUE );
endmodule
