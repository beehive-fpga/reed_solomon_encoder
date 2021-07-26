`timescale 1ns/1ns
module rs_encode_topsim();
    localparam  CLOCK_PERIOD      = 10000;
    localparam  CLOCK_HALF_PERIOD = CLOCK_PERIOD/2;
    localparam  RST_TIME          = 10 * CLOCK_PERIOD;

    logic clk;
    logic rst_n;
    
    logic           tb_encoder_start_encode;
    logic           tb_encoder_data_enable;
    logic   [7:0]   tb_encoder_data;
    logic           encoder_tb_encoding;

    logic           encoder_tb_data_val;
    logic   [7:0]   encoder_tb_data;

    initial begin
        clk = 0;
        forever begin
            #(CLOCK_HALF_PERIOD) clk = ~clk;
        end
    end

    initial begin
        rst_n = 1'b0;
        #RST_TIME rst_n = 1'b1;
    end

    rs_encode_top_wrap DUT (
         .clk   (clk    )
        ,.rst_n (rst_n  )

        ,.src_encoder_start_encode  (tb_encoder_start_encode    )
        ,.src_encoder_data_enable   (tb_encoder_data_enable     )
        ,.src_encoder_data          (tb_encoder_data            )
        ,.encoder_src_encoding      (encoder_tb_encoding        )

        ,.encoder_dst_data_val      (encoder_tb_data_val        )
        ,.encoder_dst_data          (encoder_tb_data            )
    );

    integer i;
    initial begin
        tb_encoder_start_encode = 1'b0;
        tb_encoder_data_enable = 1'b0;
        tb_encoder_data = '0;
        @(posedge rst_n);

        @(posedge clk);
        @(posedge clk);
        tb_encoder_start_encode = 1'b1;
        @(posedge clk);
        for (i = 1; i <= 223; i = i + 1) begin
            tb_encoder_start_encode = 1'b0;
            tb_encoder_data_enable = 1'b1;
            tb_encoder_data = i;
            @(posedge clk);
        end 
        tb_encoder_data_enable = 1'b0;

        repeat(100) @(posedge clk);

        $stop;
    end
 
endmodule