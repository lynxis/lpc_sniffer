
NAME=top
DEPS=buffer.v lpc.v lpc2mem.v mem2serial.v ringbuffer.v uart_tx.v power_on_reset.v
# all files *-tb*.v are treated as testbench files - the part before the '-' must match the module it tests (without the .v extension)
TESTS_SRC = $(wildcard *-tb*.v)
TESTS_BIN = $(TESTS_SRC:.v=.vvp)

$(NAME).bin: $(NAME).pcf $(NAME).v $(DEPS)
	yosys -p "synth_ice40 -blif $(NAME).blif" $(NAME).v $(DEPS)
	arachne-pnr -d 1k -p $(NAME).pcf $(NAME).blif -o $(NAME).txt
	icepack $(NAME).txt $(NAME).bin

test: $(TESTS_SRC)
	-rm -f $(TESTS_BIN)
	./run_test.sh $^

clean:
	rm -f $(NAME).blif $(NAME).txt $(NAME).ex $(NAME).bin *.vvp *.vcd

help:
	@echo "possible target:"
	@echo "$(NAME).bin		build the binary (default)"
	@echo "test		build and run all testbenches"
	@echo "clean		remove all generated files"

.PHONY: clean test help
