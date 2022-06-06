/**
 * File              : axi_dma_wrapper.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 06.06.2022
 * Last Modified Date: 06.06.2022
 */
module axi_dma_wrapper
  import utils_pkg::*;
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
  always_comb begin
    dma_m_mosi_o = s_axi_mosi_t'('0);
    dma_done_o  = 1'b0;
    dma_error_o = 1'b0;
  end

  /* verilator lint_off WIDTH */
  csr_dma u_csr_dma(
    .i_clk                      (clk),
    .i_rst_n                    (~rst),
    .i_awvalid                  (dma_csr_mosi_i.awvalid),
    .o_awready                  (dma_csr_miso_o.awready),
    .i_awid                     ('0),
    .i_awaddr                   (dma_csr_mosi_i.awaddr),
    .i_awprot                   (dma_csr_mosi_i.awprot),
    .i_wvalid                   (dma_csr_mosi_i.wvalid),
    .o_wready                   (dma_csr_miso_o.wready),
    .i_wdata                    (dma_csr_mosi_i.wdata),
    .i_wstrb                    (dma_csr_mosi_i.wstrb),
    .o_bvalid                   (dma_csr_miso_o.bvalid),
    .i_bready                   (dma_csr_mosi_i.bready),
    .o_bid                      (),
    .o_bresp                    (dma_csr_miso_o.bresp),
    .i_arvalid                  (dma_csr_mosi_i.arvalid),
    .o_arready                  (dma_csr_miso_o.arready),
    .i_arid                     (),
    .i_araddr                   (dma_csr_mosi_i.araddr),
    .i_arprot                   (dma_csr_mosi_i.arprot),
    .o_rvalid                   (dma_csr_miso_o.rvalid),
    .i_rready                   (dma_csr_mosi_i.rready),
    .o_rid                      (),
    .o_rdata                    (dma_csr_miso_o.rdata),
    .o_rresp                    (dma_csr_miso_o.rresp),
    .o_dma_control_go           (),
    .o_dma_control_abort        (),
    .i_dma_status_done          ('0),
    .i_dma_error_error_addr     ('0),
    .i_dma_error_error_type     ('0),
    .i_dma_error_error_src      ('0),
    .i_dma_error_error_trig     ('0),
    .o_dma_descriptor_src_addr  (),
    .o_dma_descriptor_dest_addr (),
    .o_dma_descriptor_num_bytes (),
    .o_dma_descriptor_write_mode(),
    .o_dma_descriptor_read_mode (),
    .o_dma_descriptor_enable    ()
  );
  /* verilator lint_on WIDTH */

endmodule
