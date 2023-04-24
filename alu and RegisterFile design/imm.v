`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: imm
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


module imm(
    input [2:0] iimj,
    output reg[31:0] immout
    );
always@(*)
    begin
    if(iimj[2]>0) begin immout={36'b11111111_11111111_11111111_11111111_1111,iimj[2:0]}; end
    else begin immout<={36'b0,iimj[2:0]}; end
    end
endmodule
