`ifndef _DMA_PKG_
  `define _DMA_PKG_

  // Remember to also change in the
  // xls sheet to generate the same
  // correspondent number of desc
  `ifndef DMA_NUM_DESC
    `define DMA_NUM_DESC    5
  `endif

  `ifndef DMA_ADDR_WIDTH
    `define DMA_ADDR_WIDTH  `AXI_ADDR_WIDTH
  `endif

  `ifndef DMA_DATA_WIDTH
    `define DMA_DATA_WIDTH  `AXI_DATA_WIDTH
  `endif

  `ifndef DMA_BYTES_WIDTH
    `define DMA_BYTES_WIDTH 32
  `endif

  `ifndef DMA_RD_TXN_BUFF
    `define DMA_RD_TXN_BUFF 8 // Must be power of 2
  `endif

  `ifndef DMA_WR_TXN_BUFF
    `define DMA_WR_TXN_BUFF 8 // Must be power of 2
  `endif

  // FIFO size in bytes = (DMA_FIFO_DEPTH*(AXI_DATA_WIDTH/8))
  `ifndef DMA_FIFO_DEPTH
    `define DMA_FIFO_DEPTH  16 // Must be power of 2
  `endif

  `ifndef DMA_ID_WIDTH
      `define DMA_ID_WIDTH  `AXI_TXN_ID_WIDTH
  `endif

  `ifndef DMA_ID_VAL
      `define DMA_ID_VAL    0
  `endif

  localparam FIFO_WIDTH = $clog2(`DMA_FIFO_DEPTH>1?`DMA_FIFO_DEPTH:2);

  typedef logic [`DMA_ADDR_WIDTH-1:0]         desc_addr_t;
  typedef logic [`DMA_BYTES_WIDTH-1:0]        desc_num_t;
  typedef logic [7:0]                         maxb_t;
  typedef logic [$clog2(`DMA_NUM_DESC)-1:0]   idx_desc_t;
  typedef logic [FIFO_WIDTH:0]                fifo_sz_t;
  typedef logic [$clog2(`DMA_RD_TXN_BUFF):0]  pend_rd_t;
  typedef logic [$clog2(`DMA_WR_TXN_BUFF):0]  pend_wr_t;

  typedef enum logic {
    DMA_ERR_CFG,
    DMA_ERR_OPE
  } err_type_t;

  typedef enum logic {
    DMA_ERR_RD,
    DMA_ERR_WR
  } err_src_t;

  typedef enum logic {
    DMA_ST_SM_IDLE,
    DMA_ST_SM_RUN
  } dma_sm_t;

  typedef enum logic [1:0] {
    DMA_ST_IDLE,
    DMA_ST_CFG,
    DMA_ST_RUN,
    DMA_ST_DONE
  } dma_st_t;

  typedef enum logic {
    DMA_MODE_INCR,
    DMA_MODE_FIXED
  } dma_mode_t;

  // Interface between DMA FSM / Streamer and DMA CSR
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
    logic       valid;
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
    axi_addr_t    addr;
    axi_alen_t    alen;
    axi_size_t    size;
    axi_wr_strb_t strb;
    dma_mode_t    mode;
    logic         valid;
  } s_dma_axi_req_t;

  typedef struct packed {
    logic       ready;
  } s_dma_axi_resp_t;

  // Interface between DMA FIFOs and DMA AXI
  typedef struct packed {
    logic       wr;
    logic       rd;
    axi_data_t  data_wr;
  } s_dma_fifo_req_t;

  typedef struct packed {
    axi_data_t  data_rd;
    fifo_sz_t   ocup;
    fifo_sz_t   space;
    logic       full;
    logic       empty;
  } s_dma_fifo_resp_t;

  // Used in the DMA AXI I/F for buffering
  // write txns
  typedef struct packed {
    axi_alen_t    alen;
    axi_wr_strb_t wstrb;
  } s_wr_req_t;
`endif
