// Warning: this module expects that the number of blocks fed in is a multiple of
// the number of RS encoders instantiated
import rs_encode_pkg::*;
module rs_encode_line_mux_wrap #(
     parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_LINES=-1
    ,parameter PARITY_W=-1
    ,parameter NUM_RS_UNITS=-1
)(
     input clk
    ,input rst

    ,input  logic   [NUM_RS_UNITS-1:0]  src_encoder_line_vals
    ,input  logic   [DATA_W-1:0]        src_encoder_line
    ,output logic   [NUM_RS_UNITS-1:0]  encoder_src_line_rdys
    
    ,output logic                       encoder_dst_line_val
    ,output logic   [DATA_W-1:0]        encoder_dst_line
    ,output logic   [PARITY_W-1:0]      encoder_dst_parity
    ,input  logic                       dst_encoder_line_rdy
);
    localparam LAST_LINE_BYTES = (RS_K % DATA_BYTES) == 0
                                ? DATA_BYTES
                                : RS_K % DATA_BYTES;
    localparam NUM_RS_UNITS_W = $clog2(NUM_RS_UNITS);

    logic   [NUM_RS_UNITS-1:0]  in_ctrl_dones;
    logic   [NUM_RS_UNITS-1:0]  out_ctrl_dones;

    logic   [NUM_RS_UNITS-1:0]                  encoder_dst_vals;
    logic   [NUM_RS_UNITS-1:0][RS_WORD_W-1:0]   encoder_dst_bytes;
    logic   [NUM_RS_UNITS-1:0]                  dst_encoder_rdys;

    logic                                       out_ctrl_in_ctrl_done;
    logic                                       in_ctrl_out_ctrl_done;
    
    logic                                       out_ctrl_out_datap_init_state;
    logic                                       out_ctrl_out_datap_store_data;
    logic                                       out_ctrl_out_datap_store_parity;
    logic                                       out_ctrl_out_datap_incr_line_count;
    logic                                       out_datap_out_ctrl_last_line_byte;
    logic                                       out_datap_out_ctrl_last_line;
    logic                                       out_datap_out_ctrl_last_parity;
    
    logic                                       encoder_out_ctrl_byte_val;
    logic   [RS_WORD_W-1:0]                     encoder_out_datap_byte;
    logic                                       out_ctrl_encoder_byte_rdy;
    
    logic   [NUM_RS_UNITS_W-1:0]                out_ctrl_unit_sel;

    genvar i;
    generate
        for (i = 0; i < NUM_RS_UNITS; i = i+1) begin
            rs_encode_line_mux_in #(
                 .DATA_W    (DATA_W     )
                ,.NUM_LINES (NUM_LINES  )
                ,.PARITY_W  (PARITY_W   )
            ) in_rs_encoder (
                 .clk   (clk)
                ,.rst   (rst)

                ,.src_encoder_line_val  (src_encoder_line_vals[i]   )
                ,.src_encoder_line      (src_encoder_line           )
                ,.encoder_src_line_rdy  (encoder_src_line_rdys[i]   )
            
                ,.encoder_dst_byte_val  (encoder_dst_vals[i]        )
                ,.encoder_dst_byte      (encoder_dst_bytes[i]       )
                ,.dst_encoder_byte_rdy  (dst_encoder_rdys[i]        )
            
                ,.in_ctrl_out_done      (in_ctrl_dones[i]           )
                ,.out_in_ctrl_done      (out_ctrl_dones[i]          )
            );
        end
    endgenerate

    bsg_mux #(
         .width_p   (1              )
        ,.els_p     (NUM_RS_UNITS   )
    ) byte_vals_mux (
         .data_i    (encoder_dst_vals           )
        ,.sel_i     (out_ctrl_unit_sel          )
        ,.data_o    (encoder_out_ctrl_byte_val  )
    );
    
    bsg_mux #(
         .width_p   (RS_WORD_W      )
        ,.els_p     (NUM_RS_UNITS   )
    ) bytes_mux (
         .data_i    (encoder_dst_bytes          )
        ,.sel_i     (out_ctrl_unit_sel          )
        ,.data_o    (encoder_out_datap_byte     )
    );

    demux #(
         .NUM_OUTPUTS   (NUM_RS_UNITS   )
        ,.INPUT_WIDTH   (1              )
    ) byte_rdys_demux (
         .input_sel     (out_ctrl_unit_sel          )
        ,.data_input    (out_ctrl_encoder_byte_rdy  )
        ,.data_outputs  (dst_encoder_rdys           )
    );
    
    demux #(
         .NUM_OUTPUTS   (NUM_RS_UNITS   )
        ,.INPUT_WIDTH   (1              )
    ) out_in_dones_demux (
         .input_sel     (out_ctrl_unit_sel          )
        ,.data_input    (out_ctrl_in_ctrl_done      )
        ,.data_outputs  (out_ctrl_dones             )
    );
    
    bsg_mux #(
         .width_p   (1              )
        ,.els_p     (NUM_RS_UNITS   )
    ) in_out_dones_mux (
         .data_i    (in_ctrl_dones              )
        ,.sel_i     (out_ctrl_unit_sel          )
        ,.data_o    (in_ctrl_out_ctrl_done      )
    );

    rs_encoder_line_mux_out_ctrl #(
         .NUM_RS_UNITS  (NUM_RS_UNITS   )
    ) out_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.encoder_out_ctrl_byte_val             (encoder_out_ctrl_byte_val          )
        ,.out_ctrl_encoder_byte_rdy             (out_ctrl_encoder_byte_rdy          )
                                                                                    
        ,.out_ctrl_unit_sel                     (out_ctrl_unit_sel                  )
                                                                                    
        ,.encoder_dst_line_val                  (encoder_dst_line_val               )
        ,.dst_encoder_line_rdy                  (dst_encoder_line_rdy               )
                                                                                    
        ,.out_ctrl_out_datap_init_state         (out_ctrl_out_datap_init_state      )
        ,.out_ctrl_out_datap_store_data         (out_ctrl_out_datap_store_data      )
        ,.out_ctrl_out_datap_store_parity       (out_ctrl_out_datap_store_parity    )
        ,.out_ctrl_out_datap_incr_line_count    (out_ctrl_out_datap_incr_line_count )
        ,.out_datap_out_ctrl_last_line_byte     (out_datap_out_ctrl_last_line_byte  )
        ,.out_datap_out_ctrl_last_line          (out_datap_out_ctrl_last_line       )
        ,.out_datap_out_ctrl_last_parity        (out_datap_out_ctrl_last_parity     )
                                                                                    
        ,.out_ctrl_in_ctrl_done                 (out_ctrl_in_ctrl_done              )
        ,.in_ctrl_out_ctrl_done                 (in_ctrl_out_ctrl_done              )
    );

    rs_encode_line_out_datap #(
         .DATA_W            (DATA_W             )
        ,.NUM_LINES         (NUM_LINES          )
        ,.LAST_LINE_BYTES   (LAST_LINE_BYTES    )
    ) out_datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.fifo_out_datap_data                   (encoder_out_datap_byte             )
    
        ,.encoder_dst_line                      (encoder_dst_line                   )
        ,.encoder_dst_parity                    (encoder_dst_parity                 )
                                                                                    
        ,.out_ctrl_out_datap_init_state         (out_ctrl_out_datap_init_state      )
        ,.out_ctrl_out_datap_store_data         (out_ctrl_out_datap_store_data      )
        ,.out_ctrl_out_datap_store_parity       (out_ctrl_out_datap_store_parity    )
        ,.out_ctrl_out_datap_incr_line_count    (out_ctrl_out_datap_incr_line_count )
        ,.out_datap_out_ctrl_last_line_byte     (out_datap_out_ctrl_last_line_byte  )
        ,.out_datap_out_ctrl_last_line          (out_datap_out_ctrl_last_line       )
        ,.out_datap_out_ctrl_last_parity        (out_datap_out_ctrl_last_parity     )
    );
endmodule
