/**
 * File              : tb_axi_dma.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 05.06.2022
 * Last Modified Date: 15.06.2022
 */
module tb_axi_dma
  import dma_utils_pkg::*;
(
  input                     clk,
  input                     rst,
  // DMA IRQs
  output                    dma_done_o,
  output                    dma_error_o,
  // Slave AXI Lite - MOSI
  // Write Address channel
  input axi_addr_t          dma_s_awaddr,
  input axi_prot_t          dma_s_awprot,
  input logic               dma_s_awvalid,
  // Write Data channel
  input axi_data_t          dma_s_wdata,
  input axi_wr_strb_t       dma_s_wstrb,
  input logic               dma_s_wlast,
  input logic               dma_s_wvalid,
  // Write Response channel
  input logic               dma_s_bready,
  // Read Address channel
  input axi_addr_t          dma_s_araddr,
  input axi_prot_t          dma_s_arprot,
  input logic               dma_s_arvalid,
  // Read Data channel
  input  logic              dma_s_rready,

  // Slave AXI Lite Interface - MISO
  // Write Addr channel
  output logic              dma_s_awready,
  // Write Data channel
  output logic              dma_s_wready,
  // Write Response channel
  output axi_error_t        dma_s_bresp,
  output logic              dma_s_bvalid,
  // Read addr channel
  output logic              dma_s_arready,
  // Read data channel
  output axi_data_t         dma_s_rdata,
  output axi_error_t        dma_s_rresp,
  output logic              dma_s_rlast,
  output logic              dma_s_rvalid,

  // Master AXI I/F
  // AXI Interface - MOSI
  // Write Address channel
  output axi_tid_t          dma_m_awid,
  output axi_addr_t         dma_m_awaddr,
  output axi_alen_t         dma_m_awlen,
  output axi_size_t         dma_m_awsize,
  output axi_burst_t        dma_m_awburst,
  output logic              dma_m_awlock,
  output logic        [3:0] dma_m_awcache,
  output axi_prot_t         dma_m_awprot,
  output logic        [3:0] dma_m_awqos,
  output logic        [3:0] dma_m_awregion,
  output axi_user_req_t     dma_m_awuser,
  output logic              dma_m_awvalid,
  // Write Data channel
  output axi_data_t         dma_m_wdata,
  output axi_wr_strb_t      dma_m_wstrb,
  output logic              dma_m_wlast,
  output axi_user_data_t    dma_m_wuser,
  output logic              dma_m_wvalid,
  // Write Response channel
  output logic              dma_m_bready,
  // Read Address channel
  output axi_tid_t          dma_m_arid,
  output axi_addr_t         dma_m_araddr,
  output axi_alen_t         dma_m_arlen,
  output axi_size_t         dma_m_arsize,
  output axi_burst_t        dma_m_arburst,
  output logic              dma_m_arlock,
  output logic        [3:0] dma_m_arcache,
  output axi_prot_t         dma_m_arprot,
  output logic        [3:0] dma_m_arqos,
  output logic        [3:0] dma_m_arregion,
  output axi_user_req_t     dma_m_aruser,
  output logic              dma_m_arvalid,
  // Read Data channel
  output  logic             dma_m_rready,

  // AXI Interface - MISO
  // Write Addr channel
  input logic               dma_m_awready,
  // Write Data channel
  input logic               dma_m_wready,
  // Write Response channel
  input axi_tid_t           dma_m_bid,
  input axi_error_t         dma_m_bresp,
  input axi_user_rsp_t      dma_m_buser,
  input logic               dma_m_bvalid,
  // Read addr channel
  input logic               dma_m_arready,
  // Read data channel
  input axi_tid_t           dma_m_rid,
  input axi_data_t          dma_m_rdata,
  input axi_error_t         dma_m_rresp,
  input logic               dma_m_rlast,
  input axi_user_data_t     dma_m_ruser,
  input logic               dma_m_rvalid
);
  s_axil_mosi_t dma_s_mosi;
  s_axil_miso_t dma_s_miso;

  s_axi_mosi_t  dma_m_mosi;
  s_axi_miso_t  dma_m_miso;

  always_comb begin
    // AXI4 Lite interface
    dma_s_mosi.awaddr   = dma_s_awaddr;
    dma_s_mosi.awprot   = dma_s_awprot;
    dma_s_mosi.awvalid  = dma_s_awvalid;
    dma_s_mosi.wdata    = dma_s_wdata;
    dma_s_mosi.wstrb    = dma_s_wstrb;
    dma_s_mosi.wvalid   = dma_s_wvalid;
    dma_s_mosi.bready   = dma_s_bready;
    dma_s_mosi.araddr   = dma_s_araddr;
    dma_s_mosi.arprot   = dma_s_arprot;
    dma_s_mosi.arvalid  = dma_s_arvalid;
    dma_s_mosi.rready   = dma_s_rready;

    dma_s_awready  = dma_s_miso.awready;
    dma_s_wready   = dma_s_miso.wready;
    dma_s_bresp    = dma_s_miso.bresp;
    dma_s_bvalid   = dma_s_miso.bvalid;
    dma_s_arready  = dma_s_miso.arready;
    dma_s_rdata    = dma_s_miso.rdata;
    dma_s_rresp    = dma_s_miso.rresp;
    dma_s_rvalid   = dma_s_miso.rvalid;

    // AXI4 Master interface
    dma_m_awid     = dma_m_mosi.awid;
    dma_m_awaddr   = dma_m_mosi.awaddr;
    dma_m_awlen    = dma_m_mosi.awlen;
    dma_m_awsize   = dma_m_mosi.awsize;
    dma_m_awburst  = dma_m_mosi.awburst;
    dma_m_awlock   = dma_m_mosi.awlock;
    dma_m_awcache  = dma_m_mosi.awcache;
    dma_m_awprot   = dma_m_mosi.awprot;
    dma_m_awqos    = dma_m_mosi.awqos;
    dma_m_awregion = dma_m_mosi.awregion;
    dma_m_awuser   = dma_m_mosi.awuser;
    dma_m_awvalid  = dma_m_mosi.awvalid;
    dma_m_wdata    = dma_m_mosi.wdata;
    dma_m_wstrb    = dma_m_mosi.wstrb;
    dma_m_wlast    = dma_m_mosi.wlast;
    dma_m_wuser    = dma_m_mosi.wuser;
    dma_m_wvalid   = dma_m_mosi.wvalid;
    dma_m_bready   = dma_m_mosi.bready;
    dma_m_arid     = dma_m_mosi.arid;
    dma_m_araddr   = dma_m_mosi.araddr;
    dma_m_arlen    = dma_m_mosi.arlen;
    dma_m_arsize   = dma_m_mosi.arsize;
    dma_m_arburst  = dma_m_mosi.arburst;
    dma_m_arlock   = dma_m_mosi.arlock;
    dma_m_arcache  = dma_m_mosi.arcache;
    dma_m_arprot   = dma_m_mosi.arprot;
    dma_m_arqos    = dma_m_mosi.arqos;
    dma_m_arregion = dma_m_mosi.arregion;
    dma_m_aruser   = dma_m_mosi.aruser;
    dma_m_arvalid  = dma_m_mosi.arvalid;
    dma_m_rready   = dma_m_mosi.rready;

    dma_m_miso.awready = dma_m_awready;
    dma_m_miso.wready  = dma_m_wready;
    dma_m_miso.bid     = dma_m_bid;
    dma_m_miso.bresp   = dma_m_bresp;
    dma_m_miso.buser   = dma_m_buser;
    dma_m_miso.bvalid  = dma_m_bvalid;
    dma_m_miso.arready = dma_m_arready;
    dma_m_miso.rid     = dma_m_rid;
    dma_m_miso.rdata   = dma_m_rdata;
    dma_m_miso.rresp   = dma_m_rresp;
    dma_m_miso.rlast   = dma_m_rlast;
    dma_m_miso.ruser   = dma_m_ruser;
    dma_m_miso.rvalid  = dma_m_rvalid;
  end

  dma_axi_wrapper u_dma_axi_wrapper(
    .clk            (clk),
    .rst            (rst),
    .dma_csr_mosi_i (dma_s_mosi),
    .dma_csr_miso_o (dma_s_miso),
    .dma_m_mosi_o   (dma_m_mosi),
    .dma_m_miso_i   (dma_m_miso),
    .dma_done_o     (dma_done_o),
    .dma_error_o    (dma_error_o)
  );

endmodule
