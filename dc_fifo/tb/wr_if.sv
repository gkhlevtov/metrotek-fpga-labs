interface wr_if #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
)(
  input bit clk	
);
  logic [DWIDTH-1:0] data;
  logic              wrreq;
  logic [AWIDTH:0]   usedw;
  logic              full;
  logic              almost_full;
endinterface 
