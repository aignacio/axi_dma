#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_dma_single_desc.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 03.06.2022
# Last Modified Date: 15.06.2022
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

async def run_test(dut, config_clk="100MHz", idle_inserter=None, backpressure_inserter=None):
    dma_flavor = os.getenv("FLAVOR")
    dma_cfg = cfg_const
    mem_size = 8*1024 #8KB

    # Setup testbench
    idle = "no_idle" if idle_inserter == None else "w_idle"
    backp = "no_backpressure" if backpressure_inserter == None else "w_backpressure"
    tb = Tb(dut=dut, log_name=f"sim_{config_clk}_{idle}_{backp}", cfg=dma_cfg, flavor=dma_flavor, ram_size=mem_size)
    sim_settings = tb.get_settings()
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    await tb.setup_clks(config_clk)
    await tb.rst(config_clk)

    #------------ Init test ------------#
    bb         = sim_settings['bb']
    max_data   = sim_settings['max_data']
    h_mem_size = mem_size//2
    size_desc  = h_mem_size
    src_addr   = 0
    dest_addr  = h_mem_size
    num_bytes  = size_desc
    wr_mode    = 0
    rd_mode    = 0
    desc_sel   = randint(0,dma_cfg.NUM_DESC-1)
    tb.log.info("Filling up data to be transfered - (0B -> {h_mem_size}B)")
    tb.fill_ram([(i*bb, randint(0, max_data)) for i in range(size_desc//bb)])
    tb.log.info("Filling up data to be overwritten - ({h_mem_size}B -> {mem_size}B)")
    tb.fill_ram([(h_mem_size+i*bb, randint(0, max_data)) for i in range(size_desc//bb)])
    tb.log.info("Programing descriptor {desc_sel}:")
    tb.log.info("Start addr  = [%s]", hex(src_addr))
    tb.log.info("End address = [%s]", hex(dest_addr))
    tb.log.info("Size bytes  = [%s]", num_bytes)
    dma_desc = {}
    dma_desc['DMA_DESC_SRC_ADDR_'+str(desc_sel)]   = src_addr
    dma_desc['DMA_DESC_DST_ADDR_'+str(desc_sel)]   = dest_addr
    dma_desc['DMA_DESC_NUM_BYTES_'+str(desc_sel)]  = num_bytes
    dma_desc['DMA_DESC_ENABLE_'+str(desc_sel)]     = (1<<2|rd_mode<<1|wr_mode)
    await tb.prg_desc(dma_desc)
    tb.log.info("Checking data mismatch prior to the DMA run")
    for i in range(0,h_mem_size,bb):
        assert tb.axi_ram.read(i, bb) != tb.axi_ram.read(h_mem_size+i, bb)
    tb.log.info("Start DMA GO")
    await tb.start_dma()
    await tb.wait_done()
    tb.log.info("Checking data was transfered after DMA run")
    for i in range(0,h_mem_size,bb):
        assert tb.axi_ram.read(i, bb) == tb.axi_ram.read(h_mem_size+i, bb)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(test_function=run_test)
    # factory.add_option("config_clk", ["100MHz", "200MHz"])
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
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