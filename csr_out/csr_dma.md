## csr_dma

* byte_size
    * 256

|name|offset_address|
|:--|:--|
|[dma_control](#csr_dma-dma_control)|0x00|
|[dma_status](#csr_dma-dma_status)|0x08|
|[dma_error](#csr_dma-dma_error)|0x10|
|[dma_descriptor[5]](#csr_dma-dma_descriptor)|0x20<br>0x40<br>0x60<br>0x80<br>0xa0|

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
|error|[17]|ro|0x0|dma_error.error_trig|Error resume|

### <div id="csr_dma-dma_error"></div>dma_error

* offset_address
    * 0x10
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|error_addr|[31:0]|ro|0x00000000||Error addr|
|error_type|[64]|ro|0x0||Error type - Operation / Configuration|
|error_src|[65]|ro|0x0||Error source - 0 READ / 1 WRITE|
|error_trig|[66]|ro|0x0||Error Trigger, asserted when error happens|

### <div id="csr_dma-dma_descriptor"></div>dma_descriptor[5]

* offset_address
    * 0x20
    * 0x40
    * 0x60
    * 0x80
    * 0xa0
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|src_addr|[31:0]|rw|0x00000000||Source address to fetch data|
|dest_addr|[95:64]|rw|0x00000000||Target address to write data|
|num_bytes|[159:128]|rw|0x00000000||Number of bytes to transfer|
|write_mode|[192]|rw|0x0||Write mode - 0 INCR / 1 FIXED|
|read_mode|[193]|rw|0x0||Read mode - 0 INCR / 1 FIXED|
|enable|[194]|rw|0x0||Enable descriptor|
