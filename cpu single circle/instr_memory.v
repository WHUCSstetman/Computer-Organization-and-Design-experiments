module instr_memory(    //指令存储器，用来从本地读指令机器码
	addr,
	instr
    );
	input [7:0]addr;        //指令存储器有256个，故要用8位地址
	output [31:0]instr;     //一个指令有32位
	
	reg[31:0] rom[255:0];   //定义一个能存储256条指令的指令存储器rom
	
    //rom进行初始化
    initial begin
        //从本地txt文件中读取16进制机器码，若想要读取2进制，将h改为b即可
        $readmemh("C:/Users/77247/Desktop/123/test/riscv32_sim6.txt", rom);
    end
	
    assign instr = rom[addr];   //对出口instr进行赋值

endmodule