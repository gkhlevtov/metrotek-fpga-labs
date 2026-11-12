`timescale 1ns/1ps

interface wr_if #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
)(
  input bit clk	
);
  logic              rst;
  logic [DWIDTH-1:0] data;
  logic              wrreq;
  logic [AWIDTH:0]   usedw;
  logic              full;
  logic              almost_full;

  initial
    begin
      wrreq = 1'b0;
      rst   = 1'b1;
    end
endinterface 
