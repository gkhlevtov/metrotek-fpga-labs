interface ctrl_if (
  input bit clk
);
  logic        rst;
  logic [15:0] offset;

  clocking drv_cb @( posedge clk );
    output rst, offset;
  endclocking

  clocking mon_cb @( posedge clk );
    input rst, offset;
  endclocking
endinterface