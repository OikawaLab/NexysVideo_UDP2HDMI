`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/26 18:49:42
// Design Name: 
// Module Name: user_defines
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

`define   HI        1'b1
`define   LO        1'b0

`define   bcast_MAC 48'hFF_FF_FF_FF_FF_FF
`define   my_MAC    48'h00_0A_35_02_0F_B0
`define   my_IP     {8'd172,8'd31,8'd210,8'd160}

`define   PREAMB     8'h55
`define   SFD        8'hD5
`define   FTYPE_ARP  16'h08_06
`define   FTYPE_IPV4 16'h08_00
`define   OPR_ARP    16'h00_01

`define   PING_REPLY 16'h00_00
