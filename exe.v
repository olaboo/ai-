`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/07 15:05:51
// Design Name: 
// Module Name: exe
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



module Execution(
	input 	clk,
	input flush,
	// control signal
	input 		Ctl_ALUSrc_in, Ctl_MemtoReg_in, 	Ctl_RegWrite_in,Ctl_MemRead_in, Ctl_MemWrite_in, Ctl_Branch_in, Ctl_ALUOpcode1_in, Ctl_ALUOpcode0_in,
	output reg						Ctl_MemtoReg_out, Ctl_RegWrite_out, Ctl_MemRead_out,	Ctl_MemWrite_out,	Ctl_Branch_out,
	// bypass
	input 		[ 4:0] Rd_in,
	output reg 	[ 4:0] Rd_out,
	input              jal_in,jalr_in,bne_in,
	output reg         jal_out,jalr_out,bne_out,
	//
	input 		[31:0] Immediate_in, ReadData1_in, ReadData2_in, PC_in,
	input       [31:0] mem_data, wb_data,
	input 		[ 6:0] funct7_in,
	input 		[ 2:0] funct3_in,
	
	//forwarding
	input      [1:0]  ForwardA_in, ForwardB_in,
	output reg			 Zero_out,
	
	output reg 	[31:0] ALUresult_out, PCimm_out, ReadData2_out,
	output reg  [31:0] PC_out
	);
	
	//RISC-V
	wire [3:0] ALU_ctl;
	wire [31:0] ALUresult;
	wire zero;
	
	wire [31:0] ALU_input1 =  (ForwardA_in==2'b10) ? mem_data :
	                          (ForwardA_in==2'b01) ? wb_data : ReadData1_in;
	wire [31:0] ForwardB_input = (ForwardB_in==2'b10) ? mem_data :
	                      (ForwardB_in==2'b01) ? wb_data: ReadData2_in;
	wire [31:0] ALU_input2 =  (Ctl_ALUSrc_in) ?  Immediate_in :  ForwardB_input;
		
	ALU_control B0 (.ALUop({ Ctl_ALUOpcode1_in, Ctl_ALUOpcode0_in}), .funct7(funct7_in[6:0]), .funct3(funct3_in[2:0]), .ALU_ctl(ALU_ctl[3:0]));
	ALU B1 (.ALU_ctl(ALU_ctl[3:0]), .in1(ALU_input1), .in2(ALU_input2), .out(ALUresult), .zero(zero));
	
	always@(posedge clk) begin
		Ctl_MemtoReg_out	<= Ctl_MemtoReg_in;
		Ctl_RegWrite_out	<= Ctl_RegWrite_in;
		Ctl_MemRead_out 	<= Ctl_MemRead_in;
		Ctl_MemWrite_out	<= Ctl_MemWrite_in;
		Ctl_Branch_out		<= Ctl_Branch_in;
		
		PC_out              <= PC_in;
		jalr_out <= jalr_in;
        jal_out  <= jal_in;
        bne_out  <= bne_in;
		Rd_out				<= Rd_in;	
		PCimm_out			<= PC_in+(Immediate_in<<1);
		ReadData2_out		<= ForwardB_input;
		ALUresult_out		<=ALUresult;
		Zero_out			<=zero;
		
	end
endmodule

module ALU_control(
    input [1:0] ALUop,
    input [6:0] funct7,
    input [2:0] funct3,
    output reg [3:0] ALU_ctl
);

// ALU_ctl   OPERATION
// 4'b0000 : and     => ReadData1 & ReadData2
// 4'b0001 : or      => ReadData1 | ReadData2
// 4'b0010 : add     => ReadData1 + ReadData2
// 4'b0010 : addi    => ReadData1 + ReadData2 (Immediate_in)
// 4'b0110 : sub     => ReadData1 - ReadData2
// 4'b0111 : blt     => (branch if less than)
// 4'b1000 : bge     => (branch if greater equal)  // blt, bge는 zero=1로 만들기 위해서 out=0으로 셋팅
// 4'b1010 : beq     => (ReadData1 == ReadData2)
// 4'b1001 : shift left
// 4'b1011 : shift right

reg [3:0] ALU_ctl;
always @(*) begin
    casex ({ALUop, funct3, funct7})
        12'b00_xxx_xxxxxxx : ALU_ctl= 4'b0010;
        12'b01_00x_xxxxxxx : ALU_ctl= 4'b0110;
        12'b01_100_xxxxxxx : ALU_ctl = 4'b0111;
        12'b01_101_xxxxxxx : ALU_ctl = 4'b1000;
        12'b10_000_0000000 : ALU_ctl = 4'b0010;
        12'b10_000_0100000 : ALU_ctl = 4'b0110;
        12'b10_111_0000000 : ALU_ctl = 4'b0000;
        12'b10_110_0000000 : ALU_ctl = 4'b0001;
        12'b10_001_0000000 : ALU_ctl = 4'b1001;
        12'b10_101_0000000 : ALU_ctl = 4'b1010;
        12'b11_000_xxxxxxx : ALU_ctl = 4'b0010;
        12'b11_111_xxxxxxx : ALU_ctl = 4'b0000;
        12'b11_001_0000000 : ALU_ctl = 4'b1001;
        12'b11_101_0000000 : ALU_ctl = 4'b1010;

        default : ALU_ctl = 4'bx;
    endcase
end

endmodule
module ALU(
    input  [3:0] ALU_ctl,
    input  [31:0] in1, in2,
    output reg [31:0] out,
    output zero
);

    always @(*) begin
        case (ALU_ctl)
            4'b0000: out = in1 & in2;
           
            // ---------------------- (빈칸 영역 시작) ----------------------
             4'b0001: out = in1 | in2;
             4'b0010: out = in1 + in2;
             4'b0110: out = in1 - in2;
             4'b0111: out = (in1 < in2) ? 0 : 1;
             4'b1000: out = (in1>= in2) ? 0 : 1;
             4'b1100: out = ~(in1 | in2);
             4'b1001: out = in1<<in2;
             4'b1010: out = in1>>in2;
             
             
             
             
           
           
           
           
           
           
           
            // ---------------------- (빈칸 영역 끝) ----------------------

            default : out = 32'b0;
        endcase
    end

    assign zero = ~|out;     // (ALU_ctl == 4'b0110) or (ALU_ctl == 4'b0111)

endmodule