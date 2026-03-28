module simple_dual_port_ram #(
  parameter int ADDR_WIDTH = 8,
	parameter int	DATA_WIDTH = 8
)( 
	input  logic                  clk,
  input  logic                  we,
  input  logic [ADDR_WIDTH-1:0] waddr,
	input  logic [ADDR_WIDTH-1:0] raddr,
	input  logic [DATA_WIDTH-1:0] wdata, 
	output logic [DATA_WIDTH-1:0] q
);
	localparam int WORDS = 1 << ADDR_WIDTH;

	logic [DATA_WIDTH-1:0] ram [0:WORDS-1];

	always_ff @( posedge clk )
    begin
      if( we )
        ram[waddr] <= wdata;

      q <= ram[raddr];
    end
endmodule
