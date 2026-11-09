interface rst_if #(
  parameter bit RESET_LOW = 1
);
  logic rst;
  
  initial
    rst = ( !RESET_LOW )
  
  function void assert_rst()
    rst = ( RESET_LOW ) ? ( 1'b0 ) : ( 1'b1 );
  endfunction
  
  function void release_rst()
    rst = ( RESET_LOW ) ? ( 1'b1 ) : ( 1'b0 );
  endfunction
endinterface
