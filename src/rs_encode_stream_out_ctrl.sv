module rs_encode_stream_out_ctrl (
     input clk
    ,input rst
    
    ,input          in_ctrl_out_ctrl_val
    ,output logic   out_ctrl_in_ctrl_rdy

    ,input          line_encode_stream_encode_val
    ,output logic   stream_encode_line_encode_rdy

    ,output logic   stream_encoder_dst_resp_data_val
    ,output logic   stream_encoder_dst_resp_last
    ,input  logic   dst_stream_encoder_resp_data_rdy

    ,output logic   parity_mem_wr_val

    ,output logic   parity_mem_rd_req_val

    ,input  logic   parity_mem_rd_resp_val
    ,output logic   parity_mem_rd_resp_rdy

    ,output logic   out_ctrl_out_datap_store_meta
    ,output logic   out_ctrl_out_datap_init_req_state

    ,output logic   out_ctrl_out_datap_incr_block_count
    ,output logic   out_ctrl_out_datap_init_line_count
    ,output logic   out_ctrl_out_datap_incr_line_count
    ,output logic   out_ctrl_out_datap_incr_parity_wr_addr
    ,output logic   out_ctrl_out_datap_incr_parity_rd_addr
    ,output logic   out_ctrl_out_datap_parity_out

    ,input  logic   out_datap_out_ctrl_last_block
    ,input  logic   out_datap_out_ctrl_last_data_line
    ,input  logic   out_datap_out_ctrl_last_all_pad_line
    ,input  logic   out_datap_out_ctrl_last_parity_line
);

    typedef enum logic [2:0] {
        READY = 3'd0,
        CATCH_DATA_LINES = 3'd1,
        STORE_PARITY = 3'd2,
        OUTPUT_PARITY = 3'd3,
        DRAIN_PADDING = 3'd4,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        stream_encoder_dst_resp_data_val = 1'b0;
        stream_encoder_dst_resp_last = 1'b0;
        stream_encode_line_encode_rdy = 1'b0;

        out_ctrl_in_ctrl_rdy = 1'b0;

        out_ctrl_out_datap_init_line_count = 1'b0;
        out_ctrl_out_datap_init_req_state = 1'b0;
        out_ctrl_out_datap_incr_line_count = 1'b0;
        out_ctrl_out_datap_incr_block_count = 1'b0;
        out_ctrl_out_datap_incr_parity_wr_addr = 1'b0;
        out_ctrl_out_datap_incr_parity_rd_addr = 1'b0;
        out_ctrl_out_datap_store_meta = 1'b0;
        out_ctrl_out_datap_parity_out = 1'b0;

        parity_mem_wr_val = 1'b0;
        parity_mem_rd_req_val = 1'b0;
        parity_mem_rd_resp_rdy = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                out_ctrl_in_ctrl_rdy = 1'b1;
                out_ctrl_out_datap_init_req_state = 1'b1;
                out_ctrl_out_datap_init_line_count = 1'b1;
                if (in_ctrl_out_ctrl_val) begin
                    out_ctrl_out_datap_store_meta = 1'b1;
                    state_next = CATCH_DATA_LINES;
                end
                else begin
                    state_next = READY;
                end
            end
            CATCH_DATA_LINES: begin
                stream_encoder_dst_resp_data_val = line_encode_stream_encode_val;
                stream_encode_line_encode_rdy = dst_stream_encoder_resp_data_rdy;
                if (line_encode_stream_encode_val & dst_stream_encoder_resp_data_rdy) begin
                    out_ctrl_out_datap_incr_line_count = 1'b1;
                    if (out_datap_out_ctrl_last_data_line) begin
                        if (out_datap_out_ctrl_last_all_pad_line) begin
                            state_next = STORE_PARITY;
                        end
                        else begin
                            state_next = DRAIN_PADDING;
                        end
                    end
                end
            end
            DRAIN_PADDING: begin
                stream_encode_line_encode_rdy = 1'b1;
                if (line_encode_stream_encode_val) begin
                    out_ctrl_out_datap_init_line_count = 1'b1;
                    if (out_datap_out_ctrl_last_all_pad_line) begin
                        state_next = STORE_PARITY;
                    end
                end
            end
            STORE_PARITY: begin
                stream_encode_line_encode_rdy = 1'b1;
                out_ctrl_out_datap_init_line_count = 1'b1;

                if (line_encode_stream_encode_val) begin
                    parity_mem_wr_val = 1'b1;
                    out_ctrl_out_datap_incr_parity_wr_addr = 1'b1;
                    out_ctrl_out_datap_incr_block_count = 1'b1;
                    if (out_datap_out_ctrl_last_block) begin
                        parity_mem_rd_req_val = 1'b1;
                        out_ctrl_out_datap_incr_parity_rd_addr = 1'b1;
                        state_next = OUTPUT_PARITY;
                    end
                    else begin
                        state_next = CATCH_DATA_LINES;
                    end
                end
                else begin
                    state_next = STORE_PARITY;
                end
            end
            OUTPUT_PARITY: begin
                stream_encoder_dst_resp_data_val = parity_mem_rd_resp_val;
                parity_mem_rd_resp_rdy = dst_stream_encoder_resp_data_rdy;
                out_ctrl_out_datap_parity_out = 1'b1;

                if (parity_mem_rd_resp_val & dst_stream_encoder_resp_data_rdy) begin
                    out_ctrl_out_datap_incr_parity_rd_addr = 1'b1;
                    if (out_datap_out_ctrl_last_parity_line) begin
                        stream_encoder_dst_resp_last = 1'b1;
                        state_next = READY;
                    end
                    else begin
                        parity_mem_rd_req_val = 1'b1;
                        state_next = OUTPUT_PARITY;
                    end
                end
                else begin
                    state_next = OUTPUT_PARITY;
                end
            end
            default: begin
                stream_encoder_dst_resp_data_val = 'X;
                stream_encoder_dst_resp_last = 'X;
                stream_encode_line_encode_rdy = 'X;

                out_ctrl_in_ctrl_rdy = 'X;
                
                out_ctrl_out_datap_store_meta = 'X;
                out_ctrl_out_datap_init_req_state = 'X;

                out_ctrl_out_datap_init_line_count = 'X;
                out_ctrl_out_datap_incr_line_count = 'X;
                out_ctrl_out_datap_incr_block_count = 'X;
                out_ctrl_out_datap_incr_parity_wr_addr = 'X;
                out_ctrl_out_datap_incr_parity_rd_addr = 'X;

                parity_mem_wr_val = 'X;
                parity_mem_rd_req_val = 'X;
                parity_mem_rd_resp_rdy = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
