`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2025 05:37:06 PM
// Design Name: 
// Module Name: core_acc_v
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


module core_acc_v
#(
    parameter   OUT_FEATURES            = 8,
    parameter   NUM_CORES               = 8,
    parameter   COMP_RANK               = 10,
    //
    parameter   WIDTH_WEIGHT_BITS       = 8,
    parameter   WIDTH_NODE_BITS         = 8,
    parameter   WIDTH_NODE_WEIGHT_BITS  = 16,
    parameter   WIDTH_RESULT_BITS       = 20,   // |_log2(COMP_RANK)_| + WIDTH_NODE_WEIGHT_BITS
    parameter   MAX_BITS                = 40,
    //
    parameter   WIDTH_ADDRESS_V         = 10,   // |_log2(COMP_RANK * NUM_ITERS)_| + 1  (bits)
    parameter   WIDTH_ADDRESS_S_V       = 5,    // |_log2(COMP_RANK)_| + 1  (bits)
    parameter   WIDTH_ADDRESS_V_OFFSET  = 2     // |_log2(NUM_ITERS)_| + 1 (bits)
)
(
    input clk,
    input reset_n,
    input i_valid_u,
    //
    input [WIDTH_NODE_BITS -1 : 0] i_node_u,
    input [WIDTH_ADDRESS_S_V -1 : 0] i_addr_v_s,
    input i_block_u_done,
    input i_state_idle_mem_ctl,
    //
    output [WIDTH_RESULT_BITS * OUT_FEATURES -1 : 0] o_result,
    output o_valid,
    //
    output [WIDTH_ADDRESS_V-1 :0] o_addr_v,
    output o_we_v,
    output o_ce_v,
    input [WIDTH_WEIGHT_BITS * NUM_CORES -1 : 0]i_wegt_v_vec,
    //
    output o_idle_c,
    output o_calc,
    output o_wait,
    output o_done_c,
    //
    output o_idle_r,
    output o_run_r,
    output o_wait_r,
    output o_done_r,
    //
    output o_addr_v_delay,
    output accum_valid
);

    localparam S_IDLE = 2'b00, S_CALC = 2'b01, S_RUN = 2'b01, S_WAIT = 2'b10, S_DONE = 2'b11;
    
    reg [1:0] n_state_calc;
    reg [1:0] c_state_calc;
    //
    reg [1:0] n_state_run;
    reg [1:0] c_state_run;

    wire is_calc_done, is_add_done;
    wire is_run_done, is_wait_done;

    // #=#=#=#=#=#=#=#= CALC FSM #=#=#=#=#=#=#=#=
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) c_state_calc <= 2'b00;
        else c_state_calc <= n_state_calc;
    end

    always @(*) begin
        case(c_state_calc)
            S_IDLE : n_state_calc = i_valid_u ? S_CALC : S_IDLE;
            S_CALC : n_state_calc = is_calc_done ? S_WAIT : S_CALC;
            S_WAIT : n_state_calc = is_add_done ? S_DONE : S_WAIT;
            S_DONE : n_state_calc = S_IDLE;
        endcase
    end


    // #=#=#=#=#=#=#=#= RUN FSM #=#=#=#=#=#=#=#=
        always @(posedge clk or negedge reset_n) begin
        if(!reset_n) c_state_run <= 2'b00;
        else c_state_run <= n_state_run;
    end

    always @(*) begin
        case(c_state_run)
            S_IDLE : n_state_run = o_ce_v ? S_RUN : S_IDLE;
            S_RUN : n_state_run = is_run_done ? S_WAIT : S_RUN;
            S_WAIT : n_state_run = is_wait_done ? S_DONE : S_WAIT;
            S_DONE : n_state_run = S_IDLE;
        endcase
    end


    // #=#=#=#=#=#=#=#= state signal #=#=#=#=#=#=#=#=
    assign o_idle_c = c_state_calc == S_IDLE;
    assign o_calc = c_state_calc == S_CALC;
    assign o_wait = c_state_calc == S_WAIT;
    assign o_done_c = c_state_calc == S_DONE;
    //
    assign o_idle_r = c_state_run == S_IDLE;
    assign o_run_r = c_state_run == S_RUN;
    assign o_wait_r = c_state_run == S_WAIT;
    assign o_done_r = c_state_run == S_DONE;
    

    // #=#=#=#=#=#=#=#= state done signal #=#=#=#=#=#=#=#=
    assign is_calc_done = addr_v_offset == (OUT_FEATURES/NUM_CORES)-1 && c_state_calc == S_CALC;
    //assign is_add_done = ~addr_v_offset_valid && c_state_calc == S_CALC;
    assign is_add_done = c_state_calc == S_WAIT && delayed_w_valid == 0;
    assign is_run_done = block_u_done & o_done_c;
//    assign is_run_done = addr_v_offset == OUT_FEATURES-1;
//    assign is_wait_done = i_state_idle_mem_ctl & o_wait_r;
//    assign is_wait_done = o_done_c;
    assign is_wait_done = delayed_o_done_c;    
    
    reg delayed_o_done_c;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) delayed_o_done_c <= 0;
        else delayed_o_done_c <= o_done_c;
    end

    // #=#=#=#=#=#=#=#= state signal #=#=#=#=#=#=#=#=
    assign o_we_v = 1'b0;
    assign o_ce_v = i_valid_u | o_calc;


    // #=#=#=#=#=#=#=#= block_u_done signal #=#=#=#=#=#=#=#=
    reg block_u_done;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) block_u_done <= 1'b0;
        else block_u_done <= o_done_r ? 1'b0 : 
                            i_valid_u ? i_block_u_done : block_u_done;
    end


    // #=#=#=#=#=#=#=#= node_u signal #=#=#=#=#=#=#=#=
    reg [WIDTH_NODE_BITS -1 : 0] node_u;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) node_u <= 1'b0;
        else node_u <= o_done_c ? 1'b0 : 
                      i_valid_u ? i_node_u : node_u;
    end

    
    // #=#=#=#=#=#=#=#= addr_v_s signal #=#=#=#=#=#=#=#=
    // A addr_v_s signal same as idx_rank_node signal in u module.
    reg [WIDTH_ADDRESS_V -1 : 0]addr_v_s;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) addr_v_s <= 0;
//        else if (o_done_c) addr_v_s <= 0;
        else if (i_valid_u) addr_v_s <= i_addr_v_s * (OUT_FEATURES/NUM_CORES);
        else if (o_done_c) addr_v_s <= i_addr_v_s * (OUT_FEATURES/NUM_CORES);
    end


    // #=#=#=#=#=#=#=#= read_valid signal #=#=#=#=#=#=#=#=
    reg read_valid;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) read_valid <= 1'b0;
        else if(o_calc) read_valid <= 1'b1;
        else read_valid <= 1'b0;
    end


    // #=#=#=#=#=#=#=#= addr_v_offset signal #=#=#=#=#=#=#=#=
    reg [WIDTH_ADDRESS_V_OFFSET-1 : 0] addr_v_offset;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) addr_v_offset <= 1'b0;
        else if(is_calc_done) addr_v_offset <= 1'b0;        // is calc done or i_valid_u
        else if(o_ce_v) addr_v_offset <= addr_v_offset + 1;
//        else if(o_calc) addr_v_offset <= addr_v_offset + 1;
    end


    // #=#=#=#=#=#=#=#= addr_v_offset_valid signal #=#=#=#=#=#=#=#=
    
    // #=#=#=#=#=#=#=#= instantiation of core_block_v #=#=#=#=#=#=#=#=
    wire [WIDTH_NODE_WEIGHT_BITS * NUM_CORES-1 : 0] w_result;
    
    wire w_valid;

    core_block_v #(
        .NUM_CORES(NUM_CORES),
        .WIDTH_WEIGHT_BITS(WIDTH_WEIGHT_BITS),
        .WIDTH_NODE_BITS(WIDTH_NODE_BITS),
        .WIDTH_NODE_WEIGHT_BITS(WIDTH_NODE_WEIGHT_BITS),
        .MAX_BITS(MAX_BITS)
    )
    u0_core_block_v(
        .i_valid_calc(o_calc),
        .reset_n(reset_n),
        .clk(clk),

        .i_node_u(node_u),
        .i_wegt_v_vec(i_wegt_v_vec),

        .o_result(w_result),        // WIDTH_NODE_WEIGHT_BITS * NUM_CORES bits
        .o_valid(w_valid)
    );


    // #=#=#=#=#=#=#=#= instantiation of core_acc_add_v #=#=#=#=#=#=#=#=
    reg delayed_w_valid;
    reg two_cycle_delayed_w_valid;
    reg [OUT_FEATURES - 1 : 0] cnt;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) delayed_w_valid <= 0;
        else delayed_w_valid <= w_valid;
    end
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) two_cycle_delayed_w_valid <= 0;
        else two_cycle_delayed_w_valid <= delayed_w_valid;
    end
       
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) cnt <= 0;
        else if(accum_valid) cnt <= 0;
//        else cnt <= cnt + 1;
//        else if(delayed_w_valid || !o_ce_v) cnt <= cnt + 1;
        else if(delayed_w_valid || two_cycle_delayed_w_valid) cnt <= cnt + 1;
//        else cnt <= 0;
    end
        
    wire concat_signal;
    wire accum_valid;
    

    assign concat_signal = w_valid || delayed_w_valid;
    assign accum_valid = cnt == (OUT_FEATURES/NUM_CORES) -1;
    
    reg [WIDTH_NODE_WEIGHT_BITS * OUT_FEATURES -1 : 0] concat;
     
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) concat <= 0;
        else if(concat_signal) concat <= {w_result, concat[(WIDTH_NODE_WEIGHT_BITS * OUT_FEATURES -1) : WIDTH_NODE_WEIGHT_BITS * NUM_CORES]};
        // 
        else if(i_valid_u) concat <= 0;
    end



    // #=#=#=#=#=#=#=#= instantiation of core_acc_add_v #=#=#=#=#=#=#=#=
    genvar i;
    //
    wire [WIDTH_RESULT_BITS * OUT_FEATURES -1 : 0] accum_result;
    
    generate
        for(i = OUT_FEATURES-1; i >= 0; i = i - 1) begin
            core_acc_add_v #(
            .WIDTH_NODE_WEIGHT_BITS(WIDTH_NODE_WEIGHT_BITS),
            .WIDTH_RESULT_BITS      (WIDTH_RESULT_BITS)
            )
            u0_core_acc_add_v(
            .clk(clk),
            .reset_n(reset_n),
            .clear(o_wait_r),
            //
            .accum_valid(accum_valid),
            .delayed_w_valid(delayed_w_valid),
            .two_cycle_delayed_w_valid(two_cycle_delayed_w_valid),
            //
            .data_n(concat[WIDTH_NODE_WEIGHT_BITS * i +: WIDTH_NODE_WEIGHT_BITS]),
            .result(accum_result[WIDTH_RESULT_BITS * i +: WIDTH_RESULT_BITS])
            );
        end
   endgenerate 


    // #=#=#=#=#=#=#=#= instantiation of act_relu #=#=#=#=#=#=#=#=
    wire [WIDTH_RESULT_BITS * OUT_FEATURES -1 : 0] final_result;

    genvar k;

    generate
        for(k = 0; k < OUT_FEATURES; k = k + 1) begin
            act_relu #(
            .WIDTH_DATA(WIDTH_RESULT_BITS),
            .WIDTH_RESULT_BITS(WIDTH_RESULT_BITS)
            )
            u0_act_relu(
            .x(accum_result[WIDTH_RESULT_BITS * k +: WIDTH_RESULT_BITS]),                   // WIDTH_DATA
            .y(final_result[WIDTH_RESULT_BITS * k +: WIDTH_RESULT_BITS])                      // WIDTH_DATA
            );
        end
    endgenerate

//    assign o_result = accum_valid ? final_result : 0;
//    always @(posedge clk or negedge reset_n) begin
//        if(!reset_n) o_result <= 0;
//        else if(accum_valid) o_result <= final_result;
//    end
    
    assign o_result = final_result;
    
    assign o_valid = is_run_done;
//    assign o_valid = c_state_run == S_WAIT;

    assign o_addr_v = addr_v_s + addr_v_offset;
    
endmodule