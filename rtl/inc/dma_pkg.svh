`ifndef _DMA_PKG_
  `define _DMA_PKG_

  `ifndef DMA_NUM_DESC
    `define DMA_NUM_DESC    5
  `endif

  `ifndef DMA_ADDR_WIDTH
    `define DMA_ADDR_WIDTH  32
  `endif

  `ifndef DMA_BYTES_WIDTH
    `define DMA_BYTES_WIDTH 32
  `endif

  typedef logic [`DMA_ADDR_WIDTH-1:0]   desc_addr_t;
  typedef logic [`DMA_BYTES_WIDTH-1:0]  desc_num_t;

  typedef enum logic {
    DMA_ERR_CFG,
    DMA_ERR_OPE
  } err_type_t;

  typedef enum logic {
    DMA_ERR_RD,
    DMA_ERR_WR
  } err_src_t;

  typedef struct packed {
    desc_addr_t src_addr;
    desc_addr_t dst_addr;
    desc_num_t  num_bytes;
    logic       wr_mode;
    logic       rd_mode;
    logic       enable;
  } s_dma_desc_t;

  typedef struct packed {
    desc_addr_t addr;
    err_type_t  type_err;
    err_src_t   src;
  } s_dma_error_t;

  typedef struct packed {
    logic       go;
    logic       abort;
  } s_dma_cmd_in_t;

  typedef struct packed {
    logic       error;
    logic       done;
  } s_dma_cmd_out_t;
`endif
