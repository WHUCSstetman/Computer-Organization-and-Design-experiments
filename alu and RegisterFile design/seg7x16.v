`timescale 1ns / 1ps

module seg7x16(
    input clk,
    input rstn,
    input disp_mode,//0：display txt mode  if_1:display gragh mode
    input[63:0]i_data,//要显示的数据,16进制文本或图�?
    output [7:0] o_seg,//数码管段选，设置当前点亮数码管的显示�?
    output [7:0] o_sel//数码管位选，选择当前点亮的数码管位置
);

reg [14:0] cnt;
wire seg7_clk;
always @(posedge clk, negedge rstn)
    if(!rstn)
        cnt <= 0;
    else
        cnt <= cnt+ 1'b1;
    assign seg7_clk=cnt[14];//seg7_clk�?2�?14分频

reg[2:0] seg7_addr;//8选一位�?�，seg7_addr范围�?0-7，seg7_addr=5表示点亮�?5个数码管，�?�过循环刷新的方式点亮全部数码管

always @ (posedge seg7_clk, negedge rstn)
    if(!rstn)
        seg7_addr <= 0;
    else
        seg7_addr <= seg7_addr + 1'b1;

reg[7:0] o_sel_r;//�?共有八个共阳数码管，低电平点亮，�?�?8位二进制位记录点亮状态，�?0的那�?位点�?

    always @ (*)//位�?�可以不�?要电平激�?
    case(seg7_addr)
        7:o_sel_r=8'b01111111;
        6:o_sel_r=8'b10111111;
        5:o_sel_r=8'b11011111;
        4:o_sel_r=8'b11101111;
        3:o_sel_r=8'b11110111;
        2:o_sel_r=8'b11111011;
        1:o_sel_r=8'b11111101;
        0:o_sel_r=8'b11111110;
    endcase

    reg[63:0] i_data_store;
    always @ (posedge clk,negedge rstn)
        if(!rstn)
            i_data_store <=0;
        else//if(cs)
            i_data_store <= i_data;
        
    reg[7:0] seg_data_r;
    always@(*)
    if(disp_mode==1'b0) begin
        case(seg7_addr)
            0:seg_data_r=i_data_store[3:0];
            1:seg_data_r=i_data_store[7:4];
            2:seg_data_r=i_data_store[11:8];
            3:seg_data_r=i_data_store[15:12];
            4:seg_data_r=i_data_store[19:16];
            5:seg_data_r=i_data_store[23:20];
            6:seg_data_r=i_data_store[27:24];
            7:seg_data_r=i_data_store[31:28];
        endcase end
        else begin
            case(seg7_addr)
            0:seg_data_r=i_data_store[7:0];
            1:seg_data_r=i_data_store[15:8];
            2:seg_data_r=i_data_store[23:16];
            3:seg_data_r=i_data_store[31:24];
            4:seg_data_r=i_data_store[39:32];
            5:seg_data_r=i_data_store[47:40];
            6:seg_data_r=i_data_store[55:48];
            7:seg_data_r=i_data_store[63:56];
            endcase end

    //seg_data_r：当前显示数据的2进制表示 
    reg[7:0] o_seg_r;    
    always @(posedge clk,negedge rstn)
        if(!rstn)
            o_seg_r <=8'hff;
            else if(disp_mode==1'b0)begin
            case(seg_data_r)
          4'h0 : o_seg_r <= 8'hC0;
            4'h1 : o_seg_r <= 8'hF9;
            4'h2 : o_seg_r <= 8'hA4;
            4'h3 : o_seg_r <= 8'hB0;
            4'h4 : o_seg_r <= 8'h99;
            4'h5 : o_seg_r <= 8'h92;
            4'h6 : o_seg_r <= 8'h82;
            4'h7 : o_seg_r <= 8'hF8;
            4'h8 : o_seg_r <= 8'h80;
            4'h9 : o_seg_r <= 8'h90;
            4'hA : o_seg_r <= 8'h88;
            4'hB : o_seg_r <= 8'h83;
            4'hC : o_seg_r <= 8'hC6;
            4'hD : o_seg_r <= 8'hA1;
            4'hE : o_seg_r <= 8'h86;
            4'hF : o_seg_r <= 8'h8E;
            default:o_seg_r<=8'hFF;
            endcase end
            else begin o_seg_r<= seg_data_r;//图形模式
            end

        assign o_sel=o_sel_r;
        assign o_seg = o_seg_r;
endmodule

