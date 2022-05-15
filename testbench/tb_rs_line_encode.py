import logging
import random

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine
from cocotb.log import SimLog
from cocotb.utils import get_sim_time
import scapy

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from simple_val_rdy import SimpleValRdyFrame, SimpleValRdyBus
from simple_val_rdy import SimpleValRdyBusSource, SimpleValRdyBusSink

MIN_PKT_SIZE=64
DATA_W = 512
DATA_BYTES = int(DATA_W/8)
PARITY_BYTES=32
PARITY_W = 32 * 8
RS_N = 255
RS_K = 223
PAD_SIZE = 31
DATA_BLOCK_SIZE = RS_K - PAD_SIZE

async def reset(dut):
    dut.rst.setimmediatevalue(0)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.input_bus = SimpleValRdyBus(dut, {"val": "src_encoder_line_val",
                                     "data": "src_encoder_line",
                                     "rdy": "encoder_src_line_rdy"},
                                     data_width=DATA_W)
        self.input_op = SimpleValRdyBusSource(self.input_bus, dut.clk)

        self.output_bus = SimpleValRdyBus(dut, {"val": "encoder_dst_line_val",
                                      "data": "encoder_dst_data",
                                      "rdy": "dst_encoder_line_rdy"},
                                      data_width=DATA_W+PARITY_W)
        self.output_op = SimpleValRdyBusSink(self.output_bus, dut.clk)

async def recv_loop(tb, output_file):
    with open(output_file, "rb") as out_file:
        block_num = 0
        while True:
            tb.log.info(f"Block number {block_num}")
            ref_output = out_file.read(RS_N)
            if ref_output == bytearray():
                break
            num_data_lines = int(DATA_BLOCK_SIZE/DATA_BYTES)
            padding_lines = ((PAD_SIZE - 1) // DATA_BYTES) + 1

            out_data = bytearray()
            for i in range(0, num_data_lines):
                data_output = await tb.output_op.recv_resp()
                start_time = get_sim_time(units="ns")
                data = data_output.data.buff[0:DATA_BYTES]
                out_data.extend(data)
                if (block_num == 0):
                    tb.log.info(f"start: {start_time}")

                assert data == ref_output[i*DATA_BYTES:(i+1)*DATA_BYTES]

            last_output = await tb.output_op.recv_resp()
            out_data.extend(last_output.data.buff[0:PAD_SIZE])
            parity = last_output.data.buff[DATA_BYTES:]

            ref_parity = ref_output[RS_K:]
            ref_data = ref_output[:RS_K]

            if ref_data != out_data:
                await RisingEdge(tb.dut.clk)
                await RisingEdge(tb.dut.clk)
                await RisingEdge(tb.dut.clk)

                raise RuntimeError(f"expected data: {ref_data}, got: "
                        f"{out_data}")

            if parity != ref_parity:
                await RisingEdge(tb.dut.clk)
                await RisingEdge(tb.dut.clk)
                await RisingEdge(tb.dut.clk)

                raise RuntimeError(f"expected parity: {ref_parity}, got: "
                        f"{parity}")

            block_num += 1

async def send_loop(tb, input_file):
    with open(input_file, "rb") as in_file:
        end_of_file = False
        while not end_of_file:
            num_data_lines = int(DATA_BLOCK_SIZE/DATA_BYTES)
            padding_lines = ((PAD_SIZE - 1) // DATA_BYTES) + 1
            for i in range(0, num_data_lines):
                in_line = in_file.read(DATA_BYTES)
                if in_line == bytearray():
                    end_of_file = True
                    break
                await tb.input_op.send_buf(in_line)

            if end_of_file:
                break

            # read in the padding
            pad = in_file.read(PAD_SIZE)
            await tb.input_op.send_buf(bytearray([0]*DATA_BYTES))

@cocotb.test()
async def bus_test(dut):
    dut.src_encoder_line_val.setimmediatevalue(0)
    dut.src_encoder_line.setimmediatevalue(BinaryValue(value=0, n_bits=DATA_W))
    dut.dst_encoder_line_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())
#
    tb = TB(dut)
    await reset(dut)

    send_task = cocotb.start_soon(send_loop(tb, "rs_2blk_input.bin"))
    recv_task = cocotb.start_soon(recv_loop(tb, "rs_2blk_output.bin"))

    await Combine(send_task, recv_task)
    end_time = get_sim_time(units="ns")

    tb.log.info(f"end: {end_time}")

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

