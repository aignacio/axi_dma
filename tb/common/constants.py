#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : constants.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 03.06.2022
# Last Modified Date: 16.10.2022
import os
import glob
import copy
import math

class cfg_const:
    ################### Start Configure ####################
    regression_setup = ['32', '64','small']
    RST_CYCLES  = 3
    TIMEOUT_VAL = 20000

    DMA_CFG_32b = {}
    DMA_CFG_32b['axi_addr_width'] = 32
    DMA_CFG_32b['axi_data_width'] = 32

    DMA_CFG_64b = {}
    DMA_CFG_64b['axi_addr_width'] = 32
    DMA_CFG_64b['axi_data_width'] = 64

    DMA_CFG_SMALL = {}
    DMA_CFG_SMALL['axi_addr_width'] = 32
    DMA_CFG_SMALL['axi_data_width'] = 32
    DMA_CFG_SMALL['dma_max_beat_burst'] = 8
    DMA_CFG_SMALL['dma_en_unaligned']   = 0

    DMA_CSRs = {}
    #-------------------------------> Addr     Mask       RW
    DMA_CSRs['DMA_CONTROL']        = (0x0000, 0x3FF,      1)
    DMA_CSRs['DMA_STATUS']         = (0x0008, 0xCAFE,     0)
    DMA_CSRs['DMA_ERROR_ADDR']     = (0x0010, 0x0,        0)
    DMA_CSRs['DMA_ERROR_MISC']     = (0x0018, 0x0,        0)
    NUM_DESC       = 2
    PER_DESC_CSRS  = 4
    CSR_ADDR_ALIG  = 8
    BASE_ADDR_DESC = 0x20
    for i in range(0, NUM_DESC):
        DMA_CSRs['DMA_DESC_SRC_ADDR_'  +str(i)] = (BASE_ADDR_DESC+(0*(NUM_DESC*8))+(i*CSR_ADDR_ALIG), 0xFFFFFFFF, 1)
        DMA_CSRs['DMA_DESC_DST_ADDR_'  +str(i)] = (BASE_ADDR_DESC+(1*(NUM_DESC*8))+(i*CSR_ADDR_ALIG), 0xFFFFFFFF, 1)
        DMA_CSRs['DMA_DESC_NUM_BYTES_' +str(i)] = (BASE_ADDR_DESC+(2*(NUM_DESC*8))+(i*CSR_ADDR_ALIG), 0xFFFFFFFF, 1)
        DMA_CSRs['DMA_DESC_WRITE_MODE_'+str(i)] = (BASE_ADDR_DESC+(3*(NUM_DESC*8))+(i*CSR_ADDR_ALIG), 0x7,        1)
        DMA_CSRs['DMA_DESC_READ_MODE_' +str(i)] = (BASE_ADDR_DESC+(3*(NUM_DESC*8))+(i*CSR_ADDR_ALIG), 0x7,        1)
        DMA_CSRs['DMA_DESC_ENABLE_'    +str(i)] = (BASE_ADDR_DESC+(3*(NUM_DESC*8))+(i*CSR_ADDR_ALIG), 0x7,        1)
    ################### End Configure ####################

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
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RGGEN_V_DIR}/rggen_rtl_macros.vh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'amba_sv_structs/amba_axi_pkg.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}inc/*.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}inc/dma_pkg.svh',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}inc/dma_utils_pkg.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RTL_DIR}**/*.sv',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{CSR_RGGEN_DIR}**/*.v',recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f'{RGGEN_V_DIR}**/*.v',recursive=True)
    PATH_RUN     = str(os.getenv("PATH_RUN"))
    COMPILE_ARGS = ["-f",os.path.join(PATH_RUN,"verilator.flags"),"--coverage","--coverage-line","--coverage-toggle"]
    if SIMULATOR == "verilator":
        EXTRA_ARGS = ["--trace-fst","--trace-structs","--Wno-UNOPTFLAT","--Wno-REDEFMACRO"]
    else:
        EXTRA_ARGS = []

    EXTRA_ARGS_32b = copy.deepcopy(EXTRA_ARGS)
    EXTRA_ARGS_64b = copy.deepcopy(EXTRA_ARGS)
    EXTRA_ARGS_SMALL = copy.deepcopy(EXTRA_ARGS)

    for param in DMA_CFG_32b.items():
        EXTRA_ARGS_32b.append("-D"+param[0].upper()+"="+str(param[1]))
    for param in DMA_CFG_64b.items():
        EXTRA_ARGS_64b.append("-D"+param[0].upper()+"="+str(param[1]))
    for param in DMA_CFG_SMALL.items():
        EXTRA_ARGS_SMALL.append("-D"+param[0].upper()+"="+str(param[1]))

    EXTRA_ARGS_32b.append("-DRGGEN_NAIVE_MUX_IMPLEMENTATION")
    EXTRA_ARGS_64b.append("-DRGGEN_NAIVE_MUX_IMPLEMENTATION")
    EXTRA_ARGS_SMALL.append("-DRGGEN_NAIVE_MUX_IMPLEMENTATION")

    def _get_cfg_args(flavor):
        if flavor == "32":
            return cfg_const.EXTRA_ARGS_32b
        elif flavor == "64":
            return cfg_const.EXTRA_ARGS_64b
        else:
            return cfg_const.EXTRA_ARGS_SMALL
