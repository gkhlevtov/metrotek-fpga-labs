module crc_16_ansi_tb;
  // Input data packs size
  parameter int DATA_LEN = 32;

  // DUT inputs and output
  bit clk;
  bit rst;

  logic        data_i;
  logic [15:0] data_o;

  // Expected output
  logic [15:0] data_o_exp;

  // Simulation success flag
  logic        pass_flag;

  // Input data pack
  logic [DATA_LEN-1:0] data_pack;

  initial
    forever
      #5 clk = !clk;

  initial
    begin
      clk        <= 1'b0;
      rst        <= 1'b1;
      data_i     <= 1'b0;
      data_o_exp <= 1'b0;
      pass_flag  <= 1'b1;
      data_pack  <= 1'b0;

      @( posedge clk );
      rst        <= 1'b0;
      @( posedge clk );
      rst        <= 1'b1;
    end

  crc_16_ansi dut (
    .rst_i  ( rst    ),
    .clk_i  ( clk    ),
    .data_i ( data_i ),
    .data_o ( data_o )
  );

  // CRC-16-ANSI calculating function
  function logic [15:0] crc_16_ansi_func ( input logic [DATA_LEN:0] data );
    
    logic        fb;
    logic [15:0] crc;
    logic [15:0] next_crc;

    crc = 16'h0000;

    for (int i = 0; i < DATA_LEN; i = i + 1)
    begin
      // feedback
      fb = crc[15] ^ data[i];

      next_crc[0]  = fb;
      next_crc[1]  = crc[0];
      next_crc[2]  = crc[1]  ^ fb;
      next_crc[3]  = crc[2];
      next_crc[4]  = crc[3];
      next_crc[5]  = crc[4];
      next_crc[6]  = crc[5];
      next_crc[7]  = crc[6];
      next_crc[8]  = crc[7];
      next_crc[9]  = crc[8];
      next_crc[10] = crc[9];
      next_crc[11] = crc[10];
      next_crc[12] = crc[11];
      next_crc[13] = crc[12];
      next_crc[14] = crc[13];
      next_crc[15] = crc[14] ^ fb;

      crc = next_crc;
    end

    return crc;
  endfunction

  task load_data ();
    begin
      // DUT and expected output reset
      @( posedge clk );
      rst        <= 1'b0;
      data_o_exp <= 1'b0;
      @( posedge clk );
      rst        <= 1'b1;

      // Data load
      for( int i = 0; i < DATA_LEN; i = i + 1 )
        begin
          data_i <= data_pack[i];
          @( posedge clk );
        end
      
      @( posedge clk );
    end
  endtask

  task run_one_check ();
    begin
      data_o_exp = crc_16_ansi_func( data_pack );
      $display( "inp = %b\nexp = %b\ngot = %b\nat time = %t", data_pack, data_o_exp, data_o, $time );
      if (data_o != data_o_exp )
        begin
          $error( "Mismatch: input data = %b, expected = %b, got = %b", data_pack, data_o_exp, data_o );
          pass_flag = 1'b0;
        end
    end
  endtask

  initial
    begin
      $display( "Simulation start" );

      #15;

      // Boundary input values test
      data_pack = { DATA_LEN{1'b1} };
      load_data();
      run_one_check();

      data_pack = { DATA_LEN{1'b0} };
      load_data();
      run_one_check();

      // 1010... check
      for (int i = 0; i < DATA_LEN; i++)
        begin
          data_pack[i] = (i % 2);
        end
      load_data();
      run_one_check();

      // Random input data test
      for ( int i = 0; i < 10; i = i + 1 )
        begin
          data_pack = $urandom_range( 0, 2**DATA_LEN - 1 );
          load_data();
          run_one_check();
        end

      if( pass_flag )
        $display( "\nTEST PASSED\n" );
      else
        $display( "\nTEST FAILED\n" );

      $display( "Simulation end" );
      
      $stop();
    end
endmodule