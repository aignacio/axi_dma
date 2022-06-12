/**
 * File              : dma_streamer.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.06.2022
 * Last Modified Date: 12.06.2022
 */
module dma_streamer
  import dma_utils_pkg::*;
(
  input                                     clk,
  input                                     rst,
  // From/To CSRs
  input   s_dma_desc_t [`DMA_NUM_DESC-1:0]  dma_desc_i,
  input   maxb_t                            dma_maxb_i,
  // From/To AXI I/F
  output  s_dma_axi_req_t                   dma_axi_req_o,
  input   s_dma_axi_resp_t                  dma_axi_resp_i,
  // To/From DMA FSM
  input   s_dma_str_out_t                   dma_stream_i,
  output  s_dma_str_in_t                    dma_stream_o
);

endmodule
