module top #(parameter CLOCK_FREQ = 12000000, parameter BAUD_RATE = 115200)
(
	input [3:0] lpc_ad,
	input lpc_clock,
	input lpc_frame,
	input lpc_reset,
	input ext_clock,
	output uart_tx,
	output lpc_clock_led,
	output lpc_frame_led,
	output lpc_reset_led,
	output uart_tx_led,
	output overflow_led);

	wire uart_tx;

	/* power on reset */
	wire reset;

	/* lpc -> lpc2mem */
	wire [3:0] dec_cyctype_dir;
	wire [31:0] dec_addr;
	wire [7:0] dec_data;
	wire dec_latch;

	/* lpc2mem -> memory */
	wire [7:0] write_addr;
	wire [7:0] write_data;
	wire write_latch;

	/* ring buffer */
	wire [4:0] upper_read_addr;
	wire [4:0] upper_write_addr;
	wire read_done;
	wire write_done;
	wire empty;
	wire overflow;

	/* mem2serial */
	wire [7:0] read_addr;
	wire [7:0] read_data;
	wire read_latch;

	/* uart tx */
	wire uart_ready;
	wire [7:0] uart_data;
	wire uart_latch;
	wire uart_clock;

	power_on_reset POR(
		.clock(ext_clock),
		.reset(reset));

	lpc LPC(
		.lpc_ad(lpc_ad),
		.lpc_clock(lpc_clock),
		.lpc_frame(lpc_frame),
		.lpc_reset(lpc_reset),
		.out_cyctype_dir(dec_cyctype_dir),
		.out_addr(dec_addr),
		.out_data(dec_data),
		.out_latch(dec_latch));

	lpc2mem LPC_MEM(
		.reset(reset),
		.lpc_cyctype_dir(dec_cyctype_dir),
		.lpc_addr(dec_addr),
		.lpc_data(dec_data),
		.lpc_latch(dec_latch),
		.clock(lpc_clock),
		.target_addr(upper_write_addr),
		.ram_addr(write_addr),
		.ram_data(write_data),
		.ram_write_clock(write_latch),
		.lpc_frame_done(write_done));

	buffer #(.AW(8), .DW(8))
		MEM (
			.write_clock(write_latch),
			.write_data(write_data),
			.write_addr(write_addr),
			.read_clock(read_latch),
			.read_data(read_data),
			.read_addr(read_addr));

	/* ringbuffer only counts the upper 5 bits, the lower 3 bits required
	 * to save 6 bytes, 2 byte are wasted */
	ringbuffer #(.BITS(5))
		RINGBUFFER (
			.reset(reset),
			.write_done(write_done),
			.read_done(read_done),
			.write_addr(upper_write_addr),
			.read_addr(upper_read_addr),
			.empty(empty),
			.overflow(overflow));

	mem2serial MEM_SERIAL(
		.reset(reset),
		.clock(ext_clock),
		.read_empty(empty),
		.read_clock(read_latch),
		.read_data(read_data),
		.read_addr(read_addr),
		.target_addr(upper_read_addr),
		.read_done(read_done),
		.uart_latch(uart_latch),
		.uart_ready(uart_ready),
		.uart_data(uart_data));

	uart_tx #(.CLOCK_FREQ(CLOCK_FREQ), .BAUD_RATE(BAUD_RATE))
		SERIAL (
			.read_data(uart_data),
			.read_latch(uart_latch),
			.reset(reset),
			.ready(uart_ready),
			.tx(uart_tx),
			.clock(ext_clock),
			.uart_clock(uart_clock));

	assign lpc_clock_led = lpc_clock;
	assign lpc_frame_led = ~lpc_frame;
	assign lpc_reset_led = ~lpc_reset;
	assign uart_tx_led = uart_tx;
	assign overflow_led = overflow;
endmodule
