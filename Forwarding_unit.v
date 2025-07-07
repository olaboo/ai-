`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/18 17:48:05
// Design Name: 
// Module Name: Forwarding_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Forwarding_unit(
	input mem_Ctl_RegWrite_in, wb_Ctl_RegWrite_in,
	input [4:0] Rs1_in, Rs2_in, mem_Rd_in, wb_Rd_in,Rs1_if_in,Rs2_if_in,
	output [1:0] ForwardA_out, ForwardB_out,
	//decode
	output ForwardA_Dec_out, ForwardB_Dec_out,
	input [4:0] Rs1dec_in, Rs2dec_in
	);

assign ForwardA_out = 
    (mem_Ctl_RegWrite_in &&( mem_Rd_in == Rs1_in)&& Rs1_in !=0) ? 2'b10 :
    (wb_Ctl_RegWrite_in  && (wb_Rd_in  == Rs1_in)&&Rs1_in !=0) ? 2'b01 : 2'b00;

assign ForwardB_out = 
    (mem_Ctl_RegWrite_in && (mem_Rd_in == Rs2_in)&& Rs2_in !=0) ? 2'b10 :
    (wb_Ctl_RegWrite_in  && (wb_Rd_in  == Rs2_in)&& Rs2_in !=0) ? 2'b01 : 
    2'b00;
assign ForwardA_Dec_out = (mem_Ctl_RegWrite_in && (mem_Rd_in == Rs1dec_in)&& Rs1dec_in !=0) ? 1:0;

assign ForwardB_Dec_out = (mem_Ctl_RegWrite_in &&( mem_Rd_in == Rs2dec_in)&& Rs2dec_in !=0) ? 1:0;

endmodule

