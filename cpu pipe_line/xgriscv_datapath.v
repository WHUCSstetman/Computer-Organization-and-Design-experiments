`include "xgriscv_defines.v"

module datapath(
	input         			clk, reset,
	input [`INSTR_SIZE-1:0] instrF, 	// from instructon memory
	output[`ADDR_SIZE-1:0] 	pcF, 		// to instruction memory

	input [`XLEN-1:0]  	    readdataM, 	// from data memory: read data
	output[`XLEN-1:0] 		aluoutM, 	// to data memory: address
 	output[`XLEN-1:0]		writedataM, // to data memory: write data
 	output					memwriteM,	// to data memory: write enable
 	output[3:0]  			ampM, 		// to data memory: access memory pattern
 	output [`ADDR_SIZE-1:0]  pcM,       // to data memory: pc of the write instruction
 	
 	output [`ADDR_SIZE-1:0]  pcW,       // to testbench
	
	// from controller
	input [4:0]				immctrlD,
	input					itype, branchD, jalD, jalrD, bunsignedD, pcsrcD,
	input [3:0]				aluctrlD,
	input [1:0]				alusrcaD,
	input					alusrcbD,
	input					memwriteD, lunsignedD,
	input [1:0]				lwhbD, swhbD,  
	input          			memtoregD, regwriteD,
	
	// to controller
	output[6:0]				opD,
	output[2:0]				funct3D,
	output[6:0]				funct7D,
	output[4:0] 			rdD, rs1D,
	output[11:0]  			immD,
	output 	       			zeroD, ltD
	);
	
	wire 		forwardaD, forwardbD, forwardM;
	wire[1:0]	forwardaE, forwardbE;
	wire 		stallF, stallD, flushD, flushE;

	wire[4:0] 	rs2D, waddrW;

	// next PC logic (operates in fetch and decode)
	wire [`ADDR_SIZE-1:0]	 pcplus4F, nextpcF, pcbranchD, pcadder2aD, pcadder2bD, pcbranch0D;
	mux2 #(`ADDR_SIZE)	pcsrcmux(pcplus4F, pcbranchD, pcsrcD, nextpcF);
	
	// Fetch stage logic
	pcenr      	pcreg(clk, reset, ~stallF, nextpcF, pcF); //停顿F时pc保持不变
	addr_adder  pcadder1 (pcF, `ADDR_SIZE'b100, pcplus4F);

	///////////////////////////////////////////////////////////////////////////////////
	// IF/ID pipeline registers
	wire [`INSTR_SIZE-1:0]	instrD;
	wire [`ADDR_SIZE-1:0]	pcD, pcplus4D;
	
	flopenrc #(`INSTR_SIZE) pr1D(clk, reset, ~stallD, flushD, instrF, instrD); // instruction
	flopenrc #(`ADDR_SIZE)	pr2D(clk, reset, ~stallD, flushD, pcF, pcD); // pc
	flopenrc #(`ADDR_SIZE)	pr3D(clk, reset, ~stallD, flushD, pcplus4F, pcplus4D); // pc+4

	// Decode stage logic
	assign  opD 	= instrD[6:0];
	assign  rdD     = instrD[11:7];
	assign  funct3D = instrD[14:12];
	assign  rs1D    = instrD[19:15];
	assign  rs2D   	= instrD[24:20];
	assign  funct7D = instrD[31:25];
	assign  immD    = instrD[31:20];

	// immediate generate
	wire [11:0]	iimmD 	= instrD[31:20];
	wire [11:0]	simmD	= {instrD[31:25], instrD[11:7]};
	wire [11:0] bimmD	= {instrD[31], instrD[7], instrD[30:25], instrD[11:8]};
	wire [19:0]	uimmD	= instrD[31:12];
	wire [19:0] jimmD	= {instrD[31], instrD[19:12], instrD[20], instrD[30:21]};
	wire [`XLEN-1:0]	immoutD, shftimmD;
	wire [`XLEN-1:0]	rdata1D, rdata2D, wdataW;
	wire [`XLEN-1:0] cmpaD, cmpbD, aluoutE;
	
	imm 	im(iimmD, simmD, bimmD, uimmD, jimmD, immctrlD, immoutD);
	// mux for pcadder2's first input
	// mux2 #(`XLEN) pcadder2amux(pcD, rdata1D, jalrD, pcadder2aD); // JALR计算地址要选rs1，Branch和JAL计算地址要选pc
	mux2 #(`XLEN) pcadder2amux(pcD, cmpaD, jalrD, pcadder2aD); // ??jalr??rs1?MEM?????????????MEM-ID?????beq?cmpaD??mux??
	sl1 		  addr_sl1(immoutD, shftimmD);
	// mux for pcadder2's second input
	mux2 #(`XLEN) pcadder2bmux(shftimmD, immoutD, jalrD, pcadder2bD); // JALR计算地址要选immout，Branch和JAL计算地址要选shftimm

	addr_adder	pcadder2 (pcadder2aD, pcadder2bD, pcbranch0D); // 计算分支/跳转指令的目标地址
	assign pcbranchD = {pcbranch0D[31:1], pcbranch0D[0] & !jalrD}; // JALR需要将计算出的地址最低位置0
  
	// register file (operates in decode and writeback)
	regfile rf(clk, rs1D, rs2D, rdata1D, rdata2D, regwriteW, waddrW, wdataW, pcW);

	// shift amount
	wire [4:0]	shamt0D = instrD[24:20];
	wire [4:0]	shamtD;
	mux2 #(5) shamtmux(rdata2D[4:0], shamt0D, itype, shamtD); // itype移位位数来自指令立即数字段，否则来自rs2读出数的低5位
  
	mux2 #(`XLEN)  cmpamux(rdata1D, aluoutM, forwardaD, cmpaD);// cmp srca mux
	mux2 #(`XLEN)  cmpbmux(rdata2D, aluoutM, forwardbD, cmpbD);// cmp srcb mux
	cmp cmp(cmpaD, cmpbD, bunsignedD, zeroD, ltD);

	///////////////////////////////////////////////////////////////////////////////////
	// ID/EX pipeline registers

	// for control signals
	wire       memtoregE, memwriteE, lunsignedE, alusrcbE, jalE;
	wire [1:0] swhbE, lwhbE, alusrcaE;
	wire [3:0] aluctrlE;
	floprc #(16) regE(clk, reset, flushE,
                  {memtoregD, regwriteD, memwriteD, swhbD, lwhbD, lunsignedD, alusrcaD, alusrcbD, aluctrlD, jalD}, 
                  {memtoregE, regwriteE, memwriteE, swhbE, lwhbE, lunsignedE, alusrcaE, alusrcbE, aluctrlE, jalE});
  
	// for data
	wire [`XLEN-1:0]		srca1E, srcb1E, immoutE, srca2E, srca3E, srcb2E, srcb3E, rs2Ef;
	wire [4:0]				rs1E, rs2E, rdE;
	wire [4:0] 				shamtE;
	wire [`ADDR_SIZE-1:0] 	pcE, pcplus4E;
	floprc #(`XLEN) 		pr1E(clk, reset, flushE, rdata1D, srca1E); 	//寄存器读出数据1
	floprc #(`XLEN) 		pr2E(clk, reset, flushE, rdata2D, srcb1E); 	//寄存器读出数据2
	floprc #(`XLEN) 		pr3E(clk, reset, flushE, immoutD, immoutE); //立即数扩展结果
	floprc #(`RFIDX_WIDTH)	pr4E(clk, reset, flushE, rs1D, rs1E); 		//源寄存器地址1
  	floprc #(`RFIDX_WIDTH)  pr5E(clk, reset, flushE, rs2D, rs2E); 		//源寄存器地址2
  	floprc #(`RFIDX_WIDTH)  pr6E(clk, reset, flushE, rdD, rdE);			//目的寄存器地址
  	floprc #(5)  			pr7E(clk, reset, flushE, shamtD, shamtE);	//32位数据的shift操作移位位数
  	floprc #(`ADDR_SIZE)	pr8E(clk, reset, flushE, pcD, pcE); 		//pc
  	floprc #(`ADDR_SIZE)	pr9E(clk, reset, flushE, pcplus4D, pcplus4E); // pc+4


	// execute stage logic
	mux3 #(`XLEN)  srca1mux(srca1E, wdataW, aluoutM, forwardaE, srca2E);// srca1mux
	mux3 #(`XLEN)  srca2mux(srca2E, 0, pcE, alusrcaE, srca3E);			// srca2mux
	mux3 #(`XLEN)  srcb1mux(srcb1E, wdataW, aluoutM, forwardbE, srcb2E);// srcb1mux
	mux2 #(`XLEN)  srcb2mux(srcb2E, immoutE, alusrcbE, srcb3E);			// srcb2mux
	// mux2 #(5)  shamtmux(shamtE, srca2E[4:0], svE, shamt2E); // for RV64I compatibility, to do

	alu alu(srca3E, srcb3E, shamtE, aluctrlE, aluoutE, overflowE, zeroE, ltE, geE);
  
  	///////////////////////////////////////////////////////////////////////////////////
	// EX/MEM pipeline registers
	// for control signals
	wire 		jalM, lunsignedM;
	wire [1:0] 	swhbM, lwhbM;
	wire 		flushM = 0;
	floprc #(9) regM(clk, reset, flushM,
                  {memtoregE, regwriteE, memwriteE, lunsignedE, swhbE, lwhbE, jalE},
                  {memtoregM, regwriteM, memwriteM, lunsignedM, swhbM, lwhbM, jalM});

	// for data
 	wire [`ADDR_SIZE-1:0] 	pcplus4M;
 	wire [`XLEN-1:0]		writedataM1;
 	wire [4:0]				rs2M, rdM;
	floprc #(`XLEN) 		pr1M(clk, reset, flushM, aluoutE, aluoutM);
	floprc #(`XLEN) 		pr2M(clk, reset, flushM, srcb2E, writedataM1);
	floprc #(`RFIDX_WIDTH) 	pr3M(clk, reset, flushM, rs2E, rs2M);
	floprc #(`RFIDX_WIDTH) 	pr4M(clk, reset, flushM, rdE, rdM);
	floprc #(`ADDR_SIZE)	pr5M(clk, reset, flushM, pcplus4E, pcplus4M); // pc+4
	floprc #(`ADDR_SIZE)	pr6M(clk, reset, flushM, pcE, pcM);            // pc

 	wire[`XLEN-1:0] 	memdataW;
	mux2 #(`XLEN)  forwardmmux(writedataM1, wdataW, forwardM, writedataM);
	
  	// memory stage logic
  	ampattern   amp(aluoutM[1:0], swhbM, ampM); // for sw, sh and sb, ampM to data memory
  	
	wire [`XLEN-1:0] membyteM, memhalfM, readdatabyteM, readdatahalfM, memdataM;
  	mux2 #(16) lhmux(readdataM[15:0], readdataM[31:16], aluoutM[1], memhalfM[15:0]); // for lh and lhu
  	wire[`XLEN-1:0] signedhalfM = {{16{memhalfM[15]}}, memhalfM[15:0]}; // for lh
  	wire[`XLEN-1:0] unsignedhalfM = {16'b0, memhalfM[15:0]}; // for lhu
  	mux2 #(32) lhumux(signedhalfM, unsignedhalfM, lunsignedM, readdatahalfM);

  	mux4 #(8) lbmux(readdataM[7:0], readdataM[15:8], readdataM[23:16], readdataM[31:24], aluoutM[1:0], membyteM[7:0]);
  	wire[`XLEN-1:0] signedbyteM = {{24{membyteM[7]}}, membyteM[7:0]}; // for lb
  	wire[`XLEN-1:0] unsignedbyteM = {24'b0, membyteM[7:0]}; // for lbu

  	mux2 #(`XLEN) lbumux(signedbyteM, unsignedbyteM, lunsignedM, readdatabyteM);

  	mux3 #(`XLEN) lwhbmux(readdataM, readdatahalfM, readdatabyteM, lwhbM, memdataM);

	 ///////////////////////////////////////////////////////////////////////////////////
  	// MEM/WB pipeline registers
  	// for control signals
  	wire flushW = 0;
	floprc #(3) regW(clk, reset, flushW,
                  {memtoregM, regwriteM, jalM},
                  {memtoregW, regwriteW, jalW});

  	// for data
  	wire[`XLEN-1:0]			aluoutW, wdata0W, pcplus4W;

	floprc #(`XLEN) 		pr1W(clk, reset, flushW, aluoutM, aluoutW);
	floprc #(`XLEN) 		pr2W(clk, reset, flushW, memdataM, memdataW);
	floprc #(`RFIDX_WIDTH) 	pr3W(clk, reset, flushW, rdM, waddrW);
	floprc #(`ADDR_SIZE)	pr4W(clk, reset, flushW, pcplus4M, pcplus4W); // pc+4, for JAL(store pc+4 to rd)
	floprc #(`ADDR_SIZE)	    pr5W(clk, reset, flushW, pcM, pcW);            // pc

	// write-back stage logic
	mux2 #(`XLEN)  memtoregmux(aluoutW, memdataW, memtoregW, wdata0W);
	mux2 #(`XLEN)  wregmux(wdata0W, pcplus4W, jalW, wdataW); // if jal/jalr, write pc+4 to regfile

	///////////////////////////////////////////////////////////////////////////////////
	//forwarding and hazard detection
	forwarding  f(pcsrcD, memwriteD, branchD, jalrD, 
				regwriteE, memtoregE, memwriteE, regwriteM, memtoregM, memwriteM, regwriteW, memtoregW,
				rs1D, rs2D, rs1E, rs2E, rdE, rs2M, rdM, waddrW,
				forwardaD, forwardbD, forwardaE, forwardbE, forwardM,
				stallF, stallD, flushD, flushE);

endmodule
