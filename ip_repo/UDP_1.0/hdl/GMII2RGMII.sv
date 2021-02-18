//                              -*- Mode: Verilog -*-
// Filename        : GMII2RGMII.sv
// Description     : 
// Author          : 
// Created On      : Wed May 23 15:13:04 2018
// Last Modified By: 
// Last Modified On: 2018-05-23 17:34:45
// Update Count    : 0
// Status          : Unknown, Use with caution!

module GMII2RGMII (
   input [7:0]  txd_i,
   input        txck_i,   // 125 MHz
   input        txck_90_i,
   input        txctl_i,

   output [3:0] txd_o,
   output       txck_o,
   output       txctl_o
) ;
   // ODDR: Output Double Data Rate Output Register with Set, Reset and Clock Enable.
   // Xilinx HDL Language Template, version 2017.4,  Artix-7

   ODDR #( .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
           .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
           .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_d0 (
      .Q(txd_o[0]),   // 1-bit DDR output
      .C(txck_i),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(txd_i[4]), // 1-bit data input (positive edge)
      .D2(txd_i[0]), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );  
   ODDR #( .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
           .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
           .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_d1 (
      .Q(txd_o[1]),   // 1-bit DDR output
      .C(txck_i),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(txd_i[5]), // 1-bit data input (positive edge)
      .D2(txd_i[1]), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );  
   ODDR #( .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
           .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
           .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_d2 (
      .Q(txd_o[2]),   // 1-bit DDR output
      .C(txck_i),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(txd_i[6]), // 1-bit data input (positive edge)
      .D2(txd_i[2]), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );  
   ODDR #( .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
           .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
           .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_d3 (
      .Q(txd_o[3]),   // 1-bit DDR output
      .C(txck_i),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(txd_i[7]), // 1-bit data input (positive edge)
      .D2(txd_i[3]), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );  
   
   ODDR #( .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
           .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
           .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_ctl (
      .Q(txctl_o),   // 1-bit DDR output
      .C(txck_i),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(txctl_i), // 1-bit data input (positive edge)
      .D2(txctl_i), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );
   
   ODDR #( .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
           .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
           .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_ck (
      .Q(txck_o),   // 1-bit DDR output
      .C(txck_90_i),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b0), // 1-bit data input (positive edge)
      .D2(1'b1), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   ); 
   
endmodule // GMII2RDMII
