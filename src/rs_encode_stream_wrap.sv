/* 
 * Distribute blocks in a request round robin across some number of 
 * RS encoders and then reassemble them into a stream of data blocks
 * followed by encoding blocks
 * FIXME (katie): right now, the number of parity mems must be a power of 2 for easy
 * division. There's a way to fix this without division, but it's just more work
 */

module rs_encode_stream_wrap #(
     parameter NUM_REQ_BLOCKS = -1
    ,parameter NUM_REQ_BLOCKS_W = $clog2(NUM_REQ_BLOCKS)
    ,parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_RS_UNITS=-1
)(
     input clk
    ,input rst

    ,input                                  src_stream_encoder_req_val
    ,input          [NUM_REQ_BLOCKS_W-1:0]  src_stream_encoder_req_num_blocks
    ,output logic                           stream_encoder_src_req_rdy

    ,input                                  src_stream_encoder_req_data_val
    ,input          [DATA_W-1:0]            src_stream_encoder_req_data
    ,output logic                           stream_encoder_src_req_data_rdy

    ,output logic                           stream_encoder_dst_resp_data_val
    ,output logic   [DATA_W-1:0]            stream_encoder_dst_resp_data
    ,input  logic                           dst_stream_encoder_resp_data_rdy
);
    localparam NUM_LINES = (RS_K % DATA_BYTES) == 0 
                           ? RS_K/DATA_BYTES 
                           : (RS_K/DATA_BYTES) + 1;
    localparam NUM_LINES_W = $clog2(NUM_LINES);
    
    logic                           in_ctrl_in_datap_store_req_meta;
    logic                           in_ctrl_in_datap_init_line_count;
    logic                           in_ctrl_in_datap_incr_line_count;
    logic                           in_ctrl_in_datap_init_block_count;
    logic                           in_ctrl_in_datap_incr_block_count;

    logic   [NUM_RS_UNITS_W-1:0]    in_ctrl_rs_unit_sel;

    logic                           in_datap_in_ctrl_last_data_line;
    logic                           in_datap_in_ctrl_last_block;

    logic                           line_encode_stream_encode_rdy;
    logic   [DATA_W-1:0]            stream_encode_line_encode_line;
    logic                           stream_encode_line_encode_val;
    
    logic                           in_ctrl_out_ctrl_val;
    logic   [NUM_REQ_BLOCKS_W:0]    in_datap_out_datap_req_num_blocks;
    logic                           out_ctrl_in_ctrl_rdy;

    logic                           line_encode_stream_encode_val;
    logic   [DATA_W-1:0]            line_encode_stream_encode_line;
    logic                           stream_encode_line_encode_rdy;
    
    logic                           parity_mem_wr_val;
    logic   [NUM_REQ_BLOCKS_W-1:0]  parity_mem_wr_addr;
    logic   [PARITY_W-1:0]          parity_mem_wr_data;

    logic                           parity_mem_rd_req_val;
    logic   [NUM_REQ_BLOCKS_W-1:0]  parity_mem_rd_req_addr;

    logic                           parity_mem_rd_resp_val;
    logic   [DATA_W-1:0]            parity_mem_rd_resp_data;
    logic                           parity_mem_rd_resp_rdy;

    logic                           out_ctrl_out_datap_store_meta;
    logic                           out_ctrl_out_datap_init_req_state;

    logic                           out_ctrl_out_datap_incr_block_count;
    logic                           out_ctrl_out_datap_init_line_count;
    logic                           out_ctrl_out_datap_incr_line_count;
    logic                           out_ctrl_out_datap_incr_parity_wr_addr;
    logic                           out_ctrl_out_datap_incr_parity_rd_addr;
    logic                           out_ctrl_out_datap_parity_out;

    logic                           out_datap_out_ctrl_last_block;
    logic                           out_datap_out_ctrl_last_data_line;
    logic                           out_datap_out_ctrl_last_parity_line;

    logic   [NUM_RS_UNITS-1:0]  line_encode_vals;
    logic   [NUM_RS_UNITS-1:0]  line_encode_rdys;

    rs_encode_stream_in_ctrl #(
         .NUM_RS_UNITS = -1
        ,.NUM_RS_UNITS_W = $clog2(NUM_RS_UNITS)
    ) in_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_stream_encoder_req_val        (src_stream_encoder_req_val         )
        ,.stream_encoder_src_req_rdy        (stream_encoder_src_req_rdy         )
                                                                                
        ,.src_stream_encoder_req_data_val   (src_stream_encoder_req_data_val    )
        ,.stream_encoder_src_req_data_rdy   (stream_encoder_src_req_data_rdy    )
        
        ,.in_ctrl_in_datap_store_req_meta   (in_ctrl_in_datap_store_req_meta    )
        ,.in_ctrl_in_datap_init_line_count  (in_ctrl_in_datap_init_line_count   )
        ,.in_ctrl_in_datap_incr_line_count  (in_ctrl_in_datap_incr_line_count   )
        ,.in_ctrl_in_datap_init_block_count (in_ctrl_in_datap_init_block_count  )
        ,.in_ctrl_in_datap_incr_block_count (in_ctrl_in_datap_incr_block_count  )
                                                                                
        ,.in_ctrl_rs_unit_sel               (in_ctrl_rs_unit_sel                )
                                                                                
        ,.in_datap_in_ctrl_last_data_line   (in_datap_in_ctrl_last_data_line    )
        ,.in_datap_in_ctrl_last_block       (in_datap_in_ctrl_last_block        )
    
        ,.line_encode_stream_encode_rdy     (line_encode_stream_encode_rdy      )
        ,.stream_encode_line_encode_val     (stream_encode_line_encode_val      )
    
        ,.in_ctrl_out_ctrl_val              (in_ctrl_out_ctrl_val               )
        ,.out_ctrl_in_ctrl_rdy              (out_ctrl_in_ctrl_rdy               )
    );

    rs_encode_stream_in_datap #(
         .NUM_REQ_BLOCKS    (NUM_REQ_BLOCKS )
        ,.DATA_W            (DATA_W         )
        ,.NUM_LINES         (NUM_LINES      )
    ) in_datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_stream_encoder_req_num_blocks (src_stream_encoder_req_num_blocks  )
                                                                                
        ,.src_stream_encoder_req_data       (src_stream_encoder_req_data        )
                                                                                
        ,.in_ctrl_in_datap_store_req_meta   (in_ctrl_in_datap_store_req_meta    )
        ,.in_ctrl_in_datap_init_line_count  (in_ctrl_in_datap_init_line_count   )
        ,.in_ctrl_in_datap_incr_line_count  (in_ctrl_in_datap_incr_line_count   )
        ,.in_ctrl_in_datap_init_block_count (in_ctrl_in_datap_init_block_count  )
        ,.in_ctrl_in_datap_incr_block_count (in_ctrl_in_datap_incr_block_count  )
                                                                                
        ,.in_datap_in_ctrl_last_data_line   (in_datap_in_ctrl_last_data_line    )
        ,.in_datap_in_ctrl_last_block       (in_datap_in_ctrl_last_block        )
                                                                                
        ,.line_encode_stream_encode_line    (line_encode_stream_encode_line     )
    
        ,.in_datap_out_datap_req_num_blocks (in_datap_out_datap_req_num_blocks  )
    );

    demux #(
         .NUM_INPUTS    (NUM_RS_UNITS   )
        ,.INPUT_WIDTH   (1              )
    ) input_val_demux (
         .input_sel     (in_ctrl_rs_unit_sel            )
        ,.data_input    (stream_encode_line_encode_val  )
        ,.data_outputs  (line_encode_vals               )
    );

    bsg_mux #(
         .width_p   (1              )
        ,.els_p     (NUM_RS_UNITS   )
    ) input_rdy_mux (
         .data_i    (line_encode_rdys               )
        ,.sel_i     (in_ctrl_rs_unit_sel            )
        ,.data_o    (line_encode_stream_encode_rdy  )
    );

    rs_encode_line_mux_wrap #(
         .DATA_W        (DATA_W         )
        ,.NUM_LINES     (NUM_LINES      )
        ,.PARITY_W      (PARITY_W       )
        ,.NUM_RS_UNITS  (NUM_RS_UNITS   )
    ) line_encode (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_encoder_line_vals (src_encoder_line_vals  )
        ,.src_encoder_line      (src_encoder_line       )
        ,.encoder_src_line_rdys (encoder_src_line_rdys  )
                                                        
        ,.encoder_dst_line_val  (encoder_dst_line_val   )
        ,.encoder_dst_line      (encoder_dst_line       )
        ,.encoder_dst_parity    (encoder_dst_parity     )
        ,.dst_encoder_line_rdy  (dst_encoder_line_rdy   )
    );

    rs_encode_stream_out_ctrl out_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.in_ctrl_out_ctrl_val                  (in_ctrl_out_ctrl_val                  )
        ,.out_ctrl_in_ctrl_rdy                  (out_ctrl_in_ctrl_rdy                  )
                                                                                       
        ,.line_encode_stream_encode_val         (line_encode_stream_encode_val         )
        ,.stream_encode_line_encode_rdy         (stream_encode_line_encode_rdy         )
                                                                                       
        ,.stream_encoder_dst_resp_data_val      (stream_encoder_dst_resp_data_val      )
        ,.dst_stream_encoder_resp_data_rdy      (dst_stream_encoder_resp_data_rdy      )
                                                                                       
        ,.parity_mem_wr_val                     (parity_mem_wr_val                     )
                                                                                       
        ,.parity_mem_rd_req_val                 (parity_mem_rd_req_val                 )
                                                                                       
        ,.parity_mem_rd_resp_val                (parity_mem_rd_resp_val                )
        ,.parity_mem_rd_resp_rdy                (parity_mem_rd_resp_rdy                )
                                                                                       
        ,.out_ctrl_out_datap_store_meta         (out_ctrl_out_datap_store_meta         )
        ,.out_ctrl_out_datap_init_req_state     (out_ctrl_out_datap_init_req_state     )
                                                                                       
        ,.out_ctrl_out_datap_incr_block_count   (out_ctrl_out_datap_incr_block_count   )
        ,.out_ctrl_out_datap_init_line_count    (out_ctrl_out_datap_init_line_count    )
        ,.out_ctrl_out_datap_incr_line_count    (out_ctrl_out_datap_incr_line_count    )
        ,.out_ctrl_out_datap_incr_parity_wr_addr(out_ctrl_out_datap_incr_parity_wr_addr)
        ,.out_ctrl_out_datap_incr_parity_rd_addr(out_ctrl_out_datap_incr_parity_rd_addr)
        ,.out_ctrl_out_datap_parity_out         (out_ctrl_out_datap_parity_out         )
                                                                                       
        ,.out_datap_out_ctrl_last_block         (out_datap_out_ctrl_last_block         )
        ,.out_datap_out_ctrl_last_data_line     (out_datap_out_ctrl_last_data_line     )
        ,.out_datap_out_ctrl_last_parity_line   (out_datap_out_ctrl_last_parity_line   )
    );

    rs_encode_stream_out_datap #(
         .NUM_REQ_BLOCKS(NUM_REQ_BLOCKS )
        ,.DATA_W        (DATA_W         )
    ) out_datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.in_datap_out_datap_req_num_blocks     (in_datap_out_datap_req_num_blocks     )
                                                                                       
        ,.line_encode_stream_encode_line        (line_encode_stream_encode_line        )
                                                                                       
        ,.stream_encoder_dst_resp_data          (stream_encoder_dst_resp_data          )
                                                                                       
        ,.parity_mem_wr_addr                    (parity_mem_wr_addr                    )
        ,.parity_mem_wr_data                    (parity_mem_wr_data                    )
                                                                                       
        ,.parity_mem_rd_req_addr                (parity_mem_rd_req_addr                )
                                                                                       
        ,.parity_mem_rd_resp_data               (parity_mem_rd_resp_data               )
                                                                                       
        ,.out_ctrl_out_datap_store_meta         (out_ctrl_out_datap_store_meta         )
        ,.out_ctrl_out_datap_init_req_state     (out_ctrl_out_datap_init_req_state     )
                                                                                       
        ,.out_ctrl_out_datap_incr_block_count   (out_ctrl_out_datap_incr_block_count   )
        ,.out_ctrl_out_datap_init_line_count    (out_ctrl_out_datap_init_line_count    )
        ,.out_ctrl_out_datap_incr_line_count    (out_ctrl_out_datap_incr_line_count    )
        ,.out_ctrl_out_datap_incr_parity_wr_addr(out_ctrl_out_datap_incr_parity_wr_addr)
        ,.out_ctrl_out_datap_incr_parity_rd_addr(out_ctrl_out_datap_incr_parity_rd_addr)
        ,.out_ctrl_out_datap_parity_out         (out_ctrl_out_datap_parity_out         )
                                                                                       
        ,.out_datap_out_ctrl_last_block         (out_datap_out_ctrl_last_block         )
        ,.out_datap_out_ctrl_last_data_line     (out_datap_out_ctrl_last_data_line     )
        ,.out_datap_out_ctrl_last_parity_line   (out_datap_out_ctrl_last_parity_line   )
    );

    parity_mem #(
         .NUM_MEMS      (NUM_MEMS   )
        ,.LOG2_DEPTH    (LOG2_DEPTH )
        ,.DATA_W        (DATA_W     )
        ,.PARITY_W      (PARITY_W   )
    ) parity_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (parity_mem_wr_val          )
        ,.wr_req_addr   (parity_mem_wr_addr         )
        ,.wr_req_data   (parity_mem_wr_data         )
                         
        ,.rd_req_val    (parity_mem_rd_req_val      )
        ,.rd_req_addr   (parity_mem_rd_req_addr     )
                         
        ,.rd_resp_val   (parity_mem_rd_resp_val     )
        ,.rd_resp_data  (parity_mem_rd_resp_data    )
        ,.rd_resp_rdy   (parity_mem_rd_resp_rdy     )
    );
endmodule
