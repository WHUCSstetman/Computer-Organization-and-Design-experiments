`include "C:/Users/77247/Desktop/123/define.v"
module control(
	opcode,
	func3,
	func7,
	MemRead,
	MemtoReg,
	MemWrite,
	ALUSrc,
	RegWrite,
	lui,
	U_type,
	jal,
	jalr,
	beq,
	bne,
	blt,
	bge,
	bltu,
	bgeu,
	RW_type,
	ALUctl

    );
	input 	 [6:0]opcode;
	input 	 [2:0]func3;
	input 	 func7;
	output   MemRead;
	output   MemtoReg;
	output   MemWrite;
	output   ALUSrc;
	output   RegWrite;
	output   lui;
	output   U_type;
	output   jal;
	output   jalr;
	output   beq;
	output   bne;
	output   blt;
	output   bge;
	output   bltu;
	output   bgeu;
	output   [2:0]RW_type;
	output   [3:0]ALUctl;
	
	wire [1:0]ALUop;
	
	main_control main_control_inst(
	.opcode(opcode),
	.func3(func3),
	.MemRead(MemRead),
	.MemtoReg(MemtoReg),
	.ALUop(ALUop),
	.MemWrite(MemWrite),
	.ALUSrc(ALUSrc),
	.RegWrite(RegWrite),
	.lui(lui),
	.U_type(U_type),
	.jal(jal),
	.jalr(jalr),
	.beq(beq),
	.bne(bne),
	.blt(blt),
	.bge(bge),
	.bltu(bltu),
	.bgeu(bgeu),
	.RW_type(RW_type)
    );
	
	alu_control alu_control_inst(
	.ALUop(ALUop),
	.func3(func3),
	.func7(func7),
	.ALUctl(ALUctl)
    );
	
endmodule

//主控制器
module main_control(
	opcode,
	func3,		
	MemRead,	//读使能信号
	MemtoReg,	//写回寄存器的数据选择器控制信号
	ALUop,		//子控制器的控制信号
	MemWrite,	//数据存储器的写使能
	ALUSrc,		//数据选择器的控制信号
	RegWrite,	//寄存器的写使能
	lui,		//lui指令标志，写回寄存器的数据选择器的控制信号
	U_type,		//U-type指令标志，写回寄存器的数据选择器的控制信号
	jal,		//jal指令标志，选择pc的数据选择器的控制信号，同时也是写回寄存器的数据选择器的控制信号
	jalr,		//jalr指令标志，选择pc的数据选择器的控制信号，同时也是写回寄存器的数据选择器的控制信号
	beq,		
	bne,
	blt,
	bge,
	bltu,
	bgeu,
	RW_type		//数据存储器的读（写）类型
    );
	input [6:0]opcode;
	input [2:0]func3;
	
	output   MemRead;
	output   MemtoReg;
	output   [1:0]ALUop;
	output   MemWrite;
	output   ALUSrc;
	output   RegWrite;
	output   lui;
	output   U_type;
	output   jal;
	output   jalr;
	output   beq;
	output   bne;
	output   blt;
	output   bge;
	output   bltu;
	output   bgeu;
	output   [2:0]RW_type;
	
	wire branch;
	wire R_type;
	wire I_type;
	wire load;
	wire store;
	wire lui;
	wire auipc;

	
	assign branch=(opcode==`B_type)?1'b1:1'b0;
	assign R_type=(opcode==`R_type)?1'b1:1'b0;
	assign I_type=(opcode==`I_type)?1'b1:1'b0;
	assign U_type=(lui | auipc)? 1'b1:1'b0;
	assign load=(opcode==`load)?1'b1:1'b0;
	assign store=(opcode==`store)?1'b1:1'b0;
	
	assign jal=(opcode==`jal)?1'b1:1'b0;
	assign jalr=(opcode==`jalr)?1'b1:1'b0;
	assign lui=(opcode==`lui)?1'b1:1'b0;
	assign auipc=(opcode==`auipc)?1'b1:1'b0;
	assign beq= branch & (func3==3'b000);
	assign bne= branch & (func3==3'b001);
	assign blt= branch & (func3==3'b100);
	assign bge= branch & (func3==3'b101);
	assign bltu= branch & (func3==3'b110);
	assign bgeu= branch & (func3==3'b111);
	assign RW_type=func3;
	
	
	////enable
	assign MemRead= load;
	assign MemWrite= store;
	assign RegWrite= jal| jalr | load | I_type |R_type | U_type;
	
	////MUX
	assign ALUSrc=load | store |I_type | jalr;  //选择立即数
	assign MemtoReg= load;  //选择数据存储器的数据
	
	////ALUop
	assign ALUop[1]= R_type|branch; //R 10 I 01 B 11 add 00
	assign ALUop[0]= I_type|branch;
	
	
endmodule

//子控制器
module alu_control(
	ALUop,
	func3,
	func7,
	ALUctl
    );
	input [1:0]ALUop;
	input [2:0]func3;
	input func7;
	output [3:0]ALUctl;
	
	wire [3:0]branchop;
	reg  [3:0]RIop;
	
	
	
	assign branchop=(func3[2] & func3[1])? `SLTU : (func3[2] ^ func3[1])? `SLT : `SUB;
	
	always@(*)
	begin
		case(func3)
			3'b000: if(ALUop[1] & func7) //R
					RIop=`SUB;
					else                 //I
					RIop=`ADD;
			3'b001: RIop=`SLL;
			3'b010: RIop=`SLT;
			3'b011: RIop=`SLTU;
			3'b100: RIop=`XOR;
			3'b101: if(func7)
					RIop=`SRA;
					else
					RIop=`SRL;
			3'b110: RIop=`OR;
			3'b111: RIop=`AND;
			default:RIop=`ADD;
		endcase
	end
	
	assign ALUctl=(ALUop[1]^ALUop[0])? RIop:(ALUop[1]&ALUop[0])?branchop:`ADD;

endmodule