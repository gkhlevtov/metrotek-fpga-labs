interface amm_ctrl_if #(
  parameter int ADDR_WIDTH = 10
)(
  input bit clk
);
  logic                  srst;
  logic [ADDR_WIDTH-1:0] base_addr;
  logic [ADDR_WIDTH-1:0] length;
  logic                  run;
  logic                  waitrequest;

  clocking drv_cb @( posedge clk );
    output srst, base_addr, length, run;
    input  waitrequest;
  endclocking

  clocking mon_cb @( posedge clk );
    input srst, base_addr, length, run, waitrequest;
  endclocking

  modport DRIVER  ( clocking drv_cb, input clk );
  modport MONITOR ( clocking mon_cb, input clk );
endinterface