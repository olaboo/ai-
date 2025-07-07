`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/18 17:53:32
// Design Name: 
// Module Name: Hazard detection unit
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


module Hazard_detection_unit(
      //decode
    input [6:0] opcode,
    input   mem_Ctl_MemRead_in,
    input [ 4:0] mem_Rd_in,
    input   exe_Ctl_RegWrite_in,
    
	input   exe_Ctl_MemRead_in,
	input [ 4:0] Rd_in,
	input [ 9:0] instruction_in,
	output 		 stall_out
	);
	wire BRANCH = (opcode == 7'b11000_11) | (opcode == 7'b11001_11);
	
	wire [ 4:0] Rs1_in = instruction_in[4:0];
	wire [ 4:0] Rs2_in = instruction_in[9:5];
	assign c_stall_out = (exe_Ctl_RegWrite_in &&(Rd_in==Rs1_in || Rd_in==Rs2_in)) ? 1 : 0;
	assign b_stall_out = (mem_Ctl_MemRead_in &&(mem_Rd_in==Rs1_in ||mem_Rd_in==Rs2_in)) ? 1 : 0;
	assign a_stall_out = (exe_Ctl_MemRead_in &&(Rd_in==Rs1_in ||Rd_in==Rs2_in)) ? 1 : 0;
	assign stall_out = a_stall_out | (BRANCH&(b_stall_out | c_stall_out));
	
endmodule

