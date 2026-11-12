`timescale 1ns/1ps

interface rd_if #(
  parameter int DWIDTH = 32,
  parameter int AWIDTH = 8
)(
  input bit clk	
);
  logic              rst;
  logic [DWIDTH-1:0] data;
  logic              rdreq;
  logic [AWIDTH:0]   usedw;
  logic              empty;
  logic              almost_empty;

  initial
    begin
      rdreq = 1'b0;
      rst   = 1'b1;
    end
endinterface
