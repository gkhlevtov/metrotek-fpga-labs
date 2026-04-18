class Monitor  #(
  parameter DWIDTH       = 16,
  parameter AWIDTH       = 8,
  parameter ALMOST_FULL  = 2,
  parameter ALMOST_EMPTY = 2
);
  virtual lifo_if #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) v_if;
  mailbox         #( Transaction #( DWIDTH, AWIDTH )           ) mon2scb;

  function new(
    virtual lifo_if #( DWIDTH, AWIDTH, ALMOST_FULL, ALMOST_EMPTY ) v_if,
    mailbox         #( Transaction #( DWIDTH, AWIDTH )           ) mon2scb
  );
    this.v_if    = v_if;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    Transaction #( DWIDTH, AWIDTH ) tr;
    forever begin
      @( v_if.mon_cb );

      if( tr != null )
        begin
          tr.data_out = v_if.mon_cb.q_o;
          tr.full     = v_if.mon_cb.full_o;
          tr.empty    = v_if.mon_cb.empty_o;
          tr.a_full   = v_if.mon_cb.almost_full_o;
          tr.a_empty  = v_if.mon_cb.almost_empty_o;
          tr.usedw    = v_if.mon_cb.usedw_o;

          mon2scb.put(tr);
        end

      tr         = new();
      tr.wr      = v_if.mon_cb.wrreq_i;
      tr.rd      = v_if.mon_cb.rdreq_i;
      tr.data_in = v_if.mon_cb.data_i;
      tr.srst    = v_if.mon_cb.srst_i;
    end
  endtask
endclass