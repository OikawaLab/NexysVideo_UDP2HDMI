`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/31 19:16:30
// Design Name: 
// Module Name: ARP_reply
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
module TOP(
    input [3:0]     ETH_RXD,     // recv data
    //input           ETH_RXCK,  // recv clk
    input           ETH_RXCTL,   // recv ctl
    
    input           BTN_C,       // input reset btn   
            
    output [3:0]    ETH_TXD,    //-- Ether RGMII Tx data.
    output          ETH_TXCK,
    output          ETH_TXCTL,
    inout           ETH_RST_B,  //-- Ether PHY reset(active low)
    input 	        eth_int_b,
    input           eth_pme_b,
    output          eth_mdc,
    inout           eth_mdio,
    input           eth_rxck,
    input           eth_rxck_90,
    //output          clk200,

    //input           SYSCLK,
    //input           ui_clk,
    input           CPU_RSTN,
    //input           mmcm_locked,
    input           aresetn,
    //output          interconnect_aresetn,
    
    output          rst_o,
    output          recvend,
    input           block_end,
    input  [7:0]    SW,
    output [7:0]    LED,
    output [7:0]    PMOD_A,
    //output [7:0]    PMOD_B,
    //output [7:0]    PMOD_C,
    
    output [1:0] SET_VADJ,
    output VADJ_EN,
    
    output [1:0]    M_AXI_AWID,
    output [28:0]   M_AXI_AWADDR,
    output [7:0]    M_AXI_AWLEN,
    output [2:0]    M_AXI_AWSIZE,
    output [1:0]    M_AXI_AWBURST,
    output          M_AXI_AWLOCK,
    output [3:0]    M_AXI_AWCACHE,
    output [2:0]    M_AXI_AWPROT,
    output [3:0]    M_AXI_AWQOS,
    output          M_AXI_AWVALID,
    input           M_AXI_AWREADY,
    output [31:0]   M_AXI_WDATA,
    output [3:0]    M_AXI_WSTRB,
    output          M_AXI_WLAST,
    output          M_AXI_WVALID,
    input           M_AXI_WREADY,
    input           M_AXI_BRESP,
    input           M_AXI_BVALID,
    output          M_AXI_BREADY,
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
    input           M_AXI_ARREADY,
    input [31:0]    M_AXI_RDATA,
    input [1:0]     M_AXI_RRESP,
    input           M_AXI_RLAST,
    input           M_AXI_RVALID,
    output          M_AXI_RREADY
    );    
    
    AXI_AW          axi_aw;
    AXI_W           axi_w;
    AXI_AR          axi_ar;
    AXI_R           axi_r;
    
    wire [7:0]       gmii_txd;
    wire             gmii_txctl;
     
    (*dont_touch="true"*) wire [7:0] gmii_rxd;
    (*dont_touch="true"*) wire  gmii_rxctl;
    
    //wire eth_rxck;
//    wire eth_rxck_90;
//    wire eth_clkgen_locked;
    wire rst_rx;
    assign rst_rx = !aresetn;
//    ETH_CLKGEN eth_clkgen (
//          .eth_rxck     (ETH_RXCK),
//          .rxck_90deg   (eth_rxck),
//          .rxck_180deg  (eth_rxck_90),
////          .clk200       (clk200),
//          .locked       (eth_clkgen_locked),
//          .resetn       (CPU_RSTN)
//    );
    
    //**------------------------------------------------------------
    //** RGMII to GMII translator. (add by moikawa)
    //**
    wire  gmii_rxctl_hi, gmii_rxctl_lo;
    RGMII2GMII rgmii2gmii (
           .rxd_i      ( ETH_RXD       ), //<-- INPUT[3:0]
           .rxck_i     ( eth_rxck      ), //<-- INPUT, Rx clock 125 MHz.
           .rxctl_i    ( ETH_RXCTL     ), //--
           .rxd_o      ( gmii_rxd      ), //--[7:0]
           .rxctl_hi_o ( gmii_rxctl_hi ),
           .rxctl_lo_o ( gmii_rxctl_lo ),
           .rxctl_o    ( gmii_rxctl    )
     ) ;
    //**------------------------------------------------------------
    //** GMII to RGMII translator. (add by moikawa)
    //**
    wire clk10;
    wire clk100;
    wire sys_clkgen_locked;
    GMII2RGMII gmii2rgmii (
          .txck_o   ( ETH_TXCK    ),
          .txd_o    ( ETH_TXD     ), //--> OUTPUT
          .txctl_o  ( ETH_TXCTL   ), //--> OUTPUT
          .txck_i   ( eth_rxck    ), //- Tx clock 125MHz.
          .txck_90_i( eth_rxck_90 ),
          .txd_i    ( gmii_txd    ), //-- [7:0]
          .txctl_i  ( gmii_txctl  )  //--
    );

    //**------------------------------------------------------------
    //** Reset generator. (add by moikawa)
    //**
//    RSTGEN rstgen125 (
//         .reset_o  ( rst_rx ),
//         .reset_i  ( 1'b0   ),
//         .locked_i ( eth_clkgen_locked ),
//         .clk      ( eth_rxck )
//    );
//    assign interconnect_aresetn = !rst_rx;
    assign rst_o = rst_rx;
    
//    RSTGEN2 rstgen100 (
//         .reset_o  ( aresetn ),
//         .locked_i ( mmcm_locked ),
//         .clk      ( ui_clk )
//    );

    
    wire rst_btn = BTN_C;
    wire UDP_btn_tx;        // ボタン入力によるUDP送信
    //AXI0
    wire axi_awready;
    wire axi_wready;
    wire axi_bresp;
    wire axi_bvalid;
    wire axi_bready;
    wire axi_arready;
    wire axi_rready;
    
    wire [8:0] rarp_o;   
    wire [8:0] ping_o;  
    wire [8:0] UDP_btn_d;   // ボタン入力によるUDP送信
    wire [8:0] UDP_o;       // UDPの送受信
    
    Arbiter R_Arbiter (
        /*---INPUT---*/
        .gmii_rxd     (gmii_rxd),   //<-- "rgmii2gmii"
        .gmii_rxctl   (gmii_rxctl), //<-- "rgmii2gmii"
        .eth_rxck     (eth_rxck),   //<-- "eth_clkgen"
        .rst_rx       (rst_rx),
        .rst_btn      (rst_btn),
        .SW           (SW),
        .recvend      (recvend),
        .block_end    (block_end),
        //AXI0
        .axi_awready  (axi_awready),
        .axi_wready   (axi_wready),
        .axi_bresp    (axi_bresp),
        .axi_bvalid   (axi_bvalid),
        .axi_arready  (axi_arready),
        .axi_r        (axi_r),
        /*---OUTPUT---*/
        .rarp_o       (rarp_o),
        .ping_o       (ping_o),
        .UDP_o        (UDP_o),
        //AXI0
        .axi_aw       (axi_aw),
        .axi_w        (axi_w),
        .axi_bready   (axi_bready),
        .axi_ar       (axi_ar),
        .axi_rready   (axi_rready)
    );

    T_Arbiter T_Arbiter(
        /*---INPUT---*/
        .rarp_i       (rarp_o),
        .ping_i       (ping_o),
        .UDP_btn_d(UDP_btn_d),
        .UDP_i        (UDP_o),
        .UDP_btn_tx(UDP_btn_tx),
        .eth_rxck(eth_rxck),
        .rst       (rst_rx),
        /*---OUTPUT---*/
        .txd_o        (gmii_txd),
        .gmii_txctl_o (gmii_txctl)
    );
    
    assign ETH_RST_B = 1'bz;
    assign eth_mdio  = 1'bz;
    assign eth_mdc   = 1'b1;
    
    assign LED[8] = sys_clkgen_locked;
    assign LED[7] = 1'b0;

//    assign PMOD_A[0] = CPU_RSTN;
//    assign PMOD_A[1] = sys_clkgen_locked;
    assign PMOD_A[2] = 1'b0;
    assign PMOD_A[3] = 1'b0;
    assign PMOD_A[4] = eth_mdc;
    assign PMOD_A[5] = 1'b0; //eth_mdio_o;
    assign PMOD_A[6] = 1'b0; //eth_mdio_oe;

    assign SET_VADJ = 2'b11;  //-- 3.3V
    assign VADJ_EN  = 1'b1;   //-- On
    
    assign M_AXI_AWID = axi_aw.id;
    assign M_AXI_AWADDR = axi_aw.addr;
    assign M_AXI_AWLEN = axi_aw.len;
    assign M_AXI_AWSIZE = axi_aw.size;
    assign M_AXI_AWBURST = axi_aw.burst;
    assign M_AXI_AWLOCK = axi_aw.lock;
    assign M_AXI_AWCACHE = axi_aw.cache;
    assign M_AXI_AWPROT = axi_aw.prot;
    assign M_AXI_AWQOS = axi_aw.qos;
    assign M_AXI_AWVALID = axi_aw.valid;
    assign axi_awready = M_AXI_AWREADY;
    
    assign M_AXI_WDATA = axi_w.data;
    assign M_AXI_WSTRB = axi_w.strb;
    assign M_AXI_WLAST = axi_w.last;
    assign M_AXI_WVALID = axi_w.valid;
    assign axi_wready = M_AXI_WREADY;
    
    assign axi_bresp = M_AXI_BRESP;
    assign axi_bvalid = M_AXI_BVALID;
    assign M_AXI_BREADY = axi_bready;
    
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
    
    assign axi_r.data = M_AXI_RDATA; 
    assign axi_r.resp = M_AXI_RRESP;
    assign axi_r.last = M_AXI_RLAST;
    assign axi_r.valid = M_AXI_RVALID;
    assign M_AXI_RREADY = axi_rready;
    
endmodule
