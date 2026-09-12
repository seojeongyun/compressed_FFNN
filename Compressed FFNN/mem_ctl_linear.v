`timescale 1ns / 1ps

module mem_ctl_linear
#(
    // Parameters for block_u
    parameter   IN_FEAT                   = 2,
    parameter   WIDTH_NODE_BITS           = 8,    // Actually, WIDTH_NODE_BITS
    // Parameters for block_v
    parameter   OUT_FEATURES                = 4,
    parameter   NUM_CORES_V                 = 8,
    // WIDTH of ADDRESSES
    parameter   WIDTH_ADDRESS_F_BITS        = 2,
    parameter   WIDTH_ADDRESS_V_BITS        = 2,
    //
    parameter   WEIGHT_BITS                 = 8
)
(
    clk, reset_n,
    //
    o_write_possible, o_read_possible,
    // For storing an output feature vector
    i_feat_vec, i_feat_valid,
    // From/to core_control_u block
    o_feat_vec, i_f_ce, i_f_we, i_addr_f,
    // From/to core_acc_v block
    o_wegt_vec_v, i_v_ce, i_v_we, i_addr_v, 
    i_wait_v
);

// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//            Define ports, wires and regs
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o

// *-*-*-*    Local Parameters   *-*-*-*
localparam  MEM_INPUT_FEAT_WIDTH_BITS   = WIDTH_NODE_BITS;
localparam  MEM_INPUT_FEAT_DEPTH        = IN_FEAT;
localparam  MEM_WEIGHT_V_WIDTH_BITS     = WEIGHT_BITS * NUM_CORES_V;
localparam  MEM_WEIGHT_V_DEPTH          = OUT_FEATURES / NUM_CORES_V * IN_FEAT;

//  For FSM
localparam  S_IDLE  =   2'b00;
localparam  S_WRITE =   2'b01;
localparam  S_READ  =   2'b10;
localparam  S_DONE  =   2'b11;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*         Ports         *-*-*-*
input   clk;
input   reset_n;

// For status of this mem_ctl module
output  o_write_possible;
output  o_read_possible;

// For storing an output feature vector
input   [WIDTH_NODE_BITS * IN_FEAT-1:0] i_feat_vec;
input                                   i_feat_valid;
// From/to core_control_u
output  [NUM_CORES_V * WIDTH_NODE_BITS-1:0] o_feat_vec;
input                                       i_f_ce;
input                                       i_f_we;
input   [WIDTH_ADDRESS_F_BITS-1:0]          i_addr_f;
// From/to core_acc_v
output  [NUM_CORES_V * WEIGHT_BITS-1:0] o_wegt_vec_v;
input                                   i_v_ce;
input                                   i_v_we;
input   [WIDTH_ADDRESS_V_BITS-1:0]      i_addr_v;

input                                   i_wait_v;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  For Main FSM  *-*-*-*
reg [1:0]   c_state;
reg [1:0]   n_state;

wire    is_write_done;
wire    is_read_done;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// *-*-*-*  Other Variables  *-*-*-*
reg [WIDTH_NODE_BITS * IN_FEAT-1:0] feat_vec;
reg feat_valid;
reg [WIDTH_ADDRESS_F_BITS-1:0]          addr_f_write;

reg [WIDTH_ADDRESS_F_BITS-1:0]          addr_infeat;
reg [WIDTH_NODE_BITS-1:0] in_feat_part;
reg ce_infeat;
reg we_infeat;
// *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//                MUX for in_feat memory
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
always @(*) begin
	ce_infeat = 1'b0;
	case (c_state)
		S_WRITE: begin
            ce_infeat = 1'b1;
		end
		S_READ: begin
            ce_infeat = i_f_ce;
		end
	endcase
end

always @(*) begin
	we_infeat = 1'b0;
	case (c_state)
		S_WRITE: begin
            we_infeat = 1'b1;
		end
		S_READ: begin
            we_infeat = i_f_we;
		end
	endcase
end

always @(*) begin
	addr_infeat = {(WIDTH_ADDRESS_F_BITS){1'b0}};
	case (c_state)
		S_WRITE: begin
            addr_infeat = addr_f_write;
		end
		S_READ: begin
            addr_infeat = i_addr_f;
		end
	endcase
end

always @(*) begin
	in_feat_part = {(MEM_INPUT_FEAT_WIDTH_BITS){1'b0}};
	case (c_state)
		S_WRITE: begin
            in_feat_part = feat_vec[addr_f_write * (MEM_INPUT_FEAT_WIDTH_BITS) +: (MEM_INPUT_FEAT_WIDTH_BITS)];
		end
	endcase
end


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        feat_vec <= {(WIDTH_NODE_BITS * IN_FEAT){1'b0}};
    end else if (c_state == S_READ) begin
        feat_vec <= {(WIDTH_NODE_BITS * IN_FEAT){1'b0}};
    end else if (i_feat_valid) begin
        feat_vec <= i_feat_vec;
    end
end


always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        feat_valid <= 1'b0;
    end else if (c_state == S_READ) begin
        feat_valid <= 1'b0;
    end else if (i_feat_valid) begin
        feat_valid <= i_feat_valid;
    end
end


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//            Write a input feature vector
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        addr_f_write <= {(WIDTH_ADDRESS_F_BITS){1'b0}};
    end else if (is_write_done) begin
        addr_f_write <= {(WIDTH_ADDRESS_F_BITS){1'b0}};
    end else if ((c_state == S_WRITE)) begin
        addr_f_write <= addr_f_write + 1'b1;
    end
end


// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//                       FSM
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		c_state <= S_IDLE;
	end else begin
		c_state <= n_state;
	end
end

always @(*) begin
	n_state = c_state;
	case (c_state)
		S_IDLE: begin
			if (i_feat_valid) begin
				n_state = S_WRITE;
			end
		end
		S_WRITE: begin
			if (is_write_done) begin
				n_state = S_READ;
			end
		end
        S_READ: begin
			if (is_read_done) begin
				n_state = S_DONE;
			end
        end
		S_DONE: n_state = S_IDLE;
	endcase
end

assign  is_write_done = (addr_f_write == (MEM_INPUT_FEAT_DEPTH - 1));
assign  is_read_done  = i_wait_v;

assign  o_write_possible = (c_state == S_IDLE);
assign  o_read_possible  = (c_state == S_READ);



// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//             Instantiation of memories
// o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o==o
//
//      Memory for a input feature vector
//
dpbram #(
    .DWIDTH     (MEM_INPUT_FEAT_WIDTH_BITS),
    .AWIDTH     (WIDTH_ADDRESS_F_BITS),
    .MEM_SIZE   (MEM_INPUT_FEAT_DEPTH)
) in_feat_mem (
    .clk        (clk),
    .addr0      (addr_infeat),
    .ce0        (ce_infeat),
    .we0        (we_infeat),
    .q0         (o_feat_vec),
    .d0         (in_feat_part)
);
//
//      Memory for a V_approx matrix
//
dpbram #(
    .DWIDTH     (MEM_WEIGHT_V_WIDTH_BITS),
    .AWIDTH     (WIDTH_ADDRESS_V_BITS),
    .MEM_SIZE   (MEM_WEIGHT_V_DEPTH)
) weight_v_mem (
    .clk        (clk),
    .addr0      (i_addr_v),
    .ce0        (i_v_ce),
    .we0        (i_v_we),
    .q0         (o_wegt_vec_v)
);


endmodule