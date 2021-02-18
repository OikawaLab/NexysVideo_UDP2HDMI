/*---STRUCT---*/
typedef struct packed{
    logic [1:0]     id;
    logic [28:0]    addr;
    logic [7:0]     len;
    logic [2:0]     size;
    logic [1:0]     burst;
    logic           lock;
    logic [3:0]     cache;
    logic [2:0]     prot;
    logic [3:0]     qos;
    logic           valid;    
}AXI_AW;
    
typedef struct packed{
    logic [31:0]    data;
    logic [3:0]     strb;
    logic           last;
    logic           valid;  
}AXI_W;

typedef struct packed{
    logic [1:0]     id;
    logic [28:0]    addr;
    logic [7:0]     len;
    logic [2:0]     size;
    logic [1:0]     burst;
    logic           lock;
    logic [3:0]     cache;
    logic [2:0]     prot;
    logic [3:0]     qos;
    logic           valid;    
}AXI_AR;
    
typedef struct packed{
    logic [31:0]    data;
    logic           last;
    logic           valid;
    logic [1:0]     resp;
}AXI_R;