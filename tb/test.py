from common.constants import cfg_const
from common.dma import dma_desc, dma_mode, dma_addr, dma_ctrl
from random import randint
print("Test")
desc = [dma_desc(i, randint(0,2),
                    randint(0,2),
                    randint(0,2),
                    dma_mode.INCR,
                    dma_mode.INCR, 1) for i in range(cfg_const.NUM_DESC)]

for i in desc:
    addr = i.get_addr(dma_addr.SRC)
    print(hex(addr))

data = dma_ctrl(1,0,255)
print(data.addr)
print(data.value)
