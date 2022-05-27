module rs_line_n_to_1 #(
     parameter NUM_INPUTS = -1
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
    localparam NUM_LINES_W = $clog2(NUM_LINES);
    localparam NUM_INPUTS_W = $clog2(NUM_INPUTS);

    logic   [NUM_INPUTS_W-1:0]  src_sel_reg;
    logic   [NUM_INPUTS_W-1:0]  src_sel_next;
    logic                       incr_src_reg;
    logic                       reset_src_reg;

    logic   [NUM_LINES_W-1:0]   line_cnt_reg;
    logic   [NUM_LINES_W-1:0]   line_cnt_next;
    logic                       incr_line_reg;
    logic                       reset_line_reg;

    logic                       last_line;
    assign last_line = line_cnt_reg == (NUM_LINES-1);

    always_ff @(posedge clk) begin
        if (rst) begin
            src_sel_reg <= '0;
            line_cnt_reg <= '0;
        end
        else begin
            src_sel_reg <= src_sel_next;
            line_cnt_reg <= line_cnt_next;
        end
    end

    bsg_mux #(
         .width_p   (1)
        ,.els_p     (NUM_INPUTS )
    ) src_vals_mux (
         .data_i    (src_n_to_1_line_vals   )
        ,.sel_i     (src_sel_reg            )
        ,.data_o    (n_to_1_dst_line_val    )
    );
    
    bsg_mux #(
         .width_p   (DATA_W     )
        ,.els_p     (NUM_INPUTS )
    ) src_datas_mux (
         .data_i    (src_n_to_1_line_datas  )
        ,.sel_i     (src_sel_reg            )
        ,.data_o    (n_to_1_dst_line_data   )
    );
    
    bsg_mux #(
         .width_p   (PARITY_W   )
        ,.els_p     (NUM_INPUTS )
    ) src_parities_mux (
         .data_i    (src_n_to_1_line_parities   )
        ,.sel_i     (src_sel_reg                )
        ,.data_o    (n_to_1_dst_line_parity     )
    );

    demux #(
         .NUM_OUTPUTS   (NUM_INPUTS )
        ,.INPUT_WIDTH   (1)
    ) src_rdys_demux (
         .input_sel     (src_sel_reg            )
        ,.data_input    (dst_n_to_1_line_rdy    )
        ,.data_outputs  (n_to_1_src_line_rdys   )
    );


    // deal with incrementing the src
    always_comb begin
        incr_src_reg = 1'b0;
        reset_src_reg = 1'b0;
        if (dst_n_to_1_line_rdy & n_to_1_dst_line_val) begin
            // are we on the last line from the selected input
            if (last_line) begin
                // are we on the last unit of the set of units
                if (src_sel_reg == (NUM_INPUTS-1)) begin
                    reset_src_reg = 1'b1;
                end
                else begin
                    incr_src_reg = 1'b1;
                end
            end
        end
    end

    // deal with incrementing the line count
    always_comb begin
        incr_line_reg = 1'b0;
        reset_line_reg = 1'b0;
        if (dst_n_to_1_line_rdy & n_to_1_dst_line_val) begin
            if (last_line) begin
                reset_line_reg = 1'b1;
            end
            else begin
                incr_line_reg = 1'b1;
            end
        end
    end

    assign line_cnt_next = reset_line_reg
                        ? '0
                        : incr_line_reg
                            ? line_cnt_reg + 1'b1
                            : line_cnt_reg;

    assign src_sel_next = reset_src_reg
                        ? '0
                        : incr_src_reg
                            ? src_sel_reg + 1'b1
                            : src_sel_reg;

endmodule
