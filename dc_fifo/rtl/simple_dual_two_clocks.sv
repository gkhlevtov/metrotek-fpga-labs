module simple_dual_two_clocks #(
  parameter DWIDTH    = 32,
  parameter AWIDTH    = 8,
  parameter RAM_DEPTH = ( 1 << AWIDTH )
)(
  input  logic              wr_clk,
  input  logic              rd_clk,
  input  logic              wr_en,
  input  logic              rd_en,
  input  logic [AWIDTH-1:0] wr_addr,
  input  logic [AWIDTH-1:0] rd_addr,
  input  logic [DWIDTH-1:0] data_i,
  output logic [DWIDTH-1:0] data_o
);
  logic [DWIDTH-1:0] mem [0:RAM_DEPTH-1];

  always_ff @( posedge wr_clk )
    begin
      if( wr_en )
        begin
   	  mem[wr_addr] <= data_i;
        end
    end

  always_ff @( posedge rd_clk )
    begin
      if( rd_en )
        begin
          data_o <= mem[rd_addr];
        end
    end
endmodule
