
NAME=top
DEPS=buffer.v lpc.v lpc2mem.v mem2serial.v ringbuffer.v uart_tx.v power_on_reset.v

$(NAME).bin: $(NAME).pcf $(NAME).v $(DEPS)
	yosys -p "synth_ice40 -blif $(NAME).blif" $(NAME).v $(DEPS)
	arachne-pnr -d 1k -p $(NAME).pcf $(NAME).blif -o $(NAME).txt
	icepack $(NAME).txt $(NAME).bin

testbenches: buffer_tb.vvp

buffer_tb.vvp: buffer.v buffer_tb.v
	iverilog -obuffer_tb.vvp $^

clean:
	rm -f top.blif top.txt top.ex top.bin *.vvp

.PHONY: clean testbenches
