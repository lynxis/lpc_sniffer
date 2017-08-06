module top #(parameter CLOCK_FREQ = 12000000, parameter BAUD_RATE = 115200)
(
	input [3:0] lpc_ad,
	input lpc_clock,
	input lpc_frame,
	input lpc_reset,
	input ext_clock,
	output uart_tx_pin,
	output lpc_clock_led,
	output lpc_frame_led,
	output lpc_reset_led,
	output valid_lpc_output_led,
	output overflow_led);

	/* power on reset */
	wire reset;

	/* lpc -> lpc2mem */
	wire [3:0] dec_cyctype_dir;
	wire [31:0] dec_addr;
	wire [7:0] dec_data;

	/* lpc2mem -> memory */
	wire [47:0] write_data;

	/* ring buffer */
	wire read_clock_enable;
	wire write_clock_enable;
	wire empty;
	wire overflow;

	/* mem2serial */
	wire [47:0] read_data;

	/* uart tx */
	wire uart_ready;
	wire [7:0] uart_data;
	wire uart_clock_enable;
	wire uart_clock;

	power_on_reset POR(
		.clock(ext_clock),
		.reset(reset));

	lpc LPC(
		.lpc_ad(lpc_ad),
		.lpc_clock(lpc_clock),
		.lpc_frame(lpc_frame),
		.lpc_reset(lpc_reset),
		.reset(reset),
		.out_cyctype_dir(dec_cyctype_dir),
		.out_addr(dec_addr),
		.out_data(dec_data),
		.out_clock_enable(write_clock_enable));

	assign write_data[47:16] = dec_addr;
	assign write_data[15:8] = dec_data;
	assign write_data[7:4] = 0;
	assign write_data[3:0] = dec_cyctype_dir;

	ringbuffer #(.AW(10), .DW(48))
		RINGBUFFER (
			.reset(reset),
			.clock(ext_clock),
			.write_clock_enable(write_clock_enable),
			.read_clock_enable(read_clock_enable),
			.read_data(read_data),
			.write_data(write_data),
			.empty(empty),
			.overflow(overflow));

	mem2serial MEM_SERIAL(
		.reset(reset),
		.clock(ext_clock),
		.read_empty(empty),
		.read_clock_enable(read_clock_enable),
		.read_data(read_data),
		.uart_clock_enable(uart_clock_enable),
		.uart_ready(uart_ready),
		.uart_data(uart_data));

	uart_tx #(.CLOCK_FREQ(CLOCK_FREQ), .BAUD_RATE(BAUD_RATE))
		SERIAL (
			.read_data(uart_data),
			.read_clock_enable(uart_clock_enable),
			.reset(reset),
			.ready(uart_ready),
			.tx(uart_tx_pin),
			.clock(ext_clock),
			.uart_clock(uart_clock));

	trigger_led TRIGGERLPC(
		.reset(reset),
		.clock(ext_clock),
		.led(valid_lpc_output_led),
		.trigger(write_clock_enable));

	assign lpc_clock_led = lpc_clock;
	assign lpc_frame_led = ~lpc_frame;
	assign lpc_reset_led = ~lpc_reset;
	assign overflow_led = overflow;
endmodule
