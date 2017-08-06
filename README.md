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
```
	For orientation: the usb port points south:
	green overflow_led
	north ~lpc_frame
	west  lpc_clock
	east  ~lpc_reset
	south valid_lpc_output_led
```

overflow_led when internal buffer is full. No more LPC frames are decoded
valid_lpc_output_led will glow when one lpc frame was succesful decoded

- J1 connector
```
	VCC 3.3|NC 1
	GND        2
	lpc_clock  3
	lpc_ad[0]  4
	lpc_ad[1]  5
	lpc_ad[2]  6
	lpc_ad[3]  7
	lpc_frame  8
	lpc_reset  9
```
- uart output over the ftdi

