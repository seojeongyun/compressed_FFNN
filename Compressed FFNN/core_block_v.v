`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2025 04:24:16 PM
// Design Name: 
// Module Name: core_block_v
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


module core_block_v
#(
        parameter   NUM_CORES               = 8,
        //
        parameter   WIDTH_WEIGHT_BITS       = 8,
        parameter   WIDTH_NODE_BITS         = 8,
        parameter   WIDTH_NODE_WEIGHT_BITS  = 16,
        parameter   MAX_BITS                = 40
)
(
        input i_valid_calc,
        input reset_n,
        input clk,

        input signed [WIDTH_NODE_BITS-1 : 0] i_node_u,
        input signed [WIDTH_WEIGHT_BITS * NUM_CORES -1 :0] i_wegt_v_vec,

        output [WIDTH_NODE_WEIGHT_BITS * NUM_CORES -1 :0] o_result,
        output o_valid
);
    
    wire [WIDTH_NODE_WEIGHT_BITS * NUM_CORES -1 :0] w_result;
    wire [NUM_CORES-1 :0] w_valid;
    
    genvar i;

    generate
        for(i = 0; i < NUM_CORES; i = i + 1) begin
            core_u
            #(
                .I_NODE_WIDTH_BITS(WIDTH_NODE_BITS),
                .I_WEGT_WIDTH_BITS(WIDTH_WEIGHT_BITS),
                .O_RESULT_WIDTH_BITS(WIDTH_NODE_WEIGHT_BITS),
                .MAX_BITS(MAX_BITS)
            )
            u0_core_u(
                .clk(clk),
                .reset_n(reset_n),
                .i_valid(i_valid_calc),
                .i_node(i_node_u),
                .i_wegt(i_wegt_v_vec[WIDTH_WEIGHT_BITS * i +: WIDTH_WEIGHT_BITS]),

                .o_result(w_result[WIDTH_NODE_WEIGHT_BITS * i +: WIDTH_NODE_WEIGHT_BITS]),
                .o_valid(w_valid[i])
            );
        end
    endgenerate
    
    assign o_result = w_result;
    assign o_valid = &w_valid;
    
endmodule