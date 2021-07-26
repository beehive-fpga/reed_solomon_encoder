vcom ../src/rs_encode.vhd

vlog -sv -f rs_encode.flist

vsim -voptargs=+acc rs_encode_topsim -wlf vsim.wlf -l vsim.log
log * -r