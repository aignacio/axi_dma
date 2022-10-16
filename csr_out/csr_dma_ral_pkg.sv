package csr_dma_ral_pkg;
  import uvm_pkg::*;
  import rggen_ral_pkg::*;
  `include "uvm_macros.svh"
  `include "rggen_ral_macros.svh"
  class dma_control_reg_model extends rggen_ral_reg;
    rand rggen_ral_field go;
    rand rggen_ral_field abort;
    rand rggen_ral_field max_burst;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(go, 0, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(abort, 1, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(max_burst, 2, 8, "RW", 0, 8'hff, 1, -1, "")
    endfunction
  endclass
  class dma_status_reg_model extends rggen_ral_reg;
    rand rggen_ral_field version;
    rand rggen_ral_field done;
    rand rggen_ral_field error;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(version, 0, 16, "RO", 0, 16'hcafe, 1, -1, "")
      `rggen_ral_create_field(done, 16, 1, "RO", 1, 1'h0, 1, -1, "")
      `rggen_ral_create_field(error, 17, 1, "RO", 1, 1'h0, 1, -1, "dma_error_stats.error_trig")
    endfunction
  endclass
  class dma_error_addr_reg_model extends rggen_ral_reg;
    rand rggen_ral_field error_addr;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(error_addr, 0, 32, "RO", 1, 32'h00000000, 1, -1, "")
    endfunction
  endclass
  class dma_error_stats_reg_model extends rggen_ral_reg;
    rand rggen_ral_field error_type;
    rand rggen_ral_field error_src;
    rand rggen_ral_field error_trig;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(error_type, 0, 1, "RO", 1, 1'h0, 1, -1, "")
      `rggen_ral_create_field(error_src, 1, 1, "RO", 1, 1'h0, 1, -1, "")
      `rggen_ral_create_field(error_trig, 2, 1, "RO", 1, 1'h0, 1, -1, "")
    endfunction
  endclass
  class dma_desc_src_addr_reg_model extends rggen_ral_reg;
    rand rggen_ral_field src_addr;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(src_addr, 0, 32, "RW", 0, 32'h00000000, 1, -1, "")
    endfunction
  endclass
  class dma_desc_dst_addr_reg_model extends rggen_ral_reg;
    rand rggen_ral_field dst_addr;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(dst_addr, 0, 32, "RW", 0, 32'h00000000, 1, -1, "")
    endfunction
  endclass
  class dma_desc_num_bytes_reg_model extends rggen_ral_reg;
    rand rggen_ral_field num_bytes;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(num_bytes, 0, 32, "RW", 0, 32'h00000000, 1, -1, "")
    endfunction
  endclass
  class dma_desc_cfg_reg_model extends rggen_ral_reg;
    rand rggen_ral_field write_mode;
    rand rggen_ral_field read_mode;
    rand rggen_ral_field enable;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(write_mode, 0, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(read_mode, 1, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(enable, 2, 1, "RW", 0, 1'h0, 1, -1, "")
    endfunction
  endclass
  class csr_dma_block_model extends rggen_ral_block;
    rand dma_control_reg_model dma_control;
    rand dma_status_reg_model dma_status;
    rand dma_error_addr_reg_model dma_error_addr;
    rand dma_error_stats_reg_model dma_error_stats;
    rand dma_desc_src_addr_reg_model dma_desc_src_addr[2];
    rand dma_desc_dst_addr_reg_model dma_desc_dst_addr[2];
    rand dma_desc_num_bytes_reg_model dma_desc_num_bytes[2];
    rand dma_desc_cfg_reg_model dma_desc_cfg[2];
    function new(string name);
      super.new(name, 8, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(dma_control, '{}, 8'h00, "RW", "g_dma_control.u_register")
      `rggen_ral_create_reg(dma_status, '{}, 8'h08, "RO", "g_dma_status.u_register")
      `rggen_ral_create_reg(dma_error_addr, '{}, 8'h10, "RO", "g_dma_error_addr.u_register")
      `rggen_ral_create_reg(dma_error_stats, '{}, 8'h18, "RO", "g_dma_error_stats.u_register")
      `rggen_ral_create_reg(dma_desc_src_addr[0], '{0}, 8'h20, "RW", "g_dma_desc_src_addr.g[0].u_register")
      `rggen_ral_create_reg(dma_desc_src_addr[1], '{1}, 8'h28, "RW", "g_dma_desc_src_addr.g[1].u_register")
      `rggen_ral_create_reg(dma_desc_dst_addr[0], '{0}, 8'h30, "RW", "g_dma_desc_dst_addr.g[0].u_register")
      `rggen_ral_create_reg(dma_desc_dst_addr[1], '{1}, 8'h38, "RW", "g_dma_desc_dst_addr.g[1].u_register")
      `rggen_ral_create_reg(dma_desc_num_bytes[0], '{0}, 8'h40, "RW", "g_dma_desc_num_bytes.g[0].u_register")
      `rggen_ral_create_reg(dma_desc_num_bytes[1], '{1}, 8'h48, "RW", "g_dma_desc_num_bytes.g[1].u_register")
      `rggen_ral_create_reg(dma_desc_cfg[0], '{0}, 8'h50, "RW", "g_dma_desc_cfg.g[0].u_register")
      `rggen_ral_create_reg(dma_desc_cfg[1], '{1}, 8'h58, "RW", "g_dma_desc_cfg.g[1].u_register")
    endfunction
  endclass
endpackage
