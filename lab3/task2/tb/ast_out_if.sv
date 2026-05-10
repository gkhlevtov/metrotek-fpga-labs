interface ast_out_if #(
  parameter int DATA_W    = 256,
  parameter int EMPTY_W   = $clog2(DATA_W/8) ? $clog2(DATA_W/8) : 1,
  parameter int CHANNEL_W = 10
)(
  input bit clk
);
  logic [DATA_W-1:0]    data;
  logic                 startofpacket;
  logic                 endofpacket;
  logic                 valid;
  logic [EMPTY_W-1:0]   empty;
  logic [CHANNEL_W-1:0] channel;
  logic                 ready;

  clocking mon_cb @( posedge clk );
    input data, startofpacket, endofpacket, valid, empty, channel, ready;
  endclocking
endinterface
