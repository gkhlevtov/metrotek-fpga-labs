interface wr_if #(
  parameter int DWIDTH = 32
)(
  input bit clk;	
);
  logic [DWIDTH-1:0] data;
  logic              wrreq;
  logic              usedw;
  logic              full;
  logic              almost_full;
endinterface 
