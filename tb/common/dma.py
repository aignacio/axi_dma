#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : dma.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 17.06.2022
# Last Modified Date: 20.06.2022
import enum
import logging
from common.constants import cfg_const

class dma_mode(enum.Enum):
    INCR  = 0
    FIXED = 1

class dma_addr(enum.Enum):
    def __str__(self):
        return str(self.value)
    SRC = 1
    DST = 2
    BYT = 3
    CFG = 4

class dma_err_type(enum.Enum):
    def __str__(self):
        return str(self.value)
    CFG  = 0
    OPER = 1

class dma_err_src(enum.Enum):
    def __str__(self):
        return str(self.value)
    READ  = 0
    WRITE = 1

class dma_ctrl:
    def __init__(self, go, abort, max_burst):
        self._go        = go
        self._abort     = abort
        self._max_burst = max_burst
        self._addr      = cfg_const.DMA_CSRs['DMA_CONTROL'][0]
        self._value     = ((max_burst<<2) | (abort<<1) | (go))

    @property
    def go(self):
        return self._go

    @property
    def abort(self):
        return self._abort

    @property
    def max_burst(self):
        return self._max_burst

    @property
    def value(self):
        return self._value

    @property
    def addr(self):
        return self._addr

class dma_status:
    def __init__(self, done, error):
        self._version = cfg_const.DMA_CSRs['DMA_STATUS'][1]
        self._done    = done
        self._error   = error
        self._addr    = cfg_const.DMA_CSRs['DMA_STATUS'][0]
        self._value   = ((error<<17) | (done<<16) | version)

    @property
    def addr(self):
        return self._addr

    @property
    def value(self):
        return self._value

class dma_error_addr:
    def __init__(self, done, error):
        self._error_addr = error_addr
        self._addr       = cfg_const.DMA_CSRs['DMA_ERROR_ADDR'][0]

    @property
    def addr(self):
        return self._addr

    @property
    def value(self):
        return self._error_addr

class dma_error_stats:
    def __init__(self, error_type, error_src, error_trig):
        self._addr  = cfg_const.DMA_CSRs['DMA_ERROR_MISC'][0]
        self._value = ((error_type.value<<2) | (error_src.value<<1) | error_trig)

    @property
    def addr(self):
        return self._addr

    @property
    def value(self):
        return self._value

class dma_desc:
    def __init__(self, desc_id, src, dst, nbytes, wr_m, rd_m, en):
        self._did    = desc_id
        self._src    = src
        self._dst    = dst
        self._wr_m   = wr_m
        self._rd_m   = rd_m
        self._en     = en
        self._nbytes = nbytes
        self._cfg    = (en<<2) | (rd_m.value<<1) | (wr_m.value)
        self.log     = logging.getLogger(f"cocotb.dma_desc.{self._did}")
        self.log.info(f'DMA Descriptor {self._did}:')
        self.log.info(f'Src    = [{hex(self._src)}]')
        self.log.info(f'Dst    = [{hex(self._dst)}]')
        self.log.info(f'Size   = [{self._nbytes}]B ~ [{self._nbytes//1024}]KB')
        self.log.info(f'Write  = [{self._wr_m}]')
        self.log.info(f'Read   = [{self._rd_m}]')
        self.log.info(f'Enable = [{self._en}]')

    def __str__(self):
        return f'DMA Descriptor {self._did}: Src[{hex(self._src)}] \
                Dst[{hex(self._dst)}] Size[{self._nbytes}] \
                Write Mode[{self._wr_m}] Read Mode[{self._rd_m}] \
                Enable[{self._en}]'

    def get_addr(self, addr):
        if addr == dma_addr.SRC:
            return cfg_const.BASE_ADDR_DESC+(0*(cfg_const.NUM_DESC*8))+(self._did*8)
        elif addr == dma_addr.DST:
            return cfg_const.BASE_ADDR_DESC+(1*(cfg_const.NUM_DESC*8))+(self._did*8)
        elif addr == dma_addr.BYT:
            return cfg_const.BASE_ADDR_DESC+(2*(cfg_const.NUM_DESC*8))+(self._did*8)
        elif addr == dma_addr.CFG:
            return cfg_const.BASE_ADDR_DESC+(3*(cfg_const.NUM_DESC*8))+(self._did*8)

    # Using properties to turn all into ReadOnly mode
    @property
    def desc_id(self):
        return self._did

    @property
    def src(self):
        return self._src

    @property
    def dst(self):
        return self._dst

    @property
    def nbytes(self):
        return self._nbytes

    @property
    def wr_m(self):
        return self._wr_m

    @property
    def rd_m(self):
        return self._rd_m

    @property
    def en(self):
        return self._en

    @property
    def rd_m(self):
        return self._rd_m

    @property
    def cfg(self):
        return self._cfg
