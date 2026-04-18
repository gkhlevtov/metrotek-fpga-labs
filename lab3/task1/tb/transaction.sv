class Transaction #( parameter DWIDTH = 16, parameter AWIDTH = 8 );
  rand bit              wr;
  rand bit              rd;
  rand bit              srst;
  rand bit [DWIDTH-1:0] data_in;

  bit      [DWIDTH-1:0] data_out;
  bit                   full;
  bit                   empty;
  bit                   a_full;
  bit                   a_empty;
  bit      [AWIDTH:0]   usedw;
  
  // constraint op_dist  { {wr, rd} dist {2'b00 := 10, 2'b01 := 30, 2'b10 := 30, 2'b11 := 30}; }

  // constraint rst_dist { srst     dist {1'b1 := 1, 1'b0 := 99                             }; }

  function void randomize_manual();
    int unsigned rnd;
    rnd = $urandom_range(0,99);
    this.srst = (rnd < 1);
    
    rnd = $urandom_range(0,99);
    if (rnd < 10)
      {this.wr, this.rd} = 2'b00;
    else if (rnd < 40)
      {this.wr, this.rd} = 2'b01;
    else if (rnd < 70)
      {this.wr, this.rd} = 2'b10;
    else
      {this.wr, this.rd} = 2'b11;
    
    this.data_in = $urandom_range(0, (1<<DWIDTH)-1);
  endfunction

  function Transaction #( DWIDTH, AWIDTH ) copy();
    Transaction #(DWIDTH, AWIDTH) copy_tr = new();
    copy_tr.wr       = this.wr;
    copy_tr.rd       = this.rd;
    copy_tr.srst     = this.srst;
    copy_tr.data_in  = this.data_in;
    copy_tr.data_out = this.data_out;
    copy_tr.full     = this.full;
    copy_tr.empty    = this.empty;
    copy_tr.a_full   = this.a_full;
    copy_tr.a_empty  = this.a_empty;
    copy_tr.usedw    = this.usedw;
    return copy_tr;
  endfunction

  function void display(string prefix = "");
    $display("[%s] @%0t: WR=%b, RD=%b, DI=%h, DO=%h", 
              prefix, $time, wr, rd, data_in, data_out);
    $display("       Flags: RST=%b, FULL=%b, EMPTY=%b, AFULL=%b, AEMPTY=%b, USEDW=%0d", 
              srst, full, empty, a_full, a_empty, usedw);
  endfunction
endclass