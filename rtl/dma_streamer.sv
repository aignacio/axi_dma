/**
 * File              : dma_streamer.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.06.2022
 * Last Modified Date: 15.10.2022
 */
module dma_streamer
  import amba_axi_pkg::*;
  import dma_utils_pkg::*;
#(
  parameter bit STREAM_TYPE = 0 // 0 - Read, 1 - Write
) (
  input                                     clk,
  input                                     rst,
  // From/To CSRs
  input   s_dma_desc_t [`DMA_NUM_DESC-1:0]  dma_desc_i,
  input                                     dma_abort_i,
  input   maxb_t                            dma_maxb_i,
  // From/To AXI I/F
  output  s_dma_axi_req_t                   dma_axi_req_o,
  input   s_dma_axi_resp_t                  dma_axi_resp_i,
  // To/From DMA FSM
  input   s_dma_str_in_t                    dma_stream_i,
  output  s_dma_str_out_t                   dma_stream_o
);
  localparam bytes_p_burst = (`DMA_DATA_WIDTH/8);
  localparam max_txn_width = $clog2(`DMA_MAX_BEAT_BURST*(`DMA_DATA_WIDTH/8));

  dma_sm_t    cur_st_ff,      next_st;
  axi_addr_t  desc_addr_ff,   next_desc_addr;
  desc_num_t  desc_bytes_ff,  next_desc_bytes;
  dma_mode_t  dma_mode_ff,    next_dma_mode;

  typedef logic [max_txn_width:0] max_bytes_t;

  s_dma_axi_req_t dma_req_ff, next_dma_req;
  max_bytes_t     txn_bytes;

  logic last_txn_ff, next_last_txn;
  logic full_burst;
  logic [3:0] num_unalign_bytes;
  logic       last_txn_proc;

  function automatic axi_wr_strb_t get_strb(logic [2:0] addr, logic [3:0] bytes);
    axi_wr_strb_t strobe;
    if (`DMA_DATA_WIDTH == 64) begin
      /* verilator lint_off WIDTH */
      case (bytes)
        'd1:  strobe = 'b0000_0001;
        'd2:  strobe = 'b0000_0011;
        'd3:  strobe = 'b0000_0111;
        'd4:  strobe = 'b0000_1111;
        'd5:  strobe = 'b0001_1111;
        'd6:  strobe = 'b0011_1111;
        'd7:  strobe = 'b0111_1111;
        default:  strobe = '0;
      endcase
      /* verilator lint_on WIDTH */
    end
    else begin
      case (bytes)
        'd1:  strobe = 'b0001;
        'd2:  strobe = 'b0011;
        'd3:  strobe = 'b0111;
        'd4:  strobe = 'b1111;
        default:  strobe = '0;
      endcase
    end

    if (`DMA_EN_UNALIGNED) begin
      for (logic [3:0] i=0; i<8; i++) begin
        if (addr == i[2:0]) begin
          strobe = strobe << i;
        end
      end
    end
    return strobe;
  endfunction

  function automatic logic [3:0] bytes_to_align(axi_addr_t addr);
    if (`DMA_DATA_WIDTH == 32) begin
      return (4'd4 - {2'b00,addr[1:0]});
    end
    else if (`DMA_DATA_WIDTH == 64) begin
      return (4'd8 - {1'b0,addr[2:0]});
    end
  endfunction

  function automatic axi_addr_t aligned_addr(axi_addr_t addr);
    if (`DMA_DATA_WIDTH == 32) begin
      return {addr[`DMA_ADDR_WIDTH-1:2],2'b00};
    end
    else begin
      return {addr[`DMA_ADDR_WIDTH-1:3],3'b000};
    end
  endfunction

  function automatic logic valid_burst(dma_mode_t mode, logic [8:0] alen_plus_1);
    if (mode == DMA_MODE_FIXED) begin
      return (alen_plus_1 <= 16);
    end
    else begin
      return 1;
    end
  endfunction

  function automatic logic is_aligned(axi_addr_t addr);
    if (`DMA_DATA_WIDTH == 32) begin
      return (addr[1:0] == '0);
    end
    else begin
      return (addr[2:0] == '0);
    end
  endfunction

  function automatic logic enough_for_burst(desc_num_t bytes);
    if (`DMA_DATA_WIDTH == 32) begin
      return (bytes >= 'd4);
    end
    else begin
      return (bytes >= 'd8);
    end
  endfunction

  function automatic logic burst_r4KB(axi_addr_t base, axi_addr_t fut);
    if (fut[`DMA_ADDR_WIDTH-1:12] < base[`DMA_ADDR_WIDTH-1:12]) begin // Overflow
      return 0; // Boundary hit
    end
    else begin
      if (fut[`DMA_ADDR_WIDTH-1:12] > base[`DMA_ADDR_WIDTH-1:12]) begin
        return (fut[11:0] == '0); // Base + burst fits exactly 4KB boundary, np
      end
      else begin
        return 1; //No leakage
      end
    end
  endfunction

  function automatic axi_alen_t great_alen(axi_addr_t addr, desc_num_t bytes);
    axi_addr_t fut_addr;
    axi_alen_t alen = 0; // Single beat-burst
    desc_num_t txn_sz;

    for (int i=`DMA_MAX_BEAT_BURST; i>0; i--) begin
      // Check if we have enough bytes for this alen and that if
      // it is less or equal than the max burst configured in the
      // CSRs and the burst mode
      fut_addr = addr+(i*bytes_p_burst);
      txn_sz = (i*bytes_p_burst);
      if ((bytes >= txn_sz) && ((`DMA_MAX_BURST_EN == 1) ? ((i-'d1) <= dma_maxb_i) : 1'b1) && ((`DMA_MAX_BEAT_BURST > 16) ? valid_burst(dma_mode_ff, i[8:0]) : 1'b1)) begin
        // Check if we respect the 4KB boundary per burst
        if (burst_r4KB(addr, fut_addr)) begin
          alen = axi_alen_t'(i-1);
          return alen;
        end
      end
    end
  endfunction

  always_comb begin : streamer_dma_ctrl
    next_st = DMA_ST_SM_IDLE;
    case (cur_st_ff)
      DMA_ST_SM_IDLE: begin
        if (dma_stream_i.valid) begin
          next_st = DMA_ST_SM_RUN;
        end
      end
      DMA_ST_SM_RUN: begin
        if (dma_abort_i) begin
          if (last_txn_proc) begin
            next_st = DMA_ST_SM_RUN;
          end
          else begin
            next_st = DMA_ST_SM_IDLE;
          end
        end
        else begin
          // Normal proc
          if (desc_bytes_ff > 0) begin
            next_st = DMA_ST_SM_RUN;
          end
          else if (last_txn_ff && ~dma_axi_resp_i.ready) begin
            next_st = DMA_ST_SM_RUN;
          end
        end
      end
    endcase
  end : streamer_dma_ctrl

  always_comb begin : burst_calc
    dma_stream_o      = s_dma_str_out_t'('0);
    next_dma_mode     = dma_mode_ff;
    next_dma_req      = dma_req_ff;
    next_desc_addr    = desc_addr_ff;
    next_desc_bytes   = desc_bytes_ff;
    dma_axi_req_o     = dma_req_ff;
    next_last_txn     = last_txn_ff;
    last_txn_proc     = 1'b0;
    full_burst        = 1'b0;
    num_unalign_bytes = '0;

    // Initialize Stream operation
    if ((cur_st_ff == DMA_ST_SM_IDLE) && (next_st == DMA_ST_SM_RUN)) begin
      next_desc_bytes =  dma_desc_i[dma_stream_i.idx].num_bytes;

      if (STREAM_TYPE) begin
        next_desc_addr = dma_desc_i[dma_stream_i.idx].dst_addr;
        next_dma_mode = dma_desc_i[dma_stream_i.idx].wr_mode;
      end
      else begin
        next_desc_addr = dma_desc_i[dma_stream_i.idx].src_addr;
        next_dma_mode = dma_desc_i[dma_stream_i.idx].rd_mode;
      end
    end

    txn_bytes = max_bytes_t'('0);

    // Burst computation
    if (cur_st_ff == DMA_ST_SM_RUN) begin
      if (~dma_abort_i) begin
        // Send the request when:
        // - Request not sent yet (First request)
        // - Next one
        // - Not the last one
        if ((~dma_req_ff.valid || (dma_req_ff.valid && dma_axi_resp_i.ready)) && ~last_txn_ff) begin
          // Best case, send as much as possible through a single txn
          // respecting the 4KB boundary and burst type INCR/FIXED
          next_dma_req.addr = aligned_addr(desc_addr_ff);
          next_dma_req.size = (`DMA_DATA_WIDTH == 32) ? axi_size_t'(2) : axi_size_t'(3);
          next_dma_req.mode = dma_mode_t'(dma_mode_ff);

          if (is_aligned(desc_addr_ff) && enough_for_burst(desc_bytes_ff)) begin
            next_dma_req.alen = great_alen(desc_addr_ff, desc_bytes_ff);
            next_dma_req.strb = '1;
            full_burst = 1'b1;
          end
          else begin
            next_dma_req.alen = axi_alen_t'('0);
            // Three possible cases here, beginning, end of processing or small descriptor
            if (`DMA_EN_UNALIGNED) begin
              if (enough_for_burst(desc_bytes_ff)) begin // Beginning unaligned
                num_unalign_bytes = bytes_to_align(desc_addr_ff);
                next_dma_req.strb = get_strb(desc_addr_ff[2:0], num_unalign_bytes);
              end
              else if (is_aligned(desc_addr_ff)) begin // Now it's aligned but not enough bytes, end of processing
                num_unalign_bytes = desc_bytes_ff[3:0];
                next_dma_req.strb = get_strb('d0, num_unalign_bytes);
              end
              else begin // Small descriptor
                num_unalign_bytes = desc_bytes_ff[3:0];
                next_dma_req.strb = get_strb(desc_addr_ff[2:0], num_unalign_bytes);
              end
            end
            else begin
              num_unalign_bytes = desc_bytes_ff[3:0];
              next_dma_req.strb = get_strb('d0, num_unalign_bytes);
            end
          end
          /* verilator lint_off WIDTH */
          txn_bytes       = full_burst ? max_bytes_t'((next_dma_req.alen+8'd1)*bytes_p_burst) :
                                         max_bytes_t'(num_unalign_bytes);
          /* verilator lint_on WIDTH */
          next_desc_bytes = desc_bytes_ff - desc_num_t'(txn_bytes);
          next_last_txn   = (next_desc_bytes == '0);
          if (dma_mode_ff == DMA_MODE_FIXED) begin
            next_desc_addr = desc_addr_ff;
          end
          else begin
            next_desc_addr = desc_addr_ff + axi_addr_t'(txn_bytes);
          end

          next_dma_req.valid = 1'b1;
        end
        else if (last_txn_ff && dma_axi_resp_i.ready) begin
          next_dma_req = s_dma_axi_req_t'('0);
          next_last_txn = 1'b0;
        end
      end
      else begin
        if (dma_req_ff.valid && ~dma_axi_resp_i.ready) begin
          last_txn_proc = 'b1;
        end
        else begin
          next_dma_req = s_dma_axi_req_t'('0);
        end
      end
    end

    dma_stream_o.done = ((cur_st_ff == DMA_ST_SM_RUN) && (next_st == DMA_ST_SM_IDLE));
  end : burst_calc

  always_ff @ (posedge clk) begin
    if (rst) begin
      cur_st_ff     <= dma_sm_t'('0);
      desc_addr_ff  <= axi_addr_t'('0);
      desc_bytes_ff <= desc_num_t'('0);
      dma_mode_ff   <= dma_mode_t'('0);
      last_txn_ff   <= 1'b0;
      dma_req_ff    <= 1'b0;
    end
    else begin
      cur_st_ff     <= next_st;
      desc_addr_ff  <= next_desc_addr;
      desc_bytes_ff <= next_desc_bytes;
      dma_mode_ff   <= next_dma_mode;
      last_txn_ff   <= next_last_txn;
      dma_req_ff    <= next_dma_req;
    end
  end
endmodule
