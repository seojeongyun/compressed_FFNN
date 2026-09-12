`timescale 1ns / 1ps

module core_linear 
#(
    parameter   IN_FEAT                     = 2,
    parameter   OUT_FEATURES                = 4,
    //
    parameter   NUM_CORES                   = 8,
    parameter   WIDTH_NODE_BITS             = 16,
    parameter   WIDTH_NODE_WEIGHT_BITS      = 16,
    parameter   WIDTH_RESULT_BITS           = 20,
    // WIDTH of ADDRESSES
    parameter   WIDTH_ADDRESS_F_BITS        = 2,
    parameter   WIDTH_ADDRESS_V_BITS        = 2,
    parameter   WIDTH_ADDRESS_V_OFFSET_BITS = 2,
    //
    parameter   WEIGHT_BITS                 = 8,
    parameter   USE_ACT_FN                  = 1
)
(
    clk, reset_n, i_run,
    //
    o_feat, o_feat_valid,
    //
    i_node_vec, o_ce, o_we, o_addr_f,
    //
    i_wegt_vec, o_v_ce, o_v_we, o_addr_v, 
    //
    o_wait_v,
    //
    o_idle, o_run, o_done,
    //
    i_state_idle_mem_ctl,
);

// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//            Define ports, wires and regs
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o

// *-*-*-*    Local Parameters   *-*-*-*
localparam  MEM_INPUT_FEAT_DEPTH = IN_FEAT;

//  For FSM
localparam  S_IDLE  =   2'b00;
localparam  S_READ  =   2'b01;
localparam  S_WAIT  =   2'b10;
localparam  S_DONE  =   2'b11;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*         Ports         *-*-*-*
input   clk;
input   reset_n;
input   i_run;

output  [OUT_FEATURES * WIDTH_RESULT_BITS-1:0]  o_feat;
output  o_feat_valid;

input   [WIDTH_NODE_BITS-1:0]       i_node_vec;
output  [WIDTH_ADDRESS_F_BITS-1:0]  o_addr_f;
output  o_ce;
output  o_we;

input   [NUM_CORES * WEIGHT_BITS-1:0]   i_wegt_vec;
output  o_v_ce;
output  o_v_we;
output  [WIDTH_ADDRESS_V_BITS-1:0]      o_addr_v;

output  o_wait_v;

output  o_idle;
output  o_run;
output  o_done;

input   i_state_idle_mem_ctl;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  *-*-*-*
reg     [WIDTH_ADDRESS_F_BITS-1:0]  addr_f;
wire    ce;
wire    we;

wire    [WIDTH_ADDRESS_V_BITS-1:0]  addr_v;
wire    v_ce;
wire    v_we;

wire    v_idle_c;
wire    v_calc_c;
wire    v_wait_c;
wire    v_done_c;

wire    v_idle_r;
wire    v_run_r;
wire    v_wait_r;
wire    v_done_r;


wire    [OUT_FEATURES * WIDTH_RESULT_BITS-1:0]  o_result_v;
wire    o_result_v_valid;

wire    valid;
wire    block_done;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  For FSM  *-*-*-*
reg [1:0]       c_state;
reg [1:0]       n_state;
wire            is_read_done;
wire            is_wait_done;
wire            go_to_read;
wire            go_to_idle;

wire    o_idle;
wire    o_read;
wire    o_wait;
wire    o_done;

reg     run_ff;
// *-*-*-*-*-*-*-*-*-*-*-*-*


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//       Wiring btw top and instantiated modules
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
assign  o_addr_f =  addr_f;
assign  o_ce    =   ce;
assign  o_we    =   we;

// *-*-*-*-*-*  core_acc_v module  *-*-*-*-*-*
assign  o_addr_v =  addr_v;
assign  o_v_ce   =  v_ce;
assign  o_v_we   =  v_we;

assign  o_wait_v =  v_wait_r;

assign  o_feat          = o_result_v;
assign  o_feat_valid    = o_result_v_valid;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//                       FSM
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
always @(*) begin
    run_ff = 1'b0;
    case (c_state)
        S_IDLE: begin
            run_ff = i_run;
        end
    endcase
end


always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        c_state <= S_IDLE;
    end else begin
        c_state <= n_state;
    end
end


always @(*) begin
    n_state = c_state;
    case (c_state)
        S_IDLE: begin
            if (run_ff) begin
                n_state = S_READ;
            end
        end
        S_READ: begin
            n_state = S_WAIT;
        end
        S_WAIT: begin
            if (go_to_read) begin
                n_state = S_READ;
            end else if (is_wait_done) begin
                n_state = S_DONE;
            end
        end
        S_DONE: begin 
            if (go_to_idle) begin
                n_state = S_IDLE;
            end
        end
    endcase
end

assign o_idle = (c_state == S_IDLE);
assign o_read = (c_state == S_READ);
assign o_wait = (c_state == S_WAIT);
assign o_done = (c_state == S_DONE);

assign valid      = (c_state == S_WAIT) && (v_idle_c);
assign block_done = (c_state == S_WAIT) && (v_idle_c) && (addr_f == (MEM_INPUT_FEAT_DEPTH - 1));

assign go_to_read   = (c_state == S_WAIT) && (v_idle_c) && ~(addr_f == (MEM_INPUT_FEAT_DEPTH - 1));
assign is_wait_done = (c_state == S_WAIT) && (v_idle_c) && (addr_f == (MEM_INPUT_FEAT_DEPTH - 1));
assign go_to_idle   = (c_state == S_DONE) && (v_idle_c);


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//                       ADDRESS
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        addr_f <= {(WIDTH_ADDRESS_F_BITS){1'b0}};
    end else if (c_state == S_DONE) begin
        addr_f <= {(WIDTH_ADDRESS_F_BITS){1'b0}};
    end else if (go_to_read) begin
        addr_f <= addr_f + 1'b1;
    end
end

assign  ce  =   o_read;
assign  we  =   1'b0;

// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//     Instantiation of control_u and acc_v modules
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o

// *-*-*-*  Instantiation  *-*-*-*
core_acc_v #(
    .OUT_FEATURES       (OUT_FEATURES),
    .NUM_CORES          (NUM_CORES),
    //
    .WIDTH_WEIGHT_BITS  (WEIGHT_BITS),
    .WIDTH_NODE_BITS    (WIDTH_NODE_BITS),
    .WIDTH_NODE_WEIGHT_BITS (WIDTH_NODE_WEIGHT_BITS),
    .WIDTH_RESULT_BITS  (WIDTH_RESULT_BITS),
    //
    .WIDTH_ADDRESS_V    (WIDTH_ADDRESS_V_BITS),
    .WIDTH_ADDRESS_S_V  (WIDTH_ADDRESS_F_BITS),
    .WIDTH_ADDRESS_V_OFFSET (WIDTH_ADDRESS_V_OFFSET_BITS),
    .USE_ACT_FN         (USE_ACT_FN)
) core_acc_v_inst (
    .clk            (clk),
    .reset_n        (reset_n),
    .i_valid_u      (valid),
    //
    .i_node_u       (i_node_vec),
    .i_addr_v_s     (addr_f),
    .i_block_u_done (block_done),
    .i_state_idle_mem_ctl   (i_state_idle_mem_ctl),
    //
    .o_result       (o_result_v),
    .o_valid        (o_result_v_valid),
    //
    .o_addr_v       (addr_v),
    .o_ce_v         (v_ce),
    .o_we_v         (v_we),
    .i_wegt_v_vec   (i_wegt_vec),
    //
    .o_idle_c       (v_idle_c),
    .o_calc         (v_calc_c),
    .o_wait         (v_wait_c),
    .o_done_c       (v_done_c),
    //
    .o_idle_r       (v_idle_r),
    .o_run_r        (v_run_r),
    .o_wait_r       (v_wait_r),
    .o_done_r       (v_done_r)
);
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


endmodule