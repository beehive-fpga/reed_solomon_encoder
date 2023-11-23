module rs_encode_stream_in_ctrl #(
     parameter NUM_RS_UNITS = -1
    ,parameter NUM_RS_UNITS_W = $clog2(NUM_RS_UNITS)
)(
     input clk
    ,input rst

    ,input                                  src_stream_encoder_req_val
    ,output logic                           stream_encoder_src_req_rdy

    ,input                                  src_stream_encoder_req_data_val
    ,output logic                           stream_encoder_src_req_data_rdy
    
    ,output logic                           in_ctrl_in_datap_store_req_meta
    ,output logic                           in_ctrl_in_datap_init_line_count
    ,output logic                           in_ctrl_in_datap_incr_line_count
    ,output logic                           in_ctrl_in_datap_init_block_count
    ,output logic                           in_ctrl_in_datap_incr_block_count

    ,output logic   [NUM_RS_UNITS_W-1:0]    in_ctrl_rs_unit_sel

    ,input  logic                           in_datap_in_ctrl_last_data_line
    ,input  logic                           in_datap_in_ctrl_last_pad_line
    ,input  logic                           in_datap_in_ctrl_last_block

    ,input  logic                           line_encode_stream_encode_rdy
    ,output logic                           stream_encode_line_encode_val

    ,output logic                           in_ctrl_out_ctrl_val
    ,input  logic                           out_ctrl_in_ctrl_rdy
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        ENCODE_BLOCK = 2'd1,
        PAD_BLOCK = 2'd2,
        META_PASS_WAIT = 2'd3,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        PASS_METADATA = 2'd1,
        DATA_PASS_WAIT = 2'd2,
        UNDEF = 'X
    } meta_state_e;

    state_e state_reg;
    state_e state_next;
    
    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    logic   reset_unit_sel;
    logic   incr_unit_sel;
    logic   [NUM_RS_UNITS-1:0]  unit_sel_reg;
    logic   [NUM_RS_UNITS-1:0]  unit_sel_next;

    logic                       output_metadata;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            meta_state_reg <= WAITING;
            unit_sel_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            meta_state_reg <= meta_state_next;
            unit_sel_reg <= unit_sel_next;
        end
    end

    assign unit_sel_next = reset_unit_sel
                        ? '0
                        : incr_unit_sel
                            ? unit_sel_reg + 1'b1
                            : unit_sel_reg;

    assign in_ctrl_rs_unit_sel = unit_sel_reg;

    always_comb begin
        in_ctrl_in_datap_incr_line_count = 1'b0;
        in_ctrl_in_datap_init_line_count = 1'b0;
        in_ctrl_in_datap_init_block_count = 1'b0;
        in_ctrl_in_datap_incr_block_count = 1'b0;
        in_ctrl_in_datap_store_req_meta = 1'b0;

        stream_encoder_src_req_rdy = 1'b0;
        stream_encoder_src_req_data_rdy = 1'b0;

        stream_encode_line_encode_val = 1'b0;

        reset_unit_sel = 1'b0;
        incr_unit_sel = 1'b0;
        output_metadata = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                reset_unit_sel = 1'b1;
                in_ctrl_in_datap_init_line_count = 1'b1;
                in_ctrl_in_datap_init_block_count = 1'b1;
                stream_encoder_src_req_rdy = 1'b1;
                in_ctrl_in_datap_store_req_meta = 1'b1;
                if (src_stream_encoder_req_val) begin
                    output_metadata = 1'b1;
                    state_next = ENCODE_BLOCK;
                end
                else begin
                    state_next = READY;
                end
            end
            ENCODE_BLOCK: begin
                stream_encode_line_encode_val = src_stream_encoder_req_data_val;
                stream_encoder_src_req_data_rdy = line_encode_stream_encode_rdy;

                if (src_stream_encoder_req_data_val & line_encode_stream_encode_rdy) begin
                    in_ctrl_in_datap_incr_line_count = 1'b1;
                    if (in_datap_in_ctrl_last_data_line) begin
                        state_next = PAD_BLOCK;
                    end
                    else begin
                        state_next = ENCODE_BLOCK;
                    end
                end
                else begin
                    state_next = ENCODE_BLOCK;
                end
            end
            PAD_BLOCK: begin
                stream_encode_line_encode_val = 1'b1;
                if (line_encode_stream_encode_rdy) begin
                    if (in_datap_in_ctrl_last_pad_line) begin
                        in_ctrl_in_datap_init_line_count = 1'b1;
                        in_ctrl_in_datap_incr_block_count = 1'b1;
                        if (in_datap_in_ctrl_last_block) begin
                            state_next = META_PASS_WAIT;
                        end
                        else begin
                            incr_unit_sel = 1'b1;
                            state_next = ENCODE_BLOCK;
                        end
                    end
                    else begin
                        in_ctrl_in_datap_incr_line_count = 1'b1;
                    end
                end
                else begin
                    state_next = PAD_BLOCK;
                end
            end
            META_PASS_WAIT: begin
                if (meta_state_reg == DATA_PASS_WAIT) begin
                    state_next = READY;
                end
            end
            default: begin
                in_ctrl_in_datap_init_line_count = 'X;
                in_ctrl_in_datap_incr_line_count = 'X;
                in_ctrl_in_datap_incr_block_count = 'X;
                in_ctrl_in_datap_store_req_meta = 'X;

                stream_encoder_src_req_rdy = 'X;
                stream_encoder_src_req_data_rdy = 'X;

                state_next = UND;
            end
        endcase
    end

    always_comb begin
        in_ctrl_out_ctrl_val = 1'b0;

        meta_state_next = meta_state_reg;
        case (meta_state_reg)
            WAITING: begin
                if (output_metadata) begin
                    meta_state_next = PASS_METADATA;
                end
                else begin
                    meta_state_next = WAITING;
                end
            end
            PASS_METADATA: begin
                in_ctrl_out_ctrl_val = 1'b1;
                if (out_ctrl_in_ctrl_rdy) begin
                    meta_state_next = DATA_PASS_WAIT;
                end
                else begin
                    meta_state_next = PASS_METADATA;
                end
            end
            DATA_PASS_WAIT: begin
                if (state_reg == META_PASS_WAIT) begin
                    meta_state_next = WAITING;
                end
                else begin
                    meta_state_next = DATA_PASS_WAIT;
                end
            end
            default: begin
                in_ctrl_out_ctrl_val = 'X;

                meta_state_next = UNDEF;
            end
        endcase
    end
endmodule
