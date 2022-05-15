module rs_encode_line_in_ctrl (
     input clk
    ,input rst

    ,input  logic                       src_encoder_line_val
    ,output logic                       encoder_src_line_rdy

    ,output logic                       in_ctrl_encoder_start_encode
    ,output logic                       in_ctrl_encoder_data_en

    ,output logic                       in_ctrl_in_datap_init_state
    ,output logic                       in_ctrl_in_datap_store_in_line
    ,output logic                       in_ctrl_in_datap_incr_byte_offset
    ,input  logic                       in_datap_in_ctrl_last_line_byte
    ,input  logic                       in_datap_in_ctrl_last_line

    ,input  logic                       out_ctrl_in_ctrl_done
    ,output logic                       in_ctrl_out_ctrl_done
);

    typedef enum logic [1:0]{
        READY = 2'd0,
        RUN_ENCODE_INPUT = 2'd1,
        WAIT_LINE = 2'd2,
        INPUT_WAIT_OUTPUT = 2'd3,
        UND = 'X
    } in_state_e;

    in_state_e  in_state_reg;
    in_state_e  in_state_next;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            in_state_reg <= READY;
        end
        else begin
            in_state_reg <= in_state_next;
        end
    end

    always_comb begin
        encoder_src_line_rdy = 1'b0;

        in_ctrl_encoder_start_encode = 1'b0;
        in_ctrl_encoder_data_en = 1'b0;
        in_ctrl_in_datap_store_in_line = 1'b0;
        in_ctrl_in_datap_init_state = 1'b0;
        in_ctrl_in_datap_incr_byte_offset = 1'b0;

        in_ctrl_out_ctrl_done = 1'b0;

        in_state_next = in_state_reg;
        case (in_state_reg)
            READY: begin
                in_ctrl_in_datap_store_in_line = 1'b1;
                in_ctrl_in_datap_init_state = 1'b1;
                encoder_src_line_rdy = 1'b1;
                if (src_encoder_line_val) begin
                    in_ctrl_encoder_start_encode = 1'b1;
                    in_state_next = RUN_ENCODE_INPUT;
                end
                else begin
                    in_state_next = READY;
                end
            end
            RUN_ENCODE_INPUT: begin
                in_ctrl_encoder_data_en = 1'b1;
                in_ctrl_in_datap_incr_byte_offset = 1'b1;
                if (in_datap_in_ctrl_last_line_byte) begin
                    if (in_datap_in_ctrl_last_line) begin
                        in_state_next = INPUT_WAIT_OUTPUT;
                    end
                    else begin
                        encoder_src_line_rdy = 1'b1;
                        if (src_encoder_line_val) begin
                            in_ctrl_in_datap_store_in_line = 1'b1;
                            in_state_next = RUN_ENCODE_INPUT;
                        end
                        else begin
                            in_state_next = WAIT_LINE;
                        end
                    end
                end
                else begin
                    in_state_next = RUN_ENCODE_INPUT;
                end
            end
            WAIT_LINE: begin
                in_ctrl_in_datap_store_in_line = 1'b1;
                encoder_src_line_rdy = 1'b1;
                if (src_encoder_line_val) begin
                    in_state_next = RUN_ENCODE_INPUT;
                end
                else begin
                    in_state_next = WAIT_LINE;
                end
            end
            INPUT_WAIT_OUTPUT: begin
                in_ctrl_out_ctrl_done = 1'b1;
                if (out_ctrl_in_ctrl_done) begin
                    in_state_next = READY;
                end
                else begin
                    in_state_next = INPUT_WAIT_OUTPUT;
                end
            end
            default: begin
                encoder_src_line_rdy = 'X;
        
                in_ctrl_encoder_start_encode = 'X;
                in_ctrl_encoder_data_en = 'X;
                in_ctrl_in_datap_store_in_line = 'X;
                in_ctrl_in_datap_init_state = 'X;
                in_ctrl_in_datap_incr_byte_offset = 'X;
        
                in_ctrl_out_ctrl_done = 'X;
        
                in_state_next = UND;
            end
        endcase
    end


endmodule
