`timescale 1ns / 1ps
module AXI2VGA # (
    /*---parameter---*/
    // Horizontal Parameter
    parameter   H_FRONT     =   16,
    parameter   H_SYNC      =   96,
    parameter   H_BACK      =   48,
    parameter   H_ACT       =   640,
    parameter   H_TOTAL     =   H_FRONT+H_SYNC+H_BACK+H_ACT,
    // Vertical Parameter
    parameter   V_FRONT     =   10,
    parameter   V_SYNC      =   2,
    parameter   V_BACK      =   33,
    parameter   V_ACT       =   480,
    parameter   V_TOTAL     =   V_FRONT+V_SYNC+V_BACK+V_ACT
)
(
    input           SYSCLK,     // 100Mhz
    input           VGACLK,     // 25MHz
    input [10:0]    HS_cnt,
    input [10:0]    VS_cnt,
    output [23:0]   VID_o,
    input           VGA_VS,
    output          empty_o,

    input [31:0]    M_AXI_RDATA,
    input [1:0]     M_AXI_RRESP,
    input           M_AXI_RLAST,
    input           M_AXI_RVALID,
    output          M_AXI_RREADY
);

    /*---signal---*/
    wire        VGA_VS_n = !VGA_VS;
    wire [31:0] axi_rdata;
    wire [1:0]  axi_rresp;
    wire        axi_rlast;
    wire        axi_rvalid;
    wire        axi_rready;
    assign axi_rdata = M_AXI_RDATA;
    assign axi_rresp = M_AXI_RRESP;
    assign axi_rlast = M_AXI_RLAST;
    assign axi_rvalid = M_AXI_RVALID;
    assign M_AXI_RREADY = axi_rready;
    assign axi_rready = axi_rvalid;

    wire [7:0]  blue    = axi_rdata[23:16];
    wire [7:0]  green   = axi_rdata[15:8];
    wire [7:0]  red     = axi_rdata[7:0];
    wire [23:0] data    = {red,blue,green};
    
    wire        rd_act  = ((HS_cnt<=H_ACT-3||HS_cnt>=H_TOTAL-3)&&VS_cnt<=V_ACT-2) || (HS_cnt<=H_ACT-3&&VS_cnt==V_ACT-1) || (HS_cnt>=H_TOTAL-3&&VS_cnt==V_TOTAL-1);
    wire        rd_en   = (rd_act) ? 1'b1 : 1'b0;
    wire [23:0] dout;
    wire        full;
    wire        overflow;
    wire        empty;
    wire        valid;
    wire        underflow;
    wire [9:0]  rd_data_count;
    wire [9:0]  wr_data_count;
    VGA_FIFO VGA_FIFO(
        .rst(VGA_VS_n),
        .wr_clk(SYSCLK),
        .rd_clk(VGACLK),
        .din(data),
        .wr_en(axi_rvalid),
        .rd_en(rd_en),
        .dout(dout),
        .full(full),
        .overflow(overflow),
        .empty(empty),
        .valid(valid),
        .underflow(underflow),
        .rd_data_count(rd_data_count),
        .wr_data_count(wr_data_count)
    );

    assign VID_o = dout;
    assign empty_o = empty;

endmodule