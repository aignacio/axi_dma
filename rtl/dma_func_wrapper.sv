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
  s_dma_str_in_t  dma_rd_stream_in;
  s_dma_str_out_t dma_rd_stream_out;
  s_dma_str_in_t  dma_wr_stream_in;
  s_dma_str_out_t dma_wr_stream_out;

  dma_fsm u_dma_fsm(
    .clk            (clk),
    .rst            (rst),
    .dma_ctrl_i     (dma_ctrl_i),
    .dma_desc_i     (dma_desc_i),
    .axi_pend_txn_i ('0),
    .axi_txn_err_i  ('0),
    .clear_dma_o    (),
    .dma_stats_o    (dma_stats_o),
    .dma_stream_rd_o(dma_rd_stream_in),
    .dma_stream_rd_i(dma_rd_stream_out),
    .dma_stream_wr_o(),
    .dma_stream_wr_i('0)
  );

  dma_streamer #(
    .STREAM_TYPE(0)
  ) u_dma_rd_streamer (
    .clk            (clk),
    .rst            (rst),
    // From/To CSRs
    .dma_desc_i     (dma_desc_i),
    .dma_abort_i    (dma_ctrl_i.abort_req),
    .dma_maxb_i     (dma_ctrl_i.max_burst),
    // From/To AXI I/F
    .dma_axi_req_o  (),
    .dma_axi_resp_i ('0),
    // To/From DMA FSM
    .dma_stream_i   (dma_rd_stream_in),
    .dma_stream_o   (dma_rd_stream_out)
  );

  dma_streamer #(
    .STREAM_TYPE(1)
  ) u_dma_wr_streamer (
    .clk            (clk),
    .rst            (rst),
    // From/To CSRs
    .dma_desc_i     (dma_desc_i),
    .dma_abort_i    (dma_ctrl_i.abort_req),
    .dma_maxb_i     (dma_ctrl_i.max_burst),
    // From/To AXI I/F
    .dma_axi_req_o  (),
    .dma_axi_resp_i ('0),
    // To/From DMA FSM
    .dma_stream_i   (dma_wr_stream_in),
    .dma_stream_o   (dma_wr_stream_out)
  );
endmodule

