`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 14:36:31
// Design Name: 
// Module Name: IF_ID
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
module PC (
    input CLK, RESETn,
    input PCWrite,
    input PCSrc,
    input [31:0] PCimm_in,
    output reg [31:0] PC_out
);

always @ (posedge CLK, negedge RESETn) begin
    if (!RESETn) begin
        PC_out <= 0;
    end else if(PCWrite) begin
       // PC_out <=PCSrc ? PCimm_in : PC_out;
        PC_out <=PC_out;
    end else begin  
        PC_out <= PCimm_in;
    end
end

endmodule

module iMEM(
    input CLK, RESETn,
    input IF_ID_Write, PCSrc,
    input [31:0] address,
    output reg [31:0] inst_out
);

parameter ROM_size = 128;
(*ram_style = "block"*) reg[31:0]ROM[0:ROM_size-1];

initial begin
    $readmemh("darksocv.rom.mem", ROM);
end

always @(posedge CLK) begin
    if (!RESETn) begin
        inst_out <= 32'b0;
    end else begin
        if(!IF_ID_Write) begin
            if (PCSrc)
                inst_out <= 32'b0;
            else
                inst_out <= ROM[address[31:2]];
        end
    end
end

endmodule

module InFetch(
    input CLK, RESETn,
    input PCSrc,
    input PCWrite,
    input [31:0] PCimm_in,
    output [31:0] r_inst_out,
    output reg [31:0] r_PC_out
);

wire [31:0] PC_out;
wire [31:0] PC4 =(PCSrc) ? PCimm_in : PC_out+4;

PC B1_PC(
    .CLK(CLK),
    .RESETn(RESETn),
    .PCWrite(PCWrite),
    .PCSrc(PCSrc),
    .PCimm_in(PC4),
    .PC_out(PC_out)
);

iMEM B2_iMEM(
    .CLK(CLK),
    .RESETn(RESETn),
    .IF_ID_Write(PCWrite),
    .PCSrc(PCSrc),
    .address(PC_out),
    .inst_out(r_inst_out)
);

always @(posedge CLK, negedge RESETn) begin
    if (!RESETn) begin
        r_PC_out <= 0;
    end else begin
        r_PC_out <= PCWrite ? r_PC_out : PC_out;
    end
end

endmodule

module Control_unit(
    input [6:0] opcode,
    input reset,
    output reg [7:0] Ctl_out
);

always @(*) begin
    if (!reset)
        Ctl_out = 8'b0;
    else
        case(opcode)
            7'b01100_11: Ctl_out = 8'b001000_10;
            7'b00100_11: Ctl_out = 8'b101000_11;
            7'b00000_11: Ctl_out = 8'b111100_00;
            7'b01000_11: Ctl_out = 8'b100010_00;
            7'b11000_11: Ctl_out = 8'b000001_01;
            7'b11011_11: Ctl_out = 8'b001001_00;
            7'b11001_11: Ctl_out = 8'b101001_11;
            
            default:    Ctl_out = 8'b0;
        endcase
end

endmodule

module Branch_Unit(
    //branch criteria
    input [6:0] opcode,
    input [2:0] funct3,
    input [31:0] Read_data1, Read_data2, //Read_data1 == Rs1

    //target PC
    input [31:0] base_pc,
    input [31:0] offset,

    //output
    output reg PCSrc,
    output [31:0] PC_imm
);

wire JAL  = (opcode == 7'b11011_11);
wire JALR = (opcode == 7'b11001_11);
wire BRANCH = (opcode == 7'b11000_11);
wire BEQ = (Read_data1 == Read_data2);
wire BLT = ($signed(Read_data1) < $signed(Read_data2));

always @(*) begin
    case (funct3)
        3'b000 : PCSrc = BEQ;
        3'b001 : PCSrc = !BEQ;
        3'b100 : PCSrc = BLT;
        3'b101 : PCSrc = !BLT;
        default: PCSrc = 0;
    endcase
    PCSrc = (PCSrc & BRANCH) | JAL | JALR;
end

assign PC_imm = JALR ? Read_data1 : (base_pc + (offset << 1));

endmodule



module InDecode(
    input CLK, RESETn,
    input stall,
    input flush, ForwardA_Dec, ForwardB_Dec,
    input Ctl_RegWrite_in,
    output reg Ctl_ALUSrc_out, Ctl_MemtoReg_out, Ctl_RegWrite_out,
    output reg Ctl_MemRead_out, Ctl_MemWrite_out, Ctl_Branch_out,
    output reg Ctl_ALUOpcode1_out, Ctl_ALUOpcode0_out,
    input [4:0] WriteReg,
    input [31:0] PC_in, instruction_in, WriteData, mem_data,
    output reg [4:0] Rd_out, Rs1_out, Rs2_out, 
    output reg [31:0] PC_out, ReadData1_out, ReadData2_out, Immediate_out,
    output reg [6:0] funct7_out,
    output reg [2:0] funct3_out,
    output reg jalr_out, jal_out, bne_out,
    output PCSrc_out,
    output [31:0] PCimm_out
   
);
`define JAL 7'b11011_11
`define JALR 7'b11001_11

wire [6:0] opcode = instruction_in[6:0];
wire [6:0] funct7 = instruction_in[31:25];
wire [2:0] funct3 = instruction_in[14:12];
wire [4:0] Rd     = instruction_in[11:7];
wire [4:0] Rs1    = instruction_in[19:15];
wire [4:0] Rs2    = instruction_in[24:20];
wire       jalr   = (opcode==`JALR) ? 1:0;
wire       jal    = (opcode==`JAL) ? 1:0;
wire       bne    = (funct3==3'b001)?1:0;
    
wire [7:0] Ctl_out;
// Branch unit
parameter reg_size = 32;
reg [31:0] Reg[0:reg_size-1];

Control_unit B0 (.opcode(instruction_in[6:0]), .Ctl_out(Ctl_out), .reset(RESETn));

reg [7:0] Control;
always @(*) begin
    Control =(flush | stall) ? 0:Ctl_out;
end


integer i;
always @(posedge CLK, negedge RESETn) begin
    if (!RESETn) begin
        for(i=0;i<reg_size;i=i+1) begin
            Reg[i] <= 32'b0;
        end
    end else if (Ctl_RegWrite_in && (WriteReg!=0)) begin
        Reg[WriteReg] <= WriteData;
    end
end

reg [31:0] Immediate;

wire [31:0] Branch_read_data1 = ForwardA_Dec ? mem_data :
                    (Ctl_RegWrite_in && WriteReg == Rs1 && WriteReg != 0) ? WriteData : Reg[Rs1];
wire [31:0] Branch_read_data2 = ForwardB_Dec ? mem_data :
                    (Ctl_RegWrite_in && WriteReg == Rs2 && WriteReg != 0) ? WriteData : Reg[Rs2];

Branch_Unit B1 (
    .opcode(opcode),
    .funct3(funct3),
    .Read_data1(Branch_read_data1),
    .Read_data2(Branch_read_data2),

    .base_pc(PC_in),
    .offset(Immediate),

    .PCSrc(PCSrc_out),
    .PC_imm(PCimm_out)
);

always @(*) begin
    case(opcode)
        7'b00000_11: Immediate = $signed(instruction_in[31:20]);
        7'b00100_11: Immediate = $signed(instruction_in[31:20]);
        7'b11001_11: Immediate = $signed(instruction_in[31:20]);
        7'b01000_11: Immediate = $signed({instruction_in[31:25], instruction_in[11:7]});
        7'b11000_11: Immediate = $signed({instruction_in[31], instruction_in[7], instruction_in[30:25], instruction_in[11:8]});
        7'b11011_11: Immediate = $signed({instruction_in[31], instruction_in[19:12], instruction_in[20], instruction_in[30:21]});
        default: Immediate = 32'b0;
    endcase
end

always @(posedge CLK, negedge RESETn) begin
    if (!RESETn) begin
        PC_out                <= 0;
        funct7_out            <= 0;
        funct3_out            <= 0;
        Rd_out                <= 0;
        Rs1_out               <= 0;
        Rs2_out               <= 0;
        ReadData1_out         <= 0;
        ReadData2_out         <= 0;
        jalr_out              <= 0;
        jal_out               <= 0;
        Ctl_ALUSrc_out        <= 0;
        Ctl_MemtoReg_out      <= 0;
        Ctl_RegWrite_out      <= 0;
        Ctl_MemRead_out       <= 0;
        Ctl_MemWrite_out      <= 0;
        Ctl_Branch_out        <= 0;
        Ctl_ALUOpcode1_out    <= 0;
        Ctl_ALUOpcode0_out    <= 0;
        Immediate_out         <= 0;
    end else begin
    PC_out             <= PC_in;
    funct7_out         <= funct7;
    funct3_out         <= funct3;
    Rd_out             <= Rd;
    Rs1_out            <= Rs1;
    Rs2_out            <= Rs2;
    ReadData1_out      <= (Ctl_RegWrite_in && WriteReg==Rs1&&WriteReg!=0) ? WriteData : Reg[Rs1];
    ReadData2_out      <= (Ctl_RegWrite_in && WriteReg==Rs2&&WriteReg!=0) ? WriteData : Reg[Rs2];
    jalr_out           <= jalr;
    jal_out            <= jal;
    bne_out            <= bne;
    Ctl_ALUSrc_out     <= Control[7];
    Ctl_MemtoReg_out   <= Control[6];
    Ctl_RegWrite_out   <= Control[5];
    Ctl_MemRead_out    <= Control[4];
    Ctl_MemWrite_out   <= Control[3];
    Ctl_Branch_out     <= Control[2];
    Ctl_ALUOpcode1_out <= Control[1];
   Ctl_ALUOpcode0_out <= Control[0];
    Immediate_out      <= Immediate;
end
end
endmodule