`include "tb_mem_ctl_mixed_network_define_LRA_0_lra_paper.vh"

//
//  SW ?? input feature ?? weights ???? ?????? ??, numpy ?? ?????????? ??.
//

`define TEST_DATA   15

`define NUM_LAYERS  3

//`define TRACE_IN_FEAT    		"/home/xilinx/MNIST_txtDATA/input_features_3000.txt"
`define TRACE_IN_FEAT    		"/home/xilinx/Downloads/final_result/in_feat_test.txt"
`define SAVE_RESULT_3           "/home/xilinx/Downloads/final_result/result_3.txt"

`define SAVE_RESULT_1           "/home/xilinx/Downloads/final_result/1f_result.txt"
`define SAVE_RESULT_2           "/home/xilinx/Downloads/final_result/2f_result.txt"

`define TRACE_IN_WEIGHT_U_1     "/home/xilinx/Downloads/final_result/0f_v_weight.txt"
`define TRACE_IN_WEIGHT_V_1     "/home/xilinx/Downloads/final_result/0f_u_weight.txt"

`define TRACE_IN_WEIGHT_V_2     "/home/xilinx/Downloads/final_result/1f_weight.txt"

`define TRACE_IN_WEIGHT_V_3     "/home/xilinx/Downloads/final_result/2f_weight.txt"


// `define TRACE_IN_FEAT    		"/home/xilinx/xilinx_study/Projects/Compressed_FFNN/test_ffnn_python/test_data/mixed/input_data_1.txt"
// `define SAVE_RESULT_1           "/home/xilinx/xilinx_study/Projects/Compressed_FFNN/sim/result_mixed/result_1_1.txt"
// `define SAVE_RESULT_2           "/home/xilinx/xilinx_study/Projects/Compressed_FFNN/sim/result_mixed/result_1_2.txt"
// `define SAVE_RESULT_3           "/home/xilinx/xilinx_study/Projects/Compressed_FFNN/sim/result_mixed/result_1_3.txt"

// `define TRACE_IN_WEIGHT_U_1     "/home/xilinx/xilinx_study/Projects/Compressed_FFNN/test_ffnn_python/test_data/mixed/weight_1_u.txt"
// `define TRACE_IN_WEIGHT_V_1     "/home/xilinx/xilinx_study/Projects/Compressed_FFNN/test_ffnn_python/test_data/mixed/weight_1_v.txt"

// `define TRACE_IN_WEIGHT_V_2     "/home/xilinx/xilinx_study/Projects/Compressed_FFNN/test_ffnn_python/test_data/mixed/weight_2_v.txt"

// `define TRACE_IN_WEIGHT_V_3     "/home/xilinx/xilinx_study/Projects/Compressed_FFNN/test_ffnn_python/test_data/mixed/weight_3_v.txt"


module  tb_mem_ctl_mixed_network_LRA_0();

//
integer idx_row;

//
integer images;
integer images_2;
integer idx_row, idx_col;
integer idx_temp_r;
integer fp_f, fcheck; 
integer fcheck_1, fcheck_2, fcheck_3; 
integer fp_w_1, fp_w_2, fp_w_3;
integer result;
integer temp;

reg     signed  [`LAYER_1_RESULT_V_BITS-1:0]    temp_1;
reg     signed  [`LAYER_2_RESULT_BITS-1:0]    temp_2;
reg     signed  [`LAYER_3_RESULT_BITS-1:0]    temp_3;


reg signed  [`LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS-1:0]    in_feat__     [`LAYER_1_MEM_INPUT_FEAT_DEPTH-1:0];
reg  [`LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS-1:0]   temp_in_feat;


reg     clk;
reg     reset_n;


// *-*-*-*  Variables for Features, Weights, and Results  *-*-*-*
//
//   These are for modeling memories storing input features and weights.
//
reg     [`LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS * `LAYER_1_MEM_INPUT_FEAT_DEPTH-1:0]    in_feat;

reg     [`LAYER_1_MEM_WEIGHT_U_WIDTH_BITS * `LAYER_1_MEM_WEIGHT_U_DEPTH-1:0]    wegt_u_1;
reg     [`LAYER_1_MEM_WEIGHT_V_WIDTH_BITS * `LAYER_1_MEM_WEIGHT_V_DEPTH-1:0]    wegt_v_1;

reg     [`LAYER_2_MEM_WEIGHT_V_WIDTH_BITS * `LAYER_2_MEM_WEIGHT_V_DEPTH-1:0]    wegt_v_2;

reg     [`LAYER_3_MEM_WEIGHT_V_WIDTH_BITS * `LAYER_3_MEM_WEIGHT_V_DEPTH-1:0]    wegt_v_3;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  Other Variables  *-*-*-*
wire    write_pos   [`NUM_LAYERS-1:0];
wire    read_pos    [`NUM_LAYERS-1:0];
reg     in_feat_valid;
//
wire    [`LAYER_1_NODE_BITS_U*`LAYER_1_NUM_CORES_U-1:0]   feat_vec_1;
wire    [`LAYER_2_NODE_BITS-1:0]   feat_vec_2;
wire    [`LAYER_3_NODE_BITS-1:0]   feat_vec_3;

wire    [`LAYER_1_MEM_WEIGHT_U_WIDTH_BITS-1:0]  wegt_vec_u_1;
wire    u_ce    [`NUM_LAYERS-1:0];
wire    u_we    [`NUM_LAYERS-1:0];
wire    [`LAYER_1_ADDR_F_BITS-1:0]  addr_f_1;
wire    [`LAYER_2_ADDR_F_BITS-1:0]  addr_f_2;
wire    [`LAYER_3_ADDR_F_BITS-1:0]  addr_f_3;
wire    [`LAYER_1_ADDR_U_BITS-1:0]  addr_u_1;

wire    [`LAYER_1_MEM_WEIGHT_V_WIDTH_BITS-1:0]  wegt_vec_v_1;
wire    [`LAYER_2_MEM_WEIGHT_V_WIDTH_BITS-1:0]  wegt_vec_v_2;
wire    [`LAYER_3_MEM_WEIGHT_V_WIDTH_BITS-1:0]  wegt_vec_v_3;
wire    v_ce    [`NUM_LAYERS-1:0];
wire    v_we    [`NUM_LAYERS-1:0];
wire    [`LAYER_1_WIDTH_ADDRESS_V-1:0]  addr_v_1;
wire    [`LAYER_2_WIDTH_ADDRESS_V-1:0]  addr_v_2;
wire    [`LAYER_3_WIDTH_ADDRESS_V-1:0]  addr_v_3;
wire    wait_v    [`NUM_LAYERS-1:0];

wire    [`LAYER_1_RESULT_V_BITS * `LAYER_1_OUT_FEAT-1:0]  w_result_1;
wire    [`LAYER_2_RESULT_BITS * `LAYER_2_OUT_FEAT-1:0]    w_result_2;
wire    [`LAYER_3_RESULT_BITS * `LAYER_3_OUT_FEAT-1:0]    w_result_3;
wire    w_valid [`NUM_LAYERS-1:0];

reg     [`LAYER_1_RESULT_V_BITS * `LAYER_1_OUT_FEAT-1:0]    ot_result_1;
reg     [`LAYER_2_RESULT_BITS * `LAYER_2_OUT_FEAT-1:0]    ot_result_2;
reg     [`LAYER_3_RESULT_BITS * `LAYER_3_OUT_FEAT-1:0]    ot_result_3;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*



// *-*-*-*  Clock  *-*-*-*
initial begin
    clk <=  0;
    forever begin
        #5  clk = ~clk;
    end
end
// *-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  Read Features, Weights, and Results  *-*-*-*
initial begin
    // Some time elapsed...
    #20

    // Layer 1
    read_wegt_layer_1(wegt_u_1, wegt_v_1);
    for(idx_row = 0; idx_row < `LAYER_1_MEM_WEIGHT_U_DEPTH; idx_row = idx_row + 1) begin
        mem_ctl_inst_1.weight_u_mem.ram[idx_row] = wegt_u_1[idx_row * `LAYER_1_MEM_WEIGHT_U_WIDTH_BITS +: `LAYER_1_MEM_WEIGHT_U_WIDTH_BITS];
    end
    for(idx_row = 0; idx_row < `LAYER_1_MEM_WEIGHT_V_DEPTH; idx_row = idx_row + 1) begin
        mem_ctl_inst_1.weight_v_mem.ram[idx_row] = wegt_v_1[idx_row * `LAYER_1_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_1_MEM_WEIGHT_V_WIDTH_BITS];
    end

    // Layer 2
    read_wegt_layer_2(wegt_v_2);
    for(idx_row = 0; idx_row < `LAYER_2_MEM_WEIGHT_V_DEPTH; idx_row = idx_row + 1) begin
        mem_ctl_linear_inst_2.weight_v_mem.ram[idx_row] = wegt_v_2[idx_row * `LAYER_2_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_2_MEM_WEIGHT_V_WIDTH_BITS];
    end

    // Layer 3
    read_wegt_layer_3(wegt_v_3);
    for(idx_row = 0; idx_row < `LAYER_3_MEM_WEIGHT_V_DEPTH; idx_row = idx_row + 1) begin
        mem_ctl_linear_inst_3.weight_v_mem.ram[idx_row] = wegt_v_3[idx_row * `LAYER_3_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_3_MEM_WEIGHT_V_WIDTH_BITS];
    end
end
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  MAIN OPERATION of TestBench  *-*-*-*
initial begin
    reset_n         =   1;
    in_feat_valid   =   0;
    
    
    //
    @(posedge clk);
    reset_n = ~reset_n;
    @(posedge clk);
    reset_n = ~reset_n;

    //
    #100
    fp_f 	=	$fopen(`TRACE_IN_FEAT, "r");
    fcheck	=	fp_f;

    if(fcheck == 0) begin
        $display("Failed to open file");
        $finish;
    end
    
    
    for(images = 0; images < `TEST_DATA; images = images + 1) begin
        #300
        $display("iteration : %d", images);
        
        
        //
        for(idx_row = 0; idx_row < `LAYER_1_MEM_INPUT_FEAT_DEPTH; idx_row = idx_row + 1) begin
            for (idx_col = 0; idx_col < `LAYER_1_NUM_CORES_U; idx_col = idx_col + 1) begin
                result = $fscanf(fp_f, "%d ", temp_in_feat[idx_col * `LAYER_1_NODE_BITS_U +: `LAYER_1_NODE_BITS_U]);
                result = $fscanf(fp_f, "\n", temp);
            end
            
            in_feat__[idx_row] = temp_in_feat;
        end
        
        result = $fscanf(fp_f, "\n", temp);
        
        for(idx_row = 0; idx_row < `LAYER_1_MEM_INPUT_FEAT_DEPTH; idx_row = idx_row + 1) begin
            in_feat[idx_row * `LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS +: `LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS] = in_feat__[idx_row];        
        end
        
        //
        #10
        @(posedge clk);
        in_feat_valid = ~in_feat_valid;
        @(posedge clk);
        in_feat_valid = ~in_feat_valid;
        
        $display("before wait");
        wait(w_valid[2]);
        wait(write_pos[2]);
        $display("aftee wait");   
    end
    
    $fclose(fp_f);
//    $finish;
    
end

initial begin
    fp_w_1 	=	$fopen(`SAVE_RESULT_1, "w");
    fp_w_2 	=	$fopen(`SAVE_RESULT_2, "w");
    fp_w_3 	=	$fopen(`SAVE_RESULT_3, "w");
        
        
    fcheck_1	=	fp_w_1;
    if(fcheck_1 == 0) begin
        $display("Failed to open file");
        $finish;
    end
        
    fcheck_2	=	fp_w_2;

    if(fcheck_2 == 0) begin
        $display("Failed to open file");
        $finish;
    end		
        
    fcheck_3	=	fp_w_3;

    if(fcheck_3 == 0) begin
        $display("Failed to open file");
        $finish;
    end
    
    
    
    for(images_2 = 0; images_2 < `TEST_DATA; images_2 = images_2 + 1) begin
    
        wait(w_valid[2]);
        wait(write_pos[2]);
        
        //
        for(idx_row = 0; idx_row < `LAYER_1_OUT_FEAT; idx_row = idx_row + 1) begin
            temp_1 = ot_result_1[(idx_row) * `LAYER_1_RESULT_V_BITS +: `LAYER_1_RESULT_V_BITS];
            $fwrite(fp_w_1, "%0d ", temp_1);
        end
        $fwrite(fp_w_1, "\n");
        
        
        //////////////////
    
        for(idx_row = 0; idx_row < `LAYER_2_OUT_FEAT; idx_row = idx_row + 1) begin
            temp_2 = ot_result_2[(idx_row) * `LAYER_2_RESULT_BITS +: `LAYER_2_RESULT_BITS];
            $fwrite(fp_w_2, "%0d ", temp_2);
        end
        $fwrite(fp_w_2, "\n");
		
		//////////////////
        
        for(idx_row = 0; idx_row < `LAYER_3_OUT_FEAT; idx_row = idx_row + 1) begin
            temp_3 = ot_result_3[(idx_row) * `LAYER_3_RESULT_BITS +: `LAYER_3_RESULT_BITS];
            $fwrite(fp_w_3, "%0d ", temp_3);
        end
        $fwrite(fp_w_3, "\n");
        
    end
    $fclose(fp_w_1);
    $fclose(fp_w_2);
    $fclose(fp_w_3);
    $finish;
end
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*   Store results   *-*-*-*
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        ot_result_1 <= {(`LAYER_1_RESULT_V_BITS * `LAYER_1_OUT_FEAT){1'b0}};
    end else if (w_valid[0]) begin
        ot_result_1 <= w_result_1;
    end
end


always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        ot_result_2 <= {(`LAYER_2_RESULT_BITS * `LAYER_2_OUT_FEAT){1'b0}};
    end else if (w_valid[1]) begin
        ot_result_2 <= w_result_2;
    end
end


always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        ot_result_3 <= {(`LAYER_3_RESULT_BITS * `LAYER_3_OUT_FEAT){1'b0}};
    end else if (w_valid[2]) begin
        ot_result_3 <= w_result_3;
    end
end
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  LAYER_1  *-*-*-*
mem_ctl #(
    .IN_FEAT_U              (`LAYER_1_IN_FEAT),
    .NUM_CORES_U            (`LAYER_1_NUM_CORES_U),
    .WIDTH_NODE_BITS_U      (`LAYER_1_NODE_BITS_U),
    //
    .OUT_FEATURES           (`LAYER_1_OUT_FEAT),
    .NUM_CORES_V            (`LAYER_1_NUM_CORES_V),
    //
    .WIDTH_ADDRESS_F_BITS   (`LAYER_1_ADDR_F_BITS),
    .WIDTH_ADDRESS_U_BITS   (`LAYER_1_ADDR_U_BITS),
    .WIDTH_ADDRESS_V_BITS   (`LAYER_1_WIDTH_ADDRESS_V),
    //
    .WEIGHT_BITS    (`WEIGHT_BITS),
    //
    .COMP_RANK      (`LAYER_1_COMP_RANK)
) mem_ctl_inst_1 (
    .clk            (clk),
    .reset_n        (reset_n),
    //
    .o_write_possible   (write_pos[0]),
    .o_read_possible    (read_pos[0]),
    //
    .i_feat_vec     (in_feat),
    .i_feat_valid   (in_feat_valid),
    //
    .o_feat_vec     (feat_vec_1),
    .o_wegt_vec_u   (wegt_vec_u_1),
    .i_u_ce         (u_ce[0]),
    .i_u_we         (u_we[0]),
    .i_addr_f       (addr_f_1),
    .i_addr_u       (addr_u_1),
    //
    .o_wegt_vec_v   (wegt_vec_v_1),
    .i_v_ce         (v_ce[0]),
    .i_v_we         (v_we[0]),
    .i_addr_v       (addr_v_1),
    .i_wait_v       (wait_v[0])
);

core_top_uv #(
    .IN_FEAT_U              (`LAYER_1_IN_FEAT),
    .NUM_CORES_U            (`LAYER_1_NUM_CORES_U),
    .WIDTH_NODE_BITS_U      (`LAYER_1_NODE_BITS_U),
    .WIDTH_NODE_WEIGHT_BITS_U   (`LAYER_1_NODE_WEIGHT_BITS_U),
    .WIDTH_ACCUM_BITS_U     (`LAYER_1_ACCUM_BITS_U),
    .WIDTH_RESULT_BITS_U    (`LAYER_1_RESULT_U_BITS),
    //
    .OUT_FEATURES           (`LAYER_1_OUT_FEAT),
    .NUM_CORES_V            (`LAYER_1_NUM_CORES_V),
    .WIDTH_NODE_WEIGHT_BITS_V   (`LAYER_1_NODE_WEIGHT_BITS_V),
    .WIDTH_RESULT_BITS_V    (`LAYER_1_RESULT_V_BITS),
    //
    .WIDTH_ADDRESS_F_BITS   (`LAYER_1_ADDR_F_BITS),
    .WIDTH_ADDRESS_U_BITS   (`LAYER_1_ADDR_U_BITS),
    .WIDTH_ADDRESS_RANK_BITS        (`LAYER_1_WIDTH_ADDRESS_S_V),
    .WIDTH_ADDRESS_V_BITS   (`LAYER_1_WIDTH_ADDRESS_V),
    .WIDTH_ADDRESS_V_OFFSET_BITS    (`LAYER_1_WIDTH_ADDRESS_V_OFFSET),
    //
    .WEIGHT_BITS    (`WEIGHT_BITS),
    .MAX_BITS       (`MAX_BITS),
    //
    .COMP_RANK      (`LAYER_1_COMP_RANK)
) core_top_uv_inst_1 (
    .clk            (clk),
    .reset_n        (reset_n),
    .i_run          (read_pos[0]),
    //
    .i_node_vec_u   (feat_vec_1),
    .i_wegt_vec_u   (wegt_vec_u_1),
    .o_u_ce         (u_ce[0]),
    .o_u_we         (u_we[0]),
    .o_addr_f       (addr_f_1),
    .o_addr_u       (addr_u_1),
    //
    .i_wegt_vec_v   (wegt_vec_v_1),
    .o_v_ce         (v_ce[0]),
    .o_v_we         (v_we[0]),
    .o_addr_v       (addr_v_1),
    .o_wait_v       (wait_v[0]),
    //
    .o_feat         (w_result_1),
    .o_feat_valid   (w_valid[0]),
    //
    .i_state_idle_mem_ctl   (1'b1)
);
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// // *-*-*-*  LAYER_2  *-*-*-*
mem_ctl_linear #(
    .IN_FEAT                (`LAYER_2_IN_FEAT),
    .WIDTH_NODE_BITS        (`LAYER_2_NODE_BITS),
    //
    .OUT_FEATURES           (`LAYER_2_OUT_FEAT),
    .NUM_CORES_V            (`LAYER_2_NUM_CORES),
    //
    .WIDTH_ADDRESS_F_BITS   (`LAYER_2_ADDR_F_BITS),
    .WIDTH_ADDRESS_V_BITS   (`LAYER_2_WIDTH_ADDRESS_V),
    //
    .WEIGHT_BITS    (`WEIGHT_BITS)
) mem_ctl_linear_inst_2 (
    .clk            (clk),
    .reset_n        (reset_n),
    //
    .o_write_possible   (write_pos[1]),
    .o_read_possible    (read_pos[1]),
    //
    .i_feat_vec     (w_result_1),
    .i_feat_valid   (w_valid[0]),
    //
    .o_feat_vec     (feat_vec_2),
    .i_f_ce         (u_ce[1]),
    .i_f_we         (u_we[1]),
    .i_addr_f       (addr_f_2),
    //
    .o_wegt_vec_v   (wegt_vec_v_2),
    .i_v_ce         (v_ce[1]),
    .i_v_we         (v_we[1]),
    .i_addr_v       (addr_v_2),
    //
    .i_wait_v       (wait_v[1])
);

core_linear #(
    .IN_FEAT                (`LAYER_2_IN_FEAT),
    .OUT_FEATURES           (`LAYER_2_OUT_FEAT),
    //
    .NUM_CORES              (`LAYER_2_NUM_CORES),
    .WIDTH_NODE_BITS        (`LAYER_2_NODE_BITS),
    .WIDTH_NODE_WEIGHT_BITS (`LAYER_2_NODE_WEIGHT_BITS),
    .WIDTH_RESULT_BITS      (`LAYER_2_RESULT_BITS),
    //
    .WIDTH_ADDRESS_F_BITS   (`LAYER_2_ADDR_F_BITS),
    .WIDTH_ADDRESS_V_BITS   (`LAYER_2_WIDTH_ADDRESS_V),
    .WIDTH_ADDRESS_V_OFFSET_BITS    (`LAYER_2_WIDTH_ADDRESS_V_OFFSET),
    //
    .WEIGHT_BITS    (`WEIGHT_BITS)
) core_linear_inst_2 (
    .clk            (clk),
    .reset_n        (reset_n),
    .i_run          (read_pos[1]),
    //
    .o_feat         (w_result_2),
    .o_feat_valid   (w_valid[1]),
    //
    .i_node_vec     (feat_vec_2),
    .o_ce           (u_ce[1]),
    .o_we           (u_we[1]),
    .o_addr_f       (addr_f_2),
    //
    .i_wegt_vec     (wegt_vec_v_2),
    .o_v_ce         (v_ce[1]),
    .o_v_we         (v_we[1]),
    .o_addr_v       (addr_v_2),
    //
    .o_wait_v       (wait_v[1]),
    //
    .i_state_idle_mem_ctl   (write_pos[2])
);
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// // *-*-*-*  LAYER_3  *-*-*-*
mem_ctl_linear #(
    .IN_FEAT                (`LAYER_3_IN_FEAT),
    .WIDTH_NODE_BITS        (`LAYER_3_NODE_BITS),
    //
    .OUT_FEATURES           (`LAYER_3_OUT_FEAT),
    .NUM_CORES_V            (`LAYER_3_NUM_CORES),
    //
    .WIDTH_ADDRESS_F_BITS   (`LAYER_3_ADDR_F_BITS),
    .WIDTH_ADDRESS_V_BITS   (`LAYER_3_WIDTH_ADDRESS_V),
    //
    .WEIGHT_BITS    (`WEIGHT_BITS)
) mem_ctl_linear_inst_3 (
    .clk            (clk),
    .reset_n        (reset_n),
    //
    .o_write_possible   (write_pos[2]),
    .o_read_possible    (read_pos[2]),
    //
    .i_feat_vec     (w_result_2),
    .i_feat_valid   (w_valid[1]),
    //
    .o_feat_vec     (feat_vec_3),
    .i_f_ce         (u_ce[2]),
    .i_f_we         (u_we[2]),
    .i_addr_f       (addr_f_3),
    //
    .o_wegt_vec_v   (wegt_vec_v_3),
    .i_v_ce         (v_ce[2]),
    .i_v_we         (v_we[2]),
    .i_addr_v       (addr_v_3),
    //
    .i_wait_v       (wait_v[2])
);

core_linear #(
    .IN_FEAT                (`LAYER_3_IN_FEAT),
    .OUT_FEATURES           (`LAYER_3_OUT_FEAT),
    //
    .NUM_CORES              (`LAYER_3_NUM_CORES),
    .WIDTH_NODE_BITS        (`LAYER_3_NODE_BITS),
    .WIDTH_NODE_WEIGHT_BITS (`LAYER_3_NODE_WEIGHT_BITS),
    .WIDTH_RESULT_BITS      (`LAYER_3_RESULT_BITS),
    //
    .WIDTH_ADDRESS_F_BITS   (`LAYER_3_ADDR_F_BITS),
    .WIDTH_ADDRESS_V_BITS   (`LAYER_3_WIDTH_ADDRESS_V),
    .WIDTH_ADDRESS_V_OFFSET_BITS    (`LAYER_3_WIDTH_ADDRESS_V_OFFSET),
    //
    .WEIGHT_BITS    (`WEIGHT_BITS),
    .USE_ACT_FN     (`LAYER_3_USE_ACT_FN)
) core_linear_inst_3 (
    .clk            (clk),
    .reset_n        (reset_n),
    .i_run          (read_pos[2]),
    //
    .o_feat         (w_result_3),
    .o_feat_valid   (w_valid[2]),
    //
    .i_node_vec     (feat_vec_3),
    .o_ce           (u_ce[2]),
    .o_we           (u_we[2]),
    .o_addr_f       (addr_f_3),
    //
    .i_wegt_vec     (wegt_vec_v_3),
    .o_v_ce         (v_ce[2]),
    .o_v_we         (v_we[2]),
    .o_addr_v       (addr_v_3),
    //
    .o_wait_v       (wait_v[2]),
    //
    .i_state_idle_mem_ctl   (1'b1)
);
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*



// Tasks loading a input feature, weights of U_approx and V_approx, and a result

task read_feat;

    output  [`LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS * `LAYER_1_MEM_INPUT_FEAT_DEPTH-1:0]    in_feat;
    reg signed  [`LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS-1:0]    in_feat__     [`LAYER_1_MEM_INPUT_FEAT_DEPTH-1:0];
	//
	integer idx_row, idx_col;
    integer idx_temp_r;
	integer temp;
    //
	integer fp_f, fcheck, result;
    reg  [`LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS-1:0]   temp_in_feat;


	begin
        // IN FEAT
		fp_f 	=	$fopen(`TRACE_IN_FEAT, "r");
		fcheck	=	fp_f;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_1_MEM_INPUT_FEAT_DEPTH; idx_row = idx_row + 1) begin
            for (idx_col = 0; idx_col < `LAYER_1_NUM_CORES_U; idx_col = idx_col + 1) begin
                result = $fscanf(fp_f, "%d ", temp_in_feat[idx_col * `LAYER_1_NODE_BITS_U +: `LAYER_1_NODE_BITS_U]);
                result = $fscanf(fp_f, "\n", temp);
            end
            in_feat__[idx_row] = temp_in_feat;
		end

		$fclose(fp_f);

        //
        for(idx_row = 0; idx_row < `LAYER_1_MEM_INPUT_FEAT_DEPTH; idx_row = idx_row + 1) begin
            in_feat[idx_row * `LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS +: `LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS] = in_feat__[idx_row];        
        end

	end

endtask


task read_wegt_layer_1;

    output  [`LAYER_1_MEM_WEIGHT_U_WIDTH_BITS * `LAYER_1_MEM_WEIGHT_U_DEPTH-1:0]    wegt_u_1;
    output  [`LAYER_1_MEM_WEIGHT_V_WIDTH_BITS * `LAYER_1_MEM_WEIGHT_V_DEPTH-1:0]    wegt_v_1;

    reg signed  [`LAYER_1_MEM_WEIGHT_U_WIDTH_BITS-1:0]      wegt_u      [`LAYER_1_MEM_WEIGHT_U_DEPTH-1:0];
    reg signed  [`LAYER_1_MEM_WEIGHT_V_WIDTH_BITS-1:0]      wegt_v      [`LAYER_1_MEM_WEIGHT_V_DEPTH-1:0];
	//
	integer idx_row, idx_col;
    integer idx_temp_r;
	integer temp;
    //
	integer fp_f, fcheck, result;
    reg  [`WEIGHT_BITS *`LAYER_1_IN_FEAT-1:0]   temp_weight_u;
    reg  [`WEIGHT_BITS *`LAYER_1_OUT_FEAT-1:0]  temp_weight_v;


	begin
        // WEIGHTS of U_approx
		fp_f 	=	$fopen(`TRACE_IN_WEIGHT_U_1, "r");
		fcheck	=	fp_f;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_1_COMP_RANK; idx_row = idx_row + 1) begin
            for (idx_col = 0; idx_col < `LAYER_1_IN_FEAT; idx_col = idx_col + 1) begin
                result = $fscanf(fp_f, "%d ", temp_weight_u[idx_col * `WEIGHT_BITS +: `WEIGHT_BITS]);
            end
            result = $fscanf(fp_f, "\n", temp);
            
            for (idx_temp_r = 0; idx_temp_r < (`LAYER_1_IN_FEAT / `LAYER_1_NUM_CORES_U); idx_temp_r = idx_temp_r + 1) begin
                wegt_u[idx_row * (`LAYER_1_IN_FEAT / `LAYER_1_NUM_CORES_U) + idx_temp_r] = temp_weight_u[idx_temp_r * `LAYER_1_MEM_WEIGHT_U_WIDTH_BITS +: `LAYER_1_MEM_WEIGHT_U_WIDTH_BITS];
            end
		end

		$fclose(fp_f);
        
        for(idx_row = 0; idx_row < `LAYER_1_MEM_WEIGHT_U_DEPTH; idx_row = idx_row + 1) begin
            wegt_u_1[idx_row * `LAYER_1_MEM_WEIGHT_U_WIDTH_BITS +: `LAYER_1_MEM_WEIGHT_U_WIDTH_BITS] = wegt_u[idx_row];
        end


        // WEIGHTS of V_approx
		fp_f 	=	$fopen(`TRACE_IN_WEIGHT_V_1, "r");
		fcheck	=	fp_f;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_1_COMP_RANK; idx_row = idx_row + 1) begin
            for (idx_col = 0; idx_col < `LAYER_1_OUT_FEAT; idx_col = idx_col + 1) begin
                result = $fscanf(fp_f, "%d ", temp_weight_v[idx_col * `WEIGHT_BITS +: `WEIGHT_BITS]);
            end
            result = $fscanf(fp_f, "\n", temp);
            
            for (idx_temp_r = 0; idx_temp_r < (`LAYER_1_OUT_FEAT / `LAYER_1_NUM_CORES_V); idx_temp_r = idx_temp_r + 1) begin
                wegt_v[idx_row * (`LAYER_1_OUT_FEAT / `LAYER_1_NUM_CORES_V) + idx_temp_r] = temp_weight_v[idx_temp_r * `LAYER_1_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_1_MEM_WEIGHT_V_WIDTH_BITS];
            end
		end

		$fclose(fp_f);

        for(idx_row = 0; idx_row < `LAYER_1_MEM_WEIGHT_V_DEPTH; idx_row = idx_row + 1) begin
            wegt_v_1[idx_row * `LAYER_1_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_1_MEM_WEIGHT_V_WIDTH_BITS] = wegt_v[idx_row];
        end

	end

endtask


task read_wegt_layer_2;

    output  [`LAYER_2_MEM_WEIGHT_V_WIDTH_BITS * `LAYER_2_MEM_WEIGHT_V_DEPTH-1:0]    wegt_v_2;

    reg signed  [`LAYER_2_MEM_WEIGHT_V_WIDTH_BITS-1:0]      wegt_v      [`LAYER_2_MEM_WEIGHT_V_DEPTH-1:0];
	//
	integer idx_row, idx_col;
    integer idx_temp_r;
	integer temp;
    //
	integer fp_f, fcheck, result;
    reg  [`WEIGHT_BITS *`LAYER_2_OUT_FEAT-1:0]  temp_weight_v;


	begin
        // WEIGHTS of V_approx
		fp_f 	=	$fopen(`TRACE_IN_WEIGHT_V_2, "r");
		fcheck	=	fp_f;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_2_IN_FEAT; idx_row = idx_row + 1) begin
            for (idx_col = 0; idx_col < `LAYER_2_OUT_FEAT; idx_col = idx_col + 1) begin
                result = $fscanf(fp_f, "%d ", temp_weight_v[idx_col * `WEIGHT_BITS +: `WEIGHT_BITS]);
            end
            result = $fscanf(fp_f, "\n", temp);
            
            for (idx_temp_r = 0; idx_temp_r < (`LAYER_2_OUT_FEAT / `LAYER_2_NUM_CORES); idx_temp_r = idx_temp_r + 1) begin
                wegt_v[idx_row * (`LAYER_2_OUT_FEAT / `LAYER_2_NUM_CORES) + idx_temp_r] = temp_weight_v[idx_temp_r * `LAYER_2_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_2_MEM_WEIGHT_V_WIDTH_BITS];
            end
		end

		$fclose(fp_f);

        for(idx_row = 0; idx_row < `LAYER_2_MEM_WEIGHT_V_DEPTH; idx_row = idx_row + 1) begin
            wegt_v_2[idx_row * `LAYER_2_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_2_MEM_WEIGHT_V_WIDTH_BITS] = wegt_v[idx_row];
        end

	end

endtask


task read_wegt_layer_3;

    output  [`LAYER_3_MEM_WEIGHT_V_WIDTH_BITS * `LAYER_3_MEM_WEIGHT_V_DEPTH-1:0]    wegt_v_3;

    reg signed  [`LAYER_3_MEM_WEIGHT_V_WIDTH_BITS-1:0]      wegt_v      [`LAYER_3_MEM_WEIGHT_V_DEPTH-1:0];
	//
	integer idx_row, idx_col;
    integer idx_temp_r;
	integer temp;
    //
	integer fp_f, fcheck, result;
    reg  [`WEIGHT_BITS *`LAYER_3_OUT_FEAT-1:0]  temp_weight_v;


	begin
        // WEIGHTS of V_approx
		fp_f 	=	$fopen(`TRACE_IN_WEIGHT_V_3, "r");
		fcheck	=	fp_f;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_3_IN_FEAT; idx_row = idx_row + 1) begin
            for (idx_col = 0; idx_col < `LAYER_3_OUT_FEAT; idx_col = idx_col + 1) begin
                result = $fscanf(fp_f, "%d ", temp_weight_v[idx_col * `WEIGHT_BITS +: `WEIGHT_BITS]);
            end
            result = $fscanf(fp_f, "\n", temp);
            
            for (idx_temp_r = 0; idx_temp_r < (`LAYER_3_OUT_FEAT / `LAYER_3_NUM_CORES); idx_temp_r = idx_temp_r + 1) begin
                wegt_v[idx_row * (`LAYER_3_OUT_FEAT / `LAYER_3_NUM_CORES) + idx_temp_r] = temp_weight_v[idx_temp_r * `LAYER_3_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_3_MEM_WEIGHT_V_WIDTH_BITS];
            end
		end

		$fclose(fp_f);

        for(idx_row = 0; idx_row < `LAYER_3_MEM_WEIGHT_V_DEPTH; idx_row = idx_row + 1) begin
            wegt_v_3[idx_row * `LAYER_3_MEM_WEIGHT_V_WIDTH_BITS +: `LAYER_3_MEM_WEIGHT_V_WIDTH_BITS] = wegt_v[idx_row];
        end

	end

endtask


task write_trace_1;
    input   [`LAYER_1_RESULT_V_BITS * `LAYER_1_OUT_FEAT-1:0]    ot_result_1;
    //
    reg     signed  [`LAYER_1_RESULT_V_BITS-1:0]    temp;
	//
	integer idx_row;
    //
	integer fp_w, fcheck, result;


	begin
        // RESULT_V
		fp_w 	=	$fopen(`SAVE_RESULT_1, "w");
		fcheck	=	fp_w;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_1_OUT_FEAT; idx_row = idx_row + 1) begin
            temp = ot_result_1[(idx_row) * `LAYER_1_RESULT_V_BITS +: `LAYER_1_RESULT_V_BITS];
            $fwrite(fp_w, "%d ", temp);
            $fwrite(fp_w, "\n");
		end

		$fclose(fp_w);
	end

endtask


task write_trace_2;
    input   [`LAYER_2_RESULT_BITS * `LAYER_2_OUT_FEAT-1:0]    ot_result_2;
    //
    reg     signed  [`LAYER_2_RESULT_BITS-1:0]    temp;
	//
	integer idx_row;
    //
	integer fp_w, fcheck, result;


	begin
        // RESULT_V
		fp_w 	=	$fopen(`SAVE_RESULT_2, "w");
		fcheck	=	fp_w;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_2_OUT_FEAT; idx_row = idx_row + 1) begin
            temp = ot_result_2[(idx_row) * `LAYER_2_RESULT_BITS +: `LAYER_2_RESULT_BITS];
            $fwrite(fp_w, "%d ", temp);
            $fwrite(fp_w, "\n");
		end

		$fclose(fp_w);
	end

endtask


task write_trace_3;
    input   [`LAYER_3_RESULT_BITS * `LAYER_3_OUT_FEAT-1:0]    ot_result_3;
    //
    reg     signed  [`LAYER_3_RESULT_BITS-1:0]    temp;
	//
	integer idx_row;
    //
	integer fp_w, fcheck, result;


	begin
        // RESULT_V
		fp_w 	=	$fopen(`SAVE_RESULT_3, "w");
		fcheck	=	fp_w;

		if(fcheck == 0) begin
			$display("Failed to open file");
            $finish;
        end

		for(idx_row = 0; idx_row < `LAYER_3_OUT_FEAT; idx_row = idx_row + 1) begin
            temp = ot_result_3[(idx_row) * `LAYER_3_RESULT_BITS +: `LAYER_3_RESULT_BITS];
            $fwrite(fp_w, "%d ", temp);
            $fwrite(fp_w, "\n");
		end

		$fclose(fp_w);
	end

endtask


endmodule