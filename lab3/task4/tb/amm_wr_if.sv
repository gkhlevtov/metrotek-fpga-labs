interface amm_wr_if #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = DATA_WIDTH / 8
)(
  input bit clk
);
  logic [ADDR_WIDTH-1:0] wr_address;
  logic                  wr_write;
  logic [DATA_WIDTH-1:0] wr_writedata;
  logic [BYTE_CNT-1:0  ] wr_byteenable;

  logic                  wr_waitrequest;

  clocking slv_cb @( posedge clk );
    output wr_waitrequest;
    input  wr_address, wr_write, wr_writedata, wr_byteenable;
  endclocking

  clocking mon_cb @( posedge clk );
    input wr_address, wr_write, wr_writedata, wr_byteenable, wr_waitrequest;
  endclocking

  modport SLAVE   ( clocking slv_cb, input clk );
  modport MONITOR ( clocking mon_cb, input clk );
endinterface