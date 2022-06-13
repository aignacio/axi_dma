# File              : Makefile
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 07.06.2022
# Last Modified Date: 13.06.2022
SPEC_TEST	?=	-k test_dma_single_desc['64']
RUN_CMD		:=	docker run --rm --name axi_dma	\
							-v $(abspath .):/axi_dma -w			\
							/axi_dma aignacio/axi_dma

.PHONY: run_test csr_dma.sv clean

all: csr_out/csr_dma.v
	$(RUN_CMD) tox -- $(SPEC_TEST)

csr_out/csr_dma.v:
	$(RUN_CMD) rggen --plugin rggen-verilog --plugin rggen-c-header -c config_csr.yml -o csr_out csr_dma.xlsx

clean:
	@rm -rf run_dir csr_out
