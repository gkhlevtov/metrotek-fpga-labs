interface amm_rd_if #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
)(
  input bit clk
);
  logic [ADDR_WIDTH-1:0] rd_address;
  logic                  rd_read;

  logic [DATA_WIDTH-1:0] rd_readdata;
  logic                  rd_readdatavalid;
  
  logic                  rd_waitrequest;

  clocking slv_cb @( posedge clk );
    output rd_readdata, rd_readdatavalid, rd_waitrequest;
    input  rd_address, rd_read;
  endclocking

  clocking mon_cb @( posedge clk );
    input rd_address, rd_read, rd_readdata, rd_readdatavalid, rd_waitrequest;
  endclocking

  modport SLAVE   ( clocking slv_cb, input clk );
  modport MONITOR ( clocking mon_cb, input clk );
endinterface