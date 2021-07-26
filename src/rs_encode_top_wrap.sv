module rs_encode_top_wrap (
     input clk
    ,input rst_n

    ,input          src_encoder_start_encode
    ,input          src_encoder_data_enable
    ,input  [7:0]   src_encoder_data
    ,output         encoder_src_encoding

    ,output         encoder_dst_data_val
    ,output [7:0]   encoder_dst_data
);

    rs_encoder rs_encoder_vhdl (
         .i_clk     (clk    )
        ,.i_rstb    (rst_n  )
        ,.i_start_enc   (src_encoder_start_encode   )
        ,.i_data_ena    (src_encoder_data_enable    )
        ,.i_data        (src_encoder_data           )
        ,.o_encoding    (encoder_src_encoding       )

        ,.o_data_valid  (encoder_dst_data_val       )
        ,.o_data        (encoder_dst_data           )
    );
endmodule