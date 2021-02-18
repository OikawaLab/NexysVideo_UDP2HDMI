`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/07/25 17:20:17
// Design Name: 
// Module Name: checksum
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


module checksum(
    clk_i,
    d,
    data_en,
    rst,
    
    csum_o
    );
    
    /*---I/O---*/
    input           clk_i;
    input [7:0]     d;
    input           data_en;
    input           rst;
    
    output [15:0]   csum_o;
    
    /*---delay en---*/
    reg [1:0] d_data_en;
    always_ff @(posedge clk_i)begin
        d_data_en <= {d_data_en[0],data_en};
    end  
    
    /*---delay clk---*/
    reg d_clk;
    always_ff @(posedge clk_i)begin
        if(d_data_en[0])   d_clk <= ~d_clk;
        else               d_clk <= 0;
    end
    
    /*---16bit---*/
    reg [16:0] buffer;
    always_ff @(posedge clk_i)begin
        buffer <= {1'b0,buffer[7:0],d};
    end
    
    /*---checksum---*/
    (*dont_touch="true"*)reg [16:0] sum_17;
//  always_ff @(posedge d_clk or negedge d_data_en[1] or posedge rst)begin
    always_ff @(posedge clk_i)begin
        if(rst) sum_17 <= 17'b0;
        else if(d_data_en[0])begin
            if (d_clk) begin
                sum_17 = sum_17 + buffer;
                sum_17 = sum_17[15:0] + sum_17[16];
            end
        end
        else sum_17 <= 17'b0;
    end
    
    assign csum_o = sum_17[15:0] ^ 16'hFF_FF;
    
endmodule
