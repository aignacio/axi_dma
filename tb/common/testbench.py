#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : testbench.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 04.06.2022
# Last Modified Date: 06.06.2022
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
from cocotbext.axi import AxiBus, AxiLiteBus, AxiMaster, AxiRam, AxiResp, AxiLiteMaster, AxiSlave
from cocotbext.axi import AxiLiteRam
from cocotb.result import TestFailure

class Tb:
    """
    Base class for RaveNoC testbench

    Args:
        dut: The Dut object coming from cocotb
        log_name: Name of the log file inside the run folder, it's append the timestamp only
        cfg: NoC cfg dict
    """
    def __init__(self, dut, log_name, cfg):
        self.dut = dut
        self.cfg = cfg
        timenow_wstamp = self._gen_log(log_name)
        self.log.info("------------[LOG - %s]------------",timenow_wstamp)
        self.log.info("SEED: %s",str(cocotb.RANDOM_SEED))
        self.log.info("Log file: %s",log_name)
        self.csr_axi_if = AxiLiteMaster(AxiLiteBus.from_prefix(self.dut, "dma_s"), self.dut.clk, self.dut.rst)
        # self.dma_axi_if = AxiSlave(AxiBus.from_prefix(self.dut, "dma_m"), self.dut.clk, self.dut.rst)
        self.axil_ram = AxiLiteRam(AxiLiteBus.from_prefix(dut, "dma_s"), dut.clk, dut.rst, size=2**16)

    def __del__(self):
        # Need to write the last strings in the buffer in the file
        self.log.info("Closing log file.")
        self.log.removeHandler(self.file_handler)

    def set_idle_generator(self, generator=None):
        if generator:
            self.csr_if.write_if.aw_channel.set_pause_generator(generator())
            self.csr_if.write_if.w_channel.set_pause_generator(generator())
            self.csr_if.read_if.ar_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.csr_if.write_if.b_channel.set_pause_generator(generator())
            self.csr_if.read_if.r_channel.set_pause_generator(generator())

    """
    Write AXILite I/F for the CSRs

    Args:
        kwargs: All aditional args that can be passed to the amba AXI driver
    """
    async def write(self, address=0x0, data=0x0, **kwargs):
        self.log.info("[AXI Lite Master - Write] Address = ["+str(hex(address))+"] ")
        write = self.csr_axi_if.init_write(address=address, data=data, **kwargs)
        await with_timeout(write.wait(), *cfg_const.TIMEOUT_AXI)
        ret = write.data
        return ret

    """
    Read AXI method

    Args:
        kwargs: All aditional args that can be passed to the amba AXI driver
    Returns:
        Return the data read from the specified node
    """
    async def read(self, address=0x0, length=4, **kwargs):
        self.log.info("[AXI Master - Read] Slave = Address = ["+str(hex(address))+"] / Length = ["+str(length)+" bytes]")
        read = self.csr_axi_if.init_read(address=address, length=length, **kwargs)
        await with_timeout(read.wait(), *cfg_const.TIMEOUT_AXI)
        resp = read.data # read.data => AxiReadResp
        return resp

    """
    Setup and launch the clocks on the simulation

    Args:
        clk_mode: Clock speed to be used to compute the BW
    """
    async def setup_clks(self, clk_mode="100MHz"):
        self.log.info(f"[Setup] Configuring the clocks: {clk_mode}")
        if clk_mode == "100MHz":
            await cocotb.start(Clock(self.dut.clk, *cfg_const.CLK_100MHz).start())
        elif clk_mode == "200MHz":
            await cocotb.start(Clock(self.dut.clk, *cfg_const.CLK_200MHz).start())
        else:
            await cocotb.start(Clock(self.dut.clk, *cfg_const.CLK_200MHz).start())

    """
    Setup and apply the reset on the NoC

    Args:
        clk_mode: Depending on the input clock mode, we need to wait different
        clk cycles for the reset, we always hold as long as the slowest clock
    """
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

    """
    Creates the tb log obj and start filling with headers
    """
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

    """
    Used to create the symlink with the latest log in the run dir folder
    """
    def _symlink_force(self, target, link_name):
        try:
            os.symlink(target, link_name)
        except OSError as e:
            if e.errno == errno.EEXIST:
                os.remove(link_name)
                os.symlink(target, link_name)
            else:
                raise e

    """
    Returns a random string with the length equal to input argument
    """
    def _get_random_string(self, length=1):
        # choose from all lowercase letter
        letters = string.ascii_lowercase
        result_str = ''.join(random.choice(letters) for i in range(length))
        return result_str
