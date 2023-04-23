module alu(
	   ALU_DA,
       ALU_DB,
       ALU_CTL,
       ALU_ZERO,
       ALU_OverFlow,
       ALU_DC   
        );
	input [31:0]    ALU_DA;
    input [31:0]    ALU_DB;
    input [3:0]     ALU_CTL;	//ALU的控制信号
    output          ALU_ZERO;
    output          ALU_OverFlow;
    output reg [31:0]   ALU_DC;
		   
//********************产生控制信号***********************
wire SUBctr;
wire SIGctr;
wire Ovctr;
wire [1:0] Opctr;
wire [1:0] Logicctr;
wire [1:0] Shiftctr;

assign SUBctr = (~ ALU_CTL[3]  & ~ALU_CTL[2]  & ALU_CTL[1]) | ( ALU_CTL[3]  & ~ALU_CTL[2]);
assign Opctr = ALU_CTL[3:2];	//判断为哪种运算，便于后面进行选择输出
assign Ovctr = ALU_CTL[0] & ~ ALU_CTL[3]  & ~ALU_CTL[2] ;	//判断是否为减法运算
assign SIGctr = ALU_CTL[0];
assign Logicctr = ALU_CTL[1:0];		//区分4个逻辑运算
assign Shiftctr = ALU_CTL[1:0]; 	//区分3个移位运算

//********************************************************

//*********************逻辑运算***************************
reg [31:0] logic_result;

always@(*) begin
    case(Logicctr)
	2'b00:logic_result = ALU_DA & ALU_DB;
	2'b01:logic_result = ALU_DA | ALU_DB;
	2'b10:logic_result = ALU_DA ^ ALU_DB;
	2'b11:logic_result = ~(ALU_DA | ALU_DB);
	endcase
end 

//********************************************************
//************************移位运算************************
wire [4:0]     ALU_SHIFT;
wire [31:0]    shift_result;
assign ALU_SHIFT = ALU_DB[4:0];		//第二个操作数作为移位数

Shifter Shifter(.ALU_DA(ALU_DA),
                .ALU_SHIFT(ALU_SHIFT),
				.Shiftctr(Shiftctr),
				.shift_result(shift_result));

//********************************************************
//************************加、减运算**********************
wire [31:0] BIT_M,XOR_M;
wire ADD_carry,ADD_OverFlow;
wire [31:0] ADD_result;

assign BIT_M={32{SUBctr}};
assign XOR_M=BIT_M^ALU_DB;

Adder Adder(.A(ALU_DA),
            .B(XOR_M),
			.Cin(SUBctr),
			.ALU_CTL(ALU_CTL),
			.ADD_carry(ADD_carry),
			.ADD_OverFlow(ADD_OverFlow),
			.ADD_zero(ALU_ZERO),
			.ADD_result(ADD_result));

assign ALU_OverFlow = ADD_OverFlow & Ovctr;

//********************************************************
//**************************小于置一运算************************
wire [31:0] SLT_result;
wire LESS_M1,LESS_M2,LESS_S,SLT_M;

assign LESS_M1 = ADD_carry ^ SUBctr;
assign LESS_M2 = ADD_OverFlow ^ ADD_result[31];
assign LESS_S = (SIGctr==1'b0)?LESS_M1:LESS_M2;
assign SLT_result = (LESS_S)?32'h00000001:32'h00000000;

//********************************************************
//**************************ALU result********************
always @(*) 
begin
  case(Opctr)	//判断为哪种运算并赋值给ALU_DC
     2'b00:ALU_DC<=ADD_result;
     2'b01:ALU_DC<=logic_result;
     2'b10:ALU_DC<=SLT_result;
     2'b11:ALU_DC<=shift_result; 
  endcase
end

//********************************************************
endmodule


//********************************************************
//*************************shifter************************
//`define BEHAVOR
module Shifter(input [31:0] ALU_DA,
               input [4:0] ALU_SHIFT,
			   input [1:0] Shiftctr,
			   output reg [31:0] shift_result);

	wire [5:0] shift_n;
	assign shift_n = 6'd32 - ALU_SHIFT;	//用于算数移位的最高位移位数
	always@(*) begin
	  case(Shiftctr)
	  2'b00:shift_result = ALU_DA << ALU_SHIFT;
	  2'b01:shift_result = ALU_DA >> ALU_SHIFT;
	  2'b10:shift_result = ({32{ALU_DA[31]}} << shift_n) | (ALU_DA >> ALU_SHIFT);
	  default:shift_result = ALU_DA;
	  endcase
	end

endmodule


//*************************************************************
//***********************************adder*********************

//`define ALGORITHM
module Adder(input [31:0] A,
             input [31:0] B,
			 input Cin,
			 input [3:0] ALU_CTL,
			 output ADD_carry,
			 output ADD_OverFlow,
			 output ADD_zero,
			 output [31:0] ADD_result);

`ifdef ALGORITHM
    assign {ADD_carry,ADD_result}=A+B+Cin;
`else
    cla_adder32 cla_adder32_inst1(.A(A),
	                        .B(B),
							.cin(Cin),
							.cout(ADD_carry),
							.result(ADD_result));	
`endif

   assign ADD_zero = ~(|ADD_result);
   assign ADD_OverFlow=((ALU_CTL==4'b0001) & ~A[31] & ~B[31] & ADD_result[31]) 
                      | ((ALU_CTL==4'b0001) & A[31] & B[31] & ~ADD_result[31])
                      | ((ALU_CTL==4'b0011) & A[31] & ~B[31] & ~ADD_result[31]) 
					  | ((ALU_CTL==4'b0011) & ~A[31] & B[31] & ADD_result[31]);
endmodule

//************************************************************************************
//***************************************cla_adder************************************

//
module cla_4(p,g,c_in,c,gx,px);
input[3:0] p,g;
input c_in;
output[4:1] c;
output gx,px;

assign c[1] = p[0]&c_in | g[0];
assign c[2] = p[1]&p[0]&c_in | p[1]&g[0] | g[1];
assign c[3] = p[2]&p[1]&p[0]&c_in | p[2]&p[1]&g[0] | p[2]&g[1] | g[2];
assign c[4] = gx | px&c_in;

assign px = p[3]&p[2]&p[1]&p[0];
assign gx = g[3] | p[3]&g[2] | p[3]&p[2]&g[1] | p[3]&p[2]&p[1]&g[0];

endmodule



module cla_adder32(A,B,cin,result,cout);

input [31:0] A;
input [31:0] B;
input cin;
output[31:0] result;
output cout;


wire[31:0] TAG,TAP;
wire[32:1] TAC;
wire[15:0] TAG_0,TAP_0;
wire[3:0] TAG_1,TAP_1;
wire[8:1] TAC_1;
wire[4:1] TAC_2;
 
assign result = A ^ B ^ {TAC[31:1],cin};  
assign TAG = A&B;
assign TAP = A|B;

cla_4 cla_0_0( .p(TAP[3:0]),  .g(TAG[3:0]),  .c_in(cin), .c(TAC[4:1]),  .gx(TAG_0[0]),.px(TAP_0[0]));
cla_4 cla_0_1( .p(TAP[7:4]),  .g(TAG[7:4]),  .c_in(TAC_1[1]),.c(TAC[8:5]),  .gx(TAG_0[1]),.px(TAP_0[1]));
cla_4 cla_0_2( .p(TAP[11:8]), .g(TAG[11:8]), .c_in(TAC_1[2]),.c(TAC[12:9]), .gx(TAG_0[2]),.px(TAP_0[2]));
cla_4 cla_0_3( .p(TAP[15:12]),.g(TAG[15:12]),.c_in(TAC_1[3]),.c(TAC[16:13]),.gx(TAG_0[3]),.px(TAP_0[3]));
cla_4 cla_0_4( .p(TAP[19:16]),.g(TAG[19:16]),.c_in(TAC_1[4]),.c(TAC[20:17]),.gx(TAG_0[4]),.px(TAP_0[4]));
cla_4 cla_0_5( .p(TAP[23:20]),.g(TAG[23:20]),.c_in(TAC_1[5]),.c(TAC[24:21]),.gx(TAG_0[5]),.px(TAP_0[5]));
cla_4 cla_0_6( .p(TAP[27:24]),.g(TAG[27:24]),.c_in(TAC_1[6]),.c(TAC[28:25]),.gx(TAG_0[6]),.px(TAP_0[6]));
cla_4 cla_0_7( .p(TAP[31:28]),.g(TAG[31:28]),.c_in(TAC_1[7]),.c(TAC[32:29]),.gx(TAG_0[7]),.px(TAP_0[7]));


////////////////////////
cla_4 cla_1_0(.p(TAP_0[3:0]),  .g(TAG_0[3:0]),  .c_in(cin),.c(TAC_1[4:1]),  .gx(TAG_1[0]),.px(TAP_1[0]));


cla_4 cla_1_1(.p(TAP_0[7:4]),  .g(TAG_0[7:4]),  .c_in(TAC_1[4]),.c(TAC_1[8:5]),  .gx(TAG_1[1]),.px(TAP_1[1]));

assign TAG_1[3:2] = 2'b00;
assign TAP_1[3:2] = 2'b00;

cla_4 cla_2_0(.p(TAP_1[3:0]),   .g(TAG_1[3:0]),    .c_in(1'b0), .c(TAC_2[4:1]),  .gx(),.px());

assign cout = TAC_2[2];

endmodule


