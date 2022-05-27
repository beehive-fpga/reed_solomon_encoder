// Warning: this module expects that the number of blocks fed in is a multiple of
// the number of RS encoders instantiated
import rs_encode_pkg::*;
module rs_encoder_line_32_mux #(
     parameter DATA_W=-1
    ,parameter DATA_BYTES = DATA_W/8
    ,parameter DATA_BYTES_W = $clog2(DATA_BYTES)
    ,parameter NUM_LINES=-1
    ,parameter PARITY_W=-1
    ,parameter NUM_RS_UNITS=32
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
    localparam NUM_RS_UNITS_W = $clog2(NUM_RS_UNITS);

    logic   [NUM_RS_UNITS-1:0]                  encoder_reducer_vals;
    logic   [NUM_RS_UNITS-1:0][DATA_W-1:0]      encoder_reducer_datas;
    logic   [NUM_RS_UNITS-1:0][PARITY_W-1:0]    encoder_reducer_parities;
    logic   [NUM_RS_UNITS-1:0]                  reducer_encoder_rdys;

    genvar rs_i;
    generate
        for (rs_i = 0; rs_i < NUM_RS_UNITS; rs_i = rs_i + 1) begin
            rs_encode_line_wrap #(
                 .DATA_W    (DATA_W     )
                ,.NUM_LINES (NUM_LINES  )
                ,.PARITY_W  (PARITY_W   )
            ) rs_encode_line_wrap (
                 .clk   (clk    )
                ,.rst   (rst    )
            
                ,.src_encoder_line_val  (src_encoder_line_vals[rs_i]    )
                ,.src_encoder_line      (src_encoder_line               )
                ,.encoder_src_line_rdy  (encoder_src_line_rdys[rs_i]    )
            
                ,.encoder_dst_line_val  (encoder_reducer_vals[rs_i]     )
                ,.encoder_dst_line      (encoder_reducer_datas[rs_i]    )
                ,.encoder_dst_parity    (encoder_reducer_parities[rs_i] )
                ,.dst_encoder_line_rdy  (reducer_encoder_rdys[rs_i]     )
            );
        end
    endgenerate

    rs_line_32_to_1 #(
         .DATA_W    (DATA_W     )
        ,.PARITY_W  (PARITY_W   )
        ,.NUM_LINES (NUM_LINES  )
    ) rs_reducer (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_1_line_vals      (encoder_reducer_vals       )
        ,.src_n_to_1_line_datas     (encoder_reducer_datas      )
        ,.src_n_to_1_line_parities  (encoder_reducer_parities   )
        ,.n_to_1_src_line_rdys      (reducer_encoder_rdys       )
    
        ,.n_to_1_dst_line_val       (encoder_dst_line_val       )
        ,.n_to_1_dst_line_data      (encoder_dst_line           )
        ,.n_to_1_dst_line_parity    (encoder_dst_parity         )
        ,.dst_n_to_1_line_rdy       (dst_encoder_line_rdy       )
    );
endmodule
