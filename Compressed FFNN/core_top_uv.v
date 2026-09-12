`timescale 1ns / 1ps

module core_top_uv 
#(
    // Parameters for block_u
    parameter   IN_FEAT_U                   = 2,
    parameter   NUM_CORES_U                 = 2,
    parameter   WIDTH_NODE_BITS_U           = 8,
    parameter   WIDTH_NODE_WEIGHT_BITS_U    = 16,
    parameter   WIDTH_ACCUM_BITS_U          = 20,   // |_log2(NUM_CORES)_|   + WIDTH_NODE_WEIGHT_BITS
    parameter   WIDTH_RESULT_BITS_U         = 20,   // |_log2(IN_FEATURES)_| + WIDTH_NODE_WEIGHT_BITS
    // Parameters for block_v
    parameter   OUT_FEATURES                = 4,
    parameter   NUM_CORES_V                 = 8,
    parameter   WIDTH_NODE_WEIGHT_BITS_V    = 16,
    parameter   WIDTH_RESULT_BITS_V         = 20,   // |_log2(COMP_RANK)_| + WIDTH_NODE_WEIGHT_BITS
    // WIDTH of ADDRESSES
    parameter   WIDTH_ADDRESS_F_BITS        = 2,
    parameter   WIDTH_ADDRESS_U_BITS        = 2,
    parameter   WIDTH_ADDRESS_RANK_BITS     = 2,    // WIDTH_ADDRESS_S_V_BITS, |_log2(COMP_RANK)_| + 1  (bits)
    parameter   WIDTH_ADDRESS_V_BITS        = 2,
    parameter   WIDTH_ADDRESS_V_OFFSET_BITS = 2,     // |_log2(NUM_ITERS)_| + 1 (bits)
    //
    parameter   WEIGHT_BITS                 = 8,
    parameter   MAX_BITS                    = 40,
    //
    parameter   COMP_RANK                   = 2
)
(
    clk, reset_n, i_run,
    // For core_control_u block
    i_node_vec_u, i_wegt_vec_u,
    o_u_ce, o_u_we, o_addr_f, o_addr_u,
    // For core_acc_v block
    i_wegt_vec_v,
    o_v_ce, o_v_we, o_addr_v, o_wait_v,
    o_feat, o_feat_valid,
    //
    o_idle_uv, o_run_uv, o_done_uv,
    //
    i_state_idle_mem_ctl,
    //
    // For debugging
    o_u_result, o_u_valid, o_u_block_done
);

// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//            Define ports, wires and regs
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o

// *-*-*-*    Local Parameters   *-*-*-*
localparam  WIDTH_NODE_BITS_V   = WIDTH_RESULT_BITS_U;
//  For FSM
localparam  S_IDLE  =   2'b00;
localparam  S_RUN   =   2'b01;
localparam  S_DONE  =   2'b10;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*         Ports         *-*-*-*
input   clk;
input   reset_n;
input   i_run;

input  [NUM_CORES_U * WIDTH_NODE_BITS_U-1:0]   i_node_vec_u;
input  [NUM_CORES_U * WEIGHT_BITS-1:0]         i_wegt_vec_u;
output  o_u_ce;
output  o_u_we;
output  [WIDTH_ADDRESS_F_BITS-1:0]  o_addr_f;
output  [WIDTH_ADDRESS_U_BITS-1:0]  o_addr_u;

input   i_state_idle_mem_ctl;

output  [OUT_FEATURES * WIDTH_RESULT_BITS_V-1:0]  o_feat;
output  o_feat_valid;

input   [NUM_CORES_V * WEIGHT_BITS-1:0] i_wegt_vec_v;
output  o_v_ce;
output  o_v_we;
output  [WIDTH_ADDRESS_V_BITS-1:0]      o_addr_v;
output  o_wait_v;

output  o_idle_uv;
output  o_run_uv;
output  o_done_uv;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  For core_control_u  *-*-*-*
wire    [WIDTH_RESULT_BITS_U-1:0]    u_result;
wire    u_valid;
wire    u_block_done;

wire    u_idle;
wire    u_calc;
wire    u_accum;
wire    u_wait;
wire    u_done;

wire    [WIDTH_ADDRESS_RANK_BITS-1:0]   addr_v_s;

wire    [WIDTH_ADDRESS_F_BITS-1:0]      addr_f;
wire    [WIDTH_ADDRESS_U_BITS-1:0]      addr_u;
wire    u_ce;
wire    u_we;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  For core_acc_v   *-*-*-*
wire    v_idle_c;
wire    v_calc_c;
wire    v_wait_c;
wire    v_done_c;

wire    v_idle_r;
wire    v_run_r;
wire    v_wait_r;
wire    v_done_r;

wire    [WIDTH_ADDRESS_V_BITS-1:0]   addr_v;
wire    v_ce;
wire    v_we;

wire    [OUT_FEATURES * WIDTH_RESULT_BITS_V-1:0]  o_result_v;
wire    o_result_v_valid;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  For FSM  *-*-*-*
reg [1:0]   c_state;
reg [1:0]   n_state;

wire    is_run_done;

reg     run_ff;
// *-*-*-*-*-*-*-*-*-*-*-*-*


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//       Wiring btw top and instantiated modules
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o

// *-*-*-*-*-*  core_control_u module  *-*-*-*-*-*
assign  o_u_ce   =  u_ce;
assign  o_u_we   =  u_we;
assign  o_addr_f =  addr_f;
assign  o_addr_u =  addr_u; 
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*-*-*  core_acc_v module  *-*-*-*-*-*
assign  o_v_ce   =  v_ce;
assign  o_v_we   =  v_we;
assign  o_addr_v =  addr_v;
assign  o_wait_v =  v_wait_r;

assign  o_feat          = o_result_v;
assign  o_feat_valid    = o_result_v_valid;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//                 Just for Debugging
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
output  [WIDTH_RESULT_BITS_U-1:0]  o_u_result;
output  o_u_valid;
output  o_u_block_done;

assign  o_u_result  =   u_result;
assign  o_u_valid   =   u_valid;
assign  o_u_block_done  =   u_block_done;


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
				n_state = S_RUN;
			end
		end
		S_RUN: begin
			if (is_run_done) begin
				n_state = S_DONE;
			end
		end
		S_DONE: n_state = S_IDLE;
	endcase
end

assign  o_idle_uv = (c_state == S_IDLE);
assign  o_run_uv  = (c_state == S_RUN);
assign  o_done_uv = (c_state == S_DONE);

assign  is_run_done = (c_state == S_RUN) && u_idle && v_idle_r;


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//     Instantiation of control_u and acc_v modules
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o

// *-*-*-*  Calculation with U_approx  *-*-*-*
core_control_u #(
    .IN_FEATURES            (IN_FEAT_U),
    .NUM_CORES              (NUM_CORES_U),
    .COMP_RANK              (COMP_RANK),
    //
    .I_WEGT_WIDTH_BITS      (WEIGHT_BITS),
    .I_NODE_WIDTH_BITS        (WIDTH_NODE_BITS_U),
    .MULT_WIDTH_BITS       (WIDTH_ACCUM_BITS_U),
    .O_RESULT_WIDTH_BITS      (WIDTH_RESULT_BITS_U),
    .MAX_BITS               (MAX_BITS),
    //
    .WIDTH_ADDR_F_BITS      (WIDTH_ADDRESS_F_BITS),
    .WIDTH_ADDR_U_BITS      (WIDTH_ADDRESS_U_BITS),
    .WIDTH_ADDR_OUT_BITS    (WIDTH_ADDRESS_RANK_BITS)
) core_control_u_inst (
    .clk            (clk),
    .reset_n        (reset_n),
    .i_valid        (run_ff),
    //
    .i_node_vec     (i_node_vec_u),
    .i_wegt_vec     (i_wegt_vec_u),
    //
    .o_result       (u_result),
    .o_valid_u      (u_valid),
    .o_block_u_done (u_block_done),
    //
    .o_idle         (u_idle),
    .o_calc         (u_calc),
    .o_accum        (u_accum),
    .o_wait         (u_wait),
    .o_done         (u_done),
    //
    .i_idle_c_v         (v_idle_c),
    .o_idx_rank_node    (addr_v_s),
    //
    .o_addr_f       (addr_f),
    .o_addr_u       (addr_u),
    .o_ce_u         (u_ce),
    .o_we_u         (u_we)
);
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

// *-*-*-*  Instantiation  *-*-*-*
core_acc_v #(
    .OUT_FEATURES       (OUT_FEATURES),
    .NUM_CORES          (NUM_CORES_V),
    .COMP_RANK          (COMP_RANK),
    //
    .WIDTH_WEIGHT_BITS  (WEIGHT_BITS),
    .WIDTH_NODE_BITS    (WIDTH_NODE_BITS_V),
    .WIDTH_NODE_WEIGHT_BITS (WIDTH_NODE_WEIGHT_BITS_V),
    .WIDTH_RESULT_BITS  (WIDTH_RESULT_BITS_V),
    .MAX_BITS           (MAX_BITS),
    //
    .WIDTH_ADDRESS_V    (WIDTH_ADDRESS_V_BITS),
    .WIDTH_ADDRESS_S_V  (WIDTH_ADDRESS_RANK_BITS),
    .WIDTH_ADDRESS_V_OFFSET (WIDTH_ADDRESS_V_OFFSET_BITS)
) core_acc_v_inst (
    .clk            (clk),
    .reset_n        (reset_n),
    .i_valid_u      (u_valid),
    //
    .i_node_u       (u_result),
    .i_addr_v_s     (addr_v_s),
    .i_block_u_done (u_block_done),
    .i_state_idle_mem_ctl   (i_state_idle_mem_ctl),
    //
    .o_result       (o_result_v),
    .o_valid        (o_result_v_valid),
    //
    .o_idle_c       (v_idle_c),
    .o_calc         (v_calc_c),
    .o_wait         (v_wait_c),
    .o_done_c       (v_done_c),
    //
    .o_idle_r       (v_idle_r),
    .o_run_r        (v_run_r),
    .o_wait_r       (v_wait_r),
    .o_done_r       (v_done_r),
    //
    .o_addr_v       (addr_v),
    .o_ce_v         (v_ce),
    .o_we_v         (v_we),
    .i_wegt_v_vec   (i_wegt_vec_v)
);
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*




endmodule