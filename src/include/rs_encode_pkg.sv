package rs_encode_pkg;
    localparam RS_WORD_W = 8;
    localparam RS_N = (1 << RS_WORD_W) - 1;
    localparam RS_K = 223;
    localparam RS_T = RS_N - RS_K;
    localparam RS_DATA_PADDING = 31;
    localparam RS_DATA_BYTES = RS_K - RS_DATA_PADDING;
    localparam RS_DATA_BLOCK_SIZE = RS_N - RS_DATA_PADDING;

    localparam PARITY_W = RS_T * 8;
endpackage
