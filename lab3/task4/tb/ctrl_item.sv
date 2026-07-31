class ctrl_item #(
  parameter int ADDR_WIDTH = 10
);
  bit [ADDR_WIDTH-1:0] base_addr;
  bit [ADDR_WIDTH-1:0] length;

  function void randomize_manual();
    base_addr = $urandom();
    length    = $urandom_range( 1, ( ( 1 << ADDR_WIDTH ) - 1 ) );
  endfunction

  function ctrl_item #( ADDR_WIDTH ) copy();
    ctrl_item #( ADDR_WIDTH ) copy_item = new();
    copy_item.base_addr = this.base_addr;
    copy_item.length    = this.length;
    return copy_item;
  endfunction
endclass