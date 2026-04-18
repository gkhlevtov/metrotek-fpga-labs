interface lifo_if #(
  parameter int DWIDTH       = 16,
  parameter int AWIDTH       = 8,
  parameter int ALMOST_FULL  = 2,
  parameter int ALMOST_EMPTY = 2
)(
  input bit clk
);
  logic              srst_i;
  logic              wrreq_i;
  logic [DWIDTH-1:0] data_i;
  logic              rdreq_i;

  logic [DWIDTH-1:0] q_o;
  logic              almost_empty_o;
  logic              empty_o;
  logic              almost_full_o;
  logic              full_o;
  logic [AWIDTH:0]   usedw_o;

  clocking drv_cb @( posedge clk );
    output srst_i, wrreq_i, data_i, rdreq_i;
    input  q_o, almost_empty_o, empty_o, almost_full_o, full_o, usedw_o;
  endclocking

  clocking mon_cb @( posedge clk );
    input srst_i, wrreq_i, data_i, rdreq_i, q_o, almost_empty_o, empty_o, almost_full_o, full_o, usedw_o;
  endclocking
endinterface
