#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : constants.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 03.06.2022
# Last Modified Date: 05.06.2022
import os
import glob
import copy
import math

class cfg_const:
    regression_setup = ['32', '64']
    CLK_100MHz  = (10, "ns")
    CLK_200MHz  = (5, "ns")
    RST_CYCLES  = 3
    TIMEOUT_AXI = (CLK_100MHz[0]*200, "ns")
    TIMEOUT_IRQ = (CLK_100MHz[0]*100, "ns")

    TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
    RTL_DIR   = os.path.join(TESTS_DIR,"../../rtl/")
    INC_DIR   = [f'{RTL_DIR}inc']
    TOPLEVEL  = str(os.getenv("DUT"))
    SIMULATOR = str(os.getenv("SIM"))
    VERILOG_SOURCES = [] # The sequence below is important...
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}inc/*.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}inc/*.svh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}**/*.sv',recursive=True)
    EXTRA_ENV = {}
    # EXTRA_ENV['COCOTB_HDL_TIMEUNIT'] = os.getenv("TIMEUNIT")
    # EXTRA_ENV['COCOTB_HDL_TIMEPRECISION'] = os.getenv("TIMEPREC")
    if SIMULATOR == "verilator":
        EXTRA_ARGS = ["--trace-fst","--coverage","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
    else:
        EXTRA_ARGS = []

    DMA_CFG_32b = {}
    DMA_CFG_64b = {}

    DMA_CFG_32b['axi_addr_width'] = 32
    DMA_CFG_32b['axi_data_width'] = 32

    DMA_CFG_64b['axi_addr_width'] = 32
    DMA_CFG_64b['axi_data_width'] = 64

    EXTRA_ARGS_32b = copy.deepcopy(EXTRA_ARGS)
    EXTRA_ARGS_64b = copy.deepcopy(EXTRA_ARGS)

    for param in DMA_CFG_32b.items():
        EXTRA_ARGS_32b.append("-D"+param[0].upper()+"="+str(param[1]))
    for param in DMA_CFG_64b.items():
        EXTRA_ARGS_64b.append("-D"+param[0].upper()+"="+str(param[1]))

    def _get_cfg_args(flavor):
        if flavor == "32":
            return cfg_const.EXTRA_ARGS_32b
        elif flavor == "64":
            return cfg_const.EXTRA_ARGS_64b
        else:
            return cfg_const.EXTRA_ARGS_64b
