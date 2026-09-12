`timescale 1ns / 1ps

module mem_ctl 
#(
    // Parameters for block_u
    parameter   IN_FEAT_U                   = 2,
    parameter   NUM_CORES_U                 = 2,
    parameter   WIDTH_NODE_BITS_U           = 8,
    // Parameters for block_v
    parameter   OUT_FEATURES                = 4,
    parameter   NUM_CORES_V                 = 8,
    // WIDTH of ADDRESSES
    parameter   WIDTH_ADDRESS_F_BITS        = 2,
    parameter   WIDTH_ADDRESS_U_BITS        = 2,
    parameter   WIDTH_ADDRESS_V_BITS        = 2,
    //
    parameter   WEIGHT_BITS                 = 8,
    //
    parameter   COMP_RANK                   = 2
)
(
    input clk, 
    input reset_n,
    //
    // For storing an output feature vector
    input [WIDTH_NODE_BITS_U * IN_FEAT_U -1 : 0] i_feat_vec, 
    input i_feat_valid,
    input i_u_ce,
    input i_u_we,
    input [WIDTH_ADDRESS_F_BITS-1 : 0] i_addr_f, 
    input [WIDTH_ADDRESS_U_BITS-1 : 0] i_addr_u,
    input [WIDTH_ADDRESS_V_BITS-1 : 0] i_addr_v,
    //
    input i_v_ce, 
    input i_v_we, 
    input i_wait_v,
    // From/to core_control_u block
    output [NUM_CORES_U * WIDTH_NODE_BITS_U-1 : 0] o_feat_vec, 
    output [NUM_CORES_U * WEIGHT_BITS-1 : 0] o_wegt_vec_u, 
    // From/to core_acc_v block
    output [NUM_CORES_V * WEIGHT_BITS-1 : 0] o_wegt_vec_v,
    output o_write_possible,
    output o_read_possible
);

    localparam  MEM_INPUT_FEAT_WIDTH_BITS   = WIDTH_NODE_BITS_U * NUM_CORES_U;
    localparam  MEM_INPUT_FEAT_DEPTH        = IN_FEAT_U / NUM_CORES_U;
    localparam  MEM_WEIGHT_U_WIDTH_BITS     = WEIGHT_BITS * NUM_CORES_U;
    localparam  MEM_WEIGHT_U_DEPTH          = IN_FEAT_U / NUM_CORES_U * COMP_RANK;
    localparam  MEM_WEIGHT_V_WIDTH_BITS     = WEIGHT_BITS * NUM_CORES_V;
    localparam  MEM_WEIGHT_V_DEPTH          = OUT_FEATURES / NUM_CORES_V * COMP_RANK;
    
    // #=#=#=#=#=#=#=#= FSM #=#=#=#=#=#=#=#=
    localparam S_IDLE = 2'b00, S_WRITE = 2'b01, S_READ = 2'b10, S_DONE = 2'b11;

    reg [1:0] c_state;
    reg [1:0] n_state;
    
    wire is_write_done;                   
    wire is_read_done;
    
    assign is_write_done = addr_f_write == MEM_INPUT_FEAT_DEPTH -1;
    assign is_read_done = i_wait_v;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) c_state <= S_IDLE;
        else c_state <= n_state;
    end

    always @(*) begin
        case(c_state)
            S_IDLE : n_state = i_feat_valid ? S_WRITE : S_IDLE;
            S_WRITE : n_state = is_write_done ? S_READ : S_WRITE;
            S_READ : n_state = is_read_done ? S_DONE : S_READ;
            S_DONE : n_state = S_IDLE;
        endcase
    end

    // #=#=#=#=#=#=#=#= signal for data #=#=#=#=#=#=#=#=
    
    wire [MEM_INPUT_FEAT_WIDTH_BITS -1 : 0] in_feat_part;
    reg [WIDTH_ADDRESS_F_BITS -1 : 0] addr_f_write;
    reg [WIDTH_NODE_BITS_U * IN_FEAT_U -1 : 0] feat_vec;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) feat_vec <= {(WIDTH_NODE_BITS_U * IN_FEAT_U){1'b0}};
        else if(c_state == S_READ) feat_vec <= {(WIDTH_NODE_BITS_U * IN_FEAT_U){1'b0}};
        else if(i_feat_valid) feat_vec <= i_feat_vec;
    end

    assign in_feat_part = c_state == S_WRITE ? feat_vec[addr_f_write * MEM_INPUT_FEAT_WIDTH_BITS +: MEM_INPUT_FEAT_WIDTH_BITS] : 0;
    
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) addr_f_write <= {(WIDTH_ADDRESS_F_BITS){1'b0}};
        else if(is_write_done) addr_f_write <= {(WIDTH_ADDRESS_F_BITS){1'b0}};
        else if(c_state == S_WRITE) addr_f_write <= addr_f_write + 1;
    end

    // #=#=#=#=#=#=#=#= signal for bram #=#=#=#=#=#=#=#=
    wire ce_infeat;
    wire we_infeat;
    wire [WIDTH_ADDRESS_F_BITS -1 : 0] addr_infeat;

    assign ce_infeat = c_state == S_WRITE ? 1'b1 : 
                          c_state == S_READ ? i_u_ce : 1'b0;

    assign we_infeat = c_state == S_WRITE ? 1'b1 :
                        c_state == S_READ ? i_u_we : 1'b0;

    assign addr_infeat = c_state == S_WRITE ? addr_f_write :
                          c_state == S_READ ? i_addr_f : 1'b0;
                          
                          
    // #=#=#=#=#=#=#=#= instantiation of brams #=#=#=#=#=#=#=#=
    dpbram  #(
    .DWIDTH     (MEM_INPUT_FEAT_WIDTH_BITS),
    .AWIDTH     (WIDTH_ADDRESS_F_BITS),
    .MEM_SIZE   (MEM_INPUT_FEAT_DEPTH)
    ) in_feat_mem
    (
        .clk(clk), 
	//
	    .addr0(addr_infeat), 
	    .ce0(ce_infeat), 
	    .we0(we_infeat), 
	    .d0(in_feat_part), 
	//
        .q0(o_feat_vec)
    );

    dpbram  #(
    .DWIDTH     (MEM_WEIGHT_U_WIDTH_BITS),
    .AWIDTH     (WIDTH_ADDRESS_U_BITS),
    .MEM_SIZE   (MEM_WEIGHT_U_DEPTH)
    ) weight_u_mem
    (
        .clk(clk), 
	//
	    .addr0(i_addr_u), 
	    .ce0(i_u_ce), 
	    .we0(i_u_we), 
	//
        .q0(o_wegt_vec_u)
    );

    dpbram  #(
    .DWIDTH     (MEM_WEIGHT_V_WIDTH_BITS),
    .AWIDTH     (WIDTH_ADDRESS_V_BITS),
    .MEM_SIZE   (MEM_WEIGHT_V_DEPTH)
    ) weight_v_mem
    (
        .clk(clk), 
	//
	    .addr0(i_addr_v), 
	    .ce0(i_v_ce), 
	    .we0(i_v_we), 
	//
        .q0(o_wegt_vec_v)
    );

    assign o_write_possible = c_state == S_IDLE;
    assign o_read_possible = c_state == S_READ;
endmodule