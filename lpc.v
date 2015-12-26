/* a lpc decoder
 * lpc signals:
	* lpc_ad: 4 data lines
	* lpc_frame: frame to start a new transaction. active low
	* lpc_reset: reset line. active low
 * output signals:
	* out_cyctype_dir: type and direction. same as in LPC Spec 1.1
        * out_addr: 16-bit address
        * out_data: data read or written (1byte)
	* out_latch: on rising edge all data must read.
 */

module lpc(lpc_ad, lpc_clock, lpc_frame, lpc_reset, out_cyctype_dir, out_addr, out_data, out_latch);
	input [3:0] lpc_ad;
	input lpc_clock;
	input lpc_frame;
	input lpc_reset;

	/* type and direction. same as in LPC Spec 1.1 */
	output [3:0] out_cyctype_dir;

	/* addr + data written or read */
	output [31:0] out_addr;
	output [7:0] out_data;

	output reg out_latch;

	/* state machine */
	reg [2:0] state;
	localparam reset = 1, start = 2, address = 3, tar = 4, sync = 5, io_data = 6;

	/* counter used by some states */
	reg [3:0] counter;

	/* mode + direction. same as in LPC Spec 1.1 */
	reg [3:0] cyctype_dir;

	reg [31:0] addr;
	reg [7:0] data;

	always @(posedge lpc_clock or negedge lpc_reset)
	begin
		addr[31:16] <= 0; /* still unused - memory mode requires these bits */

		if (~lpc_reset) begin
			state <= reset;
			addr <= 0;
		end
		else begin
			case (state)
				// wait for start segment
				reset: begin
					if (~lpc_frame && lpc_ad == 4'b0000) begin
						out_latch <= 0;
						state <= start;
					end
				end

				// read out mode (i/o memory dma)
				start: begin
					cyctype_dir <= lpc_ad;

					if (lpc_ad[3:2] == 2'b00) begin
						state <= address;
						counter <= 0;
					end
					else begin
						// unsupported mode, ignore
						state <= reset;
					end
				end

				address: begin
					// 16 bit address for io
					if (counter >= 4) begin
						counter <= 0;
						state <= tar;
					end
					else begin
						case (counter)
							0:
								addr[15:12] <= lpc_ad;
							1:
								addr[11:8] <= lpc_ad;
							2:
								addr[7:4] <= lpc_ad;
							3:
								addr[3:0] <= lpc_ad;
						endcase
						counter <= counter + 1;
					end
				end

				tar: begin
					if (counter >= 2) begin
						state <= sync;
						counter <= 0;
					end
					else begin
						counter <= counter + 1;
					end
				end

				sync: begin
					if (lpc_ad == 4'b0000) begin
						state <= io_data;
					end
				end

				io_data: begin
					if (counter >= 2) begin
						state <= reset;
						out_latch <= 1;
					end
					else begin
						case (counter)
							0:
								data[7:4] <= lpc_ad[3:0];
							1:
								data[3:0] <= lpc_ad[3:0];
						endcase
						counter <= counter + 1;
					end
				end
			endcase
		end
	end
	assign out_cyctype_dir = cyctype_dir;
	assign out_data = data;
	assign out_addr = addr;
endmodule
