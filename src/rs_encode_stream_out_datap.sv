import rs_encode_pkg::*;
module rs_encode_stream_out_datap #(
     parameter NUM_REQ_BLOCKS = -1
    ,parameter NUM_REQ_BLOCKS_W = -1
    ,parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_LINES = -1
    ,parameter NUM_LINES_W = $clog2(NUM_LINES)
)(
     input clk
    ,input rst

    ,input          [NUM_REQ_BLOCKS_W-1:0]  in_datap_out_datap_req_num_blocks

    ,input          [DATA_W-1:0]            line_encode_stream_encode_line
    ,input          [PARITY_W-1:0]          line_encode_stream_encode_parity
    
    ,output logic   [DATA_W-1:0]            stream_encoder_dst_resp_data

    ,output logic   [NUM_REQ_BLOCKS_W-1:0]  parity_mem_wr_addr
    ,output logic   [PARITY_W-1:0]          parity_mem_wr_data

    ,output logic   [NUM_REQ_BLOCKS_W-1:0]  parity_mem_rd_req_addr

    ,input  logic   [DATA_W-1:0]            parity_mem_rd_resp_data
    
    ,input  logic                           out_ctrl_out_datap_store_meta
    ,input  logic                           out_ctrl_out_datap_init_req_state

    ,input  logic                           out_ctrl_out_datap_incr_block_count
    ,input  logic                           out_ctrl_out_datap_init_line_count
    ,input  logic                           out_ctrl_out_datap_incr_line_count
    ,input  logic                           out_ctrl_out_datap_incr_parity_wr_addr
    ,input  logic                           out_ctrl_out_datap_incr_parity_rd_addr
    ,input  logic                           out_ctrl_out_datap_parity_out

    ,output logic                           out_datap_out_ctrl_last_block
    ,output logic                           out_datap_out_ctrl_last_data_line
    ,output logic                           out_datap_out_ctrl_last_all_pad_line
    ,output logic                           out_datap_out_ctrl_last_parity_line
);
    localparam NUM_DATA_LINES = RS_DATA_BYTES/DATA_BYTES;
    localparam NUM_DATA_LINES_W = $clog2(NUM_DATA_LINES);
    localparam PARITY_MEMS = DATA_BYTES/RS_T;
    localparam PARITY_SHIFT = $clog2(PARITY_MEMS);
    localparam PARITY_LINES = (RS_T % DATA_BYTES) == 0
                            ? RS_T/DATA_BYTES
                            : (RS_T/DATA_BYTES) + 1;
    localparam LAST_ALL_PAD_LINE = (NUM_LINES - PARITY_LINES) - 1;

    logic   [NUM_REQ_BLOCKS_W:0]    req_block_num_reg;
    logic   [NUM_REQ_BLOCKS_W:0]    req_block_num_next;

    logic   [NUM_REQ_BLOCKS_W:0]    block_cnt_reg;
    logic   [NUM_REQ_BLOCKS_W:0]    block_cnt_next;

    logic   [NUM_LINES_W-1:0]       line_cnt_reg;
    logic   [NUM_LINES_W-1:0]       line_cnt_next;

    logic   [NUM_REQ_BLOCKS_W-1:0]  wr_addr_reg;
    logic   [NUM_REQ_BLOCKS_W-1:0]  wr_addr_next;
    
    logic   [NUM_REQ_BLOCKS_W-1:0]  rd_req_addr_reg;
    logic   [NUM_REQ_BLOCKS_W-1:0]  rd_req_addr_next;

    logic   [NUM_REQ_BLOCKS_W-1:0]  num_parity_lines;

    assign num_parity_lines = req_block_num_reg >> PARITY_SHIFT;

    assign parity_mem_wr_data = line_encode_stream_encode_parity;
    assign parity_mem_wr_addr = wr_addr_reg;
    assign parity_mem_rd_req_addr = rd_req_addr_reg;

    assign out_datap_out_ctrl_last_block = block_cnt_reg == (req_block_num_reg - 1'b1);
    assign out_datap_out_ctrl_last_data_line = line_cnt_reg == (NUM_DATA_LINES-1);

    assign out_datap_out_ctrl_last_all_pad_line = line_cnt_reg == (LAST_ALL_PAD_LINE);

    // we don't subtract 1, because rd_req_addr_reg runs an address ahead of what
    // we're outputting
    assign out_datap_out_ctrl_last_parity_line = rd_req_addr_reg == (num_parity_lines);

    assign stream_encoder_dst_resp_data = out_ctrl_out_datap_parity_out
                                        ? parity_mem_rd_resp_data
                                        : line_encode_stream_encode_line;

    assign req_block_num_next = out_ctrl_out_datap_store_meta
                              ? in_datap_out_datap_req_num_blocks
                              : req_block_num_reg;

    assign block_cnt_next = out_ctrl_out_datap_init_req_state
                            ? '0
                            : out_ctrl_out_datap_incr_block_count
                                ? block_cnt_reg + 1'b1
                                : block_cnt_reg;

    assign line_cnt_next = out_ctrl_out_datap_init_line_count
                            ? '0
                            : out_ctrl_out_datap_incr_line_count
                                ? line_cnt_reg + 1'b1
                                : line_cnt_reg;

    assign wr_addr_next = out_ctrl_out_datap_init_req_state
                        ? '0
                        : out_ctrl_out_datap_incr_parity_wr_addr
                            ? wr_addr_reg + 1'b1
                            : wr_addr_reg;

    assign rd_req_addr_next = out_ctrl_out_datap_init_req_state
                            ? '0
                            : out_ctrl_out_datap_incr_parity_rd_addr
                                ? rd_req_addr_reg + 1'b1
                                : rd_req_addr_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            req_block_num_reg <= '0;
            block_cnt_reg <= '0;
            line_cnt_reg <= '0;
            wr_addr_reg <= '0;
            rd_req_addr_reg <= '0;
        end
        else begin
            req_block_num_reg <= req_block_num_next;
            block_cnt_reg <= block_cnt_next;
            line_cnt_reg <= line_cnt_next;
            wr_addr_reg <= wr_addr_next;
            rd_req_addr_reg <= rd_req_addr_next;
        end
    end

endmodule
