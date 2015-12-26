
NAME=top
DEPS=buffer.v lpc.v lpc2mem.v mem2serial.v ringbuffer.v uart_tx.v power_on_reset.v

$(NAME).bin: $(NAME).pcf $(NAME).v $(DEPS)
	yosys -p "synth_ice40 -blif $(NAME).blif" $(NAME).v $(DEPS)
	arachne-pnr -d 1k -p $(NAME).pcf $(NAME).blif -o $(NAME).txt
	icepack $(NAME).txt $(NAME).bin

clean:
	rm -f top.blif top.txt top.ex top.bin

