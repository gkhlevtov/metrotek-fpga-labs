module simple_dual_two_clocks #(
  parameter DWIDTH    = 32,
  parameter AWIDTH    = 8,
  parameter RAM_DEPTH = ( 1 << AWIDTH ),
  parameter OUT_REG   = 0
)(
  input  logic              wr_clk_i,
  input  logic              rd_clk_i,
  input  logic              rd_rst_i,
  input  logic              wr_en_i,
  input  logic              rd_en_i,
  input  logic              rd_reg_en_i,
  input  logic [AWIDTH-1:0] wr_addr_i,
  input  logic [AWIDTH-1:0] rd_addr_i,
  input  logic [DWIDTH-1:0] data_i,
  output logic [DWIDTH-1:0] data_o
);

  logic [DWIDTH-1:0] mem [0:RAM_DEPTH-1];

  logic [DWIDTH-1:0] ram_dout;

  always_ff @( posedge wr_clk_i )
    begin
      if( wr_en_i )
        mem[wr_addr_i] <= data_i;
    end

  always_ff @( posedge rd_clk_i )
    begin
      if( rd_en_i )
        ram_dout <= mem[rd_addr_i];
    end

  generate
    if( OUT_REG == 0 )
      begin
        assign data_o = ram_dout;
      end
    else
      begin
        always_ff @( posedge rd_clk_i )
          begin
            if( rd_rst_i )
              data_o <= DWIDTH'(0);
            else if( rd_reg_en_i )
              data_o <= ram_dout;
          end
      end
  endgenerate
endmodule
