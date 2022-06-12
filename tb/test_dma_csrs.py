#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_dma_csrs.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 03.06.2022
# Last Modified Date: 12.06.2022
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
from random import randrange
from cocotbext.axi import AxiBus, AxiLiteBus, AxiMaster, AxiRam, AxiResp, AxiLiteMaster, AxiSlave
import itertools

@cocotb.test()
async def run_test(dut, config_clk="100MHz", idle_inserter=None, backpressure_inserter=None):
    dma_flavor = os.getenv("FLAVOR")
    dma_cfg = cfg_const

    # Setup testbench
    idle = "no_idle" if idle_inserter == None else "w_idle"
    backp = "no_backpressure" if backpressure_inserter == None else "w_backpressure"
    tb = Tb(dut, f"sim_{config_clk}_{idle}_{backp}", dma_cfg)
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    await tb.setup_clks(config_clk)
    await tb.rst(config_clk)

    #------------ Init test ------------#
    for csr in dma_cfg.DMA_CSRs:
        tb.log.info("CSR [%s - Addr: %s]", csr, hex(dma_cfg.DMA_CSRs[csr][0]))
        payload = bytearray(tb._get_random_string(length=4),'utf-8')
        payload_sent = int.from_bytes(payload, byteorder='little', signed=False)
        payload_sent = payload_sent & dma_cfg.DMA_CSRs[csr][1]
        req = await tb.write(address=dma_cfg.DMA_CSRs[csr][0], data=payload)
        assert req.resp == AxiResp.OKAY, "Error while writing"
        resp = await tb.read(address=dma_cfg.DMA_CSRs[csr][0], length=0x4)
        assert resp.resp == AxiResp.OKAY, "Error while reading"
        rd_from_csr = int.from_bytes(resp.data, byteorder='little', signed=False)
        tb.log.info("Value written = %d / Read value from CSR = %d", payload_sent, rd_from_csr)
        if dma_cfg.DMA_CSRs[csr][2] == 1:
            assert payload_sent == rd_from_csr, "Mismatch on DMA CSR RW"
        else:
            if csr == 'DMA_STATUS':
                assert (dma_cfg.DMA_CSRs[csr][1] == rd_from_csr) or (0x1CAFE == rd_from_csr), "Mismatch on DMA CSR RO"
            else:
                assert dma_cfg.DMA_CSRs[csr][1] == rd_from_csr, "Mismatch on DMA CSR RO"

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(test_function=run_test)
    # factory.add_option("config_clk", ["100MHz", "200MHz"])
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",cfg_const.regression_setup)
def test_dma_csrs(flavor):
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
