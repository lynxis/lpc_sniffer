
NAME=top
DEPS=buffer.v lpc.v mem2serial.v ringbuffer.v uart_tx.v power_on_reset.v

$(NAME).bin: $(NAME).pcf $(NAME).v $(DEPS)
	yosys -p "synth_ice40 -blif $(NAME).blif" $(NAME).v $(DEPS)
	arachne-pnr -d 1k -p $(NAME).pcf $(NAME).blif -o $(NAME).txt
	icepack $(NAME).txt $(NAME).bin

helloworld.bin: helloworld.v mem2serial.v buffer.v power_on_reset.v
	yosys -p "synth_ice40 -blif helloworld.blif" helloworld.v mem2serial.v ringbuffer.v buffer.v uart_tx.v power_on_reset.v helloworldwriter.v
	arachne-pnr -d 1k -p helloworld.pcf helloworld.blif -o helloworld.txt
	icepack helloworld.txt helloworld.bin

helloonechar.bin: helloonechar.v uart_tx.v power_on_reset.v helloonechar.pcf
	yosys -p "synth_ice40 -blif helloonechar.blif" helloonechar.v uart_tx.v power_on_reset.v
	arachne-pnr -d 1k -p helloonechar.pcf helloonechar.blif -o helloonechar.txt
	icepack helloonechar.txt helloonechar.bin


buffer.vcd: buffer_tb.v buffer.v
	iverilog -o buffer_tb.vcd buffer_tb.v buffer.v

mem2serial.vcd: mem2serial_tb.v mem2serial.v
	iverilog -o mem2serial_tb.vcd mem2serial_tb.v mem2serial.v

ringbuffer.vcd: ringbuffer_tb.v ringbuffer.v buffer.v
	iverilog -o ringbuffer_tb.vcd ringbuffer_tb.v ringbuffer.v buffer.v

clean:
	rm -f top.blif top.txt top.ex top.bin

test: buffer.vcd mem2serial.vcd ringbuffer.vcd
