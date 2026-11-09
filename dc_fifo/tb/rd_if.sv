interface rd_if #(
  parameter int DWIDTH = 32
)(
  input bit clk;	
);
  logic [DWIDTH-1:0] data;
  logic              rdreq;
  logic              usedw;
  logic              empty;
  logic              almost_empty;
endinterface
