## csr_dma

* byte_size
    * 256

|name|offset_address|
|:--|:--|
|[dma_control](#csr_dma-dma_control)|0x00|
|[dma_status](#csr_dma-dma_status)|0x04|
|[dma_error](#csr_dma-dma_error)|0x08|
|[dma_descriptor[5]](#csr_dma-dma_descriptor)|0x10<br>0x20<br>0x30<br>0x40<br>0x50|

### <div id="csr_dma-dma_control"></div>dma_control

* offset_address
    * 0x00
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|go|[0]|rw|0x0||Sets the start for the DMA operation|
|abort|[1]|rw|0x0||Stop DMA operation|

### <div id="csr_dma-dma_status"></div>dma_status

* offset_address
    * 0x04
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|done|[0]|ro|0x0||Asserted when DMA finishes to process all the descriptors|
|version|[16:1]|rof|0xcafe||DMA version|
|error|[17]|ro|0x0|dma_error.error_trig|Error resume|

### <div id="csr_dma-dma_error"></div>dma_error

* offset_address
    * 0x08
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|error_addr|[31:0]|ro|0x00000000||Error addr|
|error_type|[32]|ro|0x0||Error type - 0 READ / 1 WRITE|
|error_src|[33]|ro|0x0||Error source - 0 READ / 1 WRITE|
|error_trig|[34]|ro|0x0||Error Trigger, asserted when error happens|

### <div id="csr_dma-dma_descriptor"></div>dma_descriptor[5]

* offset_address
    * 0x10
    * 0x20
    * 0x30
    * 0x40
    * 0x50
* type
    * default

|name|bit_assignments|type|initial_value|reference|comment|
|:--|:--|:--|:--|:--|:--|
|src_addr|[31:0]|rw|0x00000000||Source address to fetch data|
|dest_addr|[63:32]|rw|0x00000000||Target address to write data|
|num_bytes|[95:64]|rw|0x00000000||Number of bytes to transfer|
|write_mode|[96]|rw|0x0||Write mode - 0 INCR / 1 FIXED|
|read_mode|[97]|rw|0x0||Read mode - 0 INCR / 1 FIXED|
|enable|[98]|rw|0x0||Enable descriptor|
