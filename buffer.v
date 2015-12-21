/* dual port memory */

module buffer #(parameter AW = 16, parameter DW = 8)
	(
		input write_clock,
		input [DW-1:0] write_data,
		input [AW-1:0] write_addr,

		output [DW-1:0] read_data,
		input [AW-1:0] read_addr);

	localparam NPOS = 2 ** AW;

	reg [DW-1: 0] ram [0: NPOS-1];

	always @(posedge write_clock)
		write_data <= ram[write_addr];

	always @(read_addr)
		read_data <= ram[read_addr];
endmodule
