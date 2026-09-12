`timescale 1ps/1ps

// core_block_u NUM_CORES ? ?? ? ?? ??, U_NODE_NUM / NUM_CORES ? ?? ???? ?? 
module core_block_u
#(
    parameter I_NODE_WIDTH_BITS = 8,
    parameter I_WEGT_WIDTH_BITS = 8,
    parameter MULT_WIDTH_BITS = 16,
    parameter O_RESULT_WIDTH_BITS = 64,              // 2^16(input * weight)? ? ? ??? ??? ?? ????. --> NUM_CORES ?? ?? ????.
    parameter MAX_BITS = 40,
    parameter NUM_CORES = 2
)
(
    input clk,
    input reset_n,
    input i_valid,

    input [I_NODE_WIDTH_BITS * NUM_CORES-1 : 0] i_node_vec,
    input [I_WEGT_WIDTH_BITS * NUM_CORES-1 : 0] i_wegt_vec,

    output [O_RESULT_WIDTH_BITS-1 : 0] o_mult,
    output o_valid
);

    genvar i;

    wire [MULT_WIDTH_BITS * NUM_CORES -1 : 0] temp_result;

    reg [O_RESULT_WIDTH_BITS-1 : 0] w_mult;
    wire [NUM_CORES-1 : 0] w_valid;


    generate begin
        for(i = 0; i < NUM_CORES; i = i + 1)
            core_u #(
                .I_NODE_WIDTH_BITS          (I_NODE_WIDTH_BITS),
                .I_WEGT_WIDTH_BITS          (I_WEGT_WIDTH_BITS),
                .O_RESULT_WIDTH_BITS        (MULT_WIDTH_BITS),
                .MAX_BITS                   (MAX_BITS)
            ) u0_core_u (
                .clk                        (clk), 
                .reset_n                    (reset_n), 
                .i_valid                    (i_valid),
                .i_node                     (i_node_vec[I_NODE_WIDTH_BITS * i +: I_NODE_WIDTH_BITS]),
                .i_wegt                     (i_wegt_vec[I_WEGT_WIDTH_BITS * i +: I_WEGT_WIDTH_BITS]),
                .o_result                   (temp_result[MULT_WIDTH_BITS * i +: MULT_WIDTH_BITS]),
                .o_valid                    (w_valid[i])
            );
    end endgenerate
    
    reg [MULT_WIDTH_BITS-1 : 0] patial_sum [NUM_CORES-1 : 0];    
    
    always @(*) begin
        patial_sum[0] = temp_result[MULT_WIDTH_BITS * 0 +: MULT_WIDTH_BITS];
    end 
    
    generate
        for(i = 1; i < NUM_CORES; i = i + 1) begin
            always @(*) begin
                patial_sum[i] = patial_sum[i-1] + temp_result[MULT_WIDTH_BITS * i +: MULT_WIDTH_BITS];
            end
        end 
    endgenerate
    
    //assign w_mult = temp_result[MULT_WIDTH_BITS] + temp_result[MULT_WIDTH_BITS] 
    assign o_mult = patial_sum[NUM_CORES-1];
    assign o_valid = &w_valid;
    
endmodule