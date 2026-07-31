class rd_item #(
  parameter int DATA_WIDTH = 64,
  parameter int ADDR_WIDTH = 10
);
  logic [ADDR_WIDTH-1:0] address;
  logic [DATA_WIDTH-1:0] readdata;

  int unsigned         req_time;
  int unsigned         resp_time;
  int unsigned         seq_num;

  function rd_item #( DATA_WIDTH, ADDR_WIDTH ) copy();
    rd_item #( DATA_WIDTH, ADDR_WIDTH ) copy_item = new();

    copy_item.address  = this.address;
    copy_item.readdata = this.readdata;

    copy_item.req_time  = this.req_time;
    copy_item.resp_time = this.resp_time;
    copy_item.seq_num   = this.seq_num;

    return copy_item;
  endfunction
endclass