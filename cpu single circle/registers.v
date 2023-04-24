`include "define.v"
module registers( 		//寄存器堆
	clk,
	rst_n,
	W_en,
	Rs1,
	Rs2,
	Rd,
	Wr_data,
	Rd_data1,
	Rd_data2
    );
	input clk;
	input rst_n;
	input W_en;
	input [4:0]Rs1;
	input [4:0]Rs2;
	input [4:0]Rd;
	input [31:0]Wr_data;
	
	output [31:0]Rd_data1;
	output [31:0]Rd_data2;
	
	reg [31:0] regs [31:0];

	integer i;
	initial begin
		for (i = 0; i < 32; i = i + 1) begin
			regs[i] <= `zero_word;		//为所有寄存器赋0
		end
	end

//write
	always@(posedge clk)
		begin
		  if(W_en & (Rd!=0))
		  regs[Rd] <= Wr_data;
		end

//read
	assign Rd_data1=(Rs1==5'd0)?`zero_word: regs[Rs1];
	assign Rd_data2=(Rs2==5'd0)?`zero_word: regs[Rs2];
	

endmodule
