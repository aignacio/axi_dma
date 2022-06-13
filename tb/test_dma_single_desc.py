#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_dma_single_desc.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 03.06.2022
# Last Modified Date: 13.06.2022
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import random
import cocotb
import os
import logging
import pytest

from common.testbench import Tb
from common.constants import cfg_const
from cocotb.regression import TestFactory
from cocotb_test.simulator import run
from cocotb.result import TestFailure
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.result import SimTimeoutError
from random import randrange, randint
from cocotbext.axi import AxiBus, AxiLiteBus, AxiMaster, AxiRam, AxiResp, AxiLiteMaster, AxiSlave
import itertools

@cocotb.test()
async def run_test(dut, config_clk="100MHz", idle_inserter=None, backpressure_inserter=None):
    dma_flavor = os.getenv("FLAVOR")
    dma_cfg = cfg_const

    # Setup testbench
    idle = "no_idle" if idle_inserter == None else "w_idle"
    backp = "no_backpressure" if backpressure_inserter == None else "w_backpressure"
    tb = Tb(dut, f"sim_{config_clk}_{idle}_{backp}", dma_cfg, dma_flavor)
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    await tb.setup_clks(config_clk)
    await tb.rst(config_clk)

    #------------ Init test ------------#
    max_size_desc = 9*1024
    src_addr  = randint(0,pow(2,32)-1) #int(dma_flavor))-1)
    dest_addr = randint(0,pow(2,32)-1) #int(dma_flavor))-1)
    num_bytes = randint(1,max_size_desc)
    wr_mode   = randint(0,1)
    rd_mode   = randint(0,1)
    tb.log.info("Programing single descriptor:")
    tb.log.info("Start address [%s] - End address [%s] - Number of bytes [%s]", hex(src_addr), hex(dest_addr), num_bytes)
    dma_desc = {}
    desc_sel = randint(0,dma_cfg.NUM_DESC-1)
    dma_desc['DMA_DESC_SRC_ADDR_'+str(desc_sel)]   = src_addr
    dma_desc['DMA_DESC_DST_ADDR_'+str(desc_sel)]   = dest_addr
    dma_desc['DMA_DESC_NUM_BYTES_'+str(desc_sel)]  = num_bytes
    dma_desc['DMA_DESC_ENABLE_'+str(desc_sel)]     = (1<<2|rd_mode<<1|wr_mode)
    await tb.prg_desc(dma_desc)
    await tb.start_dma()
    for i in range(10):
        await RisingEdge(dut.clk)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(test_function=run_test)
    # factory.add_option("config_clk", ["100MHz", "200MHz"])
    # factory.add_option("idle_inserter", [None, cycle_pause])
    # factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",cfg_const.regression_setup)
def test_dma_single_desc(flavor):
    """
    Basic test that sends a packet over the NoC and checks it

    Test ID: 1

    Description:
    The simplest test to send a pkt over the NoC and checks it by reading back the correspondent destination router.
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(cfg_const.TESTS_DIR,
            f"../../run_dir/run_{cfg_const.SIMULATOR}_{module}_{flavor}")
    cfg_const.EXTRA_ENV['SIM_BUILD'] = SIM_BUILD
    cfg_const.EXTRA_ENV['FLAVOR'] = flavor
    extra_args_sim = cfg_const._get_cfg_args(flavor)

    run(
        python_search=[cfg_const.TESTS_DIR],
        includes=cfg_const.INC_DIR,
        verilog_sources=cfg_const.VERILOG_SOURCES,
        toplevel=cfg_const.TOPLEVEL,
        module=module,
        sim_build=SIM_BUILD,
        compile_args=cfg_const.COMPILE_ARGS,
        extra_env=cfg_const.EXTRA_ENV,
        extra_args=extra_args_sim
    )
