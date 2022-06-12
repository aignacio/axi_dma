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

  // FIFO size in bytes = (DMA_FIFO_DEPTH*(AXI_DATA_WIDTH/8))
  `ifndef DMA_FIFO_DEPTH
    `define DMA_FIFO_DEPTH  16 // Must be power of 2
  `endif

  typedef logic [`DMA_ADDR_WIDTH-1:0]       desc_addr_t;
  typedef logic [`DMA_BYTES_WIDTH-1:0]      desc_num_t;
  typedef logic [$clog2(`DMA_NUM_DESC)-1:0] idx_desc_t;
  typedef logic [7:0]                       maxb_t;

  typedef enum logic {
    DMA_ERR_RD,
    DMA_ERR_WR
  } err_src_t;

  typedef enum logic [1:0] {
    DMA_ST_IDLE,
    DMA_ST_CFG,
    DMA_ST_RUN,
    DMA_ST_DONE
  } dma_st_t;

  typedef enum logic {
    DMA_MODE_INCR,
    DMA_MODE_FIXD
  } dma_mode_t;

  // Interface between DMA FSM and DMA CSR
  typedef struct packed {
    desc_addr_t src_addr;
    desc_addr_t dst_addr;
    desc_num_t  num_bytes;
    dma_mode_t  wr_mode;
    dma_mode_t  rd_mode;
    logic       enable;
  } s_dma_desc_t;

  typedef struct packed {
    desc_addr_t addr;
    err_type_t  type_err;
    err_src_t   src;
  } s_dma_error_t;

  typedef struct packed {
    logic       go;
    logic       abort_req;
    maxb_t      max_burst;
  } s_dma_control_t;

  typedef struct packed {
    logic       error;
    logic       done;
  } s_dma_status_t;

  // Interface between DMA FSM and DMA Streamer
  typedef struct packed {
    logic       valid;
    idx_desc_t  idx;
  } s_dma_str_in_t;

  typedef struct packed {
    logic       done;
  } s_dma_str_out_t;

  // Interface between DMA Streamer and DMA AXI
  typedef struct packed {
    logic       valid;
    idx_desc_t  idx;
  } s_dma_axi_req_t;

  typedef struct packed {
    logic       done;
  } s_dma_axi_resp_t;

`endif
