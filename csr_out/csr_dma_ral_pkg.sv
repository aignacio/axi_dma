package csr_dma_ral_pkg;
  import uvm_pkg::*;
  import rggen_ral_pkg::*;
  `include "uvm_macros.svh"
  `include "rggen_ral_macros.svh"
  class dma_control_reg_model extends rggen_ral_reg;
    rand rggen_ral_field go;
    rand rggen_ral_field abort;
    function new(string name);
      super.new(name, 64, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(go, 0, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(abort, 1, 1, "RW", 0, 1'h0, 1, -1, "")
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
      `rggen_ral_create_field(error, 17, 1, "RO", 1, 1'h0, 1, -1, "dma_error.error_trig")
    endfunction
  endclass
  class dma_error_reg_model extends rggen_ral_reg;
    rand rggen_ral_field error_addr;
    rand rggen_ral_field error_type;
    rand rggen_ral_field error_src;
    rand rggen_ral_field error_trig;
    function new(string name);
      super.new(name, 128, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(error_addr, 0, 32, "RO", 1, 32'h00000000, 1, -1, "")
      `rggen_ral_create_field(error_type, 64, 1, "RO", 1, 1'h0, 1, -1, "")
      `rggen_ral_create_field(error_src, 65, 1, "RO", 1, 1'h0, 1, -1, "")
      `rggen_ral_create_field(error_trig, 66, 1, "RO", 1, 1'h0, 1, -1, "")
    endfunction
  endclass
  class dma_descriptor_reg_model extends rggen_ral_reg;
    rand rggen_ral_field src_addr;
    rand rggen_ral_field dest_addr;
    rand rggen_ral_field num_bytes;
    rand rggen_ral_field write_mode;
    rand rggen_ral_field read_mode;
    rand rggen_ral_field enable;
    function new(string name);
      super.new(name, 256, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(src_addr, 0, 32, "RW", 0, 32'h00000000, 1, -1, "")
      `rggen_ral_create_field(dest_addr, 64, 32, "RW", 0, 32'h00000000, 1, -1, "")
      `rggen_ral_create_field(num_bytes, 128, 32, "RW", 0, 32'h00000000, 1, -1, "")
      `rggen_ral_create_field(write_mode, 192, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(read_mode, 193, 1, "RW", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(enable, 194, 1, "RW", 0, 1'h0, 1, -1, "")
    endfunction
  endclass
  class csr_dma_block_model extends rggen_ral_block;
    rand dma_control_reg_model dma_control;
    rand dma_status_reg_model dma_status;
    rand dma_error_reg_model dma_error;
    rand dma_descriptor_reg_model dma_descriptor[5];
    function new(string name);
      super.new(name, 8, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(dma_control, '{}, 8'h00, "RW", "g_dma_control.u_register")
      `rggen_ral_create_reg(dma_status, '{}, 8'h08, "RO", "g_dma_status.u_register")
      `rggen_ral_create_reg(dma_error, '{}, 8'h10, "RO", "g_dma_error.u_register")
      `rggen_ral_create_reg(dma_descriptor[0], '{0}, 8'h20, "RW", "g_dma_descriptor.g[0].u_register")
      `rggen_ral_create_reg(dma_descriptor[1], '{1}, 8'h40, "RW", "g_dma_descriptor.g[1].u_register")
      `rggen_ral_create_reg(dma_descriptor[2], '{2}, 8'h60, "RW", "g_dma_descriptor.g[2].u_register")
      `rggen_ral_create_reg(dma_descriptor[3], '{3}, 8'h80, "RW", "g_dma_descriptor.g[3].u_register")
      `rggen_ral_create_reg(dma_descriptor[4], '{4}, 8'ha0, "RW", "g_dma_descriptor.g[4].u_register")
    endfunction
  endclass
endpackage
