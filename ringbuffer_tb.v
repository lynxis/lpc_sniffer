
`timescale 1 ns / 100 ps

module ringbuffer_tb ();

	reg write_clock_enable;
	reg read_clock_enable;
	reg clock;
	reg reset;

	wire [1:0] write_data;
	wire [1:0] read_data;
	wire empty;
	wire overflow;

	ringbuffer #(.AW(2), .DW(2))
		RINGBUFFER (
			.reset(reset),
			.clock(clock),
			.read_data(read_data),
			.read_clock_enable(read_clock_enable),
			.write_data(write_data),
			.write_clock_enable(write_clock_enable),
			.empty(empty),
			.overflow(overflow));

	initial begin
		$dumpfile ("ringbuffer_tb.vcd");
		$dumpvars (1, ringbuffer_tb);
		#1;
		clock = 0;
		write_clock_enable = 0;
		read_clock_enable = 0;
		reset = 0;
		#1;
		clock = 1;
		#1;
		reset = 1;
		clock = 0;
		if (read_data != 0) begin
			$display("After reset read_data != 0");
			$stop;
		end
		if (write_data != 0) begin
			$display("After reset write_data != 0");
			$stop;
		end
		if (~empty) begin
			$display("Ringbuffer is not empty after reset");
			$stop;
		end
		if (overflow) begin
			$display("Ringbuffer is overflowed after reset");
			$stop;
		end

		// try to read even if the buffer is empty
		#1;
		clock = 1;
		read_clock_enable = 1;
		#1;
		clock = 0;
		read_clock_enable = 1;
		#1;
		clock = 1;
		read_clock_enable = 0;
		#1;
		if (read_data != 0) begin
			$display("read_data increase even the ringbuffer is empty and a malicious read_clock_enable was triggered");
			$stop;
		end
		
		// check write, read, write, write, write,read, read, write, read, read
		#1;
		write_clock_enable = 1;
		#1;
		write_clock_enable = 0;
		#1;
		if (write_data != 1) begin
			$display("write_data doesn\'t increase when writing to an empty ringbuffer");
			$stop;
		end
		if (empty || overflow) begin
			$display("buffer should not empty nor overflowed");
			$stop;
		end
		#1;
		read_clock_enable = 1;
		#1;
		if (~empty) begin
			$display("buffer is empty, but not signaling emptyness");
			$stop;
		end
		if (read_data != 1) begin
			$display("read_data doesn\'t increase after read");
			$stop;
		end
		#1;
		read_clock_enable = 0;
		#1;
		// ringbuffer is now empty again, read_data & write_data should show = 1
		#1;
		write_clock_enable = 1;
		#1;
		write_clock_enable = 0;
		#1;
		write_clock_enable = 1;
		#1;
		write_clock_enable = 0;
		#1;
		// buffer should be full
		write_clock_enable = 1;
		#1;
		write_clock_enable = 0;
		if (~overflow) begin
			$display("overflow not signaled even it\'s full");
			$stop;
		end
		if (write_data != 0) begin
			$display("write_data not correct. Expected %x, read %x", 'h0, write_data);
			$stop;
		end
		#1;
		read_clock_enable = 1;
		#1;
		read_clock_enable = 0;
		if (overflow) begin
			$display("overflow should *NOT* signaled anymore");
			$stop;
		end
		#1;
		read_clock_enable = 1;
		#1;
		read_clock_enable = 0;
		#1;
		read_clock_enable = 1;
		#1;
		read_clock_enable = 0;
		#1;
		read_clock_enable = 1;
		#1;
		read_clock_enable = 0;
		if (~empty) begin
			$display("buffer should empty, but it doesn\'t signaling this");
			$stop;
		end
		#2;
		$finish;
	end

endmodule
