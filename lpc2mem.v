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

	/* to which we write the addr */
	reg [31:0] buffer_lpc_addr;
	reg [7:0] buffer_lpc_data;
	reg [3:0] buffer_lpc_cyctype_dir;
	reg [4:0] buffer_target_addr;

	/* we need to save 8 byte */
	reg [2:0] state;
	parameter write_type = 3'h0,
		write_addr_0 = 3'h1, write_addr_1 = 3'h2, write_addr_2 = 3'h3, write_addr_3 = 3'h4,
		write_data = 3'h5,
		idle = 3'h6;

	always @(negedge reset or posedge clock) begin
		if (~reset) begin
			state <= idle;
		end
		else
			case (state)
				idle: begin
					if (~lpc_frame_done_clock) begin
						state <= write_type;
						write_clock <= 0;
						written_frame_to_mem_clock <= 0;
						buffer_lpc_addr <= lpc_addr;
						buffer_lpc_data <= lpc_data;
						buffer_lpc_cyctype_dir <= lpc_cyctype_dir;
						buffer_target_addr <= target_addr;
					end
				end
				write_type: begin
					state <= write_addr_0;
					ram_data [3:0] <= buffer_lpc_cyctype_dir;
					ram_data [7:4] <= 4'h0;
				end
				write_addr_0: begin
					state <= write_addr_1;
					ram_data <= buffer_lpc_addr[31:24];
				end
				write_addr_1: begin
					state <= write_addr_2;
					ram_data <= buffer_lpc_addr[23:16];
				end
				write_addr_2: begin
					state <= write_addr_3;
					ram_data <= buffer_lpc_addr[15:8];
				end
				write_addr_3: begin
					state <= write_data;
					ram_data <= buffer_lpc_addr[7:0];
				end
				write_data: begin
					state <= idle;
					ram_data <= buffer_lpc_data;
					written_frame_to_mem_clock <= 1;
					write_clock <= 1;
				end
				default: begin end
			endcase
	end

	assign ram_addr [7:3] = buffer_target_addr;
	assign ram_addr [2:0] = state;
endmodule
