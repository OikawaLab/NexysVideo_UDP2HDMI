### This file is a general .xdc for the Nexys Video Rev. A
### To use it in a project:
### - uncomment the lines corresponding to used pins
### - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


### Clock Signal
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports SYSCLK]
create_clock -period 8.000 -name PHY_RXCLK -waveform {0.000 4.000} [get_ports ETH_RXCK]
create_clock -period 8.000 -name PHY_TXCLK -waveform {0.000 4.000} [get_pins gmii2rgmii/ODDR_ck/Q]

set_input_jitter [get_clocks -of_objects [get_ports ETH_RXCK]] 0.080


set_input_delay -clock PHY_RXCLK -max 0.500 [get_ports {RGMII_rd[*]}]
set_input_delay -clock PHY_RXCLK -clock_fall -max -add_delay 0.500 [get_ports {RGMII_rd[*]}]
set_input_delay -clock PHY_RXCLK -min -0.500 [get_ports {RGMII_rd[*]}]
set_input_delay -clock PHY_RXCLK -clock_fall -min -add_delay -0.500 [get_ports {RGMII_rd[*]}]

set_input_delay -clock PHY_RXCLK -max 0.500 [get_ports RGMII_rx_ctl]
set_input_delay -clock PHY_RXCLK -clock_fall -max -add_delay 0.500 [get_ports RGMII_rx_ctl]
set_input_delay -clock PHY_RXCLK -min -0.500 [get_ports RGMII_rx_ctl]
set_input_delay -clock PHY_RXCLK -clock_fall -min -add_delay -0.500 [get_ports RGMII_rx_ctl]

## CLOCK
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports SYSCLK]

## LEDs
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS25} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS25} [get_ports {LED[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS25} [get_ports {LED[4]}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS25} [get_ports {LED[5]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS25} [get_ports {LED[6]}]
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS25} [get_ports {LED[7]}]
set_false_path -to [get_ports {LED[*]}]

## Buttons
set_property -dict {PACKAGE_PIN B22 IOSTANDARD LVCMOS33} [get_ports BTN_C]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS15} [get_ports CPU_RSTN]
set_false_path -from [get_ports BTN_C]
set_false_path -from [get_ports CPU_RSTN]

## Switches
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports {SW[0]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33} [get_ports {SW[1]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {SW[2]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports {SW[3]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {SW[4]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {SW[5]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {SW[6]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports {SW[7]}]
set_false_path -from [get_ports {SW[*]}]

### Pmod header JA
#set_property -dict {PACKAGE_PIN AB22 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[0]}]
#set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[1]}]
#set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[2]}]
#set_property -dict {PACKAGE_PIN AB18 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[3]}]
#set_property -dict {PACKAGE_PIN Y21 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[4]}]
#set_property -dict {PACKAGE_PIN AA21 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[5]}]
#set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[6]}]
#set_property -dict {PACKAGE_PIN AA18 IOSTANDARD LVCMOS33} [get_ports {PMOD_A[7]}]
#set_false_path -to [get_ports {PMOD_A[*]}]

### Pmod header JB
#set_property -dict { PACKAGE_PIN V9    IOSTANDARD LVCMOS33 } [get_ports { VGA_red[0] }]; #IO_L21N_T3_DQS_34 Sch=jb_n[1]
#set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { VGA_red[1] }]; #IO_L21P_T3_DQS_34 Sch=jb_p[1]
#set_property -dict { PACKAGE_PIN V7    IOSTANDARD LVCMOS33 } [get_ports { VGA_red[2] }]; #IO_L19N_T3_VREF_34 Sch=jb_n[2]
#set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { VGA_red[3] }]; #IO_L19P_T3_34 Sch=jb_p[2]
#set_property -dict { PACKAGE_PIN W9    IOSTANDARD LVCMOS33 } [get_ports { VGA_blue[0] }]; #IO_L24N_T3_34 Sch=jb_n[3]
#set_property -dict { PACKAGE_PIN Y9    IOSTANDARD LVCMOS33 } [get_ports { VGA_blue[1] }]; #IO_L24P_T3_34 Sch=jb_p[3]
#set_property -dict { PACKAGE_PIN Y8    IOSTANDARD LVCMOS33 } [get_ports { VGA_blue[2] }]; #IO_L23N_T3_34 Sch=jb_n[4]
#set_property -dict { PACKAGE_PIN Y7    IOSTANDARD LVCMOS33 } [get_ports { VGA_blue[3] }]; #IO_L23P_T3_34 Sch=jb_p[4]
#set_false_path -to [get_ports {VGA_red[*]}]
#set_false_path -to [get_ports {VGA_blue[*]}]

### Pmod header JC
#set_property -dict { PACKAGE_PIN Y6    IOSTANDARD LVCMOS33 } [get_ports { VGA_green[0] }]; #IO_L18N_T2_34 Sch=jc_n[1]
#set_property -dict { PACKAGE_PIN AA6   IOSTANDARD LVCMOS33 } [get_ports { VGA_green[1] }]; #IO_L18P_T2_34 Sch=jc_p[1]
#set_property -dict { PACKAGE_PIN AA8   IOSTANDARD LVCMOS33 } [get_ports { VGA_green[2] }]; #IO_L22N_T3_34 Sch=jc_n[2]
#set_property -dict { PACKAGE_PIN AB8   IOSTANDARD LVCMOS33 } [get_ports { VGA_green[3] }]; #IO_L22P_T3_34 Sch=jc_p[2]
#set_property -dict { PACKAGE_PIN R6    IOSTANDARD LVCMOS33 } [get_ports { VGA_hsync }]; #IO_L17N_T2_34 Sch=jc_n[3]
#set_property -dict { PACKAGE_PIN T6    IOSTANDARD LVCMOS33 } [get_ports { VGA_vsync }]; #IO_L17P_T2_34 Sch=jc_p[3]
##set_property -dict { PACKAGE_PIN AB6   IOSTANDARD LVCMOS33 } [get_ports { jc[6] }]; #IO_L20N_T3_34 Sch=jc_n[4]
##set_property -dict { PACKAGE_PIN AB7   IOSTANDARD LVCMOS33 } [get_ports { jc[7] }]; #IO_L20P_T3_34 Sch=jc_p[4]
#set_false_path -to [get_ports {VGA_green[*]}]
#set_false_path -to [get_ports {VGA_hsync}]
#set_false_path -to [get_ports {VGA_vsync}]

# HDMI out
set_property -dict { PACKAGE_PIN U1    IOSTANDARD TMDS_33  } [get_ports { TMDS_clk_n }]; #IO_L1N_T0_34 Sch=hdmi_tx_clk_n
set_property -dict { PACKAGE_PIN T1    IOSTANDARD TMDS_33  } [get_ports { TMDS_clk_p }]; #IO_L1P_T0_34 Sch=hdmi_tx_clk_p
set_property -dict { PACKAGE_PIN Y1    IOSTANDARD TMDS_33  } [get_ports { TMDS_data_n[0] }]; #IO_L5N_T0_34 Sch=hdmi_tx_n[0]
set_property -dict { PACKAGE_PIN W1    IOSTANDARD TMDS_33  } [get_ports { TMDS_data_p[0] }]; #IO_L5P_T0_34 Sch=hdmi_tx_p[0]
set_property -dict { PACKAGE_PIN AB1   IOSTANDARD TMDS_33  } [get_ports { TMDS_data_n[1] }]; #IO_L7N_T1_34 Sch=hdmi_tx_n[1]
set_property -dict { PACKAGE_PIN AA1   IOSTANDARD TMDS_33  } [get_ports { TMDS_data_p[1] }]; #IO_L7P_T1_34 Sch=hdmi_tx_p[1]
set_property -dict { PACKAGE_PIN AB2   IOSTANDARD TMDS_33  } [get_ports { TMDS_data_n[2] }]; #IO_L8N_T1_34 Sch=hdmi_tx_n[2]
set_property -dict { PACKAGE_PIN AB3   IOSTANDARD TMDS_33  } [get_ports { TMDS_data_p[2] }]; #IO_L8P_T1_34 Sch=hdmi_tx_p[2]
set_false_path -to [get_ports {TMDS_data_n[*]}]
set_false_path -to [get_ports {TMDS_data_p[*]}]
set_false_path -to [get_ports {TMDS_clk_n}]
set_false_path -to [get_ports {TMDS_clk_p}]

## Ethernet
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS25} [get_ports eth_int_b]
set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS25} [get_ports eth_mdc]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS25} [get_ports eth_mdio]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS25} [get_ports eth_pme_b]

set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports ETH_RST_B]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS25} [get_ports ETH_RXCK]
set_property -dict {PACKAGE_PIN W10 IOSTANDARD LVCMOS25} [get_ports RGMII_rx_ctl]
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS25} [get_ports {RGMII_rd[0]}]
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS25} [get_ports {RGMII_rd[1]}]
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS25} [get_ports {RGMII_rd[2]}]
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS25} [get_ports {RGMII_rd[3]}]
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS25} [get_ports RGMII_txc]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS25} [get_ports RGMII_tx_ctl]
set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS25} [get_ports {RGMII_td[0]}]
set_property -dict {PACKAGE_PIN W12 IOSTANDARD LVCMOS25} [get_ports {RGMII_td[1]}]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS25} [get_ports {RGMII_td[2]}]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS25} [get_ports {RGMII_td[3]}]

#DDR3
set_property -dict { PACKAGE_PIN M2   } [get_ports { ddr3_addr[0] }]; #IO_L16N_T2_35 Sch=ddr3_addr[0]
set_property -dict { PACKAGE_PIN M5   } [get_ports { ddr3_addr[1] }]; #IO_L23N_T3_35 Sch=ddr3_addr[1]
set_property -dict { PACKAGE_PIN M3   } [get_ports { ddr3_addr[2] }]; #IO_L16P_T2_35 Sch=ddr3_addr[2]
set_property -dict { PACKAGE_PIN M1   } [get_ports { ddr3_addr[3] }]; #IO_L15P_T2_DQS_35 Sch=ddr3_addr[3]
set_property -dict { PACKAGE_PIN L6   } [get_ports { ddr3_addr[4] }]; #IO_25_35 Sch=ddr3_addr[4]
set_property -dict { PACKAGE_PIN P1   } [get_ports { ddr3_addr[5] }]; #IO_L20N_T3_35 Sch=ddr3_addr[5]
set_property -dict { PACKAGE_PIN N3   } [get_ports { ddr3_addr[6] }]; #IO_L19N_T3_VREF_35 Sch=ddr3_addr[6]
set_property -dict { PACKAGE_PIN N2   } [get_ports { ddr3_addr[7] }]; #IO_L22N_T3_35 Sch=ddr3_addr[7]
set_property -dict { PACKAGE_PIN M6   } [get_ports { ddr3_addr[8] }]; #IO_L23P_T3_35 Sch=ddr3_addr[8]
set_property -dict { PACKAGE_PIN R1   } [get_ports { ddr3_addr[9] }]; #IO_L20P_T3_35 Sch=ddr3_addr[9]
set_property -dict { PACKAGE_PIN L5   } [get_ports { ddr3_addr[10] }]; #IO_L18P_T2_35 Sch=ddr3_addr[10]
set_property -dict { PACKAGE_PIN N5   } [get_ports { ddr3_addr[11] }]; #IO_L24N_T3_35 Sch=ddr3_addr[11]
set_property -dict { PACKAGE_PIN N4   } [get_ports { ddr3_addr[12] }]; #IO_L19P_T3_35 Sch=ddr3_addr[12]
set_property -dict { PACKAGE_PIN P2   } [get_ports { ddr3_addr[13] }]; #IO_L22P_T3_35 Sch=ddr3_addr[13]
set_property -dict { PACKAGE_PIN P6   } [get_ports { ddr3_addr[14] }]; #IO_L24P_T3_35 Sch=ddr3_addr[14]
set_property -dict { PACKAGE_PIN L3   } [get_ports { ddr3_ba[0] }]; #IO_L14P_T2_SRCC_35 Sch=ddr3_ba[0]
set_property -dict { PACKAGE_PIN K6   } [get_ports { ddr3_ba[1] }]; #IO_L17P_T2_35 Sch=ddr3_ba[1]
set_property -dict { PACKAGE_PIN L4   } [get_ports { ddr3_ba[2] }]; #IO_L18N_T2_35 Sch=ddr3_ba[2]
set_property -dict { PACKAGE_PIN K3   } [get_ports { ddr3_cas }]; #IO_L14N_T2_SRCC_35 Sch=ddr3_cas
set_property -dict { PACKAGE_PIN J6   } [get_ports { ddr3_cke[0] }]; #IO_L17N_T2_35 Sch=ddr3_cke[0]
set_property -dict { PACKAGE_PIN P4    IOSTANDARD LVDS     } [get_ports { ddr3_clk_n[0] }]; #IO_L21N_T3_DQS_35 Sch=ddr3_clk_n[0]
set_property -dict { PACKAGE_PIN P5    IOSTANDARD LVDS     } [get_ports { ddr3_clk_p[0] }]; #IO_L21P_T3_DQS_35 Sch=ddr3_clk_p[0]
set_property -dict { PACKAGE_PIN G3   } [get_ports { ddr3_dm[0] }]; #IO_L11N_T1_SRCC_35 Sch=ddr3_dm[0]
set_property -dict { PACKAGE_PIN F1   } [get_ports { ddr3_dm[1] }]; #IO_L5N_T0_AD13N_35 Sch=ddr3_dm[1]
set_property -dict { PACKAGE_PIN G2   } [get_ports { ddr3_dq[0] }]; #IO_L8N_T1_AD14N_35 Sch=ddr3_dq[0]
set_property -dict { PACKAGE_PIN H4   } [get_ports { ddr3_dq[1] }]; #IO_L12P_T1_MRCC_35 Sch=ddr3_dq[1]
set_property -dict { PACKAGE_PIN H5   } [get_ports { ddr3_dq[2] }]; #IO_L10N_T1_AD15N_35 Sch=ddr3_dq[2]
set_property -dict { PACKAGE_PIN J1   } [get_ports { ddr3_dq[3] }]; #IO_L7N_T1_AD6N_35 Sch=ddr3_dq[3]
set_property -dict { PACKAGE_PIN K1   } [get_ports { ddr3_dq[4] }]; #IO_L7P_T1_AD6P_35 Sch=ddr3_dq[4]
set_property -dict { PACKAGE_PIN H3   } [get_ports { ddr3_dq[5] }]; #IO_L11P_T1_SRCC_35 Sch=ddr3_dq[5]
set_property -dict { PACKAGE_PIN H2   } [get_ports { ddr3_dq[6] }]; #IO_L8P_T1_AD14P_35 Sch=ddr3_dq[6]
set_property -dict { PACKAGE_PIN J5   } [get_ports { ddr3_dq[7] }]; #IO_L10P_T1_AD15P_35 Sch=ddr3_dq[7]
set_property -dict { PACKAGE_PIN E3   } [get_ports { ddr3_dq[8] }]; #IO_L6N_T0_VREF_35 Sch=ddr3_dq[8]
set_property -dict { PACKAGE_PIN B2   } [get_ports { ddr3_dq[9] }]; #IO_L2N_T0_AD12N_35 Sch=ddr3_dq[9]
set_property -dict { PACKAGE_PIN F3   } [get_ports { ddr3_dq[10] }]; #IO_L6P_T0_35 Sch=ddr3_dq[10]
set_property -dict { PACKAGE_PIN D2   } [get_ports { ddr3_dq[11] }]; #IO_L4N_T0_35 Sch=ddr3_dq[11]
set_property -dict { PACKAGE_PIN C2   } [get_ports { ddr3_dq[12] }]; #IO_L2P_T0_AD12P_35 Sch=ddr3_dq[12]
set_property -dict { PACKAGE_PIN A1   } [get_ports { ddr3_dq[13] }]; #IO_L1N_T0_AD4N_35 Sch=ddr3_dq[13]
set_property -dict { PACKAGE_PIN E2   } [get_ports { ddr3_dq[14] }]; #IO_L4P_T0_35 Sch=ddr3_dq[14]
set_property -dict { PACKAGE_PIN B1   } [get_ports { ddr3_dq[15] }]; #IO_L1P_T0_AD4P_35 Sch=ddr3_dq[15]
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_n[0] }]; #IO_L9N_T1_DQS_AD7N_35 Sch=ddr3_dqs_n[0]
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_p[0] }]; #IO_L9P_T1_DQS_AD7P_35 Sch=ddr3_dqs_p[0]
set_property -dict { PACKAGE_PIN D1    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_n[1] }]; #IO_L3N_T0_DQS_AD5N_35 Sch=ddr3_dqs_n[1]
set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVDS     } [get_ports { ddr3_dqs_p[1] }]; #IO_L3P_T0_DQS_AD5P_35 Sch=ddr3_dqs_p[1]
set_property -dict { PACKAGE_PIN K4   } [get_ports { ddr3_odt }]; #IO_L13P_T2_MRCC_35 Sch=ddr3_odt
set_property -dict { PACKAGE_PIN J4   } [get_ports { ddr3_ras }]; #IO_L13N_T2_MRCC_35 Sch=ddr3_ras
set_property -dict { PACKAGE_PIN G1   } [get_ports { ddr3_reset }]; #IO_L5P_T0_AD13P_35 Sch=ddr3_reset
set_property -dict { PACKAGE_PIN L1   } [get_ports { ddr3_we }]; #IO_L15N_T2_DQS_35 Sch=ddr3_we

## Voltage Adjust
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS25} [get_ports {SET_VADJ[0]}]
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS25} [get_ports {SET_VADJ[1]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS25} [get_ports VADJ_EN]