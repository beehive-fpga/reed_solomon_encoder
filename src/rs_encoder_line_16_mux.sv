module rs_encoder_line_16_mux #(
     parameter NUM_RS_UNITS = 16
    ,parameter DATA_W = -1
    ,parameter PARITY_W = -1
    ,parameter NUM_LINES = -1
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

    typedef struct packed {
        logic   [DATA_W-1:0]    data;
        logic   [PARITY_W-1:0]  parity;
    } fifo_struct;
    
    logic   [NUM_RS_UNITS-1:0]                  encoder_reducer_vals;
    logic   [NUM_RS_UNITS-1:0][DATA_W-1:0]      encoder_reducer_datas;
    logic   [NUM_RS_UNITS-1:0][PARITY_W-1:0]    encoder_reducer_parities;
    logic   [NUM_RS_UNITS-1:0]                  reducer_encoder_rdys;

    logic                   reducer_fifo_val;
    logic   [DATA_W-1:0]    reducer_fifo_data;
    logic   [PARITY_W-1:0]  reducer_fifo_parity;
    logic                   fifo_reducer_rdy;
    fifo_struct             fifo_wr_data;

    logic                   fifo_rd_req;
    fifo_struct             fifo_rd_data;
    
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

    rs_line_16_to_1 #(
         .DATA_W    (DATA_W     )
        ,.PARITY_W  (PARITY_W   )
        ,.NUM_LINES (NUM_LINES  )
    ) reducer_16_to_1 (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_1_line_vals      (encoder_reducer_vals       )
        ,.src_n_to_1_line_datas     (encoder_reducer_datas      )
        ,.src_n_to_1_line_parities  (encoder_reducer_parities   )
        ,.n_to_1_src_line_rdys      (reducer_encoder_rdys       )
    
        ,.n_to_1_dst_line_val       (reducer_fifo_val           )
        ,.n_to_1_dst_line_data      (reducer_fifo_data          )
        ,.n_to_1_dst_line_parity    (reducer_fifo_parity        )
        ,.dst_n_to_1_line_rdy       (fifo_reducer_rdy           )
    );

    assign fifo_wr_data.data = reducer_fifo_data;
    assign fifo_wr_data.parity = reducer_fifo_parity;
        
    bsg_fifo_1r1w_small #( 
         .width_p   (DATA_W + PARITY_W)
        ,.els_p     (2)
        ,.harden_p  (1)
    ) reducer_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (reducer_fifo_val       )
        ,.ready_o   (fifo_reducer_rdy       )
        ,.data_i    (fifo_wr_data           )
    
        ,.v_o       (encoder_dst_line_val   )
        ,.data_o    (fifo_rd_data           )
        ,.yumi_i    (fifo_rd_req            )
    );

    assign encoder_dst_line = fifo_rd_data.data;
    assign encoder_dst_parity = fifo_rd_data.parity;
    assign fifo_rd_req = encoder_dst_line_val & dst_encoder_line_rdy;

endmodule
