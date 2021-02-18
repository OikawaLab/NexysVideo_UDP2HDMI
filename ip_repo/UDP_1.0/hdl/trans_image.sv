`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/09/27 18:47:57
// Design Name: 
// Module Name: trans_image
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
/*---trans_image.sv---*/
// 受け取った画像データを受信時と同じく1,000バイトずつ送信
// 送信準備 -> 送信終了 の遷移を10回繰り返すことで10,000バイト送信する
// 送信回数をDIPスライドスイッチの入力から動的に設定できる.
// MAC/IP address はDIPスライドスイッチの入力から動的に設定できる.

module trans_image(
    /*---Input---*/
    eth_rxck,
    clk125,
    rst_rx,
    rst_btn,
    //imdata,
    recvend,
    block_end,
    //image_buffer,
    my_MACadd_i,
    my_IPadd_i,
    DstMAC_i,
    DstIP_i,
    SrcPort_i,
    DstPort_i,
    SW,
    axi_arready,
    axi_r,
    /*---Output---*/
    //image_cnt,
    //addr_cnt,
    UDP_o,
    trans_err,       // 送信エラー
    axi_ar,
    axi_rready
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
//    }AXI_AR;
    
//    typedef struct packed{
//        logic [31:0]    data;
//        logic [3:0]     strb;
//        logic           last;
//        logic           valid;
//        logic [1:0]     resp;
//    }AXI_R;    
    
    /*---I/O Declare---*/
    input       eth_rxck;
    input       clk125;
    input       rst_rx;
    input       rst_btn;
    //input [7:0] imdata;
    input       recvend;
    input       block_end;
    //input [7:0] image_buffer [9999:0];
    input [47:0] my_MACadd_i;     //<--- add 2018.12.5
    input [31:0] my_IPadd_i;      //--->
    input [47:0] DstMAC_i;
    input [31:0] DstIP_i;
    input [15:0] SrcPort_i;
    input [15:0] DstPort_i;
    input [7:0]  SW;
    
    input        axi_arready;
    input AXI_R  axi_r;
    
    //output reg [9:0]   image_cnt;
    //output reg [8:0]   addr_cnt;
    (*dont_touch="true"*)output reg [8:0]    UDP_o;
    output reg         trans_err;
    
    output AXI_AR       axi_ar;
    output              axi_rready;
    
    
    /*---parameter---*/
    parameter   IDLE    =   8'h00;
    parameter   Presv   =   8'h01;
    parameter   READY   =   8'h02;
    parameter   Hcsum   =   8'h03;
    parameter   Hc_End  =   8'h04;
    parameter   Ucsum   =   8'h05;
    parameter   Uc_End  =   8'h06;
    parameter   Tx_En   =   8'h07;
    parameter   Select  =   8'h08;
    parameter   Tx_End  =   8'h09;
    parameter   ERROR   =   8'h0A;
    
    parameter   eth_head =  4'd14;
    //parameter   udp     =   6'd34;
    parameter   FTYPE   =   16'h08_00;
    parameter   MsgSize =   16'd1440;
    parameter   TTL     =   8'd255;
    parameter   PckSize =   16'd1486;
    
    parameter   transaction_num =   4'd2;   // トランザクションの数(480回連続では送れないため)
    
    /*---wire/register---*/
    //wire [3:0] packet_cnt_sel = (SW[7:4]==4'd0) ? SW[7:4] : (SW[7:4] - 4'd1);
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
                                 8'd160-1'b1 ;


    //reg [7:0]   image_buffer_i [9999:0];
    //reg [7:0]   image_buffer [999:0];
    //reg [7:0]   image_bufferA [499:0];
    //reg [7:0]   image_bufferB [499:0];
    reg [7:0]   TXBUF [PckSize-1:0];
    //reg [7:0]   VBUF [1019:0];
    reg         rst;
    reg [47:0]  DstMAC_d;
    reg [31:0]  DstIP_d;
    reg [10:0]  UDP_cnt;  // 固定長のUDPデータ用カウント
    (*dont_touch="true"*)reg [15:0]SrcPort_d;
    (*dont_touch="true"*)reg [15:0] DstPort_d;
    reg [15:0] UDP_Checksum;
    
    /*---ステートマシン---*/
    (*dont_touch="true"*)reg [7:0]   st;
    reg [7:0]   nx;
    (*dont_touch="true"*)reg [10:0]  csum_cnt;
    (*dont_touch="true"*)reg         csum_ok;
    reg [4:0]   err_cnt;
    (*dont_touch="true"*)reg         tx_end;
    reg [10:0]   packet_cnt;
    //reg         Hcsum_st;
    //reg [3:0]   ready_cnt;
    //reg [9:0]   d_img_cnt [2:0];        // BlockRAMの出力が1サイクルずれるため & recv_image側でimage_cntにFFを挟むため
    
    wire ready_end  = (err_cnt==5'd30);
    wire hcsum_end  = (csum_cnt==8'd2);
    wire hcend_end  = (err_cnt==3'd0);    
    wire ucsum_end  = (csum_cnt==MsgSize+5'd20);
    wire ucend_end  = (err_cnt==3'd7);
    reg [1:0] transaction_cnt;
    wire      transaction = (transaction_cnt==(transaction_num));
    wire pos_last   = axi_r.last&&axi_r.valid;
    wire read_end   = pos_last&&transaction;
    
    always_ff @(posedge eth_rxck)begin
        if (rst_rx) st <= IDLE;
        else        st <= nx;
    end
    
    always_comb begin
        nx = st;
        case (st)
            IDLE : begin
//                if (recvend) nx = Presv;
                if (block_end) nx = Presv;
            end
            Presv : begin
                //if (d_img_cnt[2]>10'd999) nx = READY;
                if (transaction) nx = READY;
            end
            READY : begin
                if (ready_end) nx = Hcsum;
                //nx = Hcsum;
            end
            Hcsum : begin
                if (hcsum_end) nx = Hc_End;
            end
            Hc_End : begin
                if (hcend_end) nx = Tx_En;
            end
            Ucsum : begin
                if (ucsum_end) nx = Uc_End;
            end
            Uc_End : begin
                if (ucend_end) nx = Tx_En; 
            end
            Tx_En : begin
                //if (tx_end[3]) nx = Select;
                //if (tx_end_rxck[1]) nx = Select;
                if(tx_end)        nx = Select;
                else if (rst_btn) nx = IDLE;
            end
            Select : begin
                //if(packet_cnt==4'd9) nx = Tx_End;
                if(packet_cnt==packet_cnt_sel) nx = Tx_End;       // add 2018.12.5
                else                 nx = READY;
            end
            Tx_End : begin
                nx = IDLE;
            end
            ERROR :begin
                nx = IDLE;
            end
            default : begin
                nx = ERROR;
            end
        endcase
    end
    
    /*---データの受け渡し---*/
    always_ff @(posedge eth_rxck)begin
        if (recvend) begin
            DstMAC_d    <= DstMAC_i;
            DstIP_d     <= DstIP_i;
            SrcPort_d   <= SrcPort_i;
            DstPort_d   <= DstPort_i;
        end
    end
    
    /*---画像データ---*/
//    integer i;
//    always_ff @(posedge eth_rxck)begin
//        if (recvend) begin
//            for (i=0;i<10000;i=i+1) image_buffer_i[i] <= ~image_buffer[i];
//        end
//        else if(st==IDLE) begin
//            for (i=0;i<10000;i=i+1) image_buffer_i[i] <= 8'b0;
//        end
//    end
    
    /*---トランザクション数をカウント---*/
    always_ff @(posedge eth_rxck)begin
        if(st==IDLE)begin
            transaction_cnt <= 2'b0;
        end
        else if(st==Presv)begin
            if(pos_last)begin
                transaction_cnt <= transaction_cnt + 2'b1;
            end
        end
        else if(st==Tx_En)begin
            if(pos_last)begin
                transaction_cnt <= transaction_cnt + 2'b1;
            end
        end
        else begin
            transaction_cnt <= 2'b0;
        end
    end
    
    /*--DRAM2BUF--*/
    reg [7:0] image_buf [MsgSize-1:0];
//    wire [7:0] r_data0 = axi_r.data[31:24] ^ 8'hFF;
//    wire [7:0] r_data1 = axi_r.data[23:16] ^ 8'hFF;
//    wire [7:0] r_data2 = axi_r.data[15:8] ^ 8'hFF;
//    wire [7:0] r_data3 = axi_r.data[7:0] ^ 8'hFF;
    wire [7:0] dummy = axi_r.data[31:24];
    wire [7:0] i_blue  = axi_r.data[23:16];
    wire [7:0] i_green = axi_r.data[15:8];
    wire [7:0] i_red   = axi_r.data[7:0];
    //wire strong_red = (i_blue<=8'd70) && (i_green<=8'd70) && (i_red>=8'd120);
    
    wire [7:0] blue;
    wire [7:0] green;
    wire [7:0] red;
    /*---RED to WHITE---*/
//    assign blue = (strong_red) ? 8'hFF : i_blue;
//    assign green = (strong_red) ? 8'hFF : i_green;
//    assign red = (strong_red) ? 8'hFF : i_red;
    assign blue = i_blue;
    assign green = i_green;
    assign red = i_red;
    
    always_ff @(posedge eth_rxck)begin
        if(st==Presv)begin
            if(axi_r.valid)begin
                //image_buf <= {r_data3,r_data2,r_data1,r_data0,image_buf[999:4]};
                image_buf <= {red,green,blue,image_buf[MsgSize-1:3]};
            end
        end
        else if(st==Tx_En&&packet_cnt!=packet_cnt_sel)begin
            if(axi_r.valid)begin
                //image_buf <= {r_data3,r_data2,r_data1,r_data0,image_buf[999:4]};
                image_buf <= {red,green,blue,image_buf[MsgSize-1:3]};
            end            
        end
    end
    
    /*--Read Start--*/
    reg [1:0] d_rd_en;
    wire read_en = (d_rd_en==2'b01);    // 1度だけHIGH
    always_ff @(posedge eth_rxck)begin
        if(st==Presv)begin
            d_rd_en <= {d_rd_en[0],`HI};
        end
        else if(st==READY)begin
            d_rd_en <= 2'b0;
        end
        else if(st==Tx_En&&packet_cnt!=packet_cnt_sel)begin
            d_rd_en <= {d_rd_en[0],`HI};
        end
        else if(st==IDLE)begin
            d_rd_en <= 2'b0;
        end
    end
    
    /*--BRAM--*/
//    always_ff @(posedge eth_rxck)begin              // recv_imageにあるBRAMの出力用アドレス
//        if(st==Presv)begin
//            if(image_cnt<1000)begin
//                image_cnt <= image_cnt + 10'b1;
//            end
//        end
////        else if(st==Ucsum&&packet_cnt!=9)begin        10,000回カウントは冗長
////            if(image_cnt<((packet_cnt+2)*1000))
////                image_cnt <= image_cnt + 14'b1;
////        end
//        //else if(st==Ucsum&&packet_cnt!=9)begin
//        //else if(st==Ucsum&&packet_cnt!=packet_cnt_sel)begin     // add 2018.12.5
//        else if(st==Tx_En&&packet_cnt!=packet_cnt_sel)begin     // add 2019.1.17
//            if(image_cnt<1000)begin
//                image_cnt <= image_cnt + 10'b1;
//            end
//        end
//        else if(st==READY)begin
//            image_cnt <= 10'b0;
//        end
//        else if(st==IDLE)begin
//            image_cnt <= 10'b0;
//        end
//    end
    
    reg [10:0] addr_cnt;
    always_ff @(posedge eth_rxck)begin              // BRAM(DRAM)のアドレスを表現するためのもの
        if(st==IDLE)        addr_cnt <= 11'b0;
        else if(st==Hc_End) addr_cnt <= packet_cnt + 1;
    end
    
//    always_ff @(posedge eth_rxck)begin
//        d_img_cnt <= {d_img_cnt[1:0],image_cnt};
//    end
    
    //<-- add 2018.12.12
    reg [10:0] d_packet_cnt;
    always_ff @(posedge eth_rxck)begin
        d_packet_cnt <= packet_cnt;
    end
    //-->
    
  
//    integer bufferA;
//    integer bufferB;
//    //<-- add 2018.12.12
//    always_ff @(posedge eth_rxck)begin
//        if(st==Presv)begin
//            if(d_img_cnt[2]<500)
//                image_bufferA[d_img_cnt[2]] <= imdata ^ 8'hFF;
//        end
//        //else if(st==Ucsum&&d_packet_cnt!=packet_cnt_sel)begin
//        else if(st==Tx_En&&d_packet_cnt!=packet_cnt_sel)begin   // 2019.1.17
//            if(d_img_cnt[2]<500)
//                image_bufferA[d_img_cnt[2]] <= imdata ^ 8'hFF;
//        end
//        else if(st==IDLE)begin
//            for(bufferA=0;bufferA<500;bufferA=bufferA+1)begin
//                image_bufferA[bufferA] <= 8'h55;
//            end
//        end
//    end
    
//    always_ff @(posedge eth_rxck)begin
//        if(st==Presv)begin
//            if(d_img_cnt[2]>=500)
//                image_bufferB[d_img_cnt[2]-500] <= imdata ^ 8'hFF;
//        end
//        //else if(st==Ucsum&&d_packet_cnt!=packet_cnt_sel)begin
//        else if(st==Tx_En&&d_packet_cnt!=packet_cnt_sel)begin   // 2019.1.17
//            if(d_img_cnt[2]>=500)
//                image_bufferB[d_img_cnt[2]-500] <= imdata ^ 8'hFF;
//        end
//        else if(st==IDLE)begin
//            for(bufferB=0;bufferB<500;bufferB=bufferB+1)begin
//                image_bufferB[bufferB] <= 8'h55;    // dummy
//            end
//        end
//    end
    //-->
    
    
    /*---パケット数のカウント---*/
    always_ff @(posedge eth_rxck)begin
        if (rst_rx)             packet_cnt <= 9'd0;
        else if (st==IDLE)      packet_cnt <= 9'd0;
        else if (st==Select)    packet_cnt <= packet_cnt + 9'b1;
        else if (st==Tx_End)    packet_cnt <= 0;
    end    
    
    /*---リセット信号---*/
    always_ff @(posedge eth_rxck)begin
        if(st==IDLE)    rst <= 1;
        else            rst <= 0;
    end
    
    always_ff @(posedge eth_rxck)begin
        if (st==READY)          err_cnt <= err_cnt + 6'b1;
        else if (st==Hc_End)         err_cnt <= err_cnt + 6'b1;
        //else if (st==Uc_End)    err_cnt <= err_cnt + 4'b1;
        else                    err_cnt <= 6'b0;
    end     
    
    /*---チェックサム用データ---*/
    (*dont_touch="true"*)reg [7:0]       data;
    reg            data_en;
    (*dont_touch="true"*)reg [15:0]      csum;
    wire    [15:0]  csum_o;
    
    always_ff @(posedge eth_rxck)begin         
        if(st==IDLE)        csum_cnt <= 0;
        else if(st==Hcsum)  csum_cnt <= csum_cnt + 1;
        //else if(st==Ucsum)  csum_cnt <= csum_cnt + 1;
        else                csum_cnt <= 0; 
    end
    
//<-- moikawa add (2018.11.02)
    //TXBUF
//    wire [10:0] txbuf_sel = csum_cnt + eth_head;
//    //wire [10:0] txbuf_sel = csum_cnt;
//    reg [7:0]  data_pipe [17:0]; // part of pipelined selector from TXBUF[].
//    wire [4:0]  data_pipe_sel;
//    //VBUF
//    wire [10:0] txbuf_sel_v = csum_cnt;
//    reg [7:0]  data_pipe_v [16:0]; // part of pipelined selector from TXBUF[].
//    wire [4:0]  data_pipe_sel_v;
////--> moikawa add (2018.11.02)
    
//    /*---チェックサム用データ---*/
//    always_ff @(posedge eth_rxck)begin    // 最初の14bitはMACヘッダ
//        //if(st==Hcsum)      data <= TXBUF[csum_cnt+eth_head];
//        if(st==Hcsum)      data <= data_pipe[ data_pipe_sel ];
//        else if(st==Ucsum) data <= data_pipe_v[ data_pipe_sel_v ];
//        else               data <= 0;
//    end

////<-- moikawa add (2018.11.02)
//    reg [10:0] txbuf_sel_d;
//    integer    k;

//    always_ff @(posedge eth_rxck) begin
//        txbuf_sel_d <= txbuf_sel;
//    end
//    assign data_pipe_sel = (txbuf_sel_d[10:6] < 5'd17)? 
//                            txbuf_sel_d[10:6] : 5'd17 ;

//    always_ff @(posedge eth_rxck) begin // inserted pipelined stage.
//        //for (k=0; k<64; k=k+1) begin
//        //  data_pipe[k] <= TXBUF[ (64*k) + txbuf_sel[5:0] ];
//        //end
//        data_pipe[0]  <=  TXBUF[ txbuf_sel[5:0]         ];
//        data_pipe[1]  <=  TXBUF[ txbuf_sel[5:0] + 64    ];
//        data_pipe[2]  <=  TXBUF[ txbuf_sel[5:0] + 128   ];
//        data_pipe[3]  <=  TXBUF[ txbuf_sel[5:0] + 192   ];
//        data_pipe[4]  <=  TXBUF[ txbuf_sel[5:0] + 256   ];
//        data_pipe[5]  <=  TXBUF[ txbuf_sel[5:0] + 320   ];
//        data_pipe[6]  <=  TXBUF[ txbuf_sel[5:0] + 384   ];
//        data_pipe[7]  <=  TXBUF[ txbuf_sel[5:0] + 448   ];
//        data_pipe[8]  <=  TXBUF[ txbuf_sel[5:0] + 512   ];
//        data_pipe[9]  <=  TXBUF[ txbuf_sel[5:0] + 576   ];
//        data_pipe[10] <=  TXBUF[ txbuf_sel[5:0] + 640   ];
//        data_pipe[11] <=  TXBUF[ txbuf_sel[5:0] + 704   ];
//        data_pipe[12] <=  TXBUF[ txbuf_sel[5:0] + 768   ];
//        data_pipe[13] <=  TXBUF[ txbuf_sel[5:0] + 832   ];
//        data_pipe[14] <=  TXBUF[ txbuf_sel[5:0] + 896   ];
//        data_pipe[15] <=  TXBUF[ txbuf_sel[5:0] + 960   ];
//        if (txbuf_sel[5:0] < 6'd22) begin
//	       data_pipe[16] <=  TXBUF[ txbuf_sel[5:0] + 1024  ];
//        end else begin
//	       data_pipe[16] <=  8'h00;
//        end
//        data_pipe[17] <= 8'h00;  // dummy value.
//    end
////--> moikawa add (2018.11.02)

//    /*---VBUF用data_pipe---*/
//    reg [10:0] txbuf_sel_v_d;

//    always_ff @(posedge eth_rxck) begin
//        txbuf_sel_v_d <= txbuf_sel_v;
//    end
//    assign data_pipe_sel_v = (txbuf_sel_v_d[10:6] < 5'd17)? 
//                              txbuf_sel_v_d[10:6] : 5'd17 ;

//    always_ff @(posedge eth_rxck) begin // inserted pipelined stage.
//        data_pipe_v[0]  <=  VBUF[ txbuf_sel_v[5:0]         ];
//        data_pipe_v[1]  <=  VBUF[ txbuf_sel_v[5:0] + 64    ];
//        data_pipe_v[2]  <=  VBUF[ txbuf_sel_v[5:0] + 128   ];
//        data_pipe_v[3]  <=  VBUF[ txbuf_sel_v[5:0] + 192   ];
//        data_pipe_v[4]  <=  VBUF[ txbuf_sel_v[5:0] + 256   ];
//        data_pipe_v[5]  <=  VBUF[ txbuf_sel_v[5:0] + 320   ];
//        data_pipe_v[6]  <=  VBUF[ txbuf_sel_v[5:0] + 384   ];
//        data_pipe_v[7]  <=  VBUF[ txbuf_sel_v[5:0] + 448   ];
//        data_pipe_v[8]  <=  VBUF[ txbuf_sel_v[5:0] + 512   ];
//        data_pipe_v[9]  <=  VBUF[ txbuf_sel_v[5:0] + 576   ];
//        data_pipe_v[10] <=  VBUF[ txbuf_sel_v[5:0] + 640   ];
//        data_pipe_v[11] <=  VBUF[ txbuf_sel_v[5:0] + 704   ];
//        data_pipe_v[12] <=  VBUF[ txbuf_sel_v[5:0] + 768   ];
//        data_pipe_v[13] <=  VBUF[ txbuf_sel_v[5:0] + 832   ];
//        data_pipe_v[14] <=  VBUF[ txbuf_sel_v[5:0] + 896   ];
//        if(txbuf_sel_v[5:0] < 6'd60)begin
//            data_pipe_v[15] <=  VBUF[ txbuf_sel_v[5:0] + 960   ];
//        end else begin
//	       data_pipe_v[15] <=  8'h00;
//        end
//        data_pipe_v[16] <= 8'h00;  // dummy value.
//    end

    /*---チェックサム計算開始用---*/
    reg data_en_d;
    always_ff @(posedge eth_rxck)begin
        //if(st==Hcsum)       data_en <= (csum_cnt > 8'd13 && csum_cnt < 8'd34);
        if(st==Hcsum)       data_en <= `HI;
        //if(st==READY)       data_en <= `HI;
        //else if(st==Ucsum)  data_en <= (csum_cnt < MsgSize+5'd20);
        else if(st==Tx_En)  data_en <= `LO;
        else if(st==IDLE)   data_en <= `LO;
    end    
    
    always_ff @(posedge eth_rxck)begin
        data_en_d <= data_en;
    end
    
    reg [15:0] csum_extend;
    always_ff @(posedge eth_rxck)begin 
       if(st==Hc_End) begin
           if(err_cnt==2'b01) csum_extend <= csum;
           //if(err_cnt==2'b10) csum_extend <= 16'h00_00;
       end
       else if(st==Uc_End)begin
           //if(err_cnt==2'b10) csum_extend <= csum;
           if(err_cnt==2'b01) csum_extend <= 16'h00_00;
       end
       else if (st==IDLE) csum_extend <= 16'h5555;  // dummy value.
    end    
   
    /*---UDPパケット準備---*/
    integer tx_A;
    integer tx_B;
    //always_ff @(posedge clk125)begin
    always_ff @(posedge eth_rxck)begin
        //if(ready_clk125)begin
        if(st==READY)begin
            /*-イーサネットヘッダ-*/
            {TXBUF[0],TXBUF[1],TXBUF[2],TXBUF[3],TXBUF[4],TXBUF[5]} <= DstMAC_d;
            //{TXBUF[6],TXBUF[7],TXBUF[8],TXBUF[9],TXBUF[10],TXBUF[11]} <= `my_MAC;
            {TXBUF[6],TXBUF[7],TXBUF[8],TXBUF[9],TXBUF[10],TXBUF[11]} <= my_MACadd_i;
            {TXBUF[12],TXBUF[13]} <= FTYPE;
            /*-IPヘッダ-*/
            TXBUF[14] <= 8'h45;                             // Version/IHL
            TXBUF[15] <= 8'h00;                             // ToS
            {TXBUF[16],TXBUF[17]} <= 5'd20+4'd8+MsgSize;    // Total Length(IPヘッダ(20)+UDPヘッダ(8バイト)+UDPデータ)
            {TXBUF[18],TXBUF[19]} <= 16'hAB_CD;             // Identification
            {TXBUF[20],TXBUF[21]} <= {3'b010,13'd0};        // Flags[15:13] ,Flagment Offset[12:0]
            TXBUF[22] <= TTL;                               // Time To Live
            TXBUF[23] <= 8'h11;                             // Protocol 8'h11==8'd17==UDP
            {TXBUF[24],TXBUF[25]} <= 16'h00_00;             // IP Checksum
            //{TXBUF[26],TXBUF[27],TXBUF[28],TXBUF[29]} <= `my_IP;
            {TXBUF[26],TXBUF[27],TXBUF[28],TXBUF[29]} <= my_IPadd_i;
            {TXBUF[30],TXBUF[31],TXBUF[32],TXBUF[33]} <= DstIP_d;
            /*-UDPヘッダ-*/
            {TXBUF[34],TXBUF[35]} <= DstPort_d;             // 発信元ポート番号
            {TXBUF[36],TXBUF[37]} <= SrcPort_d;             // 宛先ポート番号   
            {TXBUF[38],TXBUF[39]} <= MsgSize+4'd8;          // UDPデータ長 UDPヘッダ(8バイト)+UDPデータ
            {TXBUF[40],TXBUF[41]} <= 16'h00_00;             // UDP Checksum (仮想ヘッダ+UDP)
            /*-UDPデータ(可変長(受信データ長による))____1000バイトに固定____-*/
            //for(j=0;j<1000;j=j+1) TXBUF[6'd42+j] <= image_buffer[j];
            //for(tx_A=0;tx_A<500;tx_A=tx_A+1) TXBUF[6'd42+tx_A] <= image_bufferA[tx_A];      // 2018.11.16
            //for(tx_B=0;tx_B<500;tx_B=tx_B+1) TXBUF[6'd42+tx_B+500] <= image_bufferB[tx_B];  // 2018.11.16
            TXBUF[PckSize-5:42] <= image_buf[MsgSize-1:0];
            {TXBUF[PckSize-4],TXBUF[PckSize-3],TXBUF[PckSize-2],TXBUF[PckSize-1]} <= 32'h01_02_03_04;   // dummy
            //Hcsum_st <= 1;
        end
        else if(st==Hc_End)    {TXBUF[24],TXBUF[25]} <= csum_o;
        //else if(st==Uc_End)    {TXBUF[40],TXBUF[41]} <= csum_extend;
        else if(st==Tx_En) TXBUF <= {TXBUF[0],TXBUF[PckSize-1:1]};
    end
    
    /*---仮想ヘッダ準備---*/
//    integer v_cnt;
//    integer v_cnt_A;
//    integer v_cnt_B;
//    always_ff @(posedge eth_rxck)begin
//        if(st==Hc_End)begin
//            //{VBUF[0],VBUF[1],VBUF[2],VBUF[3]} <= `my_IP;
//            {VBUF[0],VBUF[1],VBUF[2],VBUF[3]} <= my_IPadd_i;
//            {VBUF[4],VBUF[5],VBUF[6],VBUF[7]} <= DstIP_d;
//            {VBUF[8],VBUF[9]} <= 16'h00_11;
//            {VBUF[10],VBUF[11]} <= MsgSize+4'd8;
//            {VBUF[12],VBUF[13]} <= DstPort_d;
//            {VBUF[14],VBUF[15]} <= SrcPort_d;
//            {VBUF[16],VBUF[17]} <= MsgSize+4'd8;
//            {VBUF[18],VBUF[19]} <= 16'h00_00;
//            //for(v_cnt=0;v_cnt<10'd1000;v_cnt=v_cnt+1)
//            //    VBUF[20+v_cnt]  <= image_buffer[v_cnt];
//            for(v_cnt_A=0;v_cnt_A<500;v_cnt_A=v_cnt_A+1) VBUF[20+v_cnt_A] <= image_bufferA[v_cnt_A];      // 2018.11.16
//            for(v_cnt_B=0;v_cnt_B<500;v_cnt_B=v_cnt_B+1) VBUF[20+v_cnt_B+500] <= image_bufferB[v_cnt_B];  // 2018.11.16
//        end
//        else if(st==IDLE)begin
//            for(v_cnt=0;v_cnt<10'd1020;v_cnt=v_cnt+1) VBUF[v_cnt] <= 8'b0;
//            v_cnt <= 0;
//        end
//        else v_cnt <= 0;
//    end    
    
    checksum trans_checksum(
        .clk_i      (eth_rxck),
        .d          (data),
        .data_en    (data_en_d),
        .csum_o     (csum),
        .rst        (rst)
    );
    
    wire [7:0] csum_data [19:0];
    genvar g;
    generate
        for (g=0; g < 20; g=g+1)
        begin
            assign csum_data[g] = TXBUF[g+14];
        end
    endgenerate    
    csum_fast trans_csum(
        /*---INPUT---*/
        .CLK_i      (eth_rxck),
        .data_i     (csum_data),
        .dataen_i   (data_en_d),
        .reset_i    (rst),
        /*---OUTPUT---*/
        .csum_o     (csum_o)        
    );
    
    //<----------
    /*
    データを出すクロックを"clk125"で行うために,ステートがTx_Enであると"HIGH"になる信号を
    clk125を用いて生成している.
    */
//    reg tx_en;
//    reg tx_en_clk125_d;
//    always_ff @(posedge eth_rxck)begin
//       if(st==Tx_En) tx_en <= 1'b1;
//       else          tx_en <= 1'b0;  
//    end
    
//    always_ff @(posedge clk125) begin
//       tx_en_clk125_d <= tx_en;
//       tx_en_clk125 <= tx_en_clk125_d; 
//    end
    //---------->
    
    /*---送信---*/
    (*dont_touch="true"*)reg [10:0] tx_cnt;
    always_ff @(posedge eth_rxck)begin
        if(st==READY)begin
            tx_end <= 0;
            tx_cnt <= 0;
        end
        else if(st==Tx_En)begin
            tx_cnt <= tx_cnt + 1;
            if(tx_cnt==PckSize) tx_end <= 1'b1; 
        end
        else begin
            tx_end <= 1'b0;
            tx_cnt <= 0;
        end
    end
    
    /*---All data trans---*/
    reg transend;
    always_ff @(posedge eth_rxck)begin
        if(st==Tx_End)  transend <= 1'b1;
        else            transend <= 1'b0;
    end
    
    
//<-- moikawa add (2018.12.11)
//    (*dont_touch="true"*)reg [1:0] tx_end_rxck;
//    always_ff @(posedge eth_rxck)begin
//        if (rst_rx) tx_end_rxck <= 2'b0;
//        else        tx_end_rxck <= {tx_end_rxck[0], tx_end[3]};   
//    end    
//--> moikawa add (2018.12.11)

//<-- moikawa add (2018.11.02)
//       wire [10:0] txbuf_sel2 = tx_cnt;
//       reg [7:0]  data_pipe2 [17:0]; // part of pipelined selector from TXBUF[].
//       wire [4:0]  data_pipe_sel2;    
//--> moikawa add (2018.11.02)
    reg delay_flg;
    reg [2:0] fcs_cnt;
    always_ff @(posedge eth_rxck)begin
//        if (st==Tx_En&&tx_cnt<(PckSize-3'd4))   UDP_o <= {delay_flg,data_pipe2[data_pipe_sel2]};
//        else if (st==Tx_En&&fcs_cnt!=3'b100)    UDP_o <= {delay_flg,data_pipe2[data_pipe_sel2]};
        //if (st==Tx_En)  UDP_o <= {delay_flg,data_pipe2[data_pipe_sel2]};
        if (st==Tx_En)  UDP_o <= {(tx_cnt<(PckSize-3'd4)),TXBUF[0]};
        else            UDP_o <= 0;
    end

    always_ff @(posedge eth_rxck)begin
        if (st==Tx_En&&tx_cnt<(PckSize-3'd4))   delay_flg <= `HI;
        else if (st==Tx_En&&fcs_cnt!=3'b100)    delay_flg <= `LO;
        else                                    delay_flg <= `LO;
    end

    always_ff @(posedge eth_rxck)begin
        if (st==Tx_En&&tx_cnt>(PckSize-3'd3))   fcs_cnt <= fcs_cnt + 3'b1;
        else                                    fcs_cnt <= 3'b0;
    end

//<-- moikawa add (2018.11.02)
//    reg [10:0] txbuf_sel_d2;

//    //always_ff @(posedge clk125) begin
//    always_ff @(posedge eth_rxck)begin
//        txbuf_sel_d2 <= txbuf_sel2;
//    end
//    assign data_pipe_sel2 = (txbuf_sel_d2[10:6] < 5'd17)? 
//                             txbuf_sel_d2[10:6] : 5'd17 ;

//    //always_ff @(posedge clk125) begin // inserted pipelined stage.
//    always_ff @(posedge eth_rxck)begin
//        //for (k=0; k<64; k=k+1) begin
//        //  data_pipe[k] <= TXBUF[ (64*k) + txbuf_sel[5:0] ];
//        //end
//        data_pipe2[0]  <=  TXBUF[ txbuf_sel2[5:0]         ];
//        data_pipe2[1]  <=  TXBUF[ txbuf_sel2[5:0] + 64    ];
//        data_pipe2[2]  <=  TXBUF[ txbuf_sel2[5:0] + 128   ];
//        data_pipe2[3]  <=  TXBUF[ txbuf_sel2[5:0] + 192   ];
//        data_pipe2[4]  <=  TXBUF[ txbuf_sel2[5:0] + 256   ];
//        data_pipe2[5]  <=  TXBUF[ txbuf_sel2[5:0] + 320   ];
//        data_pipe2[6]  <=  TXBUF[ txbuf_sel2[5:0] + 384   ];
//        data_pipe2[7]  <=  TXBUF[ txbuf_sel2[5:0] + 448   ];
//        data_pipe2[8]  <=  TXBUF[ txbuf_sel2[5:0] + 512   ];
//        data_pipe2[9]  <=  TXBUF[ txbuf_sel2[5:0] + 576   ];
//        data_pipe2[10] <=  TXBUF[ txbuf_sel2[5:0] + 640   ];
//        data_pipe2[11] <=  TXBUF[ txbuf_sel2[5:0] + 704   ];
//        data_pipe2[12] <=  TXBUF[ txbuf_sel2[5:0] + 768   ];
//        data_pipe2[13] <=  TXBUF[ txbuf_sel2[5:0] + 832   ];
//        data_pipe2[14] <=  TXBUF[ txbuf_sel2[5:0] + 896   ];
//        data_pipe2[15] <=  TXBUF[ txbuf_sel2[5:0] + 960   ];
//        if (txbuf_sel2[5:0] < 6'd22) begin
//	       data_pipe2[16] <=  TXBUF[ txbuf_sel2[5:0] + 1024  ];
//        end else begin
//	       data_pipe2[16] <=  8'h00;
//        end
//        data_pipe2[17] <= 8'h00;  // dummy value.
//    end
//--> moikawa add (2018.11.02)


    /*---ERROR---*/
    always_ff @(posedge eth_rxck)begin
        if(st==ERROR)   trans_err <= 1'b1;
        else            trans_err <= 1'b0;
    end
    
    axi_read axi_read(
        /*---INPUT---*/
        .clk_i          (eth_rxck),
        .rst            (rst_rx),
        .rst_btn        (rst_btn),
        .rd_en          (read_en),
        .sel            (addr_cnt),
        .axi_arready    (axi_arready),
        .axi_r          (axi_r),
        .transend       (transend),
        .SW             (SW[7:4]),
        /*---OUTPUT---*/
        .axi_ar         (axi_ar),
        .axi_rready     (axi_rready)
    );
    
endmodule