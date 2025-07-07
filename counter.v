`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:13:02 03/26/2022 
// Design Name: 
// Module Name:    counter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

 module counter(
	input 			 clk, rst,
	input [15:0] sw,
	input 	[31:0] pc_in,
	input					 key1,
	output 	[ 2:0] LED_clk,
	output 			 clk_out
    );
	reg [31:0]count = 0;
	reg [31:0]led_count = 0;

	wire clk_check;
	reg clk_r;

	assign clk_out = clk_r;
	assign clk_check = clk_r;
	
	assign LED_clk = led_count[12:10];

	always @(posedge clk) begin
		if(sw[4])
			clk_r <= count[1];
		else if(sw[5])
			clk_r <= count[14];
		else if(sw[6])
			clk_r <= count[15];
		else if(sw[7])
			clk_r <= count[16];
		else if (sw[8])
			clk_r <= count[17];
		else if (sw[9])
			clk_r <= count[18];
		else if (sw[10])
			clk_r <= count[19];
		else if(sw[11])
			clk_r <= count[20];
		else if(sw[12])
			clk_r <= count[21];
		else if(sw[13])
			clk_r <= count[22];
		else if(sw[14])
			clk_r <= count[23];
		else if(sw[15])
			clk_r <= count[24];
		else clk_r <= count[25];
	end

	always @(posedge clk) begin
		led_count <= led_count + 32'b1;
		count <= count + 32'b1;
	end

endmodule
