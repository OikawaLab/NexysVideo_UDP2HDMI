`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/06/01 13:51:46
// Design Name: 
// Module Name: CRC_ge
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


module CRC_ge(
    input [7:0] d,
    input CLK,
    input reset,
    input flg,
    output reg [31:0] CRC
    );
    
    reg overflow=0;
    
    parameter Gx = 32'h04_C1_1D_B7;
    
    integer i = 0;
    
    reg [31:0] CRC_0;
 //<--- original 
 /*
    always@(posedge CLK)begin
        if(reset == 0)begin
            CRC = 32'hFF_FF_FF_FF;
        end
        else if(flg==1)begin
            for (i=0;i<4'd8;i=i+1)begin
                CRC_0 = CRC << 1;
                CRC[0] = d[i];
                if(CRC[31] ^ d[i])begin
                    CRC = CRC_0 ^ Gx;
                end else begin
                    CRC = CRC_0;
                end
            end
        end
    end
*/  
//---> original 

//<--- candidate 

    reg [31:0] CRC_1;
    //wire [31:0] CRC_1 = CRC;
    always_comb begin
    
    //    if (reset==0) begin 
    //        CRC_1 = 32'hFF_FF_FF_FF;
    //    end
    //    else if(flg==1)begin 
            CRC_1 = CRC;
            for (i=0;i<4'd8;i=i+1)begin
                CRC_0 = CRC_1 << 1;
                CRC_1[0] = d[i];
                if(CRC_1[31] ^ d[i])begin
                    CRC_1 = CRC_0 ^ Gx;
                end else begin
                    CRC_1 = CRC_0;
                end
            end
    //    end
    end   
        
   always_ff @(posedge CLK)begin
      if(reset == 0) CRC <= 32'hFF_FF_FF_FF;
      else if(flg==1) CRC <= CRC_1; 
   end

//---> candidate 
endmodule
