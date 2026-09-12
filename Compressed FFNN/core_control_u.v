`timescale 1ps/1ps

module core_control_u
#(
    parameter   IN_FEATURES             = 6,
    parameter   NUM_CORES               = 2,
    parameter   COMP_RANK               = 4,

    parameter   I_NODE_WIDTH_BITS       = 8,
    parameter   I_WEGT_WIDTH_BITS       = 8,

    parameter   MULT_WIDTH_BITS         = 20,
    parameter   O_RESULT_WIDTH_BITS     = 24,  

    parameter   WIDTH_ADDR_F_BITS       = 10,
    parameter   WIDTH_ADDR_U_BITS       = 10,
    parameter   WIDTH_ADDR_OUT_BITS     = 10,

    parameter LATENCY = 2,
    parameter MAX_BITS = 40
)
(
    input clk,
    input reset_n,
    input i_valid,

    input [I_NODE_WIDTH_BITS * NUM_CORES -1 : 0] i_node_vec,
    input [I_WEGT_WIDTH_BITS * NUM_CORES -1 : 0] i_wegt_vec,

    input i_idle_c_v,

    output [O_RESULT_WIDTH_BITS-1 : 0] o_result,
    output o_block_u_done,
    output o_valid_u,

    output [WIDTH_ADDR_OUT_BITS-1 : 0] o_idx_rank_node,

    output o_idle,
    output o_calc,
    output o_accum,
    output o_wait,
    output o_done,

    output [WIDTH_ADDR_F_BITS-1 : 0] o_addr_f,
    output [WIDTH_ADDR_U_BITS-1 : 0] o_addr_u,

    output o_ce_u,
    output o_we_u
);
    
    parameter S_IDLE = 3'b000, S_CALC = 3'b001, S_ACCUM = 3'b010, S_WAIT = 3'b011, S_DONE = 3'b100;

    reg [2:0] state;
    reg [2:0] n_state;
    reg read_valid;

    wire is_calc_done;
    wire is_accum_done;
    wire go_to_calc;
    wire is_wait_done;



    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# FSM Controller =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) state <= S_IDLE;
        else state <= n_state;
    end

    always @(*) begin
        n_state = state;
        case(state)
            S_IDLE : n_state = i_valid ? S_CALC : S_IDLE;
            S_CALC : n_state = is_calc_done ? S_ACCUM : S_CALC;
            S_ACCUM : n_state = is_accum_done ? S_WAIT : S_ACCUM;
            S_WAIT : n_state = go_to_calc ? S_CALC : 
                               is_wait_done ? S_DONE : S_WAIT;
            S_DONE : n_state = S_IDLE;
        endcase
    end
    


    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# read_valid gen =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) read_valid <= 1'b0;
        else read_valid <= o_calc;
    end
    
    
    
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# Core Block Inst =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    wire w_valid;
    wire [O_RESULT_WIDTH_BITS-1 : 0] w_result;

    core_block_u #(
        .I_NODE_WIDTH_BITS(I_NODE_WIDTH_BITS) ,
        .I_WEGT_WIDTH_BITS(I_WEGT_WIDTH_BITS),
        .MULT_WIDTH_BITS(MULT_WIDTH_BITS),
        .O_RESULT_WIDTH_BITS(O_RESULT_WIDTH_BITS),              
        .MAX_BITS(MAX_BITS),
        .NUM_CORES(NUM_CORES)
    ) u0_core_block_u (
        .clk(clk),
        .reset_n(reset_n),
        .i_valid(read_valid),

        .i_node_vec(i_node_vec), // [I_NODE_WIDTH_BITS * NUM_CORES-1 : 0]
        .i_wegt_vec(i_wegt_vec), // [I_WEGT_WIDTH_BITS * NUM_CORES-1 : 0] 

        .o_mult(w_result),     // [O_RESULT_WIDTH_BITS-1 : 0]
        .o_valid(w_valid)
    );



    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# o_result gen =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    reg [O_RESULT_WIDTH_BITS-1 : 0] r_result;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) r_result <= {O_RESULT_WIDTH_BITS{1'b0}};
        else if(o_valid_u) r_result <= {O_RESULT_WIDTH_BITS{1'b0}};     // o_valid_u? o_addr_f == in_feature / num_core?? ??
        else if(w_valid) r_result <= r_result + w_result;
    end



    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# addr_f gen =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    reg [WIDTH_ADDR_F_BITS-1 : 0] addr_f;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) addr_f <= {WIDTH_ADDR_F_BITS{1'b0}};
        else if(is_wait_done) addr_f <= {WIDTH_ADDR_F_BITS{1'b0}};
        else if(go_to_calc) addr_f <= {WIDTH_ADDR_F_BITS{1'b0}};
        else if(o_calc & ~is_calc_done) addr_f <= addr_f + 1;
    end



    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# addr_u gen =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    reg [WIDTH_ADDR_U_BITS-1 : 0] addr_u;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) addr_u <= {WIDTH_ADDR_F_BITS{1'b0}};
        else if(is_wait_done) addr_u <= {WIDTH_ADDR_F_BITS{1'b0}};
        else if(go_to_calc) addr_u <= addr_u + 1;
        else if(o_calc & ~is_calc_done) addr_u <= addr_u + 1;
    end



    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# idx_rank_node gen =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    reg [WIDTH_ADDR_OUT_BITS-1 : 0] idx_rank_node;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) idx_rank_node <= {WIDTH_ADDR_OUT_BITS{1'b0}};
        else if(is_wait_done) idx_rank_node <= {WIDTH_ADDR_OUT_BITS{1'b0}};
        else if(go_to_calc) idx_rank_node <= idx_rank_node + 1;
    end

    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#= condition of state change #=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    assign is_calc_done = (state == S_CALC && addr_f == (IN_FEATURES / NUM_CORES)-1);
    //assign is_accum_done = state == S_ACCUM && !w_valid;
//    assign is_accum_done = state == S_ACCUM && valid_delay[1];
    assign is_accum_done = state == S_ACCUM && !read_valid;
    assign is_wait_done = (state == S_WAIT && addr_u == (IN_FEATURES / NUM_CORES * COMP_RANK)-1);
    assign go_to_calc = (state == S_WAIT && addr_u != (IN_FEATURES / NUM_CORES * COMP_RANK)-1);
    


    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=# valid_delay_gen =#=#=#=#=#=#=#=#=#=
    // #=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
    reg [LATENCY-1 : 0] valid_delay;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) valid_delay <= {LATENCY{1'b0}};
        else valid_delay <= {valid_delay[0], w_valid};
    end


    assign o_idle = state == S_IDLE;
    assign o_calc = state == S_CALC;
    assign o_accum = state == S_ACCUM;
    assign o_wait = state == S_WAIT;
    assign o_done = state == S_DONE;

    assign o_ce_u = state == S_CALC;
    assign o_we_u = 1'b0;

    assign o_addr_f = addr_f;
    assign o_addr_u = addr_u;

    assign o_result = go_to_calc || is_wait_done ? r_result : o_result;
    assign o_block_u_done = addr_u == IN_FEATURES / NUM_CORES * COMP_RANK-1;
    assign o_valid_u = go_to_calc || is_wait_done;
    assign o_idx_rank_node = idx_rank_node;
    
endmodule