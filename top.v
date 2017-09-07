module top #(parameter CLOCK_FREQ = 12_000_000, parameter BAUD_RATE = 921600)
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

	/* buffering */
	wire [3:0] lpc_ad;

	/* lpc */
	wire [3:0] dec_cyctype_dir;
	wire [31:0] dec_addr;
	wire [7:0] dec_data;

	/* bufferdomain*/
	wire [47:0] lpc_data;
	wire [47:0] write_data;
	wire lpc_data_enable;

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

	wire no_lpc_reset;

	power_on_reset POR(
		.clock(ext_clock),
		.reset(reset));

	lpc LPC(
		.lpc_ad(lpc_ad),
		.lpc_clock(lpc_clock),
		.lpc_frame(lpc_frame),
		.lpc_reset(no_lpc_reset),
		.reset(reset),
		.out_cyctype_dir(dec_cyctype_dir),
		.out_addr(dec_addr),
		.out_data(dec_data),
		.out_clock_enable(lpc_data_enable));

	bufferdomain #(.AW(48))
		BUFFERDOMAIN(
			.input_data(lpc_data),
			.input_enable(lpc_data_enable),
			.reset(reset),
			.clock(ext_clock),
			.output_data(write_data),
			.output_enable(write_clock_enable));

	assign lpc_data[47:16] = dec_addr;
	assign lpc_data[15:8] = dec_data;
	assign lpc_data[7:4] = 0;
	assign lpc_data[3:0] = dec_cyctype_dir;

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
		.trigger(lpc_data_enable));

	assign lpc_clock_led = 0;
	assign lpc_frame_led = 0;
	assign lpc_reset_led = 1;
	assign no_lpc_reset = 1;
	assign overflow_led = overflow;
endmodule
