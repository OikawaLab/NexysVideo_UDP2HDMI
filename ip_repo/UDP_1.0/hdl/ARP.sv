`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/07/04 19:12:18
// Design Name: 
// Module Name: ARP
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
`include "user_defines.sv"

module ARP(
    input eth_rxck,
    //input clk125,
    //input rst125,
    input rst_rx,
    input start_i,
    input [47:0] myMAC_i,
    input [31:0] myIP_i,
    input [47:0] DstMAC_i,
    input [31:0] DstIP_i,
    
    //output reg tx_en_clk125,
    //output reg arp_tx,
    output reg [8:0] rarp_o
    );
    
    parameter Idle      =  4'h0;   // 待機
    parameter Tx_Ready  =  4'h1;   // 送信準備
    parameter Tx        =  4'h2;   // 送信中
    parameter Tx_End    =  4'h3;   // 送信終了
    
    /* ステートマシン */
    reg [3:0]   st;                    //state machine
    reg [3:0]   nx;                    //next;
    reg [3:0]   rdy_cyc;
    reg [7:0]   go_cyc;
    reg [3:0]   end_cyc;
    wire        s_rdy_done;
    wire        s_go_done;
    wire        s_end_done;
    always_ff @(posedge eth_rxck) begin
            if (rst_rx) st <= Idle;
            else        st <= nx;
    end
    
    always_comb begin
        nx = st;
        case(st)
            Idle : if(start_i) nx = Tx_Ready;
            Tx_Ready : if(s_rdy_done) nx = Tx;
            Tx : if(s_go_done) nx = Tx_End;
            Tx_End : if(s_end_done) nx = Idle;
            default : nx = Idle;
        endcase
    end
    
   always @(posedge eth_rxck) begin
       if(st==Idle)             rdy_cyc <= 4'd0;
       else if(st==Tx_Ready)    rdy_cyc <= rdy_cyc + 4'd1;
       else if(st==Tx_End)      rdy_cyc <= 4'd0;
    end
    assign s_rdy_done = (rdy_cyc==4'd2);
 
    always @(posedge eth_rxck) begin
       if(st==Idle)       end_cyc <= 4'd0;
       else if(st==Tx_End) end_cyc <= end_cyc + 4'd1;
    end
    assign s_end_done = (end_cyc==4'd4);    
    
    
    /* パケット準備 */
    //parameter FTYPE = 16'h08_06;                               // フレームタイプ(ARP=16'h08_06)
    parameter HTYPE = 16'h00_01;                               // ハードウェアタイプ(Erthernet=1)
    parameter PTYPE = 16'h08_00;                               // プロトコルタイプ(IPv4==0800以降)
    parameter HLEN = 8'h06;                                    // ハードウェア長=6
    parameter PLEN = 8'h04;                                    // プロトコル長=4
    parameter OPER = 16'h00_02;                                // オペレーション(要求=1,返信=2)
    
    reg [7:0] TXBUF [63:0];
    integer i;
    always_ff @(posedge eth_rxck)begin
        if(st==Tx_Ready)begin
            {TXBUF[0],TXBUF[1],TXBUF[2],TXBUF[3],TXBUF[4],TXBUF[5]} <= DstMAC_i;
            {TXBUF[6],TXBUF[7],TXBUF[8],TXBUF[9],TXBUF[10],TXBUF[11]} <= myMAC_i; // add 2018.12.5
            {TXBUF[12],TXBUF[13]} <= `FTYPE_ARP;
            {TXBUF[14],TXBUF[15]} <= HTYPE;
            {TXBUF[16],TXBUF[17]} <= PTYPE;
            {TXBUF[18],TXBUF[19]} <= {HLEN,PLEN};
            {TXBUF[20],TXBUF[21]} <= OPER;
            {TXBUF[22],TXBUF[23],TXBUF[24],TXBUF[25],TXBUF[26],TXBUF[27]} <= myMAC_i; // add 2018.12.5
            //{TXBUF[28],TXBUF[29],TXBUF[30],TXBUF[31]} <= `my_IP; 
            {TXBUF[28],TXBUF[29],TXBUF[30],TXBUF[31]} <= myIP_i;                      // add 2018.12.5
            {TXBUF[32],TXBUF[33],TXBUF[34],TXBUF[35],TXBUF[36],TXBUF[37]} <= DstMAC_i;
            {TXBUF[38],TXBUF[39],TXBUF[40],TXBUF[41]} <= DstIP_i;
            for(i=42;i<60;i=i+1)begin
               TXBUF[i] <= 0;
            end
            {TXBUF[60],TXBUF[61],TXBUF[62],TXBUF[63]} <= 32'h01_02_03_04;   // dummy
        end
        else if(st==Idle) begin
            for(i=0;i<8'd64;i=i+1) TXBUF[i] <= 0;
        end
    end
    
//    reg [6:0] clk_cnt;
//    always_ff @(posedge eth_rxck)begin
//        if(st==Tx)begin
//            clk_cnt <= clk_cnt + 1;
//            if(clk_cnt==7'd63) tx_end <= 1; 
//        end
//        else if(st==Idle)begin
//            clk_cnt <= 0;
//            tx_end <= 0;
//        end
//    end

    always_ff @(posedge eth_rxck)begin
        if(st==Tx)          go_cyc <= go_cyc + 8'd1;
        else if(st==Idle)   go_cyc <= 0;
    end
    assign s_go_done = (go_cyc==8'd63);
    
    always_ff @(posedge eth_rxck)begin
        if(st==Tx)  rarp_o[7:0] <= TXBUF[go_cyc];
        else        rarp_o[7:0] <= 8'h77;   // dummy
    end
    
    always_ff @(posedge eth_rxck)begin
        if(st==Tx) begin
            if(go_cyc < 8'd60)  rarp_o[8] <= `HI;
            else                rarp_o[8] <= `LO;
        end
        else                    rarp_o[8] <= `LO;
    end
    
//    reg [2:0] fcs_cnt;
//    always_ff @(posedge eth_rxck)begin
//        if(st==Tx&&clk_cnt<7'd60)begin
//            d <= {1'b1,TXBUF[clk_cnt]};
//            arp_tx <= 1;
//        end
//        else if(st==Tx&&fcs_cnt!=3'b100)begin
//            d <= {1'b0,TXBUF[clk_cnt]};
//            fcs_cnt <= fcs_cnt + 1;
//        end
//        else if(st==Tx&&fcs_cnt==3'b100)begin
//            arp_tx <= 0;
//        end
//        else begin
//            arp_tx <= 0;
//            d <= 0;
//            fcs_cnt <= 0;
//        end
//    end
    
//    reg tx_en;
//    reg tx_en_clk125_d;
//    always_ff @(posedge eth_rxck)begin
//        if(st==Tx) tx_en <= 1'b1;
//        else       tx_en <= 1'b0;
//    end
    
//    always_ff @(posedge clk125)begin
//        tx_en_clk125_d <= tx_en;
//        tx_en_clk125 <= tx_en_clk125_d;
//    end
    
endmodule
