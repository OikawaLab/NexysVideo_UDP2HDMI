
`timescale 1 ns / 1 ps
`include "user_defines.sv"
	module VGA_v1_0_M00_AXI #
	(
		// Users to add parameters here
        //	Horizontal	Parameter
        parameter    H_FRONT    =   16,
        parameter    H_SYNC     =   96,
        parameter    H_BACK     =   48,
        parameter    H_ACT      =   640,
        parameter    H_TOTAL    =   H_FRONT+H_SYNC+H_BACK+H_ACT,
        //    Vertical Parameter
        parameter    V_FRONT    =   10,
        parameter    V_SYNC     =   2,
        parameter    V_BACK     =   33,
        parameter    V_ACT      =   480,
        parameter    V_TOTAL    =   V_FRONT+V_SYNC+V_BACK+V_ACT,     
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Base address of targeted slave
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
		parameter integer C_M_AXI_BURST_LEN	= 16,
		// Thread ID Width
		parameter integer C_M_AXI_ID_WIDTH	= 1,
		// Width of Address Bus
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of Data Bus
		parameter integer C_M_AXI_DATA_WIDTH	= 32,
		// Width of User Write Address Bus
		parameter integer C_M_AXI_AWUSER_WIDTH	= 0,
		// Width of User Read Address Bus
		parameter integer C_M_AXI_ARUSER_WIDTH	= 0,
		// Width of User Write Data Bus
		parameter integer C_M_AXI_WUSER_WIDTH	= 0,
		// Width of User Read Data Bus
		parameter integer C_M_AXI_RUSER_WIDTH	= 0,
		// Width of User Response Bus
		parameter integer C_M_AXI_BUSER_WIDTH	= 0
	)
	(
		// Users to add ports here
        input           VGACLK,
        output [23:0]   VID_o,
        output          VGA_HS,
        output          VGA_VS,
        output          VDE_o,
        input           reset,
		// User ports ends
		// Do not modify the ports beyond this line

		// Initiate AXI transactions
		input wire  INIT_AXI_TXN,
		// Asserts when transaction is complete
		output wire  TXN_DONE,
		// Asserts when ERROR is detected
		output reg  ERROR,
		// Global Clock Signal.
		input wire  M_AXI_ACLK,
		// Global Reset Singal. This Signal is Active Low
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address ID
		output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
		// Master Interface Write Address
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		output wire [7 : 0] M_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		output wire [2 : 0] M_AXI_AWSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		output wire [1 : 0] M_AXI_AWBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		output wire  M_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		output wire [3 : 0] M_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each write transaction.
		output wire [3 : 0] M_AXI_AWQOS,
		// Optional User-defined signal in the write address channel.
		output wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data.
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write last. This signal indicates the last transfer in a write burst.
		output wire  M_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
		output wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER,
		// Write valid. This signal indicates that valid write
    // data and strobes are available
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    // can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response.
		input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
		// Write response. This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Optional User-defined signal in the write response channel
		input wire [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER,
		// Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master
    // can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address.
		output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
		// Read address. This signal indicates the initial
    // address of a read burst transaction.
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		output wire [7 : 0] M_AXI_ARLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		output wire [2 : 0] M_AXI_ARSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		output wire [1 : 0] M_AXI_ARBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		output wire  M_AXI_ARLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		output wire [3 : 0] M_AXI_ARCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Quality of Service, QoS identifier sent for each read transaction
		output wire [3 : 0] M_AXI_ARQOS,
		// Optional User-defined signal in the read address channel.
		output wire [C_M_AXI_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid read address and control information
		output wire  M_AXI_ARVALID,
		// Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
		input wire  M_AXI_ARREADY,
		// Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
		input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
		// Master Read Data
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer
		input wire [1 : 0] M_AXI_RRESP,
		// Read last. This signal indicates the last transfer in a read burst
		input wire  M_AXI_RLAST,
		// Optional User-defined signal in the read address channel.
		input wire [C_M_AXI_RUSER_WIDTH-1 : 0] M_AXI_RUSER,
		// Read valid. This signal indicates that the channel
    // is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    // accept the read data and response information.
		output wire  M_AXI_RREADY
	);
	
    wire empty;
    axi_read axi_read(
        .clk_i(M_AXI_ACLK),
        .reset(reset),
        .VGA_VS(VGA_VS),
        .empty(empty),
        .M_AXI_ARID(M_AXI_ARID),
        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARLOCK(M_AXI_ARLOCK),
        .M_AXI_ARCACHE(M_AXI_ARCACHE),
        .M_AXI_ARPROT(M_AXI_ARPROT),
        .M_AXI_ARQOS(M_AXI_ARQOS),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY)
    );
    wire [10:0] HS_cnt;
    wire [10:0] VS_cnt;
    SyncGEN # (
        //Horizontal Parameter
        .H_FRONT(H_FRONT),
        .H_SYNC(H_SYNC),
        .H_BACK(H_BACK),
        .H_ACT(H_ACT),
        .H_TOTAL(H_TOTAL),
        //Vertical Parameter
        .V_FRONT(V_FRONT),
        .V_SYNC(V_SYNC),
        .V_BACK(V_BACK),
        .V_ACT(V_ACT),
        .V_TOTAL(V_TOTAL)      
    ) SyncGEN (
        /*---INPUT---*/
        .VGA_CLK(VGACLK),
        .RESET(reset),
        /*---OUTPUT---*/
        .HS_cnt_o(HS_cnt),
        .VS_cnt_o(VS_cnt),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VDE_o(VDE_o)
    );
    
    AXI2VGA # (
        //Horizontal Parameter
        .H_FRONT(H_FRONT),
        .H_SYNC(H_SYNC),
        .H_BACK(H_BACK),
        .H_ACT(H_ACT),
        .H_TOTAL(H_TOTAL),
        //Vertical Parameter
        .V_FRONT(V_FRONT),
        .V_SYNC(V_SYNC),
        .V_BACK(V_BACK),
        .V_ACT(V_ACT),
        .V_TOTAL(V_TOTAL)
    ) AXI2VGA (
        .SYSCLK(M_AXI_ACLK),
        .VGACLK(VGACLK),
        .HS_cnt(HS_cnt),
        .VS_cnt(VS_cnt),
        .VID_o(VID_o),
        .VGA_VS(VGA_VS),
        .empty_o(empty),
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RRESP(M_AXI_RRESP),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(M_AXI_RREADY)  
    );
    assign M_AXI_AWID = 0;
    assign M_AXI_AWADDR = 0;
    assign M_AXI_AWLEN = 0;
    assign M_AXI_AWSIZE = 0;
    assign M_AXI_AWBURST = 0;
    assign M_AXI_AWLOCK = 0;
    assign M_AXI_AWCACHE = 0;
    assign M_AXI_AWPROT = 0;
    assign M_AXI_AWQOS = 0;
    assign M_AXI_AWUSER = 0;
    assign M_AXI_AWVALID = 0;
    assign M_AXI_WDATA = 0;
    assign M_AXI_WSTRB = 0;
    assign M_AXI_WLAST = 0;
    assign M_AXI_WUSER = 0;
    assign M_AXI_WVALID = 0;
    assign M_AXI_BREADY = 0;

	endmodule
