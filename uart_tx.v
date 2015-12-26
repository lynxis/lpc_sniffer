
module uart_tx #(parameter CLOCK_FREQ = 12_000_000, BAUD_RATE = 115_200)
	(
	input clock,
	input [7:0] read_data,
	input read_latch, /* on posedge new data are read */
	input reset, /* active low */
	output reg ready, /* ready to read new data */
	output reg tx,
	output reg uart_clock);

	reg [7:0] data;

	localparam CLOCKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
	reg [6:0] divider;

	reg new_data;
	reg [2:0] state;
	reg [2:0] bit_pos; /* which is the next bit we transmit */
	reg parity;

	localparam IDLE = 3'h0, START_BIT = 3'h1, DATA = 3'h2, PARITY = 3'h3, STOP_BIT = 3'h4;

	always @(posedge clock) begin
		if (divider >= CLOCKS_PER_BIT) begin
			divider <= 0;
			uart_clock <= ~uart_clock;
		end
	end

	always @(negedge ready or posedge read_latch or negedge reset) begin
		if (~reset)
			new_data <= 0;
		else
			if (ready) begin
				data <= read_data;
				new_data <= 1;
			end
			else begin
				new_data <= 0;
			end
	end

	always @(posedge uart_clock or negedge reset) begin
		if (~reset) begin
			ready <= 0;
			state <= IDLE;
		end
		else begin
			case (state)
				IDLE: begin
					tx <= 1;
					if (new_data) begin
						parity <= 1;
						ready <= 0;
						state <= START_BIT;
					end
					else
						ready <= 1;
				end
				START_BIT: begin
					tx <= 0;
					state <= DATA;
					bit_pos <= 0;
				end
				DATA: begin
					tx <= data[bit_pos];

					if (data[bit_pos])
						parity <= ~parity;

					if (bit_pos == 7)
						state <= PARITY;
					else
						bit_pos <= bit_pos + 1;
				end

				PARITY: begin
					tx <= parity;
					state <= STOP_BIT;
				end

				STOP_BIT: begin
					tx <= 1;
					state <= IDLE;
				end
				default: begin end
			endcase
		end
	end
endmodule

