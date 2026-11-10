class golden_model #(
  parameter int DWIDTH = 32
);
  logic [DWIDTH-1:0] q [$];
  int                depth;  
  int                errors;
  int                pushed;
  int                checked;

  function new( int depth );
    this.depth   = depth;
    this.errors  = 0;
    this.pushed  = 0;
    this.checked = 0;
  endfunction

  function void push( logic [DWIDTH-1:0] data );
    q.push_back(data);
    pushed++;

    if( q.size > depth )
      begin
	errors++;
        $error( "[@%0t][GM] OVERFLOW: words inside: %0d, real size: %0d", $time, q.size(), depth );
      end 
    endfunction
  
  function void check( logic [DWIDTH-1:0] got );
    logic [DWIDTH-1:0] exp;
    
    if( q.size == 0 )
      begin
        errors++;
        $error("[@%0t][GM] UNDERFLOW: reading from empty queue", $time );
	return;
      end       
    
    exp = q.pop_front();

    if( exp !== got )
      begin
        errors++;
	$error("[@%0t][GM] DATA MISMATCH #%0d:\nexp: %0h, got: %0h\n", $time, checked, exp, got);
      end

    checked++;
  endfunction

  function void clear();
    q.delete();
  endfunction

  function void finish( int expected );
    if( q.size != 0 )
      begin
	errors++;
        $display( "[@%0t][GM] %0d words left inside FIFO", $time, q.size );
      end
    if( pushed != expected )
      begin
        errors++;	      
        $display( "[@%0t][GM] accepted by FIFO: %0d, expected: %0d", $time, pushed, expected );
      end
    if( checked != expected )
      begin
	errors++;
	$display( "[@%0t][GM] read from FIFO: %0d, expected: %0d", $time, checked, expected );
      end
    if( errors == 0 )
      $display( "TEST PASSED: checked %0d words\n", checked );
    else
      $display( "TEST FAILED: %0d errors\n", errors );
  endfunction
endclass
