# File              : Makefile
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 07.06.2022
# Last Modified Date: 05.05.2024
COV_REP	  :=	$(shell find run_dir -name 'coverage.dat')
# SPEC_TEST	?= -k test_dma_error
SPEC_TEST	?=
RUN_CMD		:=	docker run --rm --name axi_dma	\
							-v $(abspath .):/rtldev -w			\
							/axi_dma aignacio/axi_dma

.PHONY: run cov clean

all: run
	say ">Test run finished, please check the terminal"

run: csr_out/csr_dma.v
	$(RUN_CMD) tox -- $(SPEC_TEST)

csr_out/csr_dma.v:
	$(RUN_CMD) rggen --plugin rggen-verilog --plugin rggen-c-header -c config_csr.yml -o csr_out csr_dma.xlsx

coverage.info:
	$(RUN_CMD) verilator_coverage $(COV_REP) --write-info coverage.info

cov: coverage.info
	$(RUN_CMD) genhtml $< -o output_lcov

clean:
	$(RUN_CMD) rm -rf run_dir csr_out
