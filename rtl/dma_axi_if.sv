/**
 * File              : dma_axi_if.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 13.06.2022
 * Last Modified Date: 13.06.2022
 */
module dma_axi_if
  import dma_utils_pkg::*;
(
  input                     clk,
  input                     rst,
  // From/To Streamers
  input   s_dma_axi_req_t   dma_axi_rd_req_i,
  output  s_dma_axi_resp_t  dma_axi_rd_resp_o,
  input   s_dma_axi_req_t   dma_axi_wr_req_i,
  output  s_dma_axi_resp_t  dma_axi_wr_resp_o,
  // Master AXI I/F
  output  s_axi_mosi_t      dma_mosi_o,
  input   s_axi_miso_t      dma_miso_i,
  // From/To FIFOs interface
  output  s_dma_fifo_req_t  dma_fifo_req_o,
  input   s_dma_fifo_resp_t dma_fifo_resp_i,
  // From/To DMA FSM
  output  logic             axi_pend_txn_o,
  output  s_dma_error_t     axi_dma_err_o,
  input                     clear_dma_i,
  input                     dma_abort_i,
  input                     dma_active_i
);
  pend_rd_t     rd_counter_ff, next_rd_counter;
  pend_wr_t     wr_counter_ff, next_wr_counter;
  logic         rd_txn_hpn;
  logic         wr_txn_hpn;
  logic         rd_resp_hpn;
  logic         wr_resp_hpn;
  logic         rd_err_hpn;
  logic         wr_err_hpn;
  axi_addr_t    rd_txn_addr;
  axi_addr_t    wr_txn_addr;
  logic         err_lock_ff, next_err_lock;

  s_dma_error_t dma_error_ff, next_dma_error;

  //logic [$bits(s_dma_axi_req_t)-1:0] in_flat_rd_req;
  //logic [$bits(s_dma_axi_req_t)-1:0] out_flat_rd_req;
  //s_dma_axi_req_t rd_req_int;

  //dma_fifo #(
    //.SLOTS  (`DMA_RD_TXN_BUFF),
    //.WIDTH  ($bits(s_dma_axi_req_t))
  //) u_rd_buf (
    //.clk    (clk),
    //.rst    (rst),
    //.write_i(),
    //.read_i (),
    //.data_i (in_flat_rd_req),
    //.data_o (out_flat_rd_req),
    //.error_o(),
    //.full_o (),
    //.empty_o(),
    //.ocup_o (),
    //.free_o ()
  //);

  dma_fifo #(
    .SLOTS  (`DMA_RD_TXN_BUFF),
    .WIDTH  (`DMA_ADDR_WIDTH)
  ) u_fifo_rd_error (
    .clk    (clk),
    .rst    (rst),
    .write_i(rd_txn_hpn),
    .read_i (rd_resp_hpn),
    .data_i (dma_axi_rd_req_i.addr),
    .data_o (rd_txn_addr),
    .error_o(),
    .full_o (),
    .empty_o(),
    .ocup_o (),
    .free_o ()
  );

  dma_fifo #(
    .SLOTS  (`DMA_WR_TXN_BUFF),
    .WIDTH  (`DMA_ADDR_WIDTH)
  ) u_fifo_wr_error (
    .clk    (clk),
    .rst    (rst),
    .write_i(wr_txn_hpn),
    .read_i (wr_resp_hpn),
    .data_i (dma_axi_wr_req_i.addr),
    .data_o (wr_txn_addr),
    .error_o(),
    .full_o (),
    .empty_o(),
    .ocup_o (),
    .free_o ()
  );

  always_comb begin
    //in_flat_rd_req  = {dma_axi_rd_req_i.addr,
                       //dma_axi_rd_req_i.alen,
                       //dma_axi_rd_req_i.size,
                       //dma_axi_rd_req_i.strb,
                       //1'b0};
    //rd_req_int = s_dma_axi_req_t'(out_flat_rd_req);

    axi_pend_txn_o  = (|rd_counter_ff) || (|wr_counter_ff);
    axi_dma_err_o   = dma_error_ff;
    next_dma_error  = dma_error_ff;
    next_err_lock   = err_lock_ff;
    next_rd_counter = rd_counter_ff;
    next_wr_counter = wr_counter_ff;

    if (~dma_active_i) begin
      next_err_lock   = 1'b0;
      next_rd_counter = 'd0;
      next_wr_counter = 'd0;
    end

    if (~err_lock_ff) begin
      if (rd_err_hpn) begin
        next_dma_error.valid    = 1'b1;
        next_dma_error.type_err = DMA_ERR_OPE;
        next_dma_error.src      = DMA_ERR_RD;
        next_dma_error.addr     = rd_txn_addr;
      end
      else if (wr_err_hpn) begin
        next_dma_error.valid    = 1'b1;
        next_dma_error.type_err = DMA_ERR_OPE;
        next_dma_error.src      = DMA_ERR_WR;
        next_dma_error.addr     = wr_txn_addr;
      end
    end

    rd_txn_hpn  = dma_mosi_o.arvalid && dma_miso_i.arready;
    rd_resp_hpn = dma_miso_i.rvalid && dma_miso_i.rlast && dma_mosi_o.rready;
    wr_txn_hpn  = dma_mosi_o.awvalid && dma_miso_i.awready;
    wr_resp_hpn = dma_miso_i.bvalid && dma_mosi_o.bready;

    if (rd_txn_hpn) begin
      next_rd_counter = rd_counter_ff + 'd1;
    end

    if (wr_txn_hpn) begin
      next_wr_counter = wr_counter_ff + 'd1;
    end
  end

  always_comb begin : axi4_master
    dma_mosi_o = s_axi_mosi_t'('0);
    dma_fifo_req_o = s_dma_fifo_req_t'('0);
    rd_err_hpn = 1'b0;
    wr_err_hpn = 1'b0;
    dma_axi_rd_resp_o = s_dma_axi_resp_t'('0);
    dma_axi_wr_resp_o = s_dma_axi_resp_t'('0);

    if (dma_active_i) begin
      // Address Read Channel - AR*
      dma_mosi_o.arvalid = (rd_counter_ff <= `DMA_RD_TXN_BUFF) ? dma_axi_rd_req_i.valid : 1'b0;
      dma_axi_rd_resp_o.ready = dma_miso_i.arready;
      if (dma_mosi_o.arvalid) begin
        dma_mosi_o.araddr  = dma_axi_rd_req_i.addr;
        dma_mosi_o.arlen   = dma_axi_rd_req_i.alen;
        dma_mosi_o.arsize  = dma_axi_rd_req_i.size;
        dma_mosi_o.arburst = (dma_axi_rd_req_i.mode == DMA_MODE_INCR) ? AXI_INCR : AXI_FIXED;
      end
      // Read Data Channel - R*
      dma_mosi_o.rready = ~dma_fifo_resp_i.full;
      if (dma_miso_i.rvalid) begin
        dma_fifo_req_o.rd      = 1'b1;
        dma_fifo_req_o.data_wr = dma_miso_i.rdata;
        if (dma_miso_i.rlast) begin
          rd_err_hpn = (dma_miso_i.rresp == AXI_SLVERR) ||
                       (dma_miso_i.rresp == AXI_DECERR);
        end
      end
      // Address Write Channel - AW*
      dma_mosi_o.awvalid = (wr_counter_ff <= `DMA_WR_TXN_BUFF) ? dma_axi_wr_req_i.valid : 1'b0;
      dma_axi_wr_resp_o.ready = dma_miso_i.awready;
      if (dma_mosi_o.awvalid) begin
        dma_mosi_o.awaddr  = dma_axi_wr_req_i.addr;
        dma_mosi_o.awlen   = dma_axi_wr_req_i.alen;
        dma_mosi_o.awsize  = dma_axi_wr_req_i.size;
        dma_mosi_o.awburst = (dma_axi_wr_req_i.mode == DMA_MODE_INCR) ? AXI_INCR : AXI_FIXED;
      end
      // Write Data Channel - W*
      // TODO
      // Write Response Channel - B*
      dma_mosi_o.bready = 1'b1;
      if (dma_miso_i.bvalid) begin
        wr_err_hpn  = (dma_miso_i.bresp == AXI_SLVERR) ||
                      (dma_miso_i.bresp == AXI_DECERR);
      end
    end
  end : axi4_master

  always_ff @ (posedge clk) begin
    if (rst) begin
      rd_counter_ff <= pend_rd_t'('0);
      wr_counter_ff <= pend_rd_t'('0);
      dma_error_ff  <= s_dma_error_t'('0);
      err_lock_ff   <= 1'b0;
    end
    else begin
      rd_counter_ff <= next_rd_counter;
      wr_counter_ff <= next_wr_counter;
      dma_error_ff  <= next_dma_error;
      err_lock_ff   <= next_err_lock;
    end
  end
endmodule
