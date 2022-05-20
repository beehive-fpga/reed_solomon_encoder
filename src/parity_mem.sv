module parity_mem #(
     parameter NUM_MEMS=-1
    ,parameter LOG2_DEPTH=-1
    ,parameter ADDR_W=LOG2_DEPTH
    ,parameter DATA_W=-1
    ,parameter PARITY_W=-1
)(
     input clk
    ,input rst

    ,input                          wr_req_val
    ,input  logic   [ADDR_W-1:0]    wr_req_addr
    ,input  logic   [PARITY_W-1:0]  wr_req_data


    ,input                          rd_req_val
    ,input  logic   [ADDR_W-1:0]    rd_req_addr
    
    ,output logic                   rd_resp_val
    ,output logic   [DATA_W-1:0]    rd_resp_data
    ,input  logic                   rd_resp_rdy
);
    localparam ADDR_SHIFT = $clog2(NUM_MEMS);
    localparam NUM_MEMS_W = NUM_MEMS == 1 ? 1 : $clog2(NUM_MEMS);
    localparam MEM_ELS = (2**LOG2_DEPTH)/NUM_MEMS;
    localparam MEM_ADDR_W = $clog2(MEM_ELS);

    logic   [NUM_MEMS-1:0]      wr_vals;
    logic   [MEM_ADDR_W-1:0]    wr_addr;
    logic   [NUM_MEMS_W-1:0]    wr_mem_sel;

    logic   [NUM_MEMS-1:0]                  rd_resp_vals;
    logic   [NUM_MEMS-1:0][PARITY_W-1:0]    rd_resp_datas;

    assign rd_resp_val = |rd_resp_vals;
    assign rd_resp_data = rd_resp_datas;

    assign wr_addr = wr_req_addr >> ADDR_SHIFT;

    assign wr_mem_sel = wr_req_addr[NUM_MEMS_W-1:0];

    demux #(
         .NUM_OUTPUTS   (NUM_MEMS   )
        ,.INPUT_WIDTH   (1          )
    ) mem_demux (
         .input_sel     (wr_mem_sel )
        ,.data_input    (wr_req_val )
        ,.data_outputs  (wr_vals    )
    );


    genvar i;
    generate
        for (i = 0; i < NUM_MEMS; i = i + 1) begin
            ram_1r1w_sync_backpressure #(
                 .width_p   (PARITY_W   )
                ,.els_p     (MEM_ELS    )
            ) parity_mem (
                 .clk   (clk    )
                ,.rst   (rst    )
            
                ,.wr_req_val    (wr_vals[i]                     )
                ,.wr_req_addr   (wr_addr                        )
                ,.wr_req_data   (wr_req_data                    )
                ,.wr_req_rdy    ()
            
                ,.rd_req_val    (rd_req_val                     )
                ,.rd_req_addr   (rd_req_addr[MEM_ADDR_W-1:0]    )
                ,.rd_req_rdy    ()
            
                ,.rd_resp_val   (rd_resp_vals[i]                )
                ,.rd_resp_data  (rd_resp_datas[i]               )
                ,.rd_resp_rdy   (rd_resp_rdy                    )
            );
        end
    endgenerate
endmodule
