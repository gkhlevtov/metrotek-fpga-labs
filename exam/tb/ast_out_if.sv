interface ast_out_if #(
  parameter int DATA_W  = 64,
  parameter int EMPTY_W = ( $clog2(DATA_W/8) ) ? ( $clog2(DATA_W/8) ) : ( 1 )
)(
  input bit clk
);
  logic [DATA_W-1:0]  data;
  logic               sop;
  logic               eop;
  logic               valid;
  logic [EMPTY_W-1:0] empty;
  logic               ready;

  clocking mon_cb @( posedge clk );
    input  data, valid, sop, eop, empty, ready;
  endclocking

  clocking drv_cb @( posedge clk );
    output ready;
  endclocking
endinterface