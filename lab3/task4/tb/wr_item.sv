class wr_item #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10,
  parameter int BYTE_CNT   = DATA_WIDTH/8
);
  logic [ADDR_WIDTH-1:0] address;
  logic [DATA_WIDTH-1:0] writedata;
  logic [BYTE_CNT-1:0  ] byteenable;

  int unsigned         req_time;

  function wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) copy();
    wr_item #( DATA_WIDTH, ADDR_WIDTH, BYTE_CNT ) copy_item = new();

    copy_item.address    = this.address;
    copy_item.writedata  = this.writedata;
    copy_item.byteenable = this.byteenable;

    copy_item.req_time   = this.req_time;

    return copy_item;
  endfunction
endclass