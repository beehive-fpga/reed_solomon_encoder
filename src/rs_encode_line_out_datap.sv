import rs_encode_pkg::*;
module rs_encode_line_out_datap #(
     parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_LINES=-1
    ,parameter NUM_LINES_W = $clog2(NUM_LINES)
    ,parameter LAST_LINE_BYTES=-1
)(
     input clk
    ,input rst

    ,input logic    [RS_WORD_W-1:0] fifo_out_datap_data

    ,output logic   [DATA_W-1:0]    encoder_dst_line
    ,output logic   [PARITY_W-1:0]  encoder_dst_parity

    ,input  logic                   out_ctrl_out_datap_init_state
    ,input  logic                   out_ctrl_out_datap_store_data
    ,input  logic                   out_ctrl_out_datap_store_parity
    ,input  logic                   out_ctrl_out_datap_incr_line_count
    ,output logic                   out_datap_out_ctrl_last_line_byte
    ,output logic                   out_datap_out_ctrl_last_line
    ,output logic                   out_datap_out_ctrl_last_parity
);

    localparam PARITY_BYTES = PARITY_W/8;
    localparam PARITY_BYTES_W = $clog2(PARITY_BYTES);

    logic   [NUM_LINES_W-1:0]       line_count_reg;
    logic   [NUM_LINES_W-1:0]       line_count_next;

    logic   [DATA_BYTES_W-1:0]      data_offset_reg;
    logic   [DATA_BYTES_W-1:0]      data_offset_next;

    logic   [PARITY_BYTES_W-1:0]    parity_offset_reg;
    logic   [PARITY_BYTES_W-1:0]    parity_offset_next;

    logic   [PARITY_BYTES-1:0][7:0] parity_reg;
    logic   [PARITY_BYTES-1:0][7:0] parity_next;

    logic   [DATA_BYTES-1:0][7:0]   data_reg;
    logic   [DATA_BYTES-1:0][7:0]   data_next;

    assign encoder_dst_line = data_reg;
    assign encoder_dst_parity = parity_reg;


    always_ff @(posedge clk) begin
        if (rst) begin
            data_reg <= '0;
            parity_reg <= '0;
        end
        else begin
            if (out_ctrl_out_datap_store_data) begin
                data_reg[DATA_BYTES-1 - data_offset_reg] <= fifo_out_datap_data;
            end

            if (out_ctrl_out_datap_store_parity) begin
                parity_reg[PARITY_BYTES-1 - parity_offset_reg] <= fifo_out_datap_data;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            data_offset_reg <= '0;
            parity_offset_reg <= '0;
            line_count_reg <= '0;
        end
        else begin
            data_offset_reg <= data_offset_next;
            parity_offset_reg <= parity_offset_next;
            line_count_reg <= line_count_next;
        end
    end

    assign out_datap_out_ctrl_last_line = line_count_reg == (NUM_LINES - 1);
    assign out_datap_out_ctrl_last_line_byte = out_datap_out_ctrl_last_line
                                            ? data_offset_reg == (LAST_LINE_BYTES - 1)
                                            : data_offset_reg == (DATA_BYTES - 1);
    assign out_datap_out_ctrl_last_parity = parity_offset_reg == (PARITY_BYTES - 1);

    always_comb begin
        data_offset_next = data_offset_reg;
        if (out_ctrl_out_datap_init_state) begin
            if (out_ctrl_out_datap_store_data) begin
                data_offset_next = {{(DATA_BYTES_W){1'b0}}, 1'b1};
            end
            else begin
                data_offset_next = '0;
            end
        end
        else if (out_ctrl_out_datap_store_data) begin
                data_offset_next = data_offset_reg + 1'b1;
        end
        else begin
            data_offset_next = data_offset_reg;
        end
    end

    assign parity_offset_next = out_ctrl_out_datap_init_state
                            ? '0
                            : out_ctrl_out_datap_store_parity
                                ? parity_offset_reg + 1'b1
                                : parity_offset_reg;

    assign line_count_next = out_ctrl_out_datap_init_state
                            ? '0
                            : out_ctrl_out_datap_incr_line_count
                                ? line_count_reg + 1'b1
                                : line_count_reg;

endmodule
