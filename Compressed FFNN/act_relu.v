`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2025 05:39:37 PM
// Design Name: 
// Module Name: act_relu
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


module act_relu
#(
    parameter       WIDTH_DATA = 32
)
(
    input signed [WIDTH_DATA-1 : 0] x,

    output          [WIDTH_DATA-1 : 0] y
);  
    assign y = x > 0 ? x : 0;

endmodule
