/**
 * File              : dma_axi_wrapper.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 06.06.2022
 * Last Modified Date: 03.07.2022
 */
module dma_axi_wrapper
  import amba_axi_pkg::*;
  import dma_utils_pkg::*;
(
  input                 clk,
  input                 rst,
  // CSR DMA I/F
  input   s_axil_mosi_t dma_csr_mosi_i,
  output  s_axil_miso_t dma_csr_miso_o,
  // Master DMA I/F
  output  s_axi_mosi_t  dma_m_mosi_o,
  input   s_axi_miso_t  dma_m_miso_i,
  // Triggers - IRQs
  output  logic         dma_done_o,
  output  logic         dma_error_o
);
  localparam AXI_DATA_WIDTH = `AXI_DATA_WIDTH;

  logic [`DMA_NUM_DESC*$bits(desc_addr_t)-1:0]  dma_desc_src_vec;
  logic [`DMA_NUM_DESC*$bits(desc_addr_t)-1:0]  dma_desc_dst_vec;
  logic [`DMA_NUM_DESC*$bits(desc_num_t)-1:0]   dma_desc_byt_vec;
  logic [`DMA_NUM_DESC-1:0]                     dma_desc_wr_mod;
  logic [`DMA_NUM_DESC-1:0]                     dma_desc_rd_mod;
  logic [`DMA_NUM_DESC-1:0]                     dma_desc_en;

  s_dma_desc_t  [`DMA_NUM_DESC-1:0]             dma_desc;
  s_dma_control_t                               dma_ctrl;
  s_dma_status_t                                dma_stats;
  s_dma_error_t                                 dma_error;

  always_comb begin
    dma_done_o  = dma_stats.done;
    dma_error_o = dma_stats.error;

    if (AXI_DATA_WIDTH == 64) begin
      dma_csr_miso_o.rdata[AXI_DATA_WIDTH-1:(AXI_DATA_WIDTH/2)] = '0;
    end

    // Hook-up Desc. CSR and DMA logic
    for (int i=0; i<`DMA_NUM_DESC; i++) begin : connecting_structs_with_csr
      dma_desc[i].src_addr  = dma_desc_src_vec[i*`DMA_ADDR_WIDTH +: `DMA_ADDR_WIDTH];
      dma_desc[i].dst_addr  = dma_desc_dst_vec[i*`DMA_ADDR_WIDTH +: `DMA_ADDR_WIDTH];
      dma_desc[i].num_bytes = dma_desc_byt_vec[i*`DMA_ADDR_WIDTH +: `DMA_ADDR_WIDTH];
      dma_desc[i].wr_mode   = dma_desc_wr_mod[i];
      dma_desc[i].rd_mode   = dma_desc_rd_mod[i];
      dma_desc[i].enable    = dma_desc_en[i];
    end : connecting_structs_with_csr
  end

  /* verilator lint_off WIDTH */
  csr_dma #(
    .ID_WIDTH                       (`AXI_TXN_ID_WIDTH)
  ) u_csr_dma (
    .i_clk                          (clk),
    .i_rst_n                        (~rst),
    .i_awvalid                      (dma_csr_mosi_i.awvalid),
    .o_awready                      (dma_csr_miso_o.awready),
    .i_awid                         (dma_csr_mosi_i.awid),
    .i_awaddr                       (dma_csr_mosi_i.awaddr),
    .i_awprot                       (dma_csr_mosi_i.awprot),
    .i_wvalid                       (dma_csr_mosi_i.wvalid),
    .o_wready                       (dma_csr_miso_o.wready),
    .i_wdata                        (dma_csr_mosi_i.wdata),
    .i_wstrb                        (dma_csr_mosi_i.wstrb),
    .o_bvalid                       (dma_csr_miso_o.bvalid),
    .i_bready                       (dma_csr_mosi_i.bready),
    .o_bid                          (dma_csr_miso_o.bid),
    .o_bresp                        (dma_csr_miso_o.bresp),
    .i_arvalid                      (dma_csr_mosi_i.arvalid),
    .o_arready                      (dma_csr_miso_o.arready),
    .i_arid                         (dma_csr_mosi_i.arid),
    .i_araddr                       (dma_csr_mosi_i.araddr),
    .i_arprot                       (dma_csr_mosi_i.arprot),
    .o_rvalid                       (dma_csr_miso_o.rvalid),
    .i_rready                       (dma_csr_mosi_i.rready),
    .o_rid                          (dma_csr_miso_o.rid),
    .o_rdata                        (dma_csr_miso_o.rdata),
    .o_rresp                        (dma_csr_miso_o.rresp),
    .o_dma_control_go               (dma_ctrl.go),
    .o_dma_control_max_burst        (dma_ctrl.max_burst),
    .o_dma_control_abort            (dma_ctrl.abort_req),
    .i_dma_status_done              (dma_stats.done),
    .i_dma_error_stats_error_trig   (dma_stats.error),
    .i_dma_error_addr_error_addr    (dma_error.addr),
    .i_dma_error_stats_error_type   (dma_error.type_err),
    .i_dma_error_stats_error_src    (dma_error.src),
    .o_dma_desc_src_addr_src_addr   (dma_desc_src_vec),
    .o_dma_desc_dst_addr_dst_addr   (dma_desc_dst_vec),
    .o_dma_desc_num_bytes_num_bytes (dma_desc_byt_vec),
    .o_dma_desc_cfg_write_mode      (dma_desc_wr_mod),
    .o_dma_desc_cfg_read_mode       (dma_desc_rd_mod),
    .o_dma_desc_cfg_enable          (dma_desc_en)
  );
  /* verilator lint_on WIDTH */

  dma_func_wrapper u_dma_func_wrapper(
    .clk         (clk),
    .rst         (rst),
    // From/To CSRs
    .dma_ctrl_i  (dma_ctrl),
    .dma_desc_i  (dma_desc),
    .dma_stats_o (dma_stats),
    .dma_error_o (dma_error),
    // Master AXI I/F
    .dma_mosi_o  (dma_m_mosi_o),
    .dma_miso_i  (dma_m_miso_i)
  );
endmodule
