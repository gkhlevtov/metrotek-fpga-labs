// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"
// CREATED		"Thu Nov  6 19:03:49 2025"

module delay_15(
	clk_i,
	rst_i,
	data_i,
	data_delay_i,
	data_o
);


input wire	clk_i;
input wire	rst_i;
input wire	data_i;
input wire	[3:0] data_delay_i;
output wire	data_o;

wire	d0;
wire	d1;
wire	d10;
wire	d11;
wire	d12;
wire	d13;
wire	d14;
wire	d15;
wire	d2;
wire	d3;
wire	d4;
wire	d5;
wire	d6;
wire	d7;
wire	d8;
wire	d9;
reg	[15:1] data;
wire	SYNTHESIZED_WIRE_50;
wire	SYNTHESIZED_WIRE_51;
wire	SYNTHESIZED_WIRE_52;
wire	SYNTHESIZED_WIRE_53;
wire	SYNTHESIZED_WIRE_32;
wire	SYNTHESIZED_WIRE_33;
wire	SYNTHESIZED_WIRE_34;
wire	SYNTHESIZED_WIRE_35;
wire	SYNTHESIZED_WIRE_36;
wire	SYNTHESIZED_WIRE_37;
wire	SYNTHESIZED_WIRE_38;
wire	SYNTHESIZED_WIRE_39;
wire	SYNTHESIZED_WIRE_40;
wire	SYNTHESIZED_WIRE_41;
wire	SYNTHESIZED_WIRE_42;
wire	SYNTHESIZED_WIRE_43;
wire	SYNTHESIZED_WIRE_44;
wire	SYNTHESIZED_WIRE_45;
wire	SYNTHESIZED_WIRE_46;
wire	SYNTHESIZED_WIRE_47;
wire	SYNTHESIZED_WIRE_48;
wire	SYNTHESIZED_WIRE_49;




assign	d0 = SYNTHESIZED_WIRE_50 & SYNTHESIZED_WIRE_51 & SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_53;

assign	d1 = data_delay_i[0] & SYNTHESIZED_WIRE_51 & SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_53;

assign	d10 = SYNTHESIZED_WIRE_50 & data_delay_i[1] & SYNTHESIZED_WIRE_52 & data_delay_i[3];

assign	d11 = data_delay_i[0] & data_delay_i[1] & SYNTHESIZED_WIRE_52 & data_delay_i[3];

assign	d12 = SYNTHESIZED_WIRE_50 & SYNTHESIZED_WIRE_51 & data_delay_i[2] & data_delay_i[3];

assign	d13 = data_delay_i[0] & SYNTHESIZED_WIRE_51 & data_delay_i[2] & data_delay_i[3];

assign	d14 = SYNTHESIZED_WIRE_50 & data_delay_i[1] & data_delay_i[2] & data_delay_i[3];

assign	d15 = data_delay_i[0] & data_delay_i[1] & data_delay_i[2] & data_delay_i[3];

assign	d2 = SYNTHESIZED_WIRE_50 & data_delay_i[1] & SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_53;

assign	d3 = data_delay_i[0] & data_delay_i[1] & SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_53;

assign	d4 = SYNTHESIZED_WIRE_50 & SYNTHESIZED_WIRE_51 & data_delay_i[2] & SYNTHESIZED_WIRE_53;

assign	d5 = data_delay_i[0] & SYNTHESIZED_WIRE_51 & data_delay_i[2] & SYNTHESIZED_WIRE_53;

assign	d6 = SYNTHESIZED_WIRE_50 & data_delay_i[1] & data_delay_i[2] & SYNTHESIZED_WIRE_53;

assign	d7 = data_delay_i[0] & data_delay_i[1] & data_delay_i[2] & SYNTHESIZED_WIRE_53;

assign	d8 = SYNTHESIZED_WIRE_50 & SYNTHESIZED_WIRE_51 & SYNTHESIZED_WIRE_52 & data_delay_i[3];

assign	d9 = data_delay_i[0] & SYNTHESIZED_WIRE_51 & SYNTHESIZED_WIRE_52 & data_delay_i[3];

assign	SYNTHESIZED_WIRE_34 = d0 & data_i;

assign	SYNTHESIZED_WIRE_36 = d1 & data[1];

assign	SYNTHESIZED_WIRE_43 = d10 & data[10];

assign	SYNTHESIZED_WIRE_45 = d11 & data[11];

assign	SYNTHESIZED_WIRE_47 = d12 & data[12];

assign	SYNTHESIZED_WIRE_46 = d13 & data[13];

assign	SYNTHESIZED_WIRE_48 = d14 & data[14];

assign	SYNTHESIZED_WIRE_49 = d15 & data[15];

assign	SYNTHESIZED_WIRE_35 = d2 & data[2];

assign	SYNTHESIZED_WIRE_37 = d3 & data[3];

assign	SYNTHESIZED_WIRE_39 = d4 & data[4];

assign	SYNTHESIZED_WIRE_38 = d5 & data[5];

assign	SYNTHESIZED_WIRE_40 = d6 & data[6];

assign	SYNTHESIZED_WIRE_41 = d7 & data[7];

assign	SYNTHESIZED_WIRE_42 = d8 & data[8];

assign	SYNTHESIZED_WIRE_44 = d9 & data[9];


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[1] <= 0;
	end
else
	begin
	data[1] <= data_i;
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[10] <= 0;
	end
else
	begin
	data[10] <= data[9];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[11] <= 0;
	end
else
	begin
	data[11] <= data[10];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[12] <= 0;
	end
else
	begin
	data[12] <= data[11];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[13] <= 0;
	end
else
	begin
	data[13] <= data[12];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[14] <= 0;
	end
else
	begin
	data[14] <= data[13];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[15] <= 0;
	end
else
	begin
	data[15] <= data[14];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[2] <= 0;
	end
else
	begin
	data[2] <= data[1];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[3] <= 0;
	end
else
	begin
	data[3] <= data[2];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[4] <= 0;
	end
else
	begin
	data[4] <= data[3];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[5] <= 0;
	end
else
	begin
	data[5] <= data[4];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[6] <= 0;
	end
else
	begin
	data[6] <= data[5];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[7] <= 0;
	end
else
	begin
	data[7] <= data[6];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[8] <= 0;
	end
else
	begin
	data[8] <= data[7];
	end
end


always@(posedge clk_i or negedge rst_i)
begin
if (!rst_i)
	begin
	data[9] <= 0;
	end
else
	begin
	data[9] <= data[8];
	end
end

assign	SYNTHESIZED_WIRE_50 =  ~data_delay_i[0];

assign	SYNTHESIZED_WIRE_51 =  ~data_delay_i[1];

assign	SYNTHESIZED_WIRE_52 =  ~data_delay_i[2];

assign	SYNTHESIZED_WIRE_53 =  ~data_delay_i[3];

assign	data_o = SYNTHESIZED_WIRE_32 | SYNTHESIZED_WIRE_33;

assign	SYNTHESIZED_WIRE_33 = SYNTHESIZED_WIRE_34 | SYNTHESIZED_WIRE_35 | SYNTHESIZED_WIRE_36 | SYNTHESIZED_WIRE_37 | SYNTHESIZED_WIRE_38 | SYNTHESIZED_WIRE_39 | SYNTHESIZED_WIRE_40 | SYNTHESIZED_WIRE_41;

assign	SYNTHESIZED_WIRE_32 = SYNTHESIZED_WIRE_42 | SYNTHESIZED_WIRE_43 | SYNTHESIZED_WIRE_44 | SYNTHESIZED_WIRE_45 | SYNTHESIZED_WIRE_46 | SYNTHESIZED_WIRE_47 | SYNTHESIZED_WIRE_48 | SYNTHESIZED_WIRE_49;


endmodule
