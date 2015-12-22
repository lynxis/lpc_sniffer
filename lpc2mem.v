/* read out lpc into memory */

module lpc2mem(
	input [3:0] lpc_cyctype_dir, /* memory or i/o or dma(dma is unsuported)) + direction. same as in lpc spec */
	input [31:0] lpc_addr, /* i/o has 16bit, memory 32 bit */
	input [7:0] lpc_data, /* data written or read */
	input lpc_latch, /* read in data when high */
	input clock, /* external clock, could connected to (lpc clock / 2) */
	input [4:0] target_addr, /* write next lpc frame into this addr (5bit higher bit of a 8bit addr) */
	output [7:0] ram_addr, /* write data to this addr */
	output [7:0] ram_data, /* write data to this data */
	output ram_write_clock); /* on high write out data */

	/* to which we write the addr */
	reg [31:0] buffer_lpc_addr;
	reg [7:0] buffer_lpc_data;
	reg [3:0] buffer_lpc_cyctype_dir;
	reg [5:0] buffer_target_addr;

	reg [7:0] data;

	wire write_clock;

	/* we need to save 8 byte */
	reg [2:0] counter;
	parameter write_type = 3'h0,
		write_addr_0 = 3'h1, write_addr_1 = 3'h2, write_addr_2 = 3'h3, write_addr_3 = 3'h4,
		write_data = 3'h5,
		idle = 3'h7;

	always @(clock or lpc_latch) begin
		if (lpc_latch) begin
			buffer_lpc_addr <= lpc_addr;
			buffer_lpc_data <= lpc_data;
			buffer_lpc_cyctype_dir <= lpc_cyctype_dir;
			buffer_target_addr <= target_addr;
			counter <= write_type;
		end
		else
			if (clock)
			begin
				case (counter)
					write_type: begin
						data [3:0] <= buffer_lpc_cyctype_dir;
						data [7:4] <= 4'h0;
					end
					write_addr_0: begin
						data <= buffer_lpc_addr[31:24];
					end
					write_addr_1: begin
						data <= buffer_lpc_addr[23:16];
					end
					write_addr_2: begin
						data <= buffer_lpc_addr[15:8];
					end
					write_addr_3: begin
						data <= buffer_lpc_addr[7:0];
					end
					write_data: begin
						data <= buffer_lpc_data;
					end
				endcase
				write_clock <= 1;
				counter <= counter + 1;
			end
			else
				write_clock <= 0;
	end

	assign ram_addr [7:3] = buffer_target_addr;
	assign ram_addr [2:0] = counter;
	assign ram_data = data;
	assign ram_write_clock = write_clock;
endmodule
