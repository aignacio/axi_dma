#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : constants.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 03.06.2022
# Last Modified Date: 09.06.2022
import os
import glob
import copy
import math

class cfg_const:
    ################### Configure ####################
    regression_setup = ['32', '64']
    RST_CYCLES  = 3
    TIMEOUT_VAL = 100

    DMA_CFG_32b = {}
    DMA_CFG_32b['axi_addr_width'] = 32
    DMA_CFG_32b['axi_data_width'] = 32

    DMA_CFG_64b = {}
    DMA_CFG_64b['axi_addr_width'] = 32
    DMA_CFG_64b['axi_data_width'] = 64

    DMA_CSRs = {}
    #-------------------------------> Addr     Mask       RW
    DMA_CSRs['DMA_CONTROL']        = (0x0000, 0x3,        1)
    DMA_CSRs['DMA_STATUS']         = (0x0008, 0xCAFE,     0)
    DMA_CSRs['DMA_ERROR_ADDR']     = (0x0010, 0x0,        0)
    DMA_CSRs['DMA_ERROR_MISC']     = (0x0018, 0x0,        0)
    NUM_DESC       = 5
    PER_DESC_CSRS  = 4
    CSR_ADDR_ALIG  = 8
    BASE_ADDR_DESC = 0x20
    for desc in range(BASE_ADDR_DESC, BASE_ADDR_DESC+NUM_DESC*PER_DESC_CSRS*CSR_ADDR_ALIG, PER_DESC_CSRS*CSR_ADDR_ALIG):
        DMA_CSRs['DMA_DESC_SRC_ADDR_' +str(desc//BASE_ADDR_DESC)] = (desc,       0xFFFFFFFF, 1)
        DMA_CSRs['DMA_DESC_DEST_ADDR_'+str(desc//BASE_ADDR_DESC)] = (desc+(1*8), 0xFFFFFFFF, 1)
        DMA_CSRs['DMA_DESC_NUM_BYTES_'+str(desc//BASE_ADDR_DESC)] = (desc+(2*8), 0xFFFFFFFF, 1)
        DMA_CSRs['DMA_DESC_WRITE_MOD_'+str(desc//BASE_ADDR_DESC)] = (desc+(3*8), 0x7,        1)
        DMA_CSRs['DMA_DESC_READ_MOD_' +str(desc//BASE_ADDR_DESC)] = (desc+(3*8), 0x7,        1)
        DMA_CSRs['DMA_DESC_ENABLE_'   +str(desc//BASE_ADDR_DESC)] = (desc+(3*8), 0x7,        1)
    ################### Configure ####################

    CLK_100MHz  = (10, "ns")
    CLK_200MHz  = (5, "ns")
    TIMEOUT_AXI = (CLK_100MHz[0]*TIMEOUT_VAL, "ns")
    TIMEOUT_IRQ = (CLK_100MHz[0]*TIMEOUT_VAL, "ns")

    TOPLEVEL  = str(os.getenv("DUT"))
    SIMULATOR = str(os.getenv("SIM"))
    EXTRA_ENV = {}
    EXTRA_ENV['COCOTB_HDL_TIMEUNIT'] = os.getenv("TIMEUNIT")
    EXTRA_ENV['COCOTB_HDL_TIMEPRECISION'] = os.getenv("TIMEPREC")

    TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
    RTL_DIR   = os.path.join(TESTS_DIR,"../../rtl/")
    RGGEN_V_DIR = os.path.join(TESTS_DIR,"../../rggen-verilog-rtl/")
    CSR_RGGEN_DIR = os.path.join(TESTS_DIR,"../../csr_out/")
    INC_DIR   = [f'{RTL_DIR}inc',f'{RGGEN_V_DIR}']
    VERILOG_SOURCES = [] # The sequence below is important...
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}inc/*.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}inc/*.svh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}**/*.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{CSR_RGGEN_DIR}**/*.v',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RGGEN_V_DIR}**/*.v',recursive=True)
    COMPILE_ARGS = ["-f","/axi_dma/verilator.flags"]
    if SIMULATOR == "verilator":
        EXTRA_ARGS = ["--trace-fst","--coverage","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
    else:
        EXTRA_ARGS = []

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
