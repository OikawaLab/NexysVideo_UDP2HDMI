//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.1 (lin64) Build 2188600 Wed Apr  4 18:39:19 MDT 2018
//Date        : Thu Feb 18 17:38:57 2021
//Host        : bluewater01.localdomain running 64-bit unknown
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (BTN_C,
    CPU_RSTN,
    ETH_RST_B,
    ETH_RXCK,
    LED,
    RGMII_rd,
    RGMII_rx_ctl,
    RGMII_td,
    RGMII_tx_ctl,
    RGMII_txc,
    SET_VADJ,
    SW,
    SYSCLK,
    TMDS_clk_n,
    TMDS_clk_p,
    TMDS_data_n,
    TMDS_data_p,
    VADJ_EN,
    ddr3_addr,
    ddr3_ba,
    ddr3_cas_n,
    ddr3_ck_n,
    ddr3_ck_p,
    ddr3_cke,
    ddr3_dm,
    ddr3_dq,
    ddr3_dqs_n,
    ddr3_dqs_p,
    ddr3_odt,
    ddr3_ras_n,
    ddr3_reset_n,
    ddr3_we_n,
    eth_int_b,
    eth_mdc,
    eth_mdio,
    eth_pme_b);
  input BTN_C;
  input CPU_RSTN;
  inout ETH_RST_B;
  input ETH_RXCK;
  output [7:0]LED;
  input [3:0]RGMII_rd;
  input RGMII_rx_ctl;
  output [3:0]RGMII_td;
  output RGMII_tx_ctl;
  output RGMII_txc;
  output [1:0]SET_VADJ;
  input [7:0]SW;
  input SYSCLK;
  output TMDS_clk_n;
  output TMDS_clk_p;
  output [2:0]TMDS_data_n;
  output [2:0]TMDS_data_p;
  output VADJ_EN;
  output [14:0]ddr3_addr;
  output [2:0]ddr3_ba;
  output ddr3_cas_n;
  output [0:0]ddr3_ck_n;
  output [0:0]ddr3_ck_p;
  output [0:0]ddr3_cke;
  output [1:0]ddr3_dm;
  inout [15:0]ddr3_dq;
  inout [1:0]ddr3_dqs_n;
  inout [1:0]ddr3_dqs_p;
  output [0:0]ddr3_odt;
  output ddr3_ras_n;
  output ddr3_reset_n;
  output ddr3_we_n;
  input eth_int_b;
  output eth_mdc;
  inout eth_mdio;
  input eth_pme_b;

  wire BTN_C;
  wire CPU_RSTN;
  wire ETH_RST_B;
  wire ETH_RXCK;
  wire [7:0]LED;
  wire [3:0]RGMII_rd;
  wire RGMII_rx_ctl;
  wire [3:0]RGMII_td;
  wire RGMII_tx_ctl;
  wire RGMII_txc;
  wire [1:0]SET_VADJ;
  wire [7:0]SW;
  wire SYSCLK;
  wire TMDS_clk_n;
  wire TMDS_clk_p;
  wire [2:0]TMDS_data_n;
  wire [2:0]TMDS_data_p;
  wire VADJ_EN;
  wire [14:0]ddr3_addr;
  wire [2:0]ddr3_ba;
  wire ddr3_cas_n;
  wire [0:0]ddr3_ck_n;
  wire [0:0]ddr3_ck_p;
  wire [0:0]ddr3_cke;
  wire [1:0]ddr3_dm;
  wire [15:0]ddr3_dq;
  wire [1:0]ddr3_dqs_n;
  wire [1:0]ddr3_dqs_p;
  wire [0:0]ddr3_odt;
  wire ddr3_ras_n;
  wire ddr3_reset_n;
  wire ddr3_we_n;
  wire eth_int_b;
  wire eth_mdc;
  wire eth_mdio;
  wire eth_pme_b;

  design_1 design_1_i
       (.BTN_C(BTN_C),
        .CPU_RSTN(CPU_RSTN),
        .ETH_RST_B(ETH_RST_B),
        .ETH_RXCK(ETH_RXCK),
        .LED(LED),
        .RGMII_rd(RGMII_rd),
        .RGMII_rx_ctl(RGMII_rx_ctl),
        .RGMII_td(RGMII_td),
        .RGMII_tx_ctl(RGMII_tx_ctl),
        .RGMII_txc(RGMII_txc),
        .SET_VADJ(SET_VADJ),
        .SW(SW),
        .SYSCLK(SYSCLK),
        .TMDS_clk_n(TMDS_clk_n),
        .TMDS_clk_p(TMDS_clk_p),
        .TMDS_data_n(TMDS_data_n),
        .TMDS_data_p(TMDS_data_p),
        .VADJ_EN(VADJ_EN),
        .ddr3_addr(ddr3_addr),
        .ddr3_ba(ddr3_ba),
        .ddr3_cas_n(ddr3_cas_n),
        .ddr3_ck_n(ddr3_ck_n),
        .ddr3_ck_p(ddr3_ck_p),
        .ddr3_cke(ddr3_cke),
        .ddr3_dm(ddr3_dm),
        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_dqs_p(ddr3_dqs_p),
        .ddr3_odt(ddr3_odt),
        .ddr3_ras_n(ddr3_ras_n),
        .ddr3_reset_n(ddr3_reset_n),
        .ddr3_we_n(ddr3_we_n),
        .eth_int_b(eth_int_b),
        .eth_mdc(eth_mdc),
        .eth_mdio(eth_mdio),
        .eth_pme_b(eth_pme_b));
endmodule
