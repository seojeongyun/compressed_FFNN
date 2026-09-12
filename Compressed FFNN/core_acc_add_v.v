`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2025 05:41:33 PM
// Design Name: 
// Module Name: core_acc_add_v
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

//    input signed [WIDTH_RESULT_BITS  * NUM_CORES -1 : 0]             data_accum,

//    output signed [WIDTH_RESULT_BITS * NUM_CORES -1 : 0]             result

module core_acc_add_v
#(
    parameter   WIDTH_NODE_WEIGHT_BITS  = 20,
    parameter   WIDTH_RESULT_BITS       = 40
)
(
    input clk,
    input reset_n,
    input clear,
    
    input accum_valid,
    input delayed_w_valid,
    input two_cycle_delayed_w_valid,
    input signed [WIDTH_NODE_WEIGHT_BITS -1 : 0]        data_n,
    
    output signed [WIDTH_RESULT_BITS -1 : 0] result
);

    reg signed [WIDTH_RESULT_BITS -1 : 0] result_;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) result_ <= 0;
//        else if(accum_valid && (!accum_signal || two_cycle_delayed_w_valid))
//            result_ = result_ + data_n;
        else if (accum_valid &&(delayed_w_valid || two_cycle_delayed_w_valid)) result_ = result_ + data_n;
        else if(clear) result_ <= 0;
//        else result_ <= 0;
    end
    
    assign result = result_;
    
    
endmodule
