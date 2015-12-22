# lpc sniffer (low pin count) for ice40 stick

Connect wire to the lpc sniffer and read out via the ftdi serial interface

# format of the serial protocol is

- Start: 2 byte 0xff23
- Type: 1 byte 0x11 (same as in the lpc)
- Addr: 4 byte (even for i/o, i/o has 16bit addr, memory 32 bit)
- data: 1 byte

# in memory layout

To syncronize between lpc and usb it used a internal ring-buffer. The internal memory layout is:

- Type: 1 byte 0x11 (same as in the lpc)
- Addr: 4 byte (even for i/o, i/o has 16bit addr, memory 32 bit)
- data: 1 byte
- waste: 2 byte (unused)

# what connectors are used on the IceStick?

- all 5 leds
- pmod 2x6 (digilent connector)
	lpc_ad[0] 1 7  reserved
	lpc_ad[1] 2 8  lpc_reset
	lpc_ad[2] 3 9  lpc_frame
	lpc_ad[3] 4 10 lpc_clock
	GND       5 11 GND
	3.3V      6 12 3.3V
- uart output over the ftdi

