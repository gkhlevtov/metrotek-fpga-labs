class Scoreboard #(
  parameter int DWIDTH       = 16,
  parameter int AWIDTH       = 8,
  parameter int ALMOST_FULL  = 2,
  parameter int ALMOST_EMPTY = 2
);
  mailbox #( Transaction #( DWIDTH, AWIDTH ) ) mon2scb;
  
  logic [DWIDTH-1:0] stack[$];

  function new( mailbox #( Transaction #( DWIDTH, AWIDTH ) ) mon2scb );
    this.mon2scb = mon2scb;
  endfunction

  task run();
    Transaction #( DWIDTH, AWIDTH ) tr;
    bit                             ready = 0;
    forever
      begin
        mon2scb.get(tr);
        if( tr.srst )
          ready = 1;
        if( ready )
          begin
            if( tr.srst )
              begin
                stack.delete();
                $display("[SCB] @%0t: Model Reset", $time);
              end
            else
              begin
                check_data(tr);
                check_flags(tr);
              end
          end
      end
  endtask

  task check_flags( Transaction #(DWIDTH, AWIDTH) tr );
    if ( tr.full    !== ( stack.size() == 2**AWIDTH ) )
      $error("[SCB] @%0t: FULL mismatch!    Got: %0b, Exp: %0b",
             $time, tr.full, stack.size() == 2**AWIDTH);
    if ( tr.empty   !== ( stack.size() == 0         ) )         
      $error("[SCB] @%0t: EMPTY mismatch!   Got: %0b, Exp: %0b",
             $time, tr.empty, stack.size() == 0);
    if ( tr.a_full  !== ( stack.size() >= ALMOST_FULL  ) )
      $error("[SCB] @%0t: ALMOST_FULL mismatch!  Got: %0b, Exp: %0b (usedw=%0d, ALMOST_FULL=%0d)",
             $time, tr.a_full, stack.size() >= ALMOST_FULL, stack.size(), ALMOST_FULL);
    if ( tr.a_empty !== ( stack.size() <= ALMOST_EMPTY ) )
      $error("[SCB] @%0t: ALMOST_EMPTY mismatch! Got: %0b, Exp: %0b (usedw=%0d, ALMOST_EMPTY=%0d)",
             $time, tr.a_empty, stack.size() <= ALMOST_EMPTY, stack.size(), ALMOST_EMPTY);
    if ( tr.usedw   !== stack.size()                  )
      $error("[SCB] @%0t: USEDW mismatch! Got: %0d, Exp: %0d", $time, tr.usedw, stack.size());
  endtask

  task check_data( Transaction #(DWIDTH, AWIDTH) tr );
    if( tr.rd && !is_empty() )
      begin
        if (tr.data_out !== stack[stack.size()-1])
          $error("[SCB] @%0t: DATA MISMATCH! Got: %0h, Exp: %0h",
                 $time, tr.data_out, stack[stack.size()-1]);
      end
    else if( tr.rd && is_empty() )
      $display("[SCB] @%0t: Read from empty LIFO - underflow protection triggered", $time);

    if (tr.wr && tr.rd)
      begin
        if( !is_empty() )
          void'(stack.pop_back()); 
        stack.push_back(tr.data_in);
      end
    else if( tr.wr && !tr.rd )
      begin
        if( !is_full() )
          stack.push_back(tr.data_in);
        else
          $display("[SCB] @%0t: Write to full LIFO - overflow protection triggered", $time);
      end
    else if( tr.rd && !tr.wr )
      begin
        if( !is_empty() )
          void'(stack.pop_back());
      end
  endtask

  function bit is_empty();
    return ( stack.size() == 0 );
  endfunction
  
  function bit is_full(); 
    return ( stack.size() == 2**AWIDTH );
  endfunction
endclass