`timescale 1ns/1ps

module core_u
#(  parameter I_NODE_WIDTH_BITS = 8,
    parameter I_WEGT_WIDTH_BITS = 8,
    parameter O_RESULT_WIDTH_BITS = 16,
    parameter MAX_BITS = 40
)
(
    input clk,
    input reset_n,
    
    input i_valid,

    input signed [I_NODE_WIDTH_BITS-1 : 0]      i_node,
    input signed [I_WEGT_WIDTH_BITS-1 : 0]      i_wegt,

    output reg signed [O_RESULT_WIDTH_BITS-1 : 0]     o_result,
    output reg o_valid
);
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            o_valid <= 1'b0;
            o_result <= {O_RESULT_WIDTH_BITS{1'b0}};
        end
    
        else begin
            o_result <= i_node * i_wegt;
            o_valid <= i_valid;
        end
    end
    

endmodule