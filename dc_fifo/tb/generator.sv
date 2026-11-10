class generator #(
  parameter int DWIDTH = 32
);
  typedef logic [DWIDTH-1:0] word_t;

  mailbox #( word_t ) gen2drv;

  int idx = 0;
  
  function new(
     mailbox #( word_t ) gen2drv
  );
     this.gen2drv = gen2drv;
  endfunction
  
  function word_t random_word();
    word_t word;
    for( int i = 0; i < DWIDTH/8; i++ )
      word[i*8 +: 8] = $urandom();
    return word;
  endfunction
 
  task send_word( word_t word );
    gen2drv.put(word);
    idx++;
    //$display( "[@%0t][GEN] sent word #%0d: %0h", $time, idx, word );
  endtask
 
  task run_simple_test( int n );
    for( int i = 0; i < n; i++ )
      send_word( random_word() );
  endtask
endclass
