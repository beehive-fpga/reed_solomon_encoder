import rs_encode_pkg::*;
module rs_encode_line_in_datap #(
     parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_LINES=-1
    ,parameter NUM_LINES_W = $clog2(NUM_LINES)
    ,parameter LAST_LINE_BYTES=-1
)(
     input clk
    ,input rst

    ,input  logic   [DATA_W-1:0]    src_encoder_line
    
    ,output logic   [RS_WORD_W-1:0] in_datap_encoder_data
    
    ,input  logic                   in_ctrl_in_datap_init_state
    ,input  logic                   in_ctrl_in_datap_store_in_line
    ,input  logic                   in_ctrl_in_datap_incr_byte_offset
    ,output logic                   in_datap_in_ctrl_last_line_byte
    ,output logic                   in_datap_in_ctrl_last_line
);


    logic   [DATA_BYTES_W-1:0]    byte_offset_reg;
    logic   [DATA_BYTES_W-1:0]    byte_offset_next;

    logic   [NUM_LINES_W-1:0]   line_count_reg;
    logic   [NUM_LINES_W-1:0]   line_count_next;

    logic   [DATA_W-1:0]        line_reg;
    logic   [DATA_W-1:0]        line_next;

    logic   [DATA_BYTES-1:0][7:0]   mux_line;

    assign mux_line = line_reg;

    assign in_datap_encoder_data = mux_line[(DATA_BYTES - 1) - byte_offset_reg];

    always_ff @(posedge clk) begin
        if (rst) begin
            byte_offset_reg <= '0; 
            line_count_reg <= '0;
            line_reg <= '0;
        end
        else begin
            byte_offset_reg <= byte_offset_next;
            line_count_reg <= line_count_next;
            line_reg <= line_next;
        end
    end
    assign in_datap_in_ctrl_last_line = line_count_reg == (NUM_LINES-1);

    assign in_datap_in_ctrl_last_line_byte = in_datap_in_ctrl_last_line
                                            ? byte_offset_reg == (LAST_LINE_BYTES - 1)
                                            : byte_offset_reg == (DATA_BYTES - 1);

    assign byte_offset_next = in_ctrl_in_datap_init_state
                            ? '0
                            : in_ctrl_in_datap_incr_byte_offset
                                ? byte_offset_reg + 1'b1
                                : byte_offset_reg;

    assign line_count_next = in_ctrl_in_datap_init_state
                            ? '0
                            : (in_datap_in_ctrl_last_line_byte 
                                & in_ctrl_in_datap_incr_byte_offset)
                                ? line_count_reg + 1'b1
                                : line_count_reg;

    assign line_next = in_ctrl_in_datap_store_in_line
                    ? src_encoder_line
                    : line_reg;
endmodule
