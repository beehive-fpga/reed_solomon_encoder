// Be super careful with the reload behavior around using multiple blocks
// Think about the timing of when you reset the data offset

module rs_encode_line_out_ctrl (
     input clk
    ,input rst

    ,output logic                       encoder_dst_line_val
    ,input  logic                       dst_encoder_line_rdy

    ,input  logic                       fifo_out_ctrl_data_val
    ,output logic                       out_ctrl_fifo_data_rdy
    
    ,output logic                       out_ctrl_out_datap_init_state
    ,output logic                       out_ctrl_out_datap_store_data
    ,output logic                       out_ctrl_out_datap_store_parity
    ,output logic                       out_ctrl_out_datap_incr_line_count
    ,input  logic                       out_datap_out_ctrl_last_line_byte
    ,input  logic                       out_datap_out_ctrl_last_line
    ,input  logic                       out_datap_out_ctrl_last_parity

    ,output logic                       out_ctrl_in_ctrl_done
    ,input  logic                       in_ctrl_out_ctrl_done
);

    typedef enum logic [2:0] {
        READY = 3'd0,
        SAVE_OUTPUT_BYTES = 3'd1,
        SAVE_PARITY_BYTES = 3'd2,
        LINE_OUT_WAIT = 3'd3,
        OUTPUT_WAIT = 3'd4,
        UND = 'X
    } out_state_e;

    out_state_e out_state_reg;
    out_state_e out_state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            out_state_reg <= READY;
        end
        else begin
            out_state_reg <= out_state_next;
        end
    end

    always_comb begin
        encoder_dst_line_val = 1'b0;

        out_ctrl_fifo_data_rdy = 1'b0;

        out_ctrl_out_datap_init_state = 1'b0;
        out_ctrl_out_datap_store_data = 1'b0;
        out_ctrl_out_datap_store_parity = 1'b0;
        out_ctrl_out_datap_incr_line_count = 1'b0;

        out_ctrl_in_ctrl_done = 1'b0;

        out_state_next = out_state_reg;
        case (out_state_reg)
            READY: begin
                out_ctrl_fifo_data_rdy = 1'b1;
                out_ctrl_out_datap_init_state = 1'b1;

                if (fifo_out_ctrl_data_val) begin
                    out_ctrl_out_datap_store_data = 1'b1;
                    out_state_next = SAVE_OUTPUT_BYTES;
                end
                else begin
                    out_state_next = READY;
                end
            end
            SAVE_OUTPUT_BYTES: begin
                out_ctrl_fifo_data_rdy = 1'b1;
                if (fifo_out_ctrl_data_val) begin
                    out_ctrl_out_datap_store_data = 1'b1;
                    if (out_datap_out_ctrl_last_line_byte) begin
                        if (out_datap_out_ctrl_last_line) begin
                            out_state_next = SAVE_PARITY_BYTES;
                        end
                        else begin
                            out_state_next = LINE_OUT_WAIT;
                        end
                    end
                    else begin
                        out_state_next = SAVE_OUTPUT_BYTES;
                    end
                end
                else begin
                    out_state_next = SAVE_OUTPUT_BYTES;
                end
            end
            SAVE_PARITY_BYTES: begin
                out_ctrl_fifo_data_rdy = 1'b1;
                if (fifo_out_ctrl_data_val) begin
                    out_ctrl_out_datap_store_parity = 1'b1;

                    if (out_datap_out_ctrl_last_parity) begin
                        out_state_next = LINE_OUT_WAIT;
                    end
                    else begin
                        out_state_next = SAVE_PARITY_BYTES;
                    end
                end
                else begin
                    out_state_next = SAVE_PARITY_BYTES;
                end
            end
            LINE_OUT_WAIT: begin
                encoder_dst_line_val = 1'b1;
                if (dst_encoder_line_rdy) begin
                    out_ctrl_out_datap_incr_line_count = 1'b1;
                    if (out_datap_out_ctrl_last_line) begin
                        out_state_next = OUTPUT_WAIT;
                    end
                    else begin
                        out_state_next = SAVE_OUTPUT_BYTES;
                    end
                end
                else begin
                    out_state_next = LINE_OUT_WAIT;
                end
            end
            OUTPUT_WAIT: begin
                out_ctrl_in_ctrl_done = 1'b1;
                out_ctrl_out_datap_init_state = 1'b1;
                if (in_ctrl_out_ctrl_done) begin
                    out_state_next = READY;
                end
                else begin
                    out_state_next = OUTPUT_WAIT;
                end
            end
            default: begin
                out_ctrl_fifo_data_rdy = 'X;

                out_ctrl_out_datap_init_state = 'X;
                out_ctrl_out_datap_store_data = 'X;
                out_ctrl_out_datap_store_parity = 'X;
                out_ctrl_out_datap_incr_line_count = 'X;

                out_ctrl_in_ctrl_done = 'X;

                out_state_next = UND;
            end
        endcase
    end

endmodule
