`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/07/25 15:50:07
// Design Name: 
// Module Name: ping
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

module ping(
    /*---Input---*/
    eth_rxck,
    rst_rx,
    rxd_i,
    els_packet,
    ping_st,
    my_MAC_i,
    my_IP_i,
    //DstMAC,
    //DstIP,
    /*---Output---*/
    ping_o
    );

    /*---I/O---*/
    input           eth_rxck;
    input           rst_rx;
    input [8:0]     rxd_i;
    input           els_packet;
    input           ping_st;
    input [47:0]    my_MAC_i;
    input [31:0]    my_IP_i;

    output reg [8:0] ping_o;
    
    /*---parameter---*/
    parameter   Idle    =   8'h00;
    parameter   Stby    =   8'h0D;
    parameter   Presv   =   8'h01;
    parameter   Hcsum   =   8'h02;
    parameter   Hc_End  =   8'h03;
    parameter   Icsum   =   8'h04;
    parameter   Ic_End  =   8'h05;
    parameter   Ready   =   8'h06;
    parameter   Tx_Hc   =   8'h07;
    parameter   Tx_HEnd =   8'h08;
    parameter   Tx_Ic   =   8'h09;
    parameter   Tx_IEnd =   8'h0A;
    parameter   Tx_En   =   8'h0B;
    parameter   Tx_End  =   8'h0C; 
    
    parameter   TTL     =   16'd255;
    //parameter   ip_head =   4'd14;
    //parameter   icmp    =   6'd34;
    //parameter   FTYPE   =   16'h08_00;
    parameter   V_I_T   =   16'h45_00;  // Version/IHL, TOS
    parameter   Protocol=   8'h01;
    parameter   ByteLen =   16'd102;
    
    /*---wire/register---*/
    (*dont_touch="true"*)reg [7:0] RXBUF [255:0];
    (*dont_touch="true"*)reg [7:0] TXBUF [255:0];
    reg [47:0] tx_dstMAC;
    reg [31:0] tx_dstIP;
    reg [15:0] ToLen;   // Total Length
    reg [15:0] Ident;
    reg [15:0] SeqNum;
//    reg [7:0] ICMP_Msg [255:0];
    
    wire [47:0] rx_dstMAC    = {RXBUF[0],RXBUF[1],RXBUF[2],RXBUF[3],RXBUF[4],RXBUF[5]};
    wire [47:0] rx_srcMAC    = {RXBUF[6],RXBUF[7],RXBUF[8],RXBUF[9],RXBUF[10],RXBUF[11]};
    wire [15:0] rx_FTYPE     = {RXBUF[12],RXBUF[13]};
    wire [15:0] rx_ToLen     = {RXBUF[16],RXBUF[17]};
    
    /*---ステートマシン---*/
    (*dont_touch="true"*)reg [7:0]   st;
    reg [7:0]   nx;
    reg [7:0]   rx_cnt;     // データ数
    reg         tx_end;
    reg [2:0]   end_cnt;
    (*dont_touch="true"*)reg [7:0]   csum_cnt;
    (*dont_touch="true"*)reg         csum_ok;
    reg [2:0]   err_cnt;
    reg [2:0]   ready_cnt;
    
    wire hcsum_end = (csum_cnt==8'd34);
    wire hcend_end = (err_cnt==3'd7);
    wire icsum_end = (csum_cnt==rx_cnt-8'd3);
    wire icend_end = (err_cnt==3'd7);
    wire txhc_end  = (csum_cnt==8'd34);
    wire txic_end  = (csum_cnt==rx_cnt-8'd3);
    wire pres_end  = (rx_cnt>=8'd255);
    
    always_ff @(posedge eth_rxck) begin
        if (rst_rx) st <= Idle;
        else        st <= nx;
    end
    
    always_comb begin
        nx = st;
        case(st)
            Idle : begin
                if(rxd_i[8]) nx = Stby;
            end
            Stby : begin
                if(rxd_i[8]) begin
                    if(rxd_i[7:0]==`SFD) nx = Presv;
                    else if(rxd_i[7:0]==`PREAMB) nx = Stby;
                    else nx=Idle;
                end 
                else nx = Idle;                
            end
            Presv : begin
                if(els_packet)  nx = Idle;
                else if(ping_st) nx = Hcsum;
                else if(pres_end) nx = Idle;
            end
            Hcsum : if(hcsum_end) nx = Hc_End;
            Hc_End : if(hcend_end)begin
                         if(csum_ok)    nx = Icsum;     // checksum correct.
                         else           nx = Idle;      // checksum error.
                     end
            Icsum : if(icsum_end) nx = Ic_End;  // add 2019.1.9
            Ic_End : if(icend_end)begin
                         if(csum_ok)    nx = Ready;
                         else           nx = Idle;
                     end
            Ready : nx = Tx_Hc;
            Tx_Hc : if(txhc_end) nx = Tx_HEnd;
            Tx_HEnd : if(err_cnt==3'd7) nx = Tx_Ic;
            Tx_Ic : if(txic_end) nx = Tx_IEnd; // add 2018.11.20
            Tx_IEnd : if(err_cnt==3'd7) nx = Tx_En;
            Tx_En : if(tx_end) nx = Tx_End;
            Tx_End : if(end_cnt==3'd7) nx = Idle;
        endcase
    end
    
    /*---データ数/RXBUF保持---*/
    integer j;
    //always_ff @(posedge ping_st)begin
    always_ff @(posedge eth_rxck)begin
        if (st==Presv) begin
            RXBUF[rx_cnt]  <= rxd_i[7:0];
        end
    end 
    
    always_ff @(posedge eth_rxck)begin
        if(st==Hcsum)begin
            tx_dstMAC <= rx_srcMAC;
            tx_dstIP  <= {RXBUF[26],RXBUF[27],RXBUF[28],RXBUF[29]};
            ToLen   <= rx_ToLen;;
            Ident   <= {RXBUF[38],RXBUF[39]};
            SeqNum  <= {RXBUF[40],RXBUF[41]};
        end
        else if(st==Idle)begin
            tx_dstMAC <= 48'b0;
            tx_dstIP  <= 32'b0;
            ToLen   <= 16'b0;
            Ident   <= 16'b0;
            SeqNum  <= 16'b0;
        end
    end
    
//    integer msg_cnt;
//    always_ff @(posedge eth_rxck)begin
//        if(st==Hcsum)begin
//            for(msg_cnt=0;msg_cnt<(256-46);msg_cnt=msg_cnt+1) ICMP_Msg[msg_cnt] <= RXBUF[msg_cnt+42];
//        end
//        else if(st==Idle) begin
//            for(msg_cnt=0;msg_cnt<256;msg_cnt=msg_cnt+1) ICMP_Msg[msg_cnt] <= 8'b0;
//        end
//    end
    
    always_ff @(posedge eth_rxck)begin
        if(st==Presv)begin
            if(rxd_i[8]) rx_cnt <= rx_cnt + 8'd1;
        end
        else if(st==Idle)begin
            rx_cnt <= 0;
        end
    end
    
    /*---リセット信号---*/
    reg chksum_rst;
    always_ff @(posedge eth_rxck)begin
        if(st==Idle) chksum_rst <= 1;
        else         chksum_rst <= 0;
    end
    
    /*---チェックサム用データ---*/
    reg [7:0]       chksum_data;
    reg             chksum_en;
    (*dont_touch="true"*)reg [15:0]      chksum_o;
    
    always_ff @(posedge eth_rxck)begin         
        if(st==Idle)       csum_cnt <= 0;
        else if(st==Hcsum) csum_cnt <= csum_cnt + 1;
        else if(st==Icsum) csum_cnt <= csum_cnt + 1;
        else if(st==Tx_Hc) csum_cnt <= csum_cnt + 1;
        else if(st==Tx_Ic) csum_cnt <= csum_cnt + 1;
        else               csum_cnt <= 0; 
    end
    
    /*---チェックサム用データ---*/
    always_ff @(posedge eth_rxck)begin    // 最初の14bitはMACヘッダ
        if(st==Hcsum)       chksum_data <= RXBUF[csum_cnt];
        else if(st==Icsum)  chksum_data <= RXBUF[csum_cnt];
        else if(st==Tx_Hc)  chksum_data <= TXBUF[csum_cnt];
        else if(st==Tx_Ic)  chksum_data <= TXBUF[csum_cnt];
        else                chksum_data <= 0;
    end
    
    /*---チェックサム計算開始用---*/
    always_ff @(posedge eth_rxck)begin
        if(st==Hcsum)       chksum_en <= (csum_cnt > 8'd13 && csum_cnt < 8'd34);
        else if(st==Icsum)  chksum_en <= (csum_cnt > 8'd33 && csum_cnt < rx_cnt-8'd4);
        else if(st==Tx_Hc)  chksum_en <= (csum_cnt > 8'd13 && csum_cnt < 8'd34);
        else if(st==Tx_Ic)  chksum_en <= (csum_cnt > 8'd33 && csum_cnt < rx_cnt-8'd4);
        else if(st==Idle)   chksum_en <= 0;
        else                chksum_en <= 0;
    end
    
    /*---Checksum OK---*/
    always_ff @(posedge eth_rxck)begin
        if(st==Hc_End)begin
            if(chksum_o==16'h00_00) csum_ok <= `HI;
        end
        else if(st==Ic_End)begin
            if(chksum_o==16'h00_00) csum_ok <= `HI;
        end
        else                        csum_ok <= `LO;
    end
    
    /*---Tx_Data Ready---*/
    reg [15:0] csum_extend;
    always_ff @(posedge eth_rxck)begin 
       if(st==Tx_HEnd) begin
           if(err_cnt==3'd1) csum_extend <= chksum_o;
       end
       else if(st==Tx_IEnd)begin
           if(err_cnt==3'd1) csum_extend <= chksum_o;
       end
       else csum_extend <= 16'h5555;  // dummy value.
    end
    
    /*---送信用データ---*/
    integer i;
    //always_ff @(posedge clk125)begin
    always_ff @(posedge eth_rxck)begin
        if(st==Ready)begin
            {TXBUF[0],TXBUF[1],TXBUF[2],TXBUF[3],TXBUF[4],TXBUF[5]} <= tx_dstMAC;
            {TXBUF[6],TXBUF[7],TXBUF[8],TXBUF[9],TXBUF[10],TXBUF[11]} <= my_MAC_i;     // add 2019.1.9
            {TXBUF[12],TXBUF[13]} <= `FTYPE_IPV4;
            {TXBUF[14],TXBUF[15]} <= V_I_T;         // Version/IHL, TOS
            {TXBUF[16],TXBUF[17]} <= ToLen;         // Total Length         
            {TXBUF[18],TXBUF[19]} <= 16'hAB_CD;     // Identification
            {TXBUF[20],TXBUF[21]} <= 16'h40_00;     // Flags[15:13] ,Flagment Offset[12:0]
            TXBUF[22] <= TTL;                       // Time To Live
            TXBUF[23] <= Protocol;                 // Protocol ICMP=1
            {TXBUF[24],TXBUF[25]} <= 16'h00_00;     // Header Checksum
            {TXBUF[26],TXBUF[27],TXBUF[28],TXBUF[29]} <= my_IP_i;                      // add 2019.1.9
            {TXBUF[30],TXBUF[31],TXBUF[32],TXBUF[33]} <= tx_dstIP;
            {TXBUF[34],TXBUF[35]} <= 16'h00_00;     // Echo Reply = {Type=8'h00,Code=8'h00}
            {TXBUF[36],TXBUF[37]} <= 16'h00_00;     // ICMP Checksum
            {TXBUF[38],TXBUF[39]} <= Ident;         // Identifier
            {TXBUF[40],TXBUF[41]} <= SeqNum;        // Sequence number
            /*--Random Data--*/
            for(i=0;i<(ByteLen-6'd46);i=i+1)begin    
                TXBUF[6'd42+i] <= i;
            end
            {TXBUF[ByteLen-4],TXBUF[ByteLen-3],TXBUF[ByteLen-2],TXBUF[ByteLen-1]} <= 32'h01_02_03_04;   // dummy
            //Hcsum_st <= 1;
        end
        else if(st==Tx_HEnd) {TXBUF[24],TXBUF[25]} <= csum_extend;
        else if(st==Tx_IEnd) {TXBUF[36],TXBUF[37]} <= csum_extend;
    end
    
    
    /*---Header Checksum Error---*/
    always_ff @(posedge eth_rxck)begin
        if(st==Hc_End)          err_cnt <= err_cnt + 3'b1;
        else if(st==Ic_End)     err_cnt <= err_cnt + 3'b1;
        else if(st==Tx_HEnd)    err_cnt <= err_cnt + 3'b1;
        else if(st==Tx_IEnd)    err_cnt <= err_cnt + 3'b1;
        else                    err_cnt <= 0;
    end
    
    always_ff @(posedge eth_rxck)begin
        if(st==Tx_End)  end_cnt <= end_cnt + 1'b1;
        else            end_cnt <= 1'b0;
    end
    
    checksum checksum(
        .clk_i   (eth_rxck),
        .d       (chksum_data),
        .data_en (chksum_en),
        .csum_o  (chksum_o),
        .rst     (chksum_rst)
    );
    
    reg [7:0] tx_cnt;
    always_ff @(posedge eth_rxck)begin
        if(st==Tx_En)begin
            tx_cnt <= tx_cnt + 1;
            if(tx_cnt==rx_cnt) tx_end <= 1; 
        end
        else begin
            tx_cnt <= 0;
            tx_end <= 0;
        end
    end
    
    reg [2:0] fcs_cnt;
    always_ff @(posedge eth_rxck)begin
        if(st==Tx_En && tx_cnt>=rx_cnt-2'd3) fcs_cnt <= fcs_cnt + 1;
        else if(fcs_cnt==3'd4)               fcs_cnt <= 0;
        else                                 fcs_cnt <= 0;
    end 
    always_ff @(posedge eth_rxck)begin
        if(st==Tx_En && tx_cnt<(rx_cnt-8'd4)) ping_o <= {`HI,TXBUF[tx_cnt]};
        else if(st==Tx_En && fcs_cnt!=3'd3)  ping_o <= {`LO,TXBUF[tx_cnt]};
        else             ping_o <= 0;
    end
    
endmodule   // PING
