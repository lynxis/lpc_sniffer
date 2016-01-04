module ringbuffer #(parameter AW = 8, DW = 48)
	(
		input reset,
		input clock,
		input read_clock_enable,
		input write_clock_enable,
		output [DW-1:0] read_data,
		input [DW-1:0] write_data,
		output reg empty,
		output reg overflow);

	reg [AW-1:0] next_write_addr;

	reg [AW-1:0] read_addr;
	reg [AW-1:0] write_addr;

	always @(*) begin
		if (read_addr == write_addr)
			empty = 1;
		else
			empty = 0;

		// TODO: only overflow when written once to this address
		if (next_write_addr == read_addr)
			overflow = 1;
		else
			overflow = 0;

	end

	always @(negedge reset or negedge clock) begin
		if (~reset) begin
			write_addr <= 0;
			next_write_addr <= 1;
		end
		else
			if (write_clock_enable)
				if (~overflow) begin
					write_addr <= write_addr + 1;
					next_write_addr <= next_write_addr + 1;
				end
	end

	always @(negedge reset or negedge clock) begin
		if (~reset) begin
			read_addr <= 0;
		end
		else begin
			if (read_clock_enable)
				if (~empty)
					read_addr <= read_addr + 1;
		end
	end

	buffer #(.AW(8), .DW(48))
		MEM (
			.clock(clock),
			.write_clock_enable(write_clock_enable),
			.write_data(write_data),
			.write_addr(write_addr),
			.read_clock_enable(read_clock_enable),
			.read_data(read_data),
			.read_addr(read_addr));
endmodule
