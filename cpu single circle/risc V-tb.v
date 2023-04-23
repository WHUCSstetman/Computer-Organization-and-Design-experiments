`timescale 1ns/1ps
module tb_riscv_top;

	reg clk;
	reg rst_n;

	wire [7:0] rom_addr;

	riscv_top uut (
		.clk(clk), 
		.rst_n(rst_n), 
		.rom_addr(rom_addr)
	);
	always #10 clk= ~clk;
	initial begin
		// 初始化
		clk = 1;
		rst_n = 0;

		// 20ns(刚好一周期)后开始运行
		#20;
		rst_n=1;

	end
      
endmodule

