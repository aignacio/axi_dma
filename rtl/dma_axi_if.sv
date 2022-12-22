/**
 * File              : dma_axi_if.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 13.06.2022
 * Last Modified Date: 30.06.2022
 */
module dma_axi_if
  import amba_axi_pkg::*;
  import dma_utils_pkg::*;
#(
  parameter int DMA_ID_VAL = 0
)(
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
  axi_wr_strb_t rd_txn_last_strb;
  logic         rd_txn_hpn;
  logic         wr_txn_hpn;
  logic         rd_resp_hpn;
  logic         wr_resp_hpn;
  logic         rd_err_hpn;
  logic         wr_err_hpn;
  axi_addr_t    rd_txn_addr;
  axi_addr_t    wr_txn_addr;
  logic         err_lock_ff, next_err_lock;
  logic         wr_data_txn_hpn;
  logic         wr_lock_ff, next_wr_lock;
  logic         wr_new_txn;
  logic         wr_beat_hpn;
  logic         wr_data_req_empty;
  logic         aw_txn_started_ff, next_aw_txn;

  s_wr_req_t    wr_data_req_in, wr_data_req_out;
  axi_alen_t    beat_counter_ff, next_beat_count;

  s_dma_error_t dma_error_ff, next_dma_error;

  function automatic axi_data_t apply_strb(axi_data_t data, axi_wr_strb_t mask);
    axi_data_t out_data;
    for (int i=0; i<$bits(axi_wr_strb_t); i++) begin
      if (mask[i] == 1'b1) begin
        out_data[(8*i)+:8] = data[(8*i)+:8];
      end
      else begin
        out_data[(8*i)+:8] = 8'd0;
      end
    end
    return out_data;
  endfunction

  //***************************************************
  // Queue the txn from the wr streamer to send in the
  // data channel
  //***************************************************
  dma_fifo #(
    .SLOTS  (`DMA_WR_TXN_BUFF),
    .WIDTH  ($bits(s_wr_req_t))
  ) u_fifo_wr_data (
    .clk    (clk),
    .rst    (rst),
    .write_i(wr_new_txn),
    .read_i (wr_data_txn_hpn),
    .data_i (wr_data_req_in),
    .data_o (wr_data_req_out),
    .error_o(),
    .full_o (),
    .empty_o(wr_data_req_empty),
    .ocup_o (),
    .clear_i(1'b0),
    .free_o ()
  );

  //***************************************************
  // Stores the strb mask used in case of unaligned
  // start/end addresses for reads
  //***************************************************
  dma_fifo #(
    .SLOTS  (`DMA_RD_TXN_BUFF),
    .WIDTH  ($bits(axi_wr_strb_t))
  ) u_fifo_rd_strb (
    .clk    (clk),
    .rst    (rst),
    .write_i(rd_txn_hpn),
    .read_i (rd_resp_hpn),
    .data_i (dma_axi_rd_req_i.strb),
    .data_o (rd_txn_last_strb),
    .error_o(),
    .full_o (),
    .empty_o(),
    .ocup_o (),
    .clear_i(1'b0),
    .free_o ()
  );

  //***************************************************
  // Stores the address of the txn that were dispatched
  // for further logging in case of error
  //***************************************************
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
    .clear_i(1'b0),
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
    .clear_i(1'b0),
    .free_o ()
  );

  always_comb begin
    axi_pend_txn_o  = (|rd_counter_ff) || (|wr_counter_ff);
    axi_dma_err_o   = dma_error_ff;
    next_dma_error  = dma_error_ff;
    next_err_lock   = err_lock_ff;
    next_rd_counter = rd_counter_ff;
    next_wr_counter = wr_counter_ff;

    if (~dma_active_i) begin
      next_err_lock   = 1'b0;
    end
    else begin
      next_err_lock = rd_err_hpn || wr_err_hpn;
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

    if (clear_dma_i) begin
      next_dma_error = s_dma_error_t'('0);
      next_wr_lock   = 1'b0;
    end

    rd_txn_hpn  = dma_mosi_o.arvalid && dma_miso_i.arready;
    rd_resp_hpn = dma_miso_i.rvalid &&
                  dma_miso_i.rlast  &&
                  dma_mosi_o.rready;
    wr_txn_hpn  = dma_mosi_o.awvalid && dma_miso_i.awready;
    wr_resp_hpn = dma_miso_i.bvalid && dma_mosi_o.bready;

    if (dma_active_i) begin
      if (rd_txn_hpn || rd_resp_hpn) begin
        next_rd_counter = rd_counter_ff + (rd_txn_hpn ? 'd1 : 'd0) - (rd_resp_hpn ? 'd1 : 'd0);
      end

      if (wr_txn_hpn || wr_resp_hpn) begin
        next_wr_counter = wr_counter_ff + (wr_txn_hpn ? 'd1 : 'd0) - (wr_resp_hpn ? 'd1 : 'd0);
      end
    end
    else begin
      next_rd_counter = 'd0;
      next_wr_counter = 'd0;
    end
    // Write Data Txn finished
    wr_data_txn_hpn = dma_mosi_o.wvalid &&
                      dma_mosi_o.wlast  &&
                      dma_miso_i.wready;

    // Every time we have a new req. coming from the wr streamer,
    // we store in the queue to push through the wr data channel
    // in the next CC. However, we don't send multiple wr data txn
    // without handshake in the wr address channel first. Having
    // both AWVALID + WVALID asserted is intended to break deadlock
    // depency in the AXI4 (A3.3 Relationships between the channels
    // page 44 - AXI4 Spec)
    wr_new_txn  = 1'b0;
    next_wr_lock = wr_lock_ff;
    wr_data_req_in = s_wr_req_t'('0);
    if (dma_axi_wr_req_i.valid) begin
      next_wr_lock = ~dma_axi_wr_resp_o.ready;
      wr_new_txn   = ~wr_lock_ff;
      wr_data_req_in.alen  = dma_axi_wr_req_i.alen;
      wr_data_req_in.wstrb = dma_axi_wr_req_i.strb;
    end

    if (wr_txn_hpn) begin
      next_wr_lock = 1'b0;
    end

    wr_beat_hpn = dma_mosi_o.wvalid && dma_miso_i.wready;
    next_beat_count = beat_counter_ff;

    // Increment each beat of the burst
    if (wr_beat_hpn) begin
      next_beat_count = beat_counter_ff + 'd1;
    end

    // If the last beat of the burst happens,
    // lets clear the beat counter
    if (wr_data_txn_hpn) begin
      next_beat_count = axi_alen_t'('0);
    end
  end

  always_comb begin : axi4_master
    dma_mosi_o = s_axi_mosi_t'('0);
    dma_fifo_req_o = s_dma_fifo_req_t'('0);
    rd_err_hpn = 1'b0;
    wr_err_hpn = 1'b0;
    dma_axi_rd_resp_o = s_dma_axi_resp_t'('0);
    dma_axi_wr_resp_o = s_dma_axi_resp_t'('0);
    next_aw_txn = aw_txn_started_ff;

    if (dma_active_i) begin
      // Address Read Channel - AR*
      dma_mosi_o.arprot = AXI_NONSECURE;
      dma_mosi_o.arid   = axi_tid_t'(DMA_ID_VAL);

      dma_mosi_o.arvalid = (rd_counter_ff < `DMA_RD_TXN_BUFF) ? dma_axi_rd_req_i.valid : 1'b0;
      if (dma_mosi_o.arvalid) begin
        dma_axi_rd_resp_o.ready = dma_miso_i.arready;
        dma_mosi_o.araddr  = dma_axi_rd_req_i.addr;
        dma_mosi_o.arlen   = dma_axi_rd_req_i.alen;
        dma_mosi_o.arsize  = dma_axi_rd_req_i.size;
        dma_mosi_o.arburst = (dma_axi_rd_req_i.mode == DMA_MODE_INCR) ? AXI_INCR : AXI_FIXED;
      end
      // Read Data Channel - R*
      dma_mosi_o.rready = (~dma_fifo_resp_i.full || dma_abort_i); // Available to recv if we're not full or there's an abort in progress
      if (dma_miso_i.rvalid && (~dma_fifo_resp_i.full || dma_abort_i)) begin
        dma_fifo_req_o.wr      = dma_abort_i ? 1'b0 : 1'b1; // Ignore incoming data in case of abort
        dma_fifo_req_o.data_wr = apply_strb(dma_miso_i.rdata, rd_txn_last_strb);
        if (dma_miso_i.rlast && dma_mosi_o.rready) begin
          rd_err_hpn = (dma_miso_i.rresp == AXI_SLVERR) ||
                       (dma_miso_i.rresp == AXI_DECERR);
        end
      end
      // Address Write Channel - AW*
      dma_mosi_o.awprot = AXI_NONSECURE;
      dma_mosi_o.awid   = axi_tid_t'(DMA_ID_VAL);
      // Send a write txn based on the following conditions:
      // 1- if (we have enough buffer space - `DMA_WR_TXN_BUFF)
      // 2- We have a request coming from the streamer - ...valid
      // 3- ...and we have something to send in the data phase ...~empty
      // 3 (OR)- we have an abort request, so we can ignore the DMA_FIFO
      // 4- Or we have started a txn and we need to respect valid/ready handshake.
      //    We could potentially put awvalid back to low if dma_fifo gets empty
      //    while we are waiting for awready from the slave
      dma_mosi_o.awvalid = (wr_counter_ff < `DMA_WR_TXN_BUFF) ? ((dma_axi_wr_req_i.valid &&
                           (~dma_fifo_resp_i.empty || dma_abort_i)) || aw_txn_started_ff) : 1'b0;
      if (dma_mosi_o.awvalid) begin
        dma_axi_wr_resp_o.ready = dma_miso_i.awready;
        dma_mosi_o.awaddr  = dma_axi_wr_req_i.addr;
        dma_mosi_o.awlen   = dma_axi_wr_req_i.alen;
        dma_mosi_o.awsize  = dma_axi_wr_req_i.size;
        dma_mosi_o.awburst = (dma_axi_wr_req_i.mode == DMA_MODE_INCR) ? AXI_INCR : AXI_FIXED;
        next_aw_txn        = ~dma_miso_i.awready; // Ensures we respect valid / ready AMBA protocol
      end
      // Write Data Channel - W*
      if (~wr_data_req_empty && (~dma_fifo_resp_i.empty || dma_abort_i)) begin
        dma_fifo_req_o.rd = dma_abort_i ? 1'b0 : dma_miso_i.wready; // Ignore fifo content in case of abort
        dma_mosi_o.wdata  = dma_fifo_resp_i.data_rd;
        dma_mosi_o.wstrb  = wr_data_req_out.wstrb;
        dma_mosi_o.wlast  = (beat_counter_ff == wr_data_req_out.alen);
        dma_mosi_o.wvalid = 1'b1;
      end
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
      rd_counter_ff     <= pend_rd_t'('0);
      wr_counter_ff     <= pend_rd_t'('0);
      dma_error_ff      <= s_dma_error_t'('0);
      err_lock_ff       <= 1'b0;
      beat_counter_ff   <= '0;
      wr_lock_ff        <= 1'b0;
      aw_txn_started_ff <= 1'b0;
    end
    else begin
      rd_counter_ff     <= next_rd_counter;
      wr_counter_ff     <= next_wr_counter;
      dma_error_ff      <= next_dma_error;
      err_lock_ff       <= next_err_lock;
      beat_counter_ff   <= next_beat_count;
      wr_lock_ff        <= next_wr_lock;
      aw_txn_started_ff <= next_aw_txn;
    end
  end

`ifndef NO_ASSERTIONS
  `ifndef VERILATOR
    axi4_arvalid_arready : assert property(@(posedge clk) $rose(dma_mosi_o.arvalid) |-> dma_mosi_o.arvalid          throughout dma_miso_i.arready[->1]);
    axi4_arvalid_araddr  : assert property(@(posedge clk) $rose(dma_mosi_o.arvalid) |-> $stable(dma_mosi_o.araddr)  throughout dma_miso_i.arready[->1]);
    axi4_arvalid_arlen   : assert property(@(posedge clk) $rose(dma_mosi_o.arvalid) |-> $stable(dma_mosi_o.arlen)   throughout dma_miso_i.arready[->1]);
    axi4_arvalid_arsize  : assert property(@(posedge clk) $rose(dma_mosi_o.arvalid) |-> $stable(dma_mosi_o.arsize)  throughout dma_miso_i.arready[->1]);
    axi4_arvalid_arburst : assert property(@(posedge clk) $rose(dma_mosi_o.arvalid) |-> $stable(dma_mosi_o.arburst) throughout dma_miso_i.arready[->1]);

    axi4_awvalid_awready : assert property(@(posedge clk) $rose(dma_mosi_o.awvalid) |-> dma_mosi_o.awvalid          throughout dma_miso_i.awready[->1]);
    axi4_awvalid_awaddr  : assert property(@(posedge clk) $rose(dma_mosi_o.awvalid) |-> $stable(dma_mosi_o.awaddr)  throughout dma_miso_i.awready[->1]);
    axi4_awvalid_awlen   : assert property(@(posedge clk) $rose(dma_mosi_o.awvalid) |-> $stable(dma_mosi_o.awlen)   throughout dma_miso_i.awready[->1]);
    axi4_awvalid_awsize  : assert property(@(posedge clk) $rose(dma_mosi_o.awvalid) |-> $stable(dma_mosi_o.awsize)  throughout dma_miso_i.awready[->1]);
    axi4_awvalid_awburst : assert property(@(posedge clk) $rose(dma_mosi_o.awvalid) |-> $stable(dma_mosi_o.awburst) throughout dma_miso_i.awready[->1]);

    axi4_wvalid_wready   : assert property(@(posedge clk) $rose(dma_mosi_o.wvalid)  |-> dma_mosi_o.wvalid           throughout dma_miso_i.wready[->1]);
    axi4_wvalid_wdata    : assert property(@(posedge clk) $rose(dma_mosi_o.wvalid)  |-> dma_mosi_o.wdata            throughout dma_miso_i.wready[->1]);
    axi4_wvalid_wstrb    : assert property(@(posedge clk) $rose(dma_mosi_o.wvalid)  |-> dma_mosi_o.wstrb            throughout dma_miso_i.wready[->1]);
    axi4_wvalid_wlast    : assert property(@(posedge clk) $rose(dma_mosi_o.wvalid)  |-> dma_mosi_o.wlast            throughout dma_miso_i.wready[->1]);

    axi4_bvalid_bready   : assert property(@(posedge clk) $rose(dma_miso_i.bvalid)  |-> dma_miso_i.bvalid           throughout dma_mosi_o.bready[->1]);
    axi4_bvalid_bresp    : assert property(@(posedge clk) $rose(dma_miso_i.bvalid)  |-> $stable(dma_miso_i.bresp)   throughout dma_mosi_o.bready[->1]);

    axi4_rvalid_rready   : assert property(@(posedge clk) $rose(dma_miso_i.rvalid)  |-> dma_miso_i.rvalid           throughout dma_mosi_o.rready[->1]);
    axi4_rvalid_rdata    : assert property(@(posedge clk) $rose(dma_miso_i.rvalid)  |-> $stable(dma_miso_i.rdata)   throughout dma_mosi_o.rready[->1]);
    axi4_rvalid_rlast    : assert property(@(posedge clk) $rose(dma_miso_i.rvalid)  |-> $stable(dma_miso_i.rlast)   throughout dma_mosi_o.rready[->1]);
  `endif
`endif
endmodule
