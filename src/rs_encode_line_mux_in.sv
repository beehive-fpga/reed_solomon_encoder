import rs_encode_pkg::*;
module rs_encode_line_mux_in #(
     parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_LINES=-1
    ,parameter PARITY_W=-1
)(
     input clk
    ,input rst

    ,input  logic                       src_encoder_line_val
    ,input  logic   [DATA_W-1:0]        src_encoder_line
    ,output logic                       encoder_src_line_rdy

    ,output logic                       encoder_dst_byte_val
    ,output logic   [RS_WORD_W-1:0]     encoder_dst_byte 
    ,input  logic                       dst_encoder_byte_rdy

    ,output logic                       in_ctrl_out_done
    ,input  logic                       out_in_ctrl_done
);
    
    localparam LAST_LINE_BYTES = (RS_K % DATA_BYTES) == 0
                                ? DATA_BYTES
                                : RS_K % DATA_BYTES;

    logic                       in_ctrl_encoder_start_encode;
    logic                       in_ctrl_encoder_data_en;
    logic   [RS_WORD_W-1:0]     in_datap_encoder_data;

    logic                       in_ctrl_in_datap_init_state;
    logic                       in_ctrl_in_datap_store_in_line;
    logic                       in_ctrl_in_datap_incr_byte_offset;
    logic                       in_datap_in_ctrl_last_line_byte;
    logic                       in_datap_in_ctrl_last_line;
    
    logic                       encoder_fifo_data_val;
    logic   [RS_WORD_W-1:0]     encoder_fifo_data;

    logic                       fifo_out_rd_req;
    logic                       fifo_out_empty;

    logic                       in_fifo_wr_req;
    logic                       in_fifo_full;

    logic                       in_fifo_rd_req;
    logic   [DATA_W-1:0]        in_fifo_rd_data;
    logic                       in_fifo_empty;

    logic                       in_fifo_in_ctrl_val;
    logic                       in_ctrl_in_fifo_rdy;


    assign in_fifo_wr_req = src_encoder_line_val & ~in_fifo_full;
    assign encoder_src_line_rdy = ~in_fifo_full;
    
    // a tiny buffer
    fifo_1r1w #(
         .width_p       (DATA_W             )
        ,.log2_els_p    ($clog2(NUM_LINES)  )
    ) input_buf (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req    (in_fifo_wr_req     )
        ,.wr_data   (src_encoder_line   )
        ,.full      (in_fifo_full       )
        
        ,.rd_req    (in_fifo_rd_req     )
        ,.rd_data   (in_fifo_rd_data    )
        ,.empty     (in_fifo_empty      )
    
    );

    assign in_fifo_in_ctrl_val = ~in_fifo_empty;
    assign in_fifo_rd_req = in_ctrl_in_fifo_rdy & ~in_fifo_empty;

    rs_encode_line_in_ctrl in_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_encoder_line_val              (in_fifo_in_ctrl_val                )
        ,.encoder_src_line_rdy              (in_ctrl_in_fifo_rdy                )
    
        ,.in_ctrl_encoder_start_encode      (in_ctrl_encoder_start_encode       )
        ,.in_ctrl_encoder_data_en           (in_ctrl_encoder_data_en            )
    
        ,.in_ctrl_in_datap_init_state       (in_ctrl_in_datap_init_state        )
        ,.in_ctrl_in_datap_store_in_line    (in_ctrl_in_datap_store_in_line     )
        ,.in_ctrl_in_datap_incr_byte_offset (in_ctrl_in_datap_incr_byte_offset  )
        ,.in_datap_in_ctrl_last_line_byte   (in_datap_in_ctrl_last_line_byte    )
        ,.in_datap_in_ctrl_last_line        (in_datap_in_ctrl_last_line         )
                                                                                
        ,.out_ctrl_in_ctrl_done             (out_in_ctrl_done                   )
        ,.in_ctrl_out_ctrl_done             (in_ctrl_out_done                   )
    );

    rs_encode_line_in_datap #(
         .DATA_W            (DATA_W             )
        ,.NUM_LINES         (NUM_LINES          )
        ,.LAST_LINE_BYTES   (LAST_LINE_BYTES    )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_encoder_line                  (in_fifo_rd_data                    )
        
        ,.in_datap_encoder_data             (in_datap_encoder_data              )
                                                                                
        ,.in_ctrl_in_datap_init_state       (in_ctrl_in_datap_init_state        )
        ,.in_ctrl_in_datap_store_in_line    (in_ctrl_in_datap_store_in_line     )
        ,.in_ctrl_in_datap_incr_byte_offset (in_ctrl_in_datap_incr_byte_offset  )
        ,.in_datap_in_ctrl_last_line_byte   (in_datap_in_ctrl_last_line_byte    )
        ,.in_datap_in_ctrl_last_line        (in_datap_in_ctrl_last_line         )
    );

    rs_encode_top_wrap rs_encoder_top (
         .clk   (clk    )
        ,.rst_n (~rst   )
    
        ,.src_encoder_start_encode  (in_ctrl_encoder_start_encode   )
        ,.src_encoder_data_enable   (in_ctrl_encoder_data_en        )
        ,.src_encoder_data          (in_datap_encoder_data          )
        ,.encoder_src_encoding      ()
    
        ,.encoder_dst_data_val      (encoder_fifo_data_val          )
        ,.encoder_dst_data          (encoder_fifo_data              )
    );

    fifo_1r1w #(
         .width_p       (RS_WORD_W          )
        ,.log2_els_p    ($clog2(RS_N + 1)   )
    ) fifo (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req    (encoder_fifo_data_val      )
        ,.wr_data   (encoder_fifo_data          )
        ,.full      ()
        
        ,.rd_req    (fifo_out_rd_req            )
        ,.rd_data   (encoder_dst_byte           )
        ,.empty     (fifo_out_empty             )
    );

    assign encoder_dst_byte_val = ~fifo_out_empty;
    assign fifo_out_rd_req = ~fifo_out_empty & dst_encoder_byte_rdy;
endmodule
