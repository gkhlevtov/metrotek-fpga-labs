module serializer_top(
  input  logic        clk_150m,
  input  logic        srst_i,

  input  logic [15:0] data_i,
  input  logic [3:0]  data_mod_i,
  input  logic        data_val_i,

  output logic        ser_data_o,
  output logic        ser_data_val_o,
  output logic        busy_o
);

  logic        srst_reg;
  logic [15:0] data_reg;
  logic [3:0]  data_mod_reg;
  logic        data_val_reg;

  logic        dut_ser_data;
  logic        dut_ser_val;
  logic        dut_busy;

  always_ff @( posedge clk_150m )
    begin
      srst_reg       <= srst_i;
      data_reg       <= data_i;
      data_mod_reg   <= data_mod_i;
      data_val_reg   <= data_val_i;
    end

  always_ff @( posedge clk_150m )
    begin
      ser_data_o     <= dut_ser_data;
      ser_data_val_o <= dut_ser_val;
      busy_o         <= dut_busy;
    end

  serializer dut(
    .clk_i          ( clk_150m      ),
    .srst_i         ( srst_reg      ),
    .data_i         ( data_reg      ),
    .data_mod_i     ( data_mod_reg  ),
    .data_val_i     ( data_val_reg  ),
    .ser_data_o     ( dut_ser_data  ),
    .ser_data_val_o ( dut_ser_val   ),
    .busy_o         ( dut_busy      )
  );
endmodule
