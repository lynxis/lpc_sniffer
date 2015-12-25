# TODO

## LPC modes
* implement memory read / writes
* abort on LPCFRAME# when driving not in idle mode

## Testbench for every module

every module needs a testbench

### lpc

* check if lpc\_frame can abort a cycle
* check lpc\_reset
* check i/o read / write
* check memory read / write

### lpc2mem

* check ignores all activity when not latched
* check i/o write to buffer
* check memory write to buffer

### ringbuffer

* check if write increases the pointer
* check if read increases the pointer
* check if overflow happens
* check if emptyness happens after overflow + multiple reads
* check write, read, write, write, write,read, read, write, read, read

### mem2serial

* check if it read successful the memory to uart
* check if it not read when buffer is empty
* check if handles uart\_ready in the correct way
* check if it latches at the end

### serial

* check if it send out uart correctly
* check parity on 0x00, 0xff, 0x12, 0x32, 0x23
* check ready bit

### top

* check if given lpc frame ends up on the uart pin
