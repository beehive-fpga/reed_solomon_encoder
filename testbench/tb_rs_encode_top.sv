module tb_rs_encode_top #(
     parameter DATA_W=512
    ,parameter NUM_LINES=4
    ,parameter PARITY_W=256
)(
     input clk
    ,input rst

    ,input  logic                           src_encoder_line_val
    ,input  logic   [DATA_W-1:0]            src_encoder_line
    ,output logic                           encoder_src_line_rdy

    ,output logic                           encoder_dst_line_val
    ,output logic   [(DATA_W+PARITY_W)-1:0] encoder_dst_data
    ,input  logic                           dst_encoder_line_rdy
);

    logic   [DATA_W-1:0]        encoder_dst_line;
    logic   [PARITY_W-1:0]      encoder_dst_parity;

    assign encoder_dst_data = {encoder_dst_line, encoder_dst_parity};

    rs_encode_line_wrap #(
         .DATA_W    (DATA_W     )
        ,.NUM_LINES (NUM_LINES  )
        ,.PARITY_W  (PARITY_W   )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_encoder_line_val  (src_encoder_line_val   )
        ,.src_encoder_line      (src_encoder_line       )
        ,.encoder_src_line_rdy  (encoder_src_line_rdy   )
    
        ,.encoder_dst_line_val  (encoder_dst_line_val   )
        ,.encoder_dst_line      (encoder_dst_line       )
        ,.encoder_dst_parity    (encoder_dst_parity     )
        ,.dst_encoder_line_rdy  (dst_encoder_line_rdy   )
    );
endmodule
