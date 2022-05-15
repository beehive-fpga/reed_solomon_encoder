# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../src/include/rs_encode_pkg.sv
VERILOG_SOURCES += $(PWD)/bsg_defines.v
VERILOG_SOURCES += $(PWD)/fifo_1r1w.sv
VERILOG_SOURCES += $(PWD)/ram_1r1w_sync_backpressure.sv
VERILOG_SOURCES += $(PWD)/bsg_mem_1r1w_sync.sv
VERILOG_SOURCES += $(PWD)/bsg_mem_1r1w_sync_synth.sv
VERILOG_SOURCES += $(PWD)/../src/rs_encode_line_in_ctrl.sv
VERILOG_SOURCES += $(PWD)/../src/rs_encode_line_in_datap.sv
VERILOG_SOURCES += $(PWD)/../src/rs_encode_line_out_ctrl.sv
VERILOG_SOURCES += $(PWD)/../src/rs_encode_line_out_datap.sv
VERILOG_SOURCES += $(PWD)/../src/rs_encode_top_wrap.sv
VERILOG_SOURCES += $(PWD)/../src/rs_line_wrap.sv
VERILOG_SOURCES += $(PWD)/tb_rs_encode_top.sv

VHDL_SOURCES += $(PWD)/../src/rs_encode.vhd

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_rs_encode_top

# MODULE is the basename of the Python test file
MODULE = tb_rs_line_encode

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

