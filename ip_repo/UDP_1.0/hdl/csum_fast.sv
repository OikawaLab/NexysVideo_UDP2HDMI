`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/01/16 21:26:20
// Design Name: 
// Module Name: csum_fast
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
// IPヘッダのチェックサム計算を1サイクルで行うためのモジュール
//

module csum_fast(
    /*---INPUT---*/
    CLK_i,
    data_i,
    dataen_i,
    reset_i,
    /*---OUTPUT---*/
    csum_o
    );
    /*---I/O Declare---*/
    input       CLK_i;
    input [7:0] data_i [19:0];
    input       dataen_i;
    input       reset_i;
    
    output [15:0] csum_o;
    
    /*---wire/resister---*/
    wire [15:0] sum0;
    wire [15:0] sum1;
    wire [15:0] sum2;
    wire [15:0] sum3;
    wire [15:0] sum4;
    wire [15:0] sum5;
    wire [15:0] sum6;
    wire [15:0] sum7;
    wire [15:0] sum8;
    
    reg  [15:0] r_sum0;
    reg  [15:0] r_sum1;
    reg  [15:0] r_sum2;
    reg  [15:0] r_sum3;
    reg  [15:0] r_sum4;
    reg  [15:0] r_sum5;
    reg  [15:0] r_sum6;
    reg  [15:0] r_sum7;
    reg  [15:0] csum;
    
    assign sum0 = subsum({data_i[0],data_i[1]},{data_i[2],data_i[3]});
    assign sum1 = subsum({data_i[4],data_i[5]},{data_i[6],data_i[7]});
    assign sum2 = subsum(r_sum0,r_sum1);
    always_ff @(posedge CLK_i)begin
        r_sum0 <= sum0;
        r_sum1 <= sum1;
        r_sum2 <= sum2;
    end
    
    assign sum3 = subsum({data_i[8],data_i[9]},{data_i[10],data_i[11]});
    assign sum4 = subsum({data_i[12],data_i[13]},{data_i[14],data_i[15]});
    assign sum5 = subsum(r_sum3,r_sum4);
    always_ff @(posedge CLK_i)begin
        r_sum3 <= sum3;
        r_sum4 <= sum4;
        r_sum5 <= sum5;
    end    
    
    assign sum6 = subsum({data_i[16],data_i[17]},{data_i[18],data_i[19]});
    assign sum7 = subsum(r_sum2,r_sum5);
    always_ff @(posedge CLK_i)begin
        r_sum6 <= sum6;
        r_sum7 <= sum7;
    end
    
    assign sum8 = subsum(r_sum6,r_sum7);
    
    always_ff @(posedge CLK_i)begin
        if(dataen_i)    csum <= sum8 ^ 16'hFF_FF;
        else            csum <= 16'h55_55;          // dummy
    end
    
    assign csum_o = csum;
    
    function  [15:0] subsum (input [15:0] inA,input [15:0] inB);
        reg [16:0] sum;
        begin
            sum = inA + inB;
            subsum = sum[15:0] + sum[16];
        end
    endfunction
    
endmodule
