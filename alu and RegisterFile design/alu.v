`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: alu
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
`define ALUOp_add 5'b00001
`define ALUOp_sub 5'b00000
`define ALUOp_mul 5'b00010
`define ALUOp_or 5'b00011

module alu(
    input signed [31:0] 	A, B,  
    input [4:0]  			ALUOp, 
    output reg signed [31:0] 	C, 
    output reg [7:0] 		Zero
); 
always@(*)
    begin
    case(ALUOp)
        `ALUOp_add:C=A+B;
        `ALUOp_sub:C=A-B;
        `ALUOp_mul:C=A*B;
        `ALUOp_or:C=A|B;
    endcase
    Zero = (C==0)?1:0;
    end
endmodule
