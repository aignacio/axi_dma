#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_dma_unaligned.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 03.06.2022
# Last Modified Date: 16.10.2022
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
from common.dma import dma_desc, dma_mode, dma_addr, dma_ctrl
from common.dma import dma_error_stats, dma_err_type, dma_err_src
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

    if (dma_flavor == "small"):
        return True
    #------------ Init test ------------#
    bb       = sim_settings['bb']
    max_data = sim_settings['max_data']
    desc_sel = randint(0,dma_cfg.NUM_DESC-1)

    for i in range(bb):
        h_mem_size = mem_size//2
        size_desc  = h_mem_size
        src_addr   = i
        dest_addr  = h_mem_size+i
        num_bytes  = size_desc
        tb.log.info("Filling up data to be transfered - (0B -> %dB)",h_mem_size)
        tb.fill_ram([(i*bb, randint(0, max_data)) for i in range(size_desc//bb)])
        tb.log.info("Filling up data to be overwritten - (%dB -> %dB)", h_mem_size, mem_size)
        tb.fill_ram([(h_mem_size+i*bb, randint(0, max_data)) for i in range(size_desc//bb)])
        desc = []
        desc.append(dma_desc(desc_sel, src_addr, dest_addr, num_bytes, dma_mode.INCR, dma_mode.INCR, 1))
        await tb.prg_desc(desc)
        tb.log.info("Checking data mismatch prior to the DMA run")
        for i in range(0,h_mem_size,bb):
            tb.log.debug("%s", tb.axi_ram.hexdump_str(h_mem_size+i,bb))
            assert tb.axi_ram.read(i, bb) != tb.axi_ram.read(h_mem_size+i, bb)
        tb.log.info("Start DMA GO")
        await tb.start_dma()
        await tb.wait_done()
        tb.log.info("Checking data was transfered after DMA run")
        if bb == 4:
            next_aligned_addr = (i+bb) & 0xFFFFFFFC
        else:
            next_aligned_addr = (i+bb) & 0xFFFFFFF8
        for addr in range(next_aligned_addr,h_mem_size,bb):
            tb.log.debug("%s", tb.axi_ram.hexdump_str(h_mem_size+addr,bb))
            assert tb.axi_ram.read(addr, bb) == tb.axi_ram.read(h_mem_size+addr, bb)
        await tb.stop_dma()

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(test_function=run_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",cfg_const.regression_setup)
def test_dma_unaligned(flavor):
    """
    Test ID: 8
    Description:
    Test different unaligned addresses in the descriptors.
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
