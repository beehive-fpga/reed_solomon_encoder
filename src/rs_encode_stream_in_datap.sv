module rs_encode_stream_in_datap #(
     parameter NUM_REQ_BLOCKS = -1
    ,parameter NUM_REQ_BLOCKS_W = $clog2(NUM_REQ_BLOCKS)
    ,parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_LINES = -1
    ,parameter NUM_LINES_W = $clog2(NUM_LINES)
)(
     input clk
    ,input rst

    ,input          [NUM_REQ_BLOCKS_W:0]    src_stream_encoder_req_num_blocks

    ,input  logic   [DATA_W-1:0]            src_stream_encoder_req_data
    
    ,input  logic                           in_ctrl_in_datap_store_req_meta
    ,input  logic                           in_ctrl_in_datap_init_line_count
    ,input  logic                           in_ctrl_in_datap_incr_line_count
    ,input  logic                           in_ctrl_in_datap_init_block_count
    ,input  logic                           in_ctrl_in_datap_incr_block_count

    ,output logic                           in_datap_in_ctrl_last_data_line
    ,output logic                           in_datap_in_ctrl_last_block

    ,output logic   [DATA_W-1:0]            stream_encode_line_encode_line

    ,output logic   [NUM_REQ_BLOCKS_W:0]    in_datap_out_datap_req_num_blocks
);

    localparam NUM_DATA_LINES = RS_DATA_BYTES/DATA_BYTES;

    logic   [NUM_REQ_BLOCKS_W:0]    req_blocks_reg;
    logic   [NUM_REQ_BLOCKS_W:0]    req_blocks_next;

    logic   [NUM_REQ_BLOCKS_W:0]    block_cnt_reg;
    logic   [NUM_REQ_BLOCKS_W:0]    block_cnt_next;

    logic   [NUM_LINES_W-1:0]       num_lines_reg;
    logic   [NUM_LINES_W-1:0]       num_lines_next;

    logic                           pad_sel;

    assign in_datap_out_datap_req_num_blocks = req_blocks_reg;

    assign in_datap_in_ctrl_last_data_line = num_lines_reg == (NUM_DATA_LINES - 1);
    assign in_datap_in_ctrl_last_block = block_cnt_reg == (req_blocks_reg - 1);

    assign pad_sel = num_lines_reg == (NUM_LINES - 1);

    assign stream_encode_line_encode_line = pad_sel
                                            ? '0
                                            : src_stream_encoder_req_data;



    always_ff @(posedge clk) begin
        if (rst) begin
            req_blocks_reg <= '0;
            block_cnt_reg <= '0;
            num_lines_reg <= '0;
        end
        else begin
            req_blocks_reg <= req_blocks_next;
            block_cnt_reg <= block_cnt_next;
            num_lines_reg <= num_lines_next;
        end
    end

    assign req_blocks_next = in_ctrl_in_datap_store_req_meta
                            ? src_stream_encoder_req_num_blocks
                            : req_blocks_reg;

    assign block_cnt_next = in_ctrl_in_datap_init_block_count
                            ? '0
                            : in_ctrl_in_datap_incr_block_count
                                ? block_cnt_reg + 1'b1
                                : block_cnt_reg;

    assign num_lines_next = in_ctrl_in_datap_init_line_count
                            ? '0
                            : in_ctrl_in_datap_incr_line_count
                                ? num_lines_reg + 1'b1
                                : num_lines_reg;


endmodule
