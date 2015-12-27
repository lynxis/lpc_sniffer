/* read out lpc into memory */

module lpc2mem(
	input [3:0] lpc_cyctype_dir, /* memory or i/o or dma(dma is unsuported)) + direction. same as in lpc spec */
	input [31:0] lpc_addr, /* i/o has 16bit, memory 32 bit */
	input [7:0] lpc_data, /* data written or read */
	input lpc_frame_done_clock, /* read in data when low */
	input clock, /* external clock */
	input reset,
	input [4:0] target_addr, /* write next lpc frame into this addr (5bit higher bit of a 8bit addr) */
	output [7:0] ram_addr, /* write data to this addr */

	output reg [47:0] ram_data, /* write data to this data */
	output reg write_clock, /* on high write out data */
	output reg written_frame_to_mem_clock); /* called when a full lpc frame was written, required for the ringbuffer */

	parameter write_type = 3'h0,
		write_addr_0 = 3'h1, write_addr_1 = 3'h2, write_addr_2 = 3'h3, write_addr_3 = 3'h4,
		write_data = 3'h5,
		idle = 3'h6;

	always @(negedge lpc_frame_done_clock) begin
		begin
			ram_data[47:16] <= lpc_addr;
			ram_data[15:8] <= lpc_data;
			ram_data[7:4] <= 0;
			ram_data[3:0] <= lpc_cyctype_dir;
		end
	end

	assign ram_addr = {target_addr, 3'h0};
	assign written_frame_to_mem_clock = lpc_frame_done_clock;
	assign write_clock = lpc_frame_done_clock;
endmodule
