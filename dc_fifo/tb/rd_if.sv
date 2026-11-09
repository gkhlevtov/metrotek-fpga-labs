interface rd_if #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
)(
  input bit clk	
);
  logic [DWIDTH-1:0] data;
  logic              rdreq;
  logic [AWIDTH:0]   usedw;
  logic              empty;
  logic              almost_empty;
endinterface
