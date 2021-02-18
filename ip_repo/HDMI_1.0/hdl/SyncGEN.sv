module SyncGEN # (
    /*---parameter---*/
    // Horizontal Parameter
    parameter	H_FRONT	=	16,
    parameter	H_SYNC	=	96,
    parameter	H_BACK	=	48,
    parameter	H_ACT	=	640,
    parameter	H_TOTAL	=	H_FRONT+H_SYNC+H_BACK+H_ACT,
    // Vertical Parameter
    parameter	V_FRONT	=	10,
    parameter	V_SYNC	=	2,
    parameter	V_BACK	=	33,
    parameter	V_ACT	=	480,
    parameter	V_TOTAL	=	V_FRONT+V_SYNC+V_BACK+V_ACT
)(
    /*---INPUT---*/
    VGA_CLK,
    RESET,
    /*---OUTPUT---*/
    HS_cnt_o,
    VS_cnt_o,
    VGA_HS,
    VGA_VS,
    VDE_o
);
/*---I/O Declare---*/
input       VGA_CLK;
input       RESET;

output [10:0] HS_cnt_o;
output [10:0] VS_cnt_o;
output reg  VGA_HS;
output reg  VGA_VS;
output reg  VDE_o;


/*---reg---*/
reg [10:0] HS_cnt;
reg [10:0] VS_cnt;

assign HS_cnt_o	= HS_cnt;
assign VS_cnt_o	= VS_cnt;

/*---Horizontal Generator---*/
always_ff @(posedge VGA_CLK)begin
	if(RESET)begin
		HS_cnt <= 11'b0;
	end
	else if(HS_cnt<H_TOTAL-1)begin
		HS_cnt <= HS_cnt + 11'b1;
	end
	else begin
		HS_cnt <= 11'b0;
	end
end

always_ff @(posedge VGA_CLK)begin
	if(RESET)begin
		VGA_HS <= 1;
	end
	else if(HS_cnt==H_ACT+H_FRONT-1)begin
		VGA_HS <= 0;
	end
	else if(HS_cnt==H_ACT+H_FRONT+H_SYNC) begin
		VGA_HS <= 1;
	end
end

/*---Vertical Generator---*/
always_ff @(posedge VGA_CLK)begin
	if(RESET)begin
		VS_cnt <= 11'b0;
	end
    else if(HS_cnt==H_ACT+H_FRONT-1)begin
        if(VS_cnt<V_TOTAL-1)begin
            VS_cnt <= VS_cnt + 11'b1;
        end
        else begin
            VS_cnt <= 11'b0;
	    end
    end
end

always_ff @(posedge VGA_CLK)begin
	if(RESET)begin
		VGA_VS <= 1;
	end
	else if(HS_cnt==H_ACT+H_FRONT-1)begin
	   if(VS_cnt==V_ACT+V_FRONT-1)begin
	       VGA_VS <= 0;
	   end
	   else if(VS_cnt==V_ACT+V_FRONT+V_SYNC-1)begin
	       VGA_VS <= 1;
	   end
    end
end

always_ff @(posedge VGA_CLK)begin
    if(RESET)begin
        VDE_o <= 1'b0;
    end
    else if(HS_cnt<H_ACT&&VS_cnt<V_ACT)begin
        VDE_o <= 1'b1;
    end
    else begin
        VDE_o <= 1'b0;
    end
end

endmodule