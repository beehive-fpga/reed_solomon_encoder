// Be super careful with the reload behavior around using multiple blocks
// Think about the timing of when you reset the data offset
module rs_encoder_line_mux_out_ctrl #(
     parameter NUM_RS_UNITS=-1
    ,parameter NUM_RS_UNITS_W=$clog2(NUM_RS_UNITS)
)(
     input clk
    ,input rst

    ,input  logic                       encoder_out_ctrl_byte_val
    ,output logic                       out_ctrl_encoder_byte_rdy

    ,output logic   [NUM_RS_UNITS-1:0]  out_ctrl_unit_sel
    
    ,output logic                       encoder_dst_line_val
    ,input  logic                       dst_encoder_line_rdy

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

    logic   [NUM_RS_UNITS_W-1:0]    unit_sel_reg;
    logic   [NUM_RS_UNITS_W-1:0]    unit_sel_next;

    logic                           init_unit_sel;
    logic                           incr_unit_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            out_state_reg <= READY;
            unit_sel_reg <= '0;
        end
        else begin
            out_state_reg <= out_state_next;
            unit_sel_reg <= unit_sel_next;
        end
    end

    assign unit_sel_next

    assign unit_sel_next = init_unit_sel
                        ? '0
                        : incr_unit_sel
                            ? unit_sel_reg + 1'b1
                            : unit_sel_reg;

    always_comb begin
        encoder_dst_line_val = 1'b0;

        out_ctrl_encoder_byte_rdy = 1'b0;

        out_ctrl_out_datap_init_state = 1'b0;
        out_ctrl_out_datap_store_data = 1'b0;
        out_ctrl_out_datap_store_parity = 1'b0;
        out_ctrl_out_datap_incr_line_count = 1'b0;

        out_ctrl_in_ctrl_done = 1'b0;

        init_unit_sel = 1'b0;
        incr_unit_sel = 1'b0;

        out_state_next = out_state_reg;
        case (out_state_reg)
            READY: begin
                out_ctrl_encoder_byte_rdy = 1'b1;
                out_ctrl_out_datap_init_state = 1'b1;
                init_unit_sel = 1'b0;

                if (encoder_out_ctrl_byte_val) begin
                    out_ctrl_out_datap_store_data = 1'b1;
                    out_state_next = SAVE_OUTPUT_BYTES;
                end
                else begin
                    out_state_next = READY;
                end
            end
            SAVE_OUTPUT_BYTES: begin
                out_ctrl_encoder_rdy = 1'b1;
                if (encoder_out_ctrl_byte_val) begin
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
                out_ctrl_encoder_rdy = 1'b1;
                if (encoder_out_ctrl_byte_val) begin
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
                    incr_unit_sel = 1'b1;
                    // if we're finished collecting the results from all the things
                    if (unit_sel_reg == (NUM_RS_UNITS-1)) begin
                        out_state_next = READY;
                    end
                    // otherwise, try to collect the result from the next unit
                    else begin
                        out_state_next = SAVE_OUTPUT_BYTES;
                    end
                end
                else begin
                    out_state_next = OUTPUT_WAIT;
                end
            end
            default: begin
                encoder_dst_line_val = 'X;

                out_ctrl_encoder_byte_rdy = 'X;

                out_ctrl_out_datap_init_state = 'X;
                out_ctrl_out_datap_store_data = 'X;
                out_ctrl_out_datap_store_parity = 'X;
                out_ctrl_out_datap_incr_line_count = 'X;

                out_ctrl_in_ctrl_done = 'X;

                init_unit_sel = 'X;
                incr_unit_sel = 'X;

                out_state_next = UND;
            end
        endcase
    end
endmodule
