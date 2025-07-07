`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 15:07:02
// Design Name: 
// Module Name: pipeline
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


module WB(
	// control signal
	input 		Ctl_RegWrite_in, 	Ctl_MemtoReg_in,
	output reg 	Ctl_RegWrite_out,
	//
	input              jal_in,jalr_in,
	input       [31:0] PC_in,
	input 		[ 4:0] Rd_in,
	input 		[31:0] ReadDatafromMem_in, ALUresult_in,
	output reg 	[ 4:0] Rd_out,
	output reg 	[31:0] WriteDatatoReg_out
	);	

	always @(*) begin
	    Ctl_RegWrite_out<=Ctl_RegWrite_in;
	    Rd_out<= Rd_in;
	
	
        if(Ctl_MemtoReg_in)
            WriteDatatoReg_out<=ReadDatafromMem_in;
        else if(jalr_in || jal_in)
            WriteDatatoReg_out<=PC_in+4;
        else
            WriteDatatoReg_out<=ALUresult_in;
		

	end
endmodule