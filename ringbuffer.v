module ringbuffer #(parameter BITS = 5)
	(
		input write_done,
		input read_done,
		input reset,
		output [BITS-1:0] write_addr,
		output [BITS-1:0] read_addr,
		output empty,
		output overflow);

	wire empty;
	wire overflow;
	wire [BITS-1:0] read_addr;
	wire [BITS-1:0] write_addr;
	reg [BITS-1:0] next_write_addr;

	always @(*) begin
		next_write_addr <= write_addr + 1;

		if (~reset) begin
			empty <= 1;
			overflow <= 0;
			write_addr <= 0;
			read_addr <= 0;
		end
		else begin
			if (read_addr == write_addr)
				empty <= 1;
			else
				empty <= 0;

			if (write_done) begin
				if (next_write_addr == read_addr)
					overflow <= 1;
				else
					write_addr <= write_addr + 1;
			end

			if (read_done) begin
				if (overflow)
					overflow <= 0;
				if (~empty)
					read_addr <= read_addr + 1;
			end
		end
	end
endmodule
