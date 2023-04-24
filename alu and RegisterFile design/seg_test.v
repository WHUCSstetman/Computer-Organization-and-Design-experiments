`timescale 1ns / 1ps

module seg_test(clk,rstn,sw_i,disp_seg_o,disp_an_o); //rs1, rs2, rd, RegWrite, WD);
    input clk;
    input rstn;
    input[15:0]sw_i;
    output[7:0]disp_an_o,disp_seg_o;
    
//     input [4:0] rs1,rs2, rd;
//    input RegWrite;
//    input WD;

    
    reg[31:0]clkdiv;
    wire Clk_CPU;
    
always@(posedge clk or negedge rstn) begin
    if(!rstn) clkdiv<=0;
    else clkdiv<=clkdiv+1'b1;end

assign Clk_CPU = (sw_i[15])?clkdiv[27]:clkdiv[25];

reg[63:0]display_data;
reg[5:0]led_data_addr;
reg[63:0]led_disp_data;
parameter LED_DATA_NUM = 19;

reg [63:0]LED_DATA[18:0];
initial begin
    LED_DATA[0]=64'hC6F6F6F0C6F6F6F0;
    LED_DATA[1]=64'hF9F6F6CFF9F6F6CF;
    LED_DATA[2]=64'hFFC6F0FFFFC6F0FF;
    LED_DATA[3]=64'hFFC0FFFFFFC0FFFF;
    LED_DATA[4]=64'hFFA3FFFFFFA3FFFF;//FF9EBCFFFF9EBCFF
    LED_DATA[5]=64'hFFFFA3FFFFFFA3FF;
    LED_DATA[6]=64'hFFFF9CFFFFFF9CFF;
    LED_DATA[7]=64'hFF9EBCFFFF9EBCFF;
    LED_DATA[8]=64'hFF9CFFFFFF9CFFFF;
    LED_DATA[9]=64'hFFC0FFFFFFC0FFFF;
    LED_DATA[10]=64'hFFA3FFFFFFA3FFFF;
    LED_DATA[11]=64'hFFA7B3FFFFA7B3FF;
    LED_DATA[12]=64'hFFC6F0FFFFC6F0FF;
    LED_DATA[13]=64'hF9F6F6CFF9F6F6CF;
    LED_DATA[14]=64'h9EBEBEBC9EBEBEBC;
    LED_DATA[15]=64'h2737373327373733;
    LED_DATA[16]=64'h505454EC505454EC;
    LED_DATA[17]=64'h744454F8744454F8;
    LED_DATA[18]=64'h0062080000620800;
end


//LED_DATA
always@(posedge Clk_CPU or negedge rstn)begin
    if(!rstn)
    begin led_data_addr = 6'd0;
    led_disp_data = 64'b1;
    end
    else if (sw_i[0]==1'b1)begin
        if (led_data_addr==LED_DATA_NUM)
        begin led_data_addr=6'd0;
        led_disp_data=64'b1;
        end
        led_disp_data=LED_DATA[led_data_addr];
        led_data_addr=led_data_addr +1'b1;
    end
    else led_data_addr=led_data_addr;
end

wire[31:0]instr;
reg[31:0]dmem_data;
reg[31:0]alu_disp_data;
reg[31:0]reg_data;
always@(sw_i)begin
if (sw_i[0]==0)begin
case(sw_i[14:11])
    4'b1000:display_data= instr;
    4'b0100:display_data = reg_data;
    4'b0010:display_data=alu_disp_data;
    4'b0001:display_data= dmem_data;
    default:display_data=instr;
    endcase end
    else begin display_data = led_disp_data;
    end
        end

reg[31:0] rom_addr;
always @(posedge Clk_CPU or negedge rstn) begin 
    if (!rstn) begin rom_addr = 31'b0; end
    else if (sw_i[14] == 1'b1) begin 
        rom_addr = rom_addr + 1'b1;
        if (rom_addr == 12) begin rom_addr = 31'b0; end end
    else rom_addr = rom_addr;
    end


wire[31:0] RD1, RD2;
reg[4:0] rs1,rs2,rd;
reg[31:0] WD;

 
reg [4:0] reg_addr;
always @(posedge Clk_CPU or negedge rstn) begin
    if (!rstn) begin
        reg_addr = 5'b0;
    end
    else if ((sw_i[1]) && sw_i[13] == 1'b1) begin
        reg_addr = reg_addr + 1'b1;
        reg_data = U_RF.rf[reg_addr];
    end
end


reg [4:0] ALUOp;
reg [2:0] alu_addr;
wire[31:0] a1;
wire[31:0] b1;
wire[31:0] OUT;
always @(posedge Clk_CPU or negedge rstn) begin 
    if (!rstn) begin
        alu_addr = 3'b0;
    end
    else if(sw_i[12] == 1'b1) begin
        alu_addr = alu_addr + 1'b1;
        case(alu_addr)
            3'b001:alu_disp_data=U_alu.A;
            3'b010:alu_disp_data=U_alu.B;
            3'b011:alu_disp_data=U_alu.C;
            3'b100:alu_disp_data=U_alu.Zero;
            default:alu_disp_data=32'hFFFFFFFF;
            endcase
        end
        
    ALUOp = sw_i[4:3];
    
    end
  
always @(posedge Clk_CPU) begin 
    if(sw_i[2]==0) begin
    rs1=sw_i[10:8];
    rs2=sw_i[7:5];
    end
    else if(sw_i[2]==1) begin
    rd=sw_i[10:8];
    WD=sw_i[7:5];
    
    end
    end

RF U_RF(
    .clk(Clk_CPU),
    .rst(rstn),
    .RFWr(1),
    .sw_i(sw_i),
    .A1(rs1),
    .A2(rs2),
    .A3(rd),
    .WD(OUT),
    .RD1(RD1),
    .RD2(RD2));
    
alu U_alu(
    .ALUOp(ALUOp),
    .A(a1),
    .B(b1)
    );
      
 imm U_immWD(
 .iimj(U_RF.rf[WD]),
 .immout(OUT)
 
    );
imm U_immA(
    .iimj(U_RF.rf[rs1]),
    .immout(a1)
    );
    
imm U_immB(
    .iimj(U_RF.rf[rs2]),
    .immout(b1)
    );
    
  dist_mem_im U_IM(
    .a(rom_addr),
    .spo(instr)
    );

seg7x16 u_seg7x16(
    .clk(clk),
    .rstn(rstn),
    .i_data(display_data),
    .o_seg(disp_seg_o),
    .o_sel(disp_an_o),
    .disp_mode(sw_i[0])
);
endmodule

