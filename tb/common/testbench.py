#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : testbench.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 04.06.2022
# Last Modified Date: 15.06.2022
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
import os, errno
import logging, string, random
from logging.handlers import RotatingFileHandler
from cocotb.log import SimLogFormatter, SimColourLogFormatter, SimLog, SimTimeContextFilter
from common.constants import cfg_const
from cocotb.clock import Clock
from datetime import datetime
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout, ReadOnly, Event
from cocotbext.axi import AxiBus, AxiLiteBus
from cocotbext.axi import AxiLiteRam, AxiRam
from cocotbext.axi import AxiResp, AxiLiteMaster, AxiSlave
from cocotb.result import TestFailure

class Tb:
    def __init__(self, dut, log_name, cfg, flavor, ram_size=(2**12)):
        self.dut = dut
        self.cfg = cfg
        self.flavor = flavor
        self.bb = 4 if flavor == '32' else 8 # Number of bytes per data bus lane
        self.max_data = ((2**32)-1) if flavor == '32' else ((2**64)-1)
        timenow_wstamp = self._gen_log(log_name)
        self.log.info("------------[LOG - %s]------------",timenow_wstamp)
        self.log.info("SEED: %s",str(cocotb.RANDOM_SEED))
        self.log.info("Log file: %s",log_name)
        self.csr_axi_if = AxiLiteMaster(AxiLiteBus.from_prefix(self.dut, "dma_s"), self.dut.clk, self.dut.rst)
        self.axi_ram = AxiRam(AxiBus.from_prefix(self.dut, "dma_m"), self.dut.clk, self.dut.rst, size=ram_size)
        self.axi_ram.write_if.log.setLevel(logging.DEBUG)
        self.axi_ram.read_if.log.setLevel(logging.DEBUG)

    def __del__(self):
        # Need to write the last strings in the buffer in the file
        self.log.info("Closing log file.")
        self.log.removeHandler(self.file_handler)
        self.file_handler.close()

    def set_idle_generator(self, generator=None):
        if generator:
            self.csr_axi_if.write_if.aw_channel.set_pause_generator(generator())
            self.csr_axi_if.write_if.w_channel.set_pause_generator(generator())
            self.csr_axi_if.read_if.ar_channel.set_pause_generator(generator())
            self.axi_ram.write_if.b_channel.set_pause_generator(generator())
            self.axi_ram.read_if.r_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.csr_axi_if.write_if.b_channel.set_pause_generator(generator())
            self.csr_axi_if.read_if.r_channel.set_pause_generator(generator())
            self.axi_ram.write_if.aw_channel.set_pause_generator(generator())
            self.axi_ram.write_if.w_channel.set_pause_generator(generator())
            self.axi_ram.read_if.ar_channel.set_pause_generator(generator())

    def get_settings(self):
        run_settings = {}
        run_settings['bb'] = self.bb
        run_settings['max_data'] = self.max_data
        return run_settings

    def fill_ram(self, mem, log=None):
        for i in mem:
            addr   = i[0]
            data   = i[1].to_bytes(self.bb,'little')
            data_p = i[1].to_bytes(self.bb,'big') # We revert to print
            addr_h = hex(addr)
            if log != None:
                self.log.info(f"[AXI RAM] Loading: {addr_h} - {data_p.hex()}")
            self.axi_ram.write(addr, data)

    async def wait_done(self):
        timeout_cnt = 0
        while int(self.dut.dma_done_o == 0):
            await RisingEdge(self.dut.clk)
            if timeout_cnt == self.cfg.TIMEOUT_VAL:
                self.log.error("Timeout on waiting for DMA DONE")
                raise TestFailure("Timeout on waiting for DMA DONE")
            else:
                timeout_cnt += 1

    async def prg_desc(self, descriptors, **kwargs):
        for desc in descriptors:
            addr  = self.cfg.DMA_CSRs[desc][0]
            dataW = descriptors[desc]
            dataW = dataW.to_bytes(4 if self.flavor == '32' else 8,'little')
            write = self.csr_axi_if.init_write(address=addr, data=dataW, **kwargs)
            await with_timeout(write.wait(), *cfg_const.TIMEOUT_AXI)
        ret = write.data
        return ret

    async def start_dma(self, **kwargs):
        addr  = self.cfg.DMA_CSRs['DMA_CONTROL'][0]
        dataW = 0x3FD # MAX_BURST[7:0] ABORT[0] GO[0]
        dataW = dataW.to_bytes(4 if self.flavor == '32' else 8,'little')
        write = self.csr_axi_if.init_write(address=addr, data=dataW, **kwargs)
        await with_timeout(write.wait(), *cfg_const.TIMEOUT_AXI)
        ret = write.data
        return ret

    async def write(self, address=0x0, data=0x0, **kwargs):
        # self.log.info("[AXI Lite Master - Write] Address = ["+str(hex(address))+"] ")
        write = self.csr_axi_if.init_write(address=address, data=data, **kwargs)
        await with_timeout(write.wait(), *cfg_const.TIMEOUT_AXI)
        ret = write.data
        return ret

    async def read(self, address=0x0, length=4, **kwargs):
        # self.log.info("[AXI Lite Master - Read] Slave = Address = ["+str(hex(address))+"] / Length = ["+str(length)+" bytes]")
        read = self.csr_axi_if.init_read(address=address, length=length, **kwargs)
        await with_timeout(read.wait(), *cfg_const.TIMEOUT_AXI)
        resp = read.data
        return resp

    async def setup_clks(self, clk_mode="100MHz"):
        self.log.info(f"[Setup] Configuring the clocks: {clk_mode}")
        if clk_mode == "100MHz":
            await cocotb.start(Clock(self.dut.clk, *cfg_const.CLK_100MHz).start())
        elif clk_mode == "200MHz":
            await cocotb.start(Clock(self.dut.clk, *cfg_const.CLK_200MHz).start())
        else:
            await cocotb.start(Clock(self.dut.clk, *cfg_const.CLK_200MHz).start())

    async def rst(self, clk_mode="100MHz"):
        self.log.info("[Setup] Reset DUT")
        self.dut.rst.setimmediatevalue(1)
        self.dut.rst.value = 1
        if clk_mode == "100MHz":
            await ClockCycles(self.dut.clk, cfg_const.RST_CYCLES)
        else:
            await ClockCycles(self.dut.clk, cfg_const.RST_CYCLES)
        self.dut.rst.value = 0
        await ClockCycles(self.dut.clk, 1)

    def _gen_log(self, log_name):
        timenow = datetime.now().strftime("%d_%b_%Y_%Hh_%Mm_%Ss")
        timenow_wstamp = timenow + str("_") + str(datetime.timestamp(datetime.now()))
        self.log = SimLog(log_name)
        self.log.setLevel(logging.DEBUG)
        self.file_handler = RotatingFileHandler(f"{log_name}_{timenow}.log", maxBytes=(5 * 1024 * 1024), backupCount=2, mode='w')
        self._symlink_force(f"{log_name}_{timenow}.log",f"latest_{log_name}.log")
        self.file_handler.setFormatter(SimLogFormatter())
        self.log.addHandler(self.file_handler)
        self.log.addFilter(SimTimeContextFilter())
        return timenow_wstamp

    def _symlink_force(self, target, link_name):
        try:
            os.symlink(target, link_name)
        except OSError as e:
            if e.errno == errno.EEXIST:
                os.remove(link_name)
                os.symlink(target, link_name)
            else:
                raise e

    def _get_random_string(self, length=1):
        # choose from all lowercase letter
        letters = string.ascii_lowercase
        result_str = ''.join(random.choice(letters) for i in range(length))
        return result_str
