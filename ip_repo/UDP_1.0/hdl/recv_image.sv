`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/09/27 18:47:57
// Design Name: 
// Module Name: recv_image
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
//`include "struct_list.vh"
/*---recv_image.sv---*/
// 受信チェックサム計算と画像データの取得,処理を行う
// 画像データは100x100の10,000バイト
// フラグメントなし
// UDPデータとして1,000バイトずつ送られてくる
// UDPデータの順番については考慮しない
// 取得した画像は明度反転して返信

module recv_image(
    /*---Input---*/
    eth_rxck,
    //clk125,
    rst_rx,
    //pre,
    rxd_i,
    //RXBUF,
    //rx_cnt,
    arp_st,
    ping_st,
    UDP_st,
    els_packet,
    //addrb,
    //addr_cnt,
    rst_btn,            // 任意のタイミングでのリセット
    trans_err,          // 送信エラー
    SW,
    axi_awready,
    axi_wready,
    axi_bresp,
    axi_bvalid,
    /*---Output---*/
    //imdata,
    recvend,
    DstMAC_o,
    DstIP_o,
    SrcPort_o,
    DstPort_o,
    axi_aw,
    axi_w,
    axi_bready
    //write_end
    );
//    /*---STRUCT---*/
//    typedef struct packed{
//        logic           id;
//        logic [28:0]    addr;
//        logic [7:0]     len;
//        logic [2:0]     size;
//        logic [1:0]     burst;
//        logic           lock;
//        logic [3:0]     cache;
//        logic [2:0]     prot;
//        logic [3:0]     qos;
//        logic           valid;    
//    }AXI_AW;
    
//    typedef struct packed{
//        logic [31:0]    data;
//        logic [3:0]     strb;
//        logic           last;
//        logic           valid;  
//    }AXI_W;
        
    /*---I/O Declare---*/
    input           eth_rxck;
    //input           clk125;
    input           rst_rx;
    //input           pre;
    (*dont_touch="true"*)input [8:0]     rxd_i;
    //input [7:0]     RXBUF [1045:0];
    //input [10:0]    rx_cnt;
    input           arp_st;
    input           ping_st;
    input           UDP_st;
    input           els_packet;
    //input [9:0]     addrb;
    //input [8:0]     addr_cnt;
    
    input           rst_btn;
    input           trans_err;
    input [7:0]     SW;
    input           axi_awready;
    input           axi_wready;
    input           axi_bresp;
    input           axi_bvalid;
        
    //(*dont_touch="true"*)output reg [7:0]  imdata;
    output reg        recvend;
    output reg [47:0] DstMAC_o;
    output reg [31:0] DstIP_o;
    output reg [15:0] SrcPort_o;
    output reg [15:0] DstPort_o;
    
    output AXI_AW   axi_aw;
    output AXI_W    axi_w;
    output          axi_bready;
    //output          write_end;
    //output reg [7:0]  image_buffer [9999:0];
    
    /*---parameter---*/
    parameter   Idle        =   8'h00;
    parameter   Stby        =   8'h09;
    parameter   Presv       =   8'h01;
    parameter   Hcsum       =   8'h02;
    parameter   Hc_End      =   8'h03;
    parameter   Ucsum       =   8'h04;
    parameter   Uc_End      =   8'h05;
    parameter   Select      =   8'h06;
    parameter   Recv_End    =   8'h07;
    parameter   ERROR       =   8'h08;
    
    parameter   eth_head    =   4'd14;
    //parameter   udp         =   6'd34;
    parameter   MsgSize     =   16'd1440;   // 1440[byte] / 3[channel] = 480[px]
    
    /*---wire/register---*/
    //wire [3:0] packet_cnt_sel = (SW[7:4]==4'd0) ? SW[7:4] : (SW[7:4] - 4'd1) ;     // add 2018.12.5
    wire [10:0] packet_cnt_sel = (SW[7:4]==4'd0) ? 4'd0 :                            // add 2018.12.6
                                 (SW[7:4]==4'd1) ? 4'd1-1'b1 :
                                 (SW[7:4]==4'd2) ? 4'd2-1'b1 :
                                 (SW[7:4]==4'd3) ? 4'd4-1'b1 :
                                 (SW[7:4]==4'd4) ? 4'd8-1'b1 :
                                 (SW[7:4]==4'd5) ? 5'd16-1'b1 :
                                 (SW[7:4]==4'd6) ? 6'd32-1'b1 :
                                 (SW[7:4]==4'd7) ? 7'd64-1'b1 :
                                 (SW[7:4]==4'd8) ? 8'd128-1'b1 :
                                 (SW[7:4]==4'd9) ? 9'd256-1'b1 :
                                 (SW[7:4]==4'd10) ? 4'd10-1'b1 :
                                 (SW[7:4]==4'd11) ? 10'd640-1'b1 :  // 640x480(RGB)
                                 (SW[7:4]==4'd12) ? 11'd1920-1'b1 : // 1280x720(RGB)
                                 (SW[7:4]==4'd13) ? 11'd3-1'b1 :    // 48x30(RGB)
                                 8'd160-1'b1;
    
    reg [7:0]   RXBUF   [1485:0];
    //reg [7:0]   VBUF    [1459:0];
    reg [10:0]  rx_cnt;
    reg         rst;
    reg [10:0]  UDP_cnt;  // 固定長のUDPデータ用カウント
    reg [15:0]  UDP_Checksum;
    reg [4:0]   end_cnt;

    /*---ステートマシン---*/
    (*dont_touch="true"*)reg [7:0]   st;
    reg [7:0]   nx;
    (*dont_touch="true"*)reg [10:0]  csum_cnt;
    (*dont_touch="true"*)reg [10:0]  d_csum_cnt;   
    (*dont_touch="true"*)reg         csum_ok;
    reg [2:0]   err_cnt;
    reg [10:0]   packet_cnt;
    
    wire hcsum_end = (csum_cnt==11'd0);
    wire hcend_end = (err_cnt==3'd1);    
    wire ucsum_end = (csum_cnt==MsgSize+5'd20);
    wire ucend_end = (err_cnt==3'd7);    

    always_ff @(posedge eth_rxck)begin
        if (rst_rx) st <= Idle;
        else        st <= nx;
    end
    
    always_comb begin
        nx = st;
        case (st)
            Idle : begin
                if (rxd_i[8]) nx = Stby;
            end
            Stby : begin
                if (rxd_i[8])begin
                    if (rxd_i[7:0]==`SFD) nx = Presv;
                    else if (rxd_i[7:0]==`PREAMB) nx = Stby;
                    else nx = Idle;
                end
                else nx = Idle;
            end
            Presv : begin
                if (arp_st||ping_st||els_packet)            nx = Idle;
                //else if (UDP_st&&rx_cnt<100)    nx = Idle;        // add 2018.11.19
                //else if (UDP_st&&rx_cnt>100)    nx = Hcsum;       // add 2018.11.19
                else if (UDP_st)                nx = Hcsum;
                else if (rst_btn)               nx = Idle;
            end
            Hcsum : begin
                if (hcsum_end) nx = Hc_End;
            end
            Hc_End : begin 
                if (hcend_end)begin
                    //if (csum_ok) nx = Ucsum;
                    if (csum_ok) nx = Select;
                    else nx = ERROR;
                end
            end
            Ucsum : begin
                if (ucsum_end) nx = Uc_End;    // 仮想ヘッダの長さ(仮想ヘッダ(12)+UDPデータ長(1008))
            end
            Uc_End : begin
                if (ucend_end) begin
                    if (csum_ok) nx = Select;
                    else nx = ERROR;
                end
            end
            Select : begin
                if (packet_cnt==packet_cnt_sel) nx = Recv_End;   // add 2018.12.5
                else                 nx = Idle;
            end
            Recv_End : begin
                if (end_cnt==5'h1F) nx = Idle;
            end
            ERROR : begin
                nx = Idle;
            end
            default : begin
                nx = Idle;
            end
        endcase
    end
    
    /*---データの保持---*/
    always_ff @(posedge eth_rxck)begin
        if(st==Presv)begin
            if(rxd_i[8]) rx_cnt <= rx_cnt + 11'd1;
        end
        else if(st==Idle)begin
            rx_cnt <= 0;
        end
    end
    
    integer i;    
    always_ff @(posedge eth_rxck)begin
        if(st==Presv)begin
            RXBUF[rx_cnt] <= rxd_i[7:0];
        end
        else if(st==Idle)begin
            for (i=0;i<1486;i=i+1) RXBUF[i] <= 8'h00;
        end
    end
    
    always_ff @(posedge eth_rxck)begin
        if (st==Select) begin
            DstMAC_o  <= {RXBUF[6],RXBUF[7],RXBUF[8],RXBUF[9],RXBUF[10],RXBUF[11]};
            DstIP_o   <= {RXBUF[26],RXBUF[27],RXBUF[28],RXBUF[29]};
        end
        else if(st==Idle)begin
            DstMAC_o  <= 48'b0;
            DstIP_o   <= 32'b0;
        end
    end
    
    always_ff @(posedge eth_rxck)begin
        if(st==Select)begin
            SrcPort_o <= {RXBUF[34],RXBUF[35]};
            DstPort_o <= {RXBUF[36],RXBUF[37]};    
            //UDP_Checksum <= {RXBUF[40],RXBUF[41]}; 
        end
        else if(st==Idle)begin
            SrcPort_o <= 16'b0;
            DstPort_o <= 16'b0;
            //UDP_Checksum <= 16'b0;
        end
    end
    
    /*---パケット判別---*/
    reg [7:0] q_rxd [23:0];
    always_ff @(posedge eth_rxck)begin
        q_rxd <= {q_rxd[22:0],rxd_i[7:0]};
    end
    
    reg udp_flg;
    wire [47:0] my_MACadd = `my_MAC | {44'b0, SW[3:0]};
    wire [47:0] MACAdd = {q_rxd[23],q_rxd[22],q_rxd[21],q_rxd[20],q_rxd[19],q_rxd[18]}; 
    always_ff @(posedge eth_rxck)begin
        if(rx_cnt==11'd24)
            udp_flg <= (q_rxd[0]==8'h11&&MACAdd==my_MACadd) ? `HI : `LO ;
        else
            udp_flg <= `LO;
    end
    
    
    /*---RAM用データ--->SDRAM用データ---*/
    reg wea;
    //reg [17:0] addra;
    always_ff @(posedge eth_rxck)begin
        if(st==Presv) begin
            if(rx_cnt==11'd41) wea <= 1'b1;
            //if(rx_cnt==11'd42) wea <= 1'b1;     // debug
            else if(rx_cnt==11'd1481) wea <= 1'b0;
        end
        else begin
            wea <= 1'b0;
        end
    end
    
//    always_ff @(posedge eth_rxck)begin
//        if(st==Presv) begin
//            if(rx_cnt>11'd41&&rx_cnt<11'd1042) addra <= addra + 1'b1;
//        end
//        //else if(st==Idle&&packet_cnt==0) begin
//        else if(st==Idle) begin             // add 2018.11.19
//            //addra <= 11'b0;
//            addra <= packet_cnt * 1000;     // add 2018.11.19
//        end
//    end
    
    /*---パケット数のカウント---*/
    always_ff @(posedge eth_rxck)begin
        if (rst_rx)                         packet_cnt <= 11'd0;    //9'd0 -> 11'd0
        else if (rst_btn||trans_err)        packet_cnt <= 11'd0;
        else if (st==Select)                packet_cnt <= packet_cnt + 11'b1;
        else if (st==Recv_End||st==ERROR)   packet_cnt <= 11'b0;;
    end
    
    /*---リセット信号---*/
    always_ff @(posedge eth_rxck)begin
        if (st==Idle)   rst <= 1;
        else            rst <= 0;
    end  
    
    /*---チェックサム計算失敗用(2019.1.10 現在,この用途では用いていない)---*/
    always_ff @(posedge eth_rxck)begin
        if(st==Hc_End)          err_cnt <= err_cnt + 3'b1;
        //else if(st==Uc_End)     err_cnt <= err_cnt + 3'b1;
        else                    err_cnt <= 0;
    end 
    
    /*---チェックサム用データ---*/
    (*dont_touch="true"*)reg [7:0]       data;
    reg             data_en;
    (*dont_touch="true"*)reg [15:0]      csum;
       
    always_ff @(posedge eth_rxck)begin         
        if(st==Idle)       csum_cnt <= 0;
        else if(st==Hcsum) csum_cnt <= csum_cnt + 1;
        //else if(st==Ucsum) csum_cnt <= csum_cnt + 1;
        else               csum_cnt <= 0;
    end


//<-- moikawa add (2018.11.02)
//    wire [10:0] rxbuf_sel = csum_cnt + eth_head;
//    //wire [10:0] rxbuf_sel = csum_cnt;
//    reg [7:0]  data_pipe [17:0]; // part of pipelined selector from TXBUF[].
//    wire [4:0]  data_pipe_sel;

//    wire [10:0] rxbuf_sel_v = csum_cnt;
//    reg [7:0]  data_pipe_v [16:0]; // part of pipelined selector from TXBUF[].
//    wire [4:0]  data_pipe_sel_v; 
//--> moikawa add (2018.11.02)

    
//    always_ff @(posedge eth_rxck)begin    // 最初の14bitはMACヘッダ
//        //if(st==Hcsum)       data <= RXBUF[csum_cnt+eth_head];
//        if(st==Hcsum)       data <= data_pipe[ data_pipe_sel ];
//        //else if(st==Ucsum)  data <= VBUF[csum_cnt];
//        else if(st==Ucsum)  data <= data_pipe_v[ data_pipe_sel_v ];
//        else                data <= 0;
//    end

////<-- moikawa add (2018.11.02)
//    reg [10:0] rxbuf_sel_d;
//    integer    k;

//    always_ff @(posedge eth_rxck) begin
//        rxbuf_sel_d <= rxbuf_sel;
//    end
//    assign data_pipe_sel = (rxbuf_sel_d[10:6] < 5'd17)? 
//                            rxbuf_sel_d[10:6] : 5'd17 ;

//    always_ff @(posedge eth_rxck) begin // inserted pipelined stage.
//        //for (k=0; k<64; k=k+1) begin
//        //  data_pipe[k] <= TXBUF[ (64*k) + txbuf_sel[5:0] ];
//        //end
//        data_pipe[0]  <=  RXBUF[ rxbuf_sel[5:0]         ];
//        data_pipe[1]  <=  RXBUF[ rxbuf_sel[5:0] + 64    ];
//        data_pipe[2]  <=  RXBUF[ rxbuf_sel[5:0] + 128   ];
//        data_pipe[3]  <=  RXBUF[ rxbuf_sel[5:0] + 192   ];
//        data_pipe[4]  <=  RXBUF[ rxbuf_sel[5:0] + 256   ];
//        data_pipe[5]  <=  RXBUF[ rxbuf_sel[5:0] + 320   ];
//        data_pipe[6]  <=  RXBUF[ rxbuf_sel[5:0] + 384   ];
//        data_pipe[7]  <=  RXBUF[ rxbuf_sel[5:0] + 448   ];
//        data_pipe[8]  <=  RXBUF[ rxbuf_sel[5:0] + 512   ];
//        data_pipe[9]  <=  RXBUF[ rxbuf_sel[5:0] + 576   ];
//        data_pipe[10] <=  RXBUF[ rxbuf_sel[5:0] + 640   ];
//        data_pipe[11] <=  RXBUF[ rxbuf_sel[5:0] + 704   ];
//        data_pipe[12] <=  RXBUF[ rxbuf_sel[5:0] + 768   ];
//        data_pipe[13] <=  RXBUF[ rxbuf_sel[5:0] + 832   ];
//        data_pipe[14] <=  RXBUF[ rxbuf_sel[5:0] + 896   ];
//        data_pipe[15] <=  RXBUF[ rxbuf_sel[5:0] + 960   ];
//        if (rxbuf_sel[5:0] < 6'd22) begin
//	       data_pipe[16] <=  RXBUF[ rxbuf_sel[5:0] + 1024  ];
//        end else begin
//	       data_pipe[16] <=  8'h00;
//        end
//        data_pipe[17] <= 8'h00;  // dummy value.
//    end
////--> moikawa add (2018.11.02)

//    /*---VBUF用data_pipe---*/
//    reg [10:0] rxbuf_sel_v_d;

//    always_ff @(posedge eth_rxck) begin
//        rxbuf_sel_v_d <= rxbuf_sel_v;
//    end
//    assign data_pipe_sel_v = (rxbuf_sel_v_d[10:6] < 5'd17)? 
//                              rxbuf_sel_v_d[10:6] : 5'd17 ;

//    always_ff @(posedge eth_rxck) begin // inserted pipelined stage.
//        data_pipe_v[0]  <=  VBUF[ rxbuf_sel_v[5:0]         ];
//        data_pipe_v[1]  <=  VBUF[ rxbuf_sel_v[5:0] + 64    ];
//        data_pipe_v[2]  <=  VBUF[ rxbuf_sel_v[5:0] + 128   ];
//        data_pipe_v[3]  <=  VBUF[ rxbuf_sel_v[5:0] + 192   ];
//        data_pipe_v[4]  <=  VBUF[ rxbuf_sel_v[5:0] + 256   ];
//        data_pipe_v[5]  <=  VBUF[ rxbuf_sel_v[5:0] + 320   ];
//        data_pipe_v[6]  <=  VBUF[ rxbuf_sel_v[5:0] + 384   ];
//        data_pipe_v[7]  <=  VBUF[ rxbuf_sel_v[5:0] + 448   ];
//        data_pipe_v[8]  <=  VBUF[ rxbuf_sel_v[5:0] + 512   ];
//        data_pipe_v[9]  <=  VBUF[ rxbuf_sel_v[5:0] + 576   ];
//        data_pipe_v[10] <=  VBUF[ rxbuf_sel_v[5:0] + 640   ];
//        data_pipe_v[11] <=  VBUF[ rxbuf_sel_v[5:0] + 704   ];
//        data_pipe_v[12] <=  VBUF[ rxbuf_sel_v[5:0] + 768   ];
//        data_pipe_v[13] <=  VBUF[ rxbuf_sel_v[5:0] + 832   ];
//        data_pipe_v[14] <=  VBUF[ rxbuf_sel_v[5:0] + 896   ];
//        if(rxbuf_sel_v[5:0] < 6'd60)begin
//            data_pipe_v[15] <=  VBUF[ rxbuf_sel_v[5:0] + 960   ];
//        end else begin
//	       data_pipe_v[15] <=  8'h00;
//        end
//        data_pipe_v[16] <= 8'h00;  // dummy value.
//    end
    
    /*---チェックサム計算開始用---*/
    reg data_en_d;
    always_ff @(posedge eth_rxck)begin
        //if(st==Hcsum)       data_en <= (csum_cnt > 8'd13 && csum_cnt < 8'd34);
        if(UDP_st)       data_en <= `HI;
        //else if(st==Ucsum)  data_en <= (csum_cnt < MsgSize+5'd20);
        else if(st==Idle)   data_en <= `LO;
    end
    
    always_ff @(posedge eth_rxck)begin
       data_en_d <= data_en; 
    end
    
    wire [15:0] csum_o;     // add 2019.1.17
    /*---Checksum OK---*/
    always_ff @(posedge eth_rxck)begin
        if(st==Hc_End)begin
            if(csum_o==16'h00_00) csum_ok <= `HI;
        end
//        else if(st==Uc_End)begin
//            if(csum==16'h00_00) csum_ok <= `HI;
//        end
        else                    csum_ok <= `LO;
    end
    
    /*---仮想ヘッダ準備---*/
//    integer v_cnt;
//    always_ff @(posedge eth_rxck)begin
//        if(st==Hc_End)begin
//            {VBUF[0],VBUF[1],VBUF[2],VBUF[3]} <= {RXBUF[26],RXBUF[27],RXBUF[28],RXBUF[29]};
//            //{VBUF[4],VBUF[5],VBUF[6],VBUF[7]} <= `my_IP;
//            {VBUF[4],VBUF[5],VBUF[6],VBUF[7]} <= {RXBUF[30],RXBUF[31],RXBUF[32],RXBUF[33]};        // add 2018.12.5
//            {VBUF[8],VBUF[9]} <= 16'h00_11;
//            {VBUF[10],VBUF[11]} <= MsgSize+4'd8;
//            {VBUF[12],VBUF[13]} <= {RXBUF[34],RXBUF[35]};
//            {VBUF[14],VBUF[15]} <= {RXBUF[36],RXBUF[37]};
//            {VBUF[16],VBUF[17]} <= MsgSize+4'd8;
//            {VBUF[18],VBUF[19]} <= {RXBUF[40],RXBUF[41]};
//            for(v_cnt=0;v_cnt<10'd1000;v_cnt=v_cnt+1)
//                VBUF[20+v_cnt]  <= RXBUF[42+v_cnt];
//        end
//        else if(st==Idle)begin
//            for(v_cnt=0;v_cnt<10'd1020;v_cnt=v_cnt+1) VBUF[v_cnt] <= 8'b0;
//            v_cnt <= 0;
//        end
//    end
    
    /*---終了---*/
    always_ff @(posedge eth_rxck)begin
        if (st==Recv_End) end_cnt <= end_cnt + 1;
        else              end_cnt <= 0;
    end
    
    always_ff @(posedge eth_rxck)begin
        if (st==Recv_End) recvend <= 1;
        else              recvend <= 0;
    end
    
    /*---checksum---*/
    checksum recv_checksum(
        .clk_i(eth_rxck),
        .d(data),
        .data_en(data_en_d),
        .csum_o(csum),
        .rst(rst)
    );
    /*---checksum_fast---*/
    wire [7:0] csum_data [19:0];
    genvar g;
    generate
        for (g=0; g < 20; g=g+1)
        begin
            assign csum_data[g] = RXBUF[g+14];
        end
    endgenerate
    
    csum_fast recv_csum(
        /*---INPUT---*/
        .CLK_i      (eth_rxck),
        .data_i     (csum_data),
        .dataen_i   (data_en),
        .reset_i    (rst),
        /*---OUTPUT---*/
        .csum_o     (csum_o)
    );
    /*
    wire [17:0] addr_r = addrb + (addr_cnt * 1000);
    */
//    reg [17:0] addr_r;
//    always_ff @(posedge eth_rxck)begin
//        addr_r <= addrb + (addr_cnt * 1000);
//    end
    
    /*---BlockRAM Generator---*/
//    image_RAM image_RAM(
//        .clka   (eth_rxck),
//        //.ena(1'b1),           // PortA  enable
//        .wea    (wea),          // write enable
//        .addra  (addra),        // write address
//        .dina   (rxd_i[7:0]),   // write data
//        .clkb   (eth_rxck),
//        //.enb(1'b1),           // PortB enable
//        .addrb  (addr_r),       // read address
//        .doutb  (imdata)        // read data
//    );
    
    axi_write axi_write(
        /*---INPUT---*/
        .clk_i      (eth_rxck),
        .rst        (rst_rx),
        .rst_btn    (rst_btn),
        .wea        (wea),
        .data_i     (rxd_i[7:0]),
        .udp_flg    (udp_flg),
        .packet_cnt (packet_cnt),
        .UDP_st     (UDP_st),
        .els_packet (els_packet),
        .recvend    (recvend),
        .axi_awready(axi_awready),
        .axi_wready (axi_wready),
        .axi_bresp  (axi_bresp),
        .axi_bvalid (axi_bvalid),
        /*---OUTPUT---*/
        .axi_aw     (axi_aw),
        .axi_w      (axi_w),
        .axi_bready (axi_bready)
        //.write_end  (write_end)
    );
    
endmodule
