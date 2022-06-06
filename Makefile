RUN_CMD	:=	docker run --rm --name axi_dma	\
						-v $(abspath .):/axi_dma -w			\
						/axi_dma aignacio/axi_dma

.PHONY: run_test csr_dma.sv clean

run_test: csr_out
	$(RUN_CMD) tox

csr_out:
	$(RUN_CMD) rggen --plugin rggen-verilog -c config.yml -o csr_out csr_dma.xlsx

clean:
	@rm -rf run_dir
