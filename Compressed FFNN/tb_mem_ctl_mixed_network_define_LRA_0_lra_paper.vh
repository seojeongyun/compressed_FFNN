`timescale 1ns / 1ps

`define WEIGHT_BITS                     8
`define MAX_BITS                        128

//
//  784_98_50_10
//

// LAYER 1
`define LAYER_1_IN_FEAT                 784
`define LAYER_1_COMP_RANK               30
`define LAYER_1_OUT_FEAT                50
`define LAYER_1_NUM_CORES_U             8
`define LAYER_1_NUM_CORES_V             10
`define LAYER_1_NUM_ACTUAL_IN_U         (`LAYER_1_IN_FEAT / `LAYER_1_NUM_CORES_U)
`define LAYER_1_ADDR_F_BITS             20   //  |_log2(IN_FEAT / NUM_CORES_U)_| + 1 (bits)
`define LAYER_1_ADDR_U_BITS             20   //  |_log2(IN_FEAT/ NUM_CORES_U * COMP_RANK)_| + 1 (bits)
`define LAYER_1_NODE_BITS_U             9
`define LAYER_1_NODE_WEIGHT_BITS_U      (`LAYER_1_NODE_BITS_U + `WEIGHT_BITS)
`define LAYER_1_ACCUM_BITS_U            64  // |_log2(NUM_CORES_U)_| + 1 + WIDTH_NODE_WEIGHT_BITS_U (bits)
`define LAYER_1_RESULT_U_BITS           64  // |_log2(IN_FEAT)_| + 1 + NODE_WEIGHT_BITS_U (bits)
`define LAYER_1_NODE_WEIGHT_BITS_V      (`LAYER_1_RESULT_U_BITS + `WEIGHT_BITS)
`define LAYER_1_RESULT_V_BITS           64  // |_log2(COMP_RANK)_| + 1 + NODE_WEIGHT_BITS_V (bits)
`define LAYER_1_WIDTH_ADDRESS_V         20  // |_log2(COMP_RANK * OUT_FEATURE / NUM_CORES_V)_| + 1  (bits)
`define LAYER_1_WIDTH_ADDRESS_S_V       20   // |_log2(COMP_RANK)_| + 1  (bits)
`define LAYER_1_WIDTH_ADDRESS_V_OFFSET  20     // |_log2(OUT_FEATURES / NUM_CORES_V)_| + 1 (bits)
`define LAYER_1_USE_ACT_FN              1


`define  LAYER_1_MEM_INPUT_FEAT_WIDTH_BITS  (`LAYER_1_NODE_BITS_U *`LAYER_1_NUM_CORES_U)
`define  LAYER_1_MEM_INPUT_FEAT_DEPTH       (`LAYER_1_IN_FEAT / `LAYER_1_NUM_CORES_U)
`define  LAYER_1_MEM_WEIGHT_U_WIDTH_BITS    (`WEIGHT_BITS *`LAYER_1_NUM_CORES_U)
`define  LAYER_1_MEM_WEIGHT_U_DEPTH         (`LAYER_1_IN_FEAT / `LAYER_1_NUM_CORES_U *`LAYER_1_COMP_RANK)
`define  LAYER_1_MEM_WEIGHT_V_WIDTH_BITS    (`WEIGHT_BITS *`LAYER_1_NUM_CORES_V)
`define  LAYER_1_MEM_WEIGHT_V_DEPTH         (`LAYER_1_OUT_FEAT / `LAYER_1_NUM_CORES_V * `LAYER_1_COMP_RANK)


// LAYER 2
`define LAYER_2_IN_FEAT                 50
`define LAYER_2_OUT_FEAT                100
`define LAYER_2_NUM_CORES               25
`define LAYER_2_ADDR_F_BITS             20   //  |_log2(IN_FEAT / NUM_CORES_U)_| + 1 (bits)
`define LAYER_2_NODE_BITS               `LAYER_1_RESULT_V_BITS
`define LAYER_2_NODE_WEIGHT_BITS        (`LAYER_2_NODE_BITS + `WEIGHT_BITS)
`define LAYER_2_RESULT_BITS             64  // |_log2(COMP_RANK)_| + 1 + NODE_WEIGHT_BITS_V (bits)
`define LAYER_2_WIDTH_ADDRESS_V         20  // |_log2(COMP_RANK * OUT_FEATURE / NUM_CORES_V)_| + 1  (bits)
`define LAYER_2_WIDTH_ADDRESS_S_V       20   // |_log2(COMP_RANK)_| + 1  (bits)
`define LAYER_2_WIDTH_ADDRESS_V_OFFSET  20     // |_log2(OUT_FEATURES / NUM_CORES_V)_| + 1 (bits)
`define LAYER_2_USE_ACT_FN              1


`define  LAYER_2_MEM_INPUT_FEAT_WIDTH_BITS  (`LAYER_2_NODE_BITS)
`define  LAYER_2_MEM_INPUT_FEAT_DEPTH       (`LAYER_2_IN_FEAT)
`define  LAYER_2_MEM_WEIGHT_V_WIDTH_BITS    (`WEIGHT_BITS *`LAYER_2_NUM_CORES)
`define  LAYER_2_MEM_WEIGHT_V_DEPTH         (`LAYER_2_OUT_FEAT / `LAYER_2_NUM_CORES * `LAYER_2_IN_FEAT)


// LAYER 3
`define LAYER_3_IN_FEAT                 100
`define LAYER_3_OUT_FEAT                10
`define LAYER_3_NUM_CORES               2
`define LAYER_3_ADDR_F_BITS             100   //  |_log2(IN_FEAT / NUM_CORES_U)_| + 1 (bits)
`define LAYER_3_NODE_BITS               `LAYER_2_RESULT_BITS
`define LAYER_3_NODE_WEIGHT_BITS        (`LAYER_3_NODE_BITS + `WEIGHT_BITS)
`define LAYER_3_RESULT_BITS             100  // |_log2(COMP_RANK)_| + 1 + NODE_WEIGHT_BITS_V (bits)
`define LAYER_3_WIDTH_ADDRESS_V         100  // |_log2(COMP_RANK * OUT_FEATURE / NUM_CORES_V)_| + 1  (bits)
`define LAYER_3_WIDTH_ADDRESS_S_V       100   // |_log2(COMP_RANK)_| + 1  (bits)
`define LAYER_3_WIDTH_ADDRESS_V_OFFSET  100     // |_log2(OUT_FEATURES / NUM_CORES_V)_| + 1 (bits)
`define LAYER_3_USE_ACT_FN              0


`define  LAYER_3_MEM_INPUT_FEAT_WIDTH_BITS  (`LAYER_3_NODE_BITS)
`define  LAYER_3_MEM_INPUT_FEAT_DEPTH       (`LAYER_3_IN_FEAT)
`define  LAYER_3_MEM_WEIGHT_V_WIDTH_BITS    (`WEIGHT_BITS *`LAYER_3_NUM_CORES)
`define  LAYER_3_MEM_WEIGHT_V_DEPTH         (`LAYER_3_OUT_FEAT / `LAYER_3_NUM_CORES * `LAYER_3_IN_FEAT)
