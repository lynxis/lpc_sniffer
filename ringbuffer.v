module ringbuffer #(parameter BITS = 5)
	(
		input write_done,
		input read_done,
		input reset,
		output reg [BITS-1:0] write_addr,
		output reg [BITS-1:0] read_addr,
		output reg empty,
		output reg overflow);

	reg [BITS-1:0] next_write_addr;


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

	always @(negedge reset or posedge write_done) begin
		if (~reset) begin
			write_addr <= 0;
			next_write_addr <= 1;
		end
		else
			if (~overflow) begin
				write_addr <= write_addr + 1;
				next_write_addr <= next_write_addr + 1;
			end
	end

	always @(negedge reset or posedge read_done) begin
		if (~reset) begin
			read_addr <= 0;
		end
		else begin
			if (~empty)
				read_addr <= read_addr + 1;
		end
	end
endmodule
