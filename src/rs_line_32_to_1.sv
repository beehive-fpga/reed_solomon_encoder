// Reduce 32 lines to 1 via two 16 to 1s

module rs_line_32_to_1 #(
     parameter NUM_INPUTS = 32
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

    localparam REDUCE_15_0_ID = 0;
    localparam REDUCE_31_16_ID = 1;
    typedef struct packed {
        logic   [DATA_W-1:0]    data;
        logic   [PARITY_W-1:0]  parity;
    } fifo_struct;

    logic                   reduce_15_0_val;
    logic   [DATA_W-1:0]    reduce_15_0_data;
    logic   [PARITY_W-1:0]  reduce_15_0_parity;
    logic                   reduce_15_0_rdy;

    fifo_struct             reduce_15_0_fifo_wr_data;

    logic                   reduce_15_0_fifo_rd_req;
    logic                   reduce_15_0_fifo_rd_val;
    fifo_struct             reduce_15_0_fifo_rd_data;
    
    logic                   reduce_31_16_val;
    logic   [DATA_W-1:0]    reduce_31_16_data;
    logic   [PARITY_W-1:0]  reduce_31_16_parity;
    logic                   reduce_31_16_rdy;

    fifo_struct             reduce_31_16_fifo_wr_data;

    logic                   reduce_31_16_fifo_rd_req;
    logic                   reduce_31_16_fifo_rd_val;
    fifo_struct             reduce_31_16_fifo_rd_data;
    
    logic   [2-1:0]                src_rs_2_to_1_line_vals;
    logic   [2-1:0][DATA_W-1:0]    src_rs_2_to_1_line_datas;
    logic   [2-1:0][PARITY_W-1:0]  src_rs_2_to_1_line_parities;
    logic   [2-1:0]                rs_2_to_1_src_line_rdys;

    /*************************************************************
     * First set of reductions
     ************************************************************/
    rs_line_16_to_1 #(
         .DATA_W        (DATA_W     )
        ,.PARITY_W      (PARITY_W   )
        ,.NUM_LINES     (NUM_LINES  )
    ) reduce_15_0 (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_1_line_vals      (src_n_to_1_line_vals[15:0]     )
        ,.src_n_to_1_line_datas     (src_n_to_1_line_datas[15:0]    )
        ,.src_n_to_1_line_parities  (src_n_to_1_line_parities[15:0] )
        ,.n_to_1_src_line_rdys      (n_to_1_src_line_rdys[15:0]     )
                                                                
        ,.n_to_1_dst_line_val       (reduce_15_0_val                )
        ,.n_to_1_dst_line_data      (reduce_15_0_data               )
        ,.n_to_1_dst_line_parity    (reduce_15_0_parity             )
        ,.dst_n_to_1_line_rdy       (reduce_15_0_rdy                )
    );

    assign reduce_15_0_fifo_wr_data.data = reduce_15_0_data;
    assign reduce_15_0_fifo_wr_data.parity = reduce_15_0_parity;

    bsg_fifo_1r1w_small #( 
         .width_p   (DATA_W + PARITY_W)
        ,.els_p     (2)
        ,.harden_p  (1)
    ) reduce_15_0_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (reduce_15_0_val            )
        ,.ready_o   (reduce_15_0_rdy            )
        ,.data_i    (reduce_15_0_fifo_wr_data   )
    
        ,.v_o       (reduce_15_0_fifo_rd_val    )
        ,.data_o    (reduce_15_0_fifo_rd_data   )
        ,.yumi_i    (reduce_15_0_fifo_rd_req    )
    );

    assign reduce_15_0_fifo_rd_req = reduce_15_0_fifo_rd_val 
                                     & rs_2_to_1_src_line_rdys[REDUCE_15_0_ID];

    assign src_rs_2_to_1_line_vals[REDUCE_15_0_ID] = reduce_15_0_fifo_rd_val;
    assign src_rs_2_to_1_line_datas[REDUCE_15_0_ID] = reduce_15_0_fifo_rd_data.data;
    assign src_rs_2_to_1_line_parities[REDUCE_15_0_ID] = reduce_15_0_fifo_rd_data.parity;
    
    /*************************************************************
     * Second set of reductions
     ************************************************************/
    rs_line_16_to_1 #(
         .DATA_W        (DATA_W     )
        ,.PARITY_W      (PARITY_W   )
        ,.NUM_LINES     (NUM_LINES  )
    ) reduce_31_16 (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_1_line_vals      (src_n_to_1_line_vals[31:16]        )
        ,.src_n_to_1_line_datas     (src_n_to_1_line_datas[31:16]       )
        ,.src_n_to_1_line_parities  (src_n_to_1_line_parities[31:16]    )
        ,.n_to_1_src_line_rdys      (n_to_1_src_line_rdys[31:16]        )
                                                                
        ,.n_to_1_dst_line_val       (reduce_31_16_val                   )
        ,.n_to_1_dst_line_data      (reduce_31_16_data                  )
        ,.n_to_1_dst_line_parity    (reduce_31_16_parity                )
        ,.dst_n_to_1_line_rdy       (reduce_31_16_rdy                   )
    );

    assign reduce_31_16_fifo_wr_data.data = reduce_31_16_data;
    assign reduce_31_16_fifo_wr_data.parity = reduce_31_16_parity;

    bsg_fifo_1r1w_small #( 
         .width_p   (DATA_W + PARITY_W)
        ,.els_p     (2)
        ,.harden_p  (1)
    ) reduce_31_16_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (reduce_31_16_val            )
        ,.ready_o   (reduce_31_16_rdy            )
        ,.data_i    (reduce_31_16_fifo_wr_data   )
    
        ,.v_o       (reduce_31_16_fifo_rd_val    )
        ,.data_o    (reduce_31_16_fifo_rd_data   )
        ,.yumi_i    (reduce_31_16_fifo_rd_req    )
    );

    assign reduce_31_16_fifo_rd_req = reduce_31_16_fifo_rd_val 
                                     & rs_2_to_1_src_line_rdys[REDUCE_31_16_ID];

    assign src_rs_2_to_1_line_vals[REDUCE_31_16_ID] = reduce_31_16_fifo_rd_val;
    assign src_rs_2_to_1_line_datas[REDUCE_31_16_ID] = reduce_31_16_fifo_rd_data.data;
    assign src_rs_2_to_1_line_parities[REDUCE_31_16_ID] = reduce_31_16_fifo_rd_data.parity;

    /*************************************************************
     * Final reducer
     ************************************************************/
    rs_line_n_to_1 #(
         .NUM_INPUTS    (2  )
        ,.DATA_W        (DATA_W         )
        ,.PARITY_W      (PARITY_W       )
        ,.NUM_LINES     (NUM_LINES*16   )
    ) rs_2_to_1 (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_1_line_vals      (src_rs_2_to_1_line_vals    )
        ,.src_n_to_1_line_datas     (src_rs_2_to_1_line_datas   )
        ,.src_n_to_1_line_parities  (src_rs_2_to_1_line_parities)
        ,.n_to_1_src_line_rdys      (rs_2_to_1_src_line_rdys    )
    
        ,.n_to_1_dst_line_val       (n_to_1_dst_line_val        )
        ,.n_to_1_dst_line_data      (n_to_1_dst_line_data       )
        ,.n_to_1_dst_line_parity    (n_to_1_dst_line_parity     )
        ,.dst_n_to_1_line_rdy       (dst_n_to_1_line_rdy        )
    );
endmodule
