`include "C:/Users/77247/Desktop/123/define.v"
module data_memory(		//数据存储器
	clk,
	rst_n,
	W_en,
	R_en,
	addr,
	RW_type,
	din,
	dout
    );
	
	
	input clk;		//时钟信号
	input rst_n;	//读出的指令
	
	input W_en;		//写使能信号
	input R_en;		//读使能信号
	
	input [31:0]addr;	//读or写的地址
	input [2:0]RW_type;	//读or写的类型：字节、半字、字、双字

	input [31:0]din;	//要写入寄存器的值
	output [31:0]dout;	//从数据存储器中读出的数据


	reg [31:0]ram[255:0];	//ram表示数据存储器，初始化时应该就是没有数据，先存再读
	
	wire [31:0]Rd_data;		//表示要读的数据，默认为一个字32位
	
	reg [31:0]Wr_data_B;		//字节拼接
	wire [31:0]Wr_data_H;		//半字拼接
	wire [31:0]Wr_data;			//默认位一个字
	
	assign Rd_data = ram[addr[31:2]];		//读基准

//RW_type对应的指令：
//(1)000：lb,sb  (2)001：lh,sh  (3)010：lw,sw  (4)100：lbu  (5)101：lhu

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

//下面这段指令的作用是判断字节写入时，要写入的数据在双字中的哪个位置
always@(*)
	begin
		case(addr[1:0])
			2'b00:Wr_data_B={Rd_data[31:8],din[7:0]};
			2'b01:Wr_data_B={Rd_data[31:16],din[7:0],Rd_data[7:0]};
			2'b10:Wr_data_B={Rd_data[31:24],din[7:0],Rd_data[15:0]};
			2'b11:Wr_data_B={din[7:0],Rd_data[23:0]};
		endcase
	end

//下面这段指令的作用是判断半字写入时，要写入的数据在双字中的哪个位置
assign Wr_data_H=(addr[1]) ? {din[15:0],Rd_data[15:0]} : {Rd_data[31:16],din[15:0]} ;
	
//根据写类型，选择写入的数据
assign Wr_data=(RW_type[1:0]==2'b00) ? Wr_data_B :( (RW_type[1:0]==2'b01) ? Wr_data_H : din   );

always@(posedge clk)	//上升沿写入数捿
begin
	if(W_en)
		ram[addr[9:2]]<=Wr_data;
end

 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////读部刿


reg [7:0]Rd_data_B;
wire [15:0]Rd_data_H;

wire [31:0] Rd_data_B_ext;
wire [31:0] Rd_data_H_ext;

always@(*)
begin
	case(addr[1:0])
		2'b00:Rd_data_B=Rd_data[7:0];
		2'b01:Rd_data_B=Rd_data[15:8];
		2'b10:Rd_data_B=Rd_data[23:16];
		2'b11:Rd_data_B=Rd_data[31:24];
	endcase
end
		
assign Rd_data_H=(addr[1])? Rd_data[31:16]:Rd_data[15:0];

//进行符号扩展，先判断是否为符号扩展，然后进行32位扩展
assign Rd_data_B_ext=(RW_type[2]) ? {24'd0,Rd_data_B} : {{24{Rd_data_B[7]}},Rd_data_B};

assign Rd_data_H_ext=(RW_type[2]) ? {16'd0,Rd_data_H} : {{16{Rd_data_H[15]}},Rd_data_H};


//根据写类型，选择读出的数据
assign dout=(RW_type[1:0]==2'b00) ? Rd_data_B_ext : ((RW_type[1:0]==2'b01) ? Rd_data_H_ext : Rd_data );


endmodule