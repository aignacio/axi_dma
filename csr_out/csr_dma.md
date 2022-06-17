## csr_dma

* byte_size
    * 256

|name|offset_address|
|:--|:--|
|[dma_control](#csr_dma-dma_control)|0x00|
|[dma_status](#csr_dma-dma_status)|0x08|
|[dma_error_addr](#csr_dma-dma_error_addr)|0x10|
|[dma_error_stats](#csr_dma-dma_error_stats)|0x18|
|[dma_desc_src_addr[5]](#csr_dma-dma_desc_src_addr)|0x20<br>0x28<br>0x30<br>0x38<br>0x40|
|[dma_desc_dst_addr[5]](#csr_dma-dma_desc_dst_addr)|0x48<br>0x50<br>0x58<br>0x60<br>0x68|
|[dma_desc_num_bytes[5]](#csr_dma-dma_desc_num_bytes)|0x70<br>0x78<br>0x80<br>0x88<br>0x90|
|[dma_desc_cfg[5]](#csr_dma-dma_desc_cfg)|0x98<br>0xa0<br>0xa8<br>0xb0<br>0xb8|

### <div id="csr_dma-dma_control"></div>dma_control

* offset_address
    * 0x00
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|go|[0]|rw|0x0||Sets the start for the DMA operation|
|abort|[1]|rw|0x0||Stop DMA operation|
|max_burst|[9:2]|rw|0xff||Max burst length (ALEN) in the AXI txn|

### <div id="csr_dma-dma_status"></div>dma_status

* offset_address
    * 0x08
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|version|[15:0]|rof|0xcafe||DMA version|
|done|[16]|ro|0x0||Asserted when DMA finishes to process all the descriptors|
|error|[17]|ro|0x0|dma_error_stats.error_trig|Error resume|

### <div id="csr_dma-dma_error_addr"></div>dma_error_addr

* offset_address
    * 0x10
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|error_addr|[31:0]|ro|0x00000000||Error addr|

### <div id="csr_dma-dma_error_stats"></div>dma_error_stats

* offset_address
    * 0x18
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|error_type|[0]|ro|0x0||Error type - 0 - Operation / 1 - Configuration|
|error_src|[1]|ro|0x0||Error source - 0 READ / 1 WRITE|
|error_trig|[2]|ro|0x0||Error Trigger, asserted when error happens|

### <div id="csr_dma-dma_desc_src_addr"></div>dma_desc_src_addr[5]

* offset_address
    * 0x20
    * 0x28
    * 0x30
    * 0x38
    * 0x40
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|src_addr|[31:0]|rw|0x00000000||Source address to fetch data|

### <div id="csr_dma-dma_desc_dst_addr"></div>dma_desc_dst_addr[5]

* offset_address
    * 0x48
    * 0x50
    * 0x58
    * 0x60
    * 0x68
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|dst_addr|[31:0]|rw|0x00000000||Target address to write data|

### <div id="csr_dma-dma_desc_num_bytes"></div>dma_desc_num_bytes[5]

* offset_address
    * 0x70
    * 0x78
    * 0x80
    * 0x88
    * 0x90
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|num_bytes|[31:0]|rw|0x00000000||Number of bytes to transfer|

### <div id="csr_dma-dma_desc_cfg"></div>dma_desc_cfg[5]

* offset_address
    * 0x98
    * 0xa0
    * 0xa8
    * 0xb0
    * 0xb8
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|write_mode|[0]|rw|0x0||Write mode - 0 INCR / 1 FIXED|
|read_mode|[1]|rw|0x0||Read mode - 0 INCR / 1 FIXED|
|enable|[2]|rw|0x0||Enable descriptor|
