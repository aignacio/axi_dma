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
  output  s_axil_mosi_t dma_csr_miso_o,
  // Master DMA I/F
  output  s_axi_mosi_t  dma_m_mosi_o,
  input   s_axi_mosi_t  dma_m_miso_i,
  // Triggers - IRQs
  output  logic         dma_done_o,
  output  logic         dma_error_o
);
  rggen_axi4lite_if.slave csr_axi_if;

  always_comb begin
    dma_m_mosi_o = s_axi_mosi_t'('0);
    dma_done = 1'b0;
    dma_error = 1'b0;

    //csr_axi_if.awvalid     = dma_csr_mosi_i.awvalid;
    //dma_csr_miso_o.awready = csr_axi_if.awready;
    //csr_axi_if.awid        = '0;
    //csr_axi_if.awaddr      = dma_csr_mosi_i.awaddr;
    //csr_axi_if.awprot      = dma_csr_mosi_i.awprot;
    //csr_axi_if.wvalid      = dma_csr_mosi_i.wvalid;
    //dma_csr_miso_o.wready  = csr_axi_if.wready;
    //csr_axi_if.wdata       = dma_csr_mosi_i.wdata;
    //csr_axi_if.wstrb       = dma_csr_mosi_i.wstrb;
    //dma_csr_miso_o.bvalid  = csr_axi_if.bvalid;
    //csr_axi_if.bready      = dma_csr_mosi_i.bready;
    //csr_axi_if.bid         = '0;
    //dma_csr_miso_o.bresp   = csr_axi_if.bresp;
    //csr_axi_if.arvalid     = dma_csr_mosi_i.arvalid;
    //dma_csr_miso_o.arready = csr_axi_if.arready;
    //csr_axi_if.arid        = '0;
    //csr_axi_if.araddr      = dma_csr_mosi_i.araddr;
    //csr_axi_if.arprot      = dma_csr_mosi_i.arprot;
    //dma_csr_miso_o.rvalid  = csr_axi_if.rvalid;
    //csr_axi_if.rready      = dma_csr_mosi_i.rready;
    //csr_axi_if.rid         = '0;
    //dma_csr_miso_o.rresp   = csr_axi_if.rresp;
    //dma_csr_miso_o.rdata   = csr_axi_if.rdata;
  end

  csr_dma u_csr_dma(
    .i_clk                      (clk),
    .i_rst_n                    (~rst),
    .axi4lite_if                (csr_axi_if),
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

endmodule
