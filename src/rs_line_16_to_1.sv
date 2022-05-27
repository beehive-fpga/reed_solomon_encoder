// Reduce 16 lines to 1 via two tiers of 4 to 1s
module rs_line_16_to_1 #(
     parameter NUM_INPUTS = 16
    ,parameter DATA_W = -1
    ,parameter PARITY_W = -1
    ,parameter NUM_LINES = -1
)(
     input clk
    ,input rst

    ,input  [NUM_INPUTS-1:0]                src_n_to_1_line_vals
    ,input  [NUM_INPUTS-1:0][DATA_W-1:0]    src_n_to_1_line_datas
    ,input  [NUM_INPUTS-1:0][PARITY_W-1:0]  src_n_to_1_line_parities
    ,output [NUM_INPUTS-1:0]                n_to_1_src_line_rdys

    ,output                                 n_to_1_dst_line_val
    ,output [DATA_W-1:0]                    n_to_1_dst_line_data
    ,output [PARITY_W-1:0]                  n_to_1_dst_line_parity
    ,input                                  dst_n_to_1_line_rdy
);
    localparam N_TO_1 = 4;
    localparam NUM_REDUCE_TIER_1 = NUM_INPUTS/N_TO_1;
    localparam TIER_2_NUM_LINES = NUM_LINES * N_TO_1;
    
    typedef struct packed {
        logic   [DATA_W-1:0]    data;
        logic   [PARITY_W-1:0]  parity;
    } fifo_struct;
    localparam FIFO_STRUCT_W = DATA_W + PARITY_W;


    logic   [NUM_REDUCE_TIER_1-1:0]                src_rs_4_to_1_line_vals;
    logic   [NUM_REDUCE_TIER_1-1:0][DATA_W-1:0]    src_rs_4_to_1_line_datas;
    logic   [NUM_REDUCE_TIER_1-1:0][PARITY_W-1:0]  src_rs_4_to_1_line_parities;
    logic   [NUM_REDUCE_TIER_1-1:0]                rs_4_to_1_src_line_rdys;
    
    logic   [NUM_REDUCE_TIER_1-1:0]                 reducer_fifo_vals;
    logic   [NUM_REDUCE_TIER_1-1:0][DATA_W-1:0]     reducer_fifo_datas;
    logic   [NUM_REDUCE_TIER_1-1:0][PARITY_W-1:0]   reducer_fifo_parities;
    logic   [NUM_REDUCE_TIER_1-1:0]                 reducer_fifo_rdys;

    logic   [NUM_REDUCE_TIER_1-1:0][FIFO_STRUCT_W-1:0]  reducer_fifo_wr_datas;
    
    logic   [NUM_REDUCE_TIER_1-1:0]                 reducer_fifo_rd_reqs;
    logic   [NUM_REDUCE_TIER_1-1:0]                 reducer_fifo_rd_vals;
    logic   [NUM_REDUCE_TIER_1-1:0][FIFO_STRUCT_W-1:0]  reducer_fifo_rd_datas;
   
    // i don't trust a packed array of packed structs, so we're here
    fifo_struct             reducer0_fifo_wr_data;
    fifo_struct             reducer0_fifo_rd_data;
    fifo_struct             reducer1_fifo_wr_data;
    fifo_struct             reducer1_fifo_rd_data;
    fifo_struct             reducer2_fifo_wr_data;
    fifo_struct             reducer2_fifo_rd_data;
    fifo_struct             reducer3_fifo_wr_data;
    fifo_struct             reducer3_fifo_rd_data;

    assign reducer0_fifo_wr_data.data = reducer_fifo_datas[0];
    assign reducer0_fifo_wr_data.parity = reducer_fifo_parities[0];
    assign reducer1_fifo_wr_data.data = reducer_fifo_datas[1];
    assign reducer1_fifo_wr_data.parity = reducer_fifo_parities[1];
    assign reducer2_fifo_wr_data.data = reducer_fifo_datas[2];
    assign reducer2_fifo_wr_data.parity = reducer_fifo_parities[2];
    assign reducer3_fifo_wr_data.data = reducer_fifo_datas[3];
    assign reducer3_fifo_wr_data.parity = reducer_fifo_parities[3];

    assign reducer_fifo_wr_datas[0] = reducer0_fifo_wr_data;
    assign reducer_fifo_wr_datas[1] = reducer1_fifo_wr_data;
    assign reducer_fifo_wr_datas[2] = reducer2_fifo_wr_data;
    assign reducer_fifo_wr_datas[3] = reducer3_fifo_wr_data;

genvar tier_1_i;
generate
    for (tier_1_i = 0; tier_1_i < NUM_REDUCE_TIER_1; tier_1_i = tier_1_i + 1) begin
        rs_line_n_to_1 #(
             .NUM_INPUTS    (N_TO_1     )
            ,.DATA_W        (DATA_W     )
            ,.PARITY_W      (PARITY_W   )
            ,.NUM_LINES     (NUM_LINES  )
        ) rs_4_to_1 (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_n_to_1_line_vals    (src_n_to_1_line_vals[((tier_1_i+1)*N_TO_1)-1:tier_1_i*N_TO_1]    )
            ,.src_n_to_1_line_datas   (src_n_to_1_line_datas[((tier_1_i+1)*N_TO_1)-1:tier_1_i*N_TO_1]   )
            ,.src_n_to_1_line_parities(src_n_to_1_line_parities[((tier_1_i+1)*N_TO_1)-1:tier_1_i*N_TO_1])
            ,.n_to_1_src_line_rdys    (n_to_1_src_line_rdys[((tier_1_i+1)*N_TO_1)-1:tier_1_i*N_TO_1]    )
        
            ,.n_to_1_dst_line_val     (reducer_fifo_vals[tier_1_i]      )
            ,.n_to_1_dst_line_data    (reducer_fifo_datas[tier_1_i]     )
            ,.n_to_1_dst_line_parity  (reducer_fifo_parities[tier_1_i]  )
            ,.dst_n_to_1_line_rdy     (reducer_fifo_rdys[tier_1_i]      )
        );
    
        bsg_fifo_1r1w_small #( 
             .width_p   (DATA_W + PARITY_W)
            ,.els_p     (2)
            ,.harden_p  (1)
        ) reducer_fifo ( 
             .clk_i     (clk    )
            ,.reset_i   (rst    )
        
            ,.v_i       (reducer_fifo_vals[tier_1_i]    )
            ,.ready_o   (reducer_fifo_rdys[tier_1_i]    )
            ,.data_i    (reducer_fifo_wr_datas[tier_1_i])
        
            ,.v_o       (reducer_fifo_rd_vals[tier_1_i]     )
            ,.data_o    (reducer_fifo_rd_datas[tier_1_i]    )
            ,.yumi_i    (reducer_fifo_rd_reqs[tier_1_i]     )
        );

        assign reducer_fifo_rd_reqs[tier_1_i] = rs_4_to_1_src_line_rdys[tier_1_i] &
                                                reducer_fifo_rd_vals[tier_1_i];
    end
endgenerate

    assign reducer0_fifo_rd_data = reducer_fifo_rd_datas[0];
    assign reducer1_fifo_rd_data = reducer_fifo_rd_datas[1];
    assign reducer2_fifo_rd_data = reducer_fifo_rd_datas[2];
    assign reducer3_fifo_rd_data = reducer_fifo_rd_datas[3];

    assign src_rs_4_to_1_line_datas[0] = reducer0_fifo_rd_data.data;
    assign src_rs_4_to_1_line_datas[1] = reducer1_fifo_rd_data.data;
    assign src_rs_4_to_1_line_datas[2] = reducer2_fifo_rd_data.data;
    assign src_rs_4_to_1_line_datas[3] = reducer3_fifo_rd_data.data;
    
    assign src_rs_4_to_1_line_parities[0] = reducer0_fifo_rd_data.parity;
    assign src_rs_4_to_1_line_parities[1] = reducer1_fifo_rd_data.parity;
    assign src_rs_4_to_1_line_parities[2] = reducer2_fifo_rd_data.parity;
    assign src_rs_4_to_1_line_parities[3] = reducer3_fifo_rd_data.parity;

    assign src_rs_4_to_1_line_vals = reducer_fifo_rd_vals;

    rs_line_n_to_1 #(
         .NUM_INPUTS    (NUM_REDUCE_TIER_1  )
        ,.DATA_W        (DATA_W             )
        ,.PARITY_W      (PARITY_W           )
        // we need to collect all the lines from all of the encoders in the
        // first tier, so there are actually 4 * TIER_2_NUM_LINES to be read
        // before advancing the mux
        ,.NUM_LINES     (TIER_2_NUM_LINES   )
    ) rs_last_4_to_1 (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_1_line_vals      (src_rs_4_to_1_line_vals    )
        ,.src_n_to_1_line_datas     (src_rs_4_to_1_line_datas   )
        ,.src_n_to_1_line_parities  (src_rs_4_to_1_line_parities)
        ,.n_to_1_src_line_rdys      (rs_4_to_1_src_line_rdys    )
    
        ,.n_to_1_dst_line_val       (n_to_1_dst_line_val        )
        ,.n_to_1_dst_line_data      (n_to_1_dst_line_data       )
        ,.n_to_1_dst_line_parity    (n_to_1_dst_line_parity     )
        ,.dst_n_to_1_line_rdy       (dst_n_to_1_line_rdy        )
    );

endmodule
