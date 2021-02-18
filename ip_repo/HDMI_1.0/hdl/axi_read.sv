`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/24 16:45:16
// Design Name: 
// Module Name: axi_read
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
`include "struct_list.vh"
module axi_read(
    input           clk_i,
    input           reset,
    input           VGA_VS,
    input           empty,
    output [1:0]    M_AXI_ARID,
    output [28:0]   M_AXI_ARADDR,
    output [7:0]    M_AXI_ARLEN,
    output [2:0]    M_AXI_ARSIZE,
    output [1:0]    M_AXI_ARBURST,
    output          M_AXI_ARLOCK,
    output [3:0]    M_AXI_ARCACHE,
    output [2:0]    M_AXI_ARPROT,
    output [3:0]    M_AXI_ARQOS,
    output          M_AXI_ARVALID,
    input           M_AXI_ARREADY
    );
    
    /*---signal---*/
    wire    axi_arready;
    
    assign M_AXI_ARID = axi_ar.id;
    assign M_AXI_ARADDR = axi_ar.addr;
    assign M_AXI_ARLEN = axi_ar.len;
    assign M_AXI_ARSIZE = axi_ar.size;
    assign M_AXI_ARBURST = axi_ar.burst;
    assign M_AXI_ARLOCK = axi_ar.lock;
    assign M_AXI_ARCACHE = axi_ar.cache;
    assign M_AXI_ARPROT = axi_ar.prot;
    assign M_AXI_ARQOS = axi_ar.qos;
    assign M_AXI_ARVALID = axi_ar.valid;
    assign axi_arready = M_AXI_ARREADY;
    
    /*---wire/register---*/
    AXI_AR      axi_ar;
    
    /*---parameter---*/
    parameter   IDLE    =   4'h0;
    parameter   ARCH    =   4'h1;
    parameter   AR_OK   =   4'h2;
    
    parameter   STBY    =   4'h3;
    parameter   READ    =   4'h4;
    parameter   REND    =   4'h5;
    
    parameter   transaction_num =   4'd3;   // トランザクションの数(640回連続では送れないため)
    
    /*---ステートマシン(AR_CH)---*/
    reg [3:0] st_ar;
    reg [3:0] nx_ar;
    reg [1:0] transaction_cnt;
    reg [1:0] read_end;
    reg [1:0] shift;
    wire    rd_start = (shift==2'b01);
    wire    VGA_VS_n = !VGA_VS;
    wire    archannel_ok = (axi_arready&&axi_ar.valid);
    wire    ar_end = archannel_ok&&(transaction_cnt==transaction_num-1);
    always_ff @(posedge clk_i)begin
        if(reset)   st_ar <= IDLE;
        else        st_ar <= nx_ar;
    end
    
    always_comb begin
        nx_ar = st_ar;
        case (st_ar)
            IDLE : begin
                if (rd_start) nx_ar = ARCH;
            end
            ARCH : begin
                if (ar_end) nx_ar = AR_OK;
            end
            AR_OK :begin
                nx_ar = IDLE;
            end
            default : begin
            end
        endcase
    end    
    
    always_ff @(posedge clk_i)begin
        if(reset||VGA_VS_n) shift <= 2'b0;
        else                shift <= {shift[0],empty};
    end

    /*---トランザクション数をカウント---*/
    always_ff @(posedge clk_i)begin
        if(st_ar==ARCH)begin
            if(archannel_ok)begin
                transaction_cnt <= transaction_cnt + 2'b1;
            end
        end
        else begin
            transaction_cnt <= 2'b0;
        end
    end                                         
    
    /*---AR_CH---*/
    always_ff @(posedge clk_i)begin
        if(st_ar==ARCH)begin
            axi_ar.id       <=  1'b0;
            axi_ar.len      <=  (transaction_cnt==2'd2) ? 8'd127 : 8'd255;
            axi_ar.size     <=  3'b010;
            axi_ar.burst    <=  2'b01;
            axi_ar.lock     <=  2'b0;
            axi_ar.cache    <=  4'b0011;
            axi_ar.prot     <=  3'b0;
            axi_ar.qos      <=  4'b0;
        end
        else if(st_ar==IDLE)begin
            axi_ar.id       <= 1'b0;
            axi_ar.len      <= 8'h0;
            axi_ar.size     <= 3'b0;
            axi_ar.burst    <= 2'b0;
            axi_ar.lock     <= 2'b0;
            axi_ar.cache    <= 4'b0;
            axi_ar.prot     <= 3'b0;
            axi_ar.qos      <= 4'b0;        
        end
    end
    /*--address--*/
    wire addr_reset = VGA_VS_n;
    reg [28:0] address_buff;
    always_ff @(posedge clk_i)begin
        if(addr_reset) address_buff <= 29'd0;       // 読み出し開始地点(nomal)
        else if(archannel_ok) address_buff <= (transaction_cnt==2'd2) ? address_buff + 11'd512 : address_buff + 11'd1024;
    end
    assign axi_ar.addr = address_buff;
    
    /*--valid--*/
    always_ff @(posedge clk_i)begin
        if(st_ar==ARCH)begin
            if(archannel_ok)begin
                axi_ar.valid <= 1'b0;
            end
            else begin
                axi_ar.valid <= 1'b1;
            end
        end
        else if (st_ar==AR_OK)begin
            axi_ar.valid    <= 1'b0;
        end
        else if (st_ar==IDLE)begin
            axi_ar.valid    <= 1'b0;
        end
    end
    
endmodule
