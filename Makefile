
NAME=top
DEPS=buffer.v lpc.v lpc2mem.v mem2serial.v ringbuffer.v uart_tx.v power_on_reset.v

$(NAME).bin: $(NAME).pcf $(NAME).v $(DEPS)
	yosys -p "synth_ice40 -blif $(NAME).blif" $(NAME).v $(DEPS)
	arachne-pnr -d 1k -p $(NAME).pcf $(NAME).blif -o $(NAME).txt
	icepack $(NAME).txt $(NAME).bin

test: buffer_tb.vvp lpc_tb.vvp
	for test in $^; do echo "#DBG running $$test"; vvp -N $$test || echo "#ERR test $$test failed"; done

buffer_tb.vvp: buffer.v buffer_tb.v
	iverilog -o $@ $^

lpc_tb.vvp: lpc.v lpc_tb.v
	iverilog -o $@ $^

clean:
	rm -f $(NAME).blif $(NAME).txt $(NAME).ex $(NAME).bin *.vvp

.PHONY: clean test
