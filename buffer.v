/* dual port memory */

module buffer #(parameter AW = 8, parameter DW = 8)
	(
		input write_clock,
		input [DW-1:0] write_data,
		input [AW-1:0] write_addr,

		input read_clock,
		output [DW-1:0] read_data,
		input [AW-1:0] read_addr);

	localparam NPOS = 2 ** AW;

	reg [DW-1: 0] ram [0: NPOS-1];

	always @(posedge write_clock)
		ram[write_addr] <= write_data;

	always @(posedge read_clock)
		read_data <= ram[read_addr];
endmodule
