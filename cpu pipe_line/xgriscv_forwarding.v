`include "xgriscv_defines.v"

module forwarding(
	input			pcsrcD, memwriteD, branchD, jalrD,
					regwriteE, memtoregE, memwriteE, regwriteM, memtoregM, memwriteM, regwriteW, memtoregW,
	input [4:0]		rs1D, rs2D, rs1E, rs2E, rdE, rs2M, rdM, rdW,
	output			forwardaD, forwardbD,
	output[1:0] 	forwardaE, forwardbE,
	output			forwardM,
	output			stallF, stallD, flushD, flushE);

	//for beq in the ID stage
	//WB阶段的指令前半周期写，ID阶段的指令后半周期读，所以不需要转发
	//EX阶段指令写ID阶段beq读，那么需要停顿而不是转发
	//所以只有MEM阶段指令不是load而且要写寄存器，而beq要读该寄存器，才需要转发；如果是load还需要再停顿一个周期
	//如果和WB阶段的指令有数据依赖，可以前半周期写后半周期读解决
	assign forwardaD = regwriteM & (rdM != 0) & ~memtoregM & (rdM == rs1D);
	assign forwardbD = regwriteM & (rdM != 0) & ~memtoregM & (rdM == rs2D);
	
	//for ops in the EX stage
	wire forwardaEfromM = regwriteM & (rdM != 0) & (rdM == rs1E);
	wire forwardaEfromW = !forwardaEfromM & regwriteW & (rdW != 0) & (rdW == rs1E);
	assign forwardaE = ({2{forwardaEfromM}} & 2'b10) | ({2{forwardaEfromW}} & 2'b01);

	wire forwardbEfromM = regwriteM & (rdM != 0) & (rdM == rs2E);
	wire forwardbEfromW = !forwardbEfromM & regwriteW & (rdW != 0) & (rdW == rs2E);
	assign forwardbE = ({2{forwardbEfromM}} & 2'b10) | ({2{forwardbEfromW}} & 2'b01);

	//for ops in the MEM stage
	//前面一条指令写，后面一条是store指令要存这个写入的数
	assign forwardM = (memwriteM & regwriteW & rs2M == rdW);

	//stalls
	//EX阶段指令是lw，ID阶段指令不是sw，那么是一个load-use的冒险
	wire lwstallD = ~memwriteD & memtoregE & ((rdE == rs1D) | (rdE == rs2D)); 
	//ID阶段指令是branch指令，EX阶段指令写branch的源操作数，或者MEM阶段是lw指令，读出branch的源操作数 
	wire bstallD  = branchD & ((regwriteE & ((rdE == rs1D) | (rdE == rs2D))) 
								  | (memtoregM & ((rdM == rs1D) | (rdM == rs2D))));
	//ID阶段是jalr指令，EX阶段指令写jalr的rs1寄存器，或者MEM阶段的指令是lw，读出jalr的rs1寄存器的值
	wire jalrstallD  = jalrD & ((regwriteE & (rdE == rs1D)) | (memtoregM & (rdM == rs1D)));

	//stall ID的指令意味着同时stall IF的指令以及新EX的指令为空，即flushE
	assign stallD = lwstallD | bstallD | jalrstallD;
	assign stallF = stallD;
	assign flushE = stallD;

	assign flushD = pcsrcD & ~stallD; //如果不stallD，
	//且如果ID阶段指令是无条件跳转，或者条件跳转满足，pcsrc要选择新目标地址，那么就应该flushD，清除pc+4处取出的指令

endmodule
