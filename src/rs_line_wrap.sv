/*
 * This module accepts ceil(RS_K/DATA_BYTES) lines representing the input data block.
 * The last line may not have all the bytes
 * It outputs the data block as ceil(RS_K/DATA_BYTES) lines and the parity bytes
 * with the last data line
 */
import rs_encode_pkg::*;
module rs_encode_line_wrap #(
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

    ,output logic                       encoder_dst_line_val
    ,output logic   [DATA_W-1:0]        encoder_dst_line
    ,output logic   [PARITY_W-1:0]      encoder_dst_parity
    ,input  logic                       dst_encoder_line_rdy
);

    typedef struct packed {
        logic   [DATA_W-1:0]    data;
        logic   [PARITY_W-1:0]  parity;
    } fifo_struct;

    localparam LAST_LINE_BYTES = (RS_K % DATA_BYTES) == 0
                                ? DATA_BYTES
                                : RS_K % DATA_BYTES;
    
    logic                       in_ctrl_encoder_start_encode;
    logic                       in_ctrl_encoder_data_en;

    logic                       in_ctrl_in_datap_init_state;
    logic                       in_ctrl_in_datap_store_in_line;
    logic                       in_ctrl_in_datap_incr_byte_offset;
    logic                       in_datap_in_ctrl_last_line_byte;
    logic                       in_datap_in_ctrl_last_line;

    logic                       out_ctrl_in_ctrl_done;
    logic                       in_ctrl_out_ctrl_done;
    
    logic   [RS_WORD_W-1:0]     in_datap_encoder_data;

    logic                       encoder_fifo_data_val;
    logic   [RS_WORD_W-1:0]     encoder_fifo_data;
    
    logic                       fifo_out_ctrl_data_val;
    logic                       fifo_out_ctrl_data_req;
    logic                       fifo_out_ctrl_data_empty;
    logic   [RS_WORD_W-1:0]     fifo_out_datap_data;
    logic                       out_ctrl_fifo_data_rdy;
    
    logic                       out_ctrl_out_datap_init_state;
    logic                       out_ctrl_out_datap_store_data;
    logic                       out_ctrl_out_datap_store_parity;
    logic                       out_ctrl_out_datap_incr_line_count;
    logic                       out_datap_out_ctrl_last_line_byte;
    logic                       out_datap_out_ctrl_last_line;
    logic                       out_datap_out_ctrl_last_parity;

    logic                       encoder_fifo_wr_req;
    fifo_struct                 encoder_fifo_wr_data; 

    logic                       fifo_rd_req;
    logic                       fifo_rd_val;
    fifo_struct                 fifo_rd_data;

    logic                       encoder_in_fifo_rd_req;
    logic                       encoder_in_fifo_rdy;
    logic                       in_fifo_encoder_val;
    logic   [DATA_W-1:0]        in_fifo_encoder_data;
    
    bsg_fifo_1r1w_small #( 
         .width_p   (DATA_W     )
        ,.els_p     (NUM_LINES  )
        ,.harden_p  (1)
    ) input_buf ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (src_encoder_line_val   )
        ,.ready_o   (encoder_src_line_rdy   )
        ,.data_i    (src_encoder_line       )
    
        ,.v_o       (in_fifo_encoder_val    )
        ,.data_o    (in_fifo_encoder_data   )
        ,.yumi_i    (encoder_in_fifo_rd_req )
    );

    assign encoder_in_fifo_rd_req = in_fifo_encoder_val & encoder_in_fifo_rdy;


    rs_encode_line_in_ctrl in_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_encoder_line_val              (in_fifo_encoder_val                )
        ,.encoder_src_line_rdy              (encoder_in_fifo_rdy                )
    
        ,.in_ctrl_encoder_start_encode      (in_ctrl_encoder_start_encode       )
        ,.in_ctrl_encoder_data_en           (in_ctrl_encoder_data_en            )
    
        ,.in_ctrl_in_datap_init_state       (in_ctrl_in_datap_init_state        )
        ,.in_ctrl_in_datap_store_in_line    (in_ctrl_in_datap_store_in_line     )
        ,.in_ctrl_in_datap_incr_byte_offset (in_ctrl_in_datap_incr_byte_offset  )
        ,.in_datap_in_ctrl_last_line_byte   (in_datap_in_ctrl_last_line_byte    )
        ,.in_datap_in_ctrl_last_line        (in_datap_in_ctrl_last_line         )
                                                                                
        ,.out_ctrl_in_ctrl_done             (out_ctrl_in_ctrl_done              )
        ,.in_ctrl_out_ctrl_done             (in_ctrl_out_ctrl_done              )
    );

    rs_encode_line_in_datap #(
         .DATA_W            (DATA_W             )
        ,.NUM_LINES         (NUM_LINES          )
        ,.LAST_LINE_BYTES   (LAST_LINE_BYTES    )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_encoder_line                  (in_fifo_encoder_data               )
        
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
        
        ,.rd_req    (fifo_out_ctrl_data_req     )
        ,.rd_data   (fifo_out_datap_data        )
        ,.empty     (fifo_out_ctrl_data_empty   )
    );

    assign fifo_out_ctrl_data_req = out_ctrl_fifo_data_rdy & ~fifo_out_ctrl_data_empty;
    assign fifo_out_ctrl_data_val = ~fifo_out_ctrl_data_empty;

    rs_encode_line_out_ctrl out_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.encoder_dst_line_val              (encoder_fifo_val                   )
        ,.dst_encoder_line_rdy              (fifo_encoder_rdy                   )
                                                                                
        ,.fifo_out_ctrl_data_val            (fifo_out_ctrl_data_val             )
        ,.out_ctrl_fifo_data_rdy            (out_ctrl_fifo_data_rdy             )
                                                                                
        ,.out_ctrl_out_datap_init_state     (out_ctrl_out_datap_init_state      )
        ,.out_ctrl_out_datap_store_data     (out_ctrl_out_datap_store_data      )
        ,.out_ctrl_out_datap_store_parity   (out_ctrl_out_datap_store_parity    )
        ,.out_ctrl_out_datap_incr_line_count(out_ctrl_out_datap_incr_line_count )
        ,.out_datap_out_ctrl_last_line_byte (out_datap_out_ctrl_last_line_byte  )
        ,.out_datap_out_ctrl_last_line      (out_datap_out_ctrl_last_line       )
        ,.out_datap_out_ctrl_last_parity    (out_datap_out_ctrl_last_parity     )
                                                                                
        ,.out_ctrl_in_ctrl_done             (out_ctrl_in_ctrl_done              )
        ,.in_ctrl_out_ctrl_done             (in_ctrl_out_ctrl_done              )
    );

    rs_encode_line_out_datap #(
         .DATA_W            (DATA_W             )
        ,.NUM_LINES         (NUM_LINES          )
        ,.LAST_LINE_BYTES   (LAST_LINE_BYTES    )
    ) out_datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.fifo_out_datap_data               (fifo_out_datap_data                )
    
        ,.encoder_dst_line                  (encoder_fifo_wr_data.data          )
        ,.encoder_dst_parity                (encoder_fifo_wr_data.parity        )
                                                                                
        ,.out_ctrl_out_datap_init_state     (out_ctrl_out_datap_init_state      )
        ,.out_ctrl_out_datap_store_data     (out_ctrl_out_datap_store_data      )
        ,.out_ctrl_out_datap_store_parity   (out_ctrl_out_datap_store_parity    )
        ,.out_ctrl_out_datap_incr_line_count(out_ctrl_out_datap_incr_line_count )
        ,.out_datap_out_ctrl_last_line_byte (out_datap_out_ctrl_last_line_byte  )
        ,.out_datap_out_ctrl_last_line      (out_datap_out_ctrl_last_line       )
        ,.out_datap_out_ctrl_last_parity    (out_datap_out_ctrl_last_parity     )
    );
        
    bsg_fifo_1r1w_small #( 
         .width_p   (DATA_W + PARITY_W)
        ,.els_p     (4)
        ,.harden_p  (1)
    ) line_out_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (encoder_fifo_val       )
        ,.ready_o   (fifo_encoder_rdy       )
        ,.data_i    (encoder_fifo_wr_data   )
    
        ,.v_o       (fifo_rd_val            )
        ,.data_o    (fifo_rd_data           )
        ,.yumi_i    (fifo_rd_req            )
    );

    assign fifo_rd_req = fifo_rd_val & dst_encoder_line_rdy;
    assign encoder_dst_line_val = fifo_rd_val;
    assign encoder_dst_line = fifo_rd_data.data;
    assign encoder_dst_parity = fifo_rd_data.parity;
endmodule
