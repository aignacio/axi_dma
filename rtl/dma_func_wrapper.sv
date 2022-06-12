/**
 * File              : dma_func_wrapper.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.06.2022
 * Last Modified Date: 12.06.2022
 */
module dma_func_wrapper
  import dma_utils_pkg::*;
(
  input                                     clk,
  input                                     rst,
  // From/To CSRs
  input   s_dma_control_t                   dma_ctrl_i,
  input   s_dma_desc_t [`DMA_NUM_DESC-1:0]  dma_desc_i,
  output  s_dma_status_t                    dma_stats_o
);

  dma_fsm u_dma_fsm(
    .clk            (clk),
    .rst            (rst),
    .dma_ctrl_i     (dma_ctrl_i),
    .dma_desc_i     (dma_desc_i),
    .axi_pend_txn_i ('0),
    .axi_txn_err_i  ('0),
    .clear_dma_o    (),
    .dma_stats_o    (dma_stats_o),
    .dma_stream_rd_o(),
    .dma_stream_rd_i('0),
    .dma_stream_wr_o(),
    .dma_stream_wr_i('0)
  );

endmodule

