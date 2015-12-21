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
