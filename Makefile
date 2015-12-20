lpc.bin: lpc.v lpc.pcf
	yosys -q -p "synth_ice40 -blif lpc.blif" lpc.v
	arachne-pnr -p lpc.pcf lpc.blif -o lpc.txt
	icebox_explain lpc.txt > lpc.ex
	icepack lpc.txt lpc.bin

clean:
	rm -f lpc.blif lpc.txt lpc.ex lpc.bin

