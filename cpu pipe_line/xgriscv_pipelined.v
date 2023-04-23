//=====================================================================
//
// Designer   : Yili Gong
//
// Description:
// As part of the project of Computer Organization Experiments, Wuhan University
// In spring 2021
// The overall of the pipelined xg-riscv implementation.
//
// ====================================================================

`include "xgriscv_defines.v"
module xgriscv_sc(
  input                   clk, reset, 
  output[`ADDR_SIZE-1:0]  pcW);
  
  wire [31:0]    instr;
  wire [31:0]    pcF, pcM;
  wire           memwrite;
  wire [3:0]     amp;
  wire [31:0]    addr, writedata, readdata;
   
  imem U_imem(pcF, instr);

  dmem U_dmem(clk, memwrite, amp, addr, writedata, pcM, readdata);
  
  xgriscv U_xgriscv(clk, reset, pcF, instr, memwrite, amp, addr, writedata, pcM, pcW, readdata);
  
endmodule

// xgriscv: a pipelined riscv processor
module xgriscv(input         			        clk, reset,
               output [31:0] 			        pc,
               input  [`INSTR_SIZE-1:0] instr,
               output					              memwrite,
               output [3:0]  			        amp,
               output [`ADDR_SIZE-1:0]  daddr, 
               output [`XLEN-1:0] 		    writedata,
               output [`ADDR_SIZE-1:0] 	pcM,
               output [`ADDR_SIZE-1:0] 	pcW,
               input  [`XLEN-1:0] 		    readdata);
	
  wire [6:0]  opD;
  wire [2:0]  funct3D;
  wire [6:0]  funct7D;
  wire [4:0]  rs1D, rs2D, rdD, rs1E, rs2E, rdE, rdM, rdW;
  wire [11:0] immD;
  wire        zeroD, ltD;
  wire [4:0]  immctrlD;
  wire        itypeD, branchD, jalD, jalrD, bunsignedD, pcsrcD;
  wire [3:0]  aluctrlD;
  wire [1:0]  alusrcaD;
  wire        alusrcbD;
  wire        memwriteD, lunsignedD;
  wire [1:0]  swhbD, lwhbD;
  wire        memtoregD, regwriteD;
  wire        regwriteE, regwriteM, regwriteW;
	wire[1:0]		 forwardaD, forwardbD, forwardaE, forwardbE;

  controller  c(clk, reset, opD, funct3D, funct7D, rdD, rs1D, immD, zeroD, ltD,
              immctrlD, itypeD, branchD, jalD, jalrD, bunsignedD, pcsrcD, 
              aluctrlD, alusrcaD, alusrcbD, 
              memwriteD, lunsignedD, lwhbD, swhbD, 
              memtoregD, regwriteD);

  datapath    dp(clk, reset,
              instr, pc,
              readdata, daddr, writedata, memwrite, amp, pcM, pcW,
              immctrlD, itypeD, branchD, jalD, jalrD, bunsignedD, pcsrcD, 
              aluctrlD, alusrcaD, alusrcbD, 
              memwriteD, lunsignedD, lwhbD, swhbD, 
              memtoregD, regwriteD, 
              opD, funct3D, funct7D, rdD, rs1D, immD, zeroD, ltD);

endmodule
