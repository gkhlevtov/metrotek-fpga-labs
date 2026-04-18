class Driver #(
  parameter DWIDTH       = 16,
  parameter AWIDTH       = 8,
  parameter ALMOST_FULL  = 2,
  parameter ALMOST_EMPTY = 2
);
  virtual lifo_if #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) v_if;
  mailbox         #( Transaction #( DWIDTH, AWIDTH )           ) gen2drv;

  function new(
    virtual lifo_if #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) v_if,
    mailbox         #( Transaction #( DWIDTH, AWIDTH )           ) gen2drv
  );
    this.v_if = v_if;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    Transaction #( DWIDTH, AWIDTH ) tr;
    
    forever
      begin
        gen2drv.get(tr);
        
        @( v_if.drv_cb );
        v_if.drv_cb.srst_i  <= tr.srst;
        v_if.drv_cb.wrreq_i <= tr.wr;
        v_if.drv_cb.rdreq_i <= tr.rd;
        if(tr.wr)
          v_if.drv_cb.data_i <= tr.data_in;
      end
  endtask
endclass