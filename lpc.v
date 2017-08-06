/* a lpc decoder
 * lpc signals:
	* lpc_ad: 4 data lines
	* lpc_frame: frame to start a new transaction. active low
	* lpc_reset: reset line. active low
 * output signals:
	* out_cyctype_dir: type and direction. same as in LPC Spec 1.1
        * out_addr: 16-bit address
        * out_data: data read or written (1byte)
	* out_clock_enable: on rising edge all data must read.
 */

module lpc(
	input [3:0] lpc_ad,
	input lpc_clock,
	input lpc_frame,
	input lpc_reset,
	input reset,
	output [3:0] out_cyctype_dir,
	output [31:0] out_addr,
	output [7:0] out_data,
	output reg out_clock_enable);

	/* type and direction. same as in LPC Spec 1.1 */

	/* addr + data written or read */

	/* state machine */
	reg [3:0] state = 0;
	localparam idle = 0, start = 1, cycle_dir = 2, address = 3, tar = 4, sync = 5, read_data = 6, abort = 7;

	/* counter used by some states */
	reg [3:0] counter;

	/* mode + direction. same as in LPC Spec 1.1 */
	reg [3:0] cyctype_dir;

	reg [31:0] addr;
	reg [7:0] data;

	always @(posedge lpc_clock or negedge lpc_reset) begin
		if (~lpc_reset) begin
			state <= idle;
			counter <= 1;
		end
		else begin
			if (counter == 1)
				counter <= counter - 1;
			else
				case (state)
					idle:
						// wait for start condition
						if (~lpc_frame && lpc_ad == 4'b0000)
							state <= cycle_dir;
					cycle_dir: begin
						if (cyctype_dir[3:2] == 2'b00) begin /* i/o */
							state <= address;
							counter <= 4;
						end
						else if (cyctype_dir[3:2] == 2'b01) begin /* memory */
							state <= address;
							counter <= 8;
						end
						else begin /* dma or reserved not yet supported */
							state <= idle;
						end
					end
					address: begin
						if (cyctype_dir[1]) begin /* write memory or i/o */
							state <= read_data;
							counter <= 2;
						end
						else begin /* read memory or i/o */
							state <= tar;
							counter <= 2;
						end
					end
					tar: begin
						state <= sync;
					end
					sync:
						if (lpc_ad == 4'b0000)
							if (cyctype_dir[3] == 0) begin /* i/o or memory */
								state <= read_data;
								counter <= 2;
							end
							else
								state <= idle; /* unsupported dma or reserved */
					read_data: begin
						state <= idle;
					end
					/* todo: missing TAR after read_data */

					abort: begin /* lpc abort */
						counter <= 2;
					end
				endcase
		end
	end

	always @(negedge lpc_clock or negedge reset) begin
	if (~reset)
		out_clock_enable <= 0;
	else
		case (state)
			// wait for start segment
			idle: begin
				out_clock_enable <= 0;
			end

			cycle_dir: begin
				cyctype_dir <= lpc_ad;
			end
			address: begin
				case (cyctype_dir[3:2])
				2'b00: begin /* 16 bit i/o */
					addr[31:16] <= 0;
					case (counter)
						4:
							addr[15:12] <= lpc_ad;
						3:
							addr[11:8] <= lpc_ad;
						2:
							addr[7:4] <= lpc_ad;
						1:
							addr[3:0] <= lpc_ad;
					endcase
				end
				2'b10: begin /* 32 bit memory */
					case (counter)
						8:
							addr[31:28] <= lpc_ad;
						7:
							addr[27:24] <= lpc_ad;
						6:
							addr[23:20] <= lpc_ad;
						5:
							addr[19:16] <= lpc_ad;
						4:
							addr[15:12] <= lpc_ad;
						3:
							addr[11:8] <= lpc_ad;
						2:
							addr[7:4] <= lpc_ad;
						1:
							addr[3:0] <= lpc_ad;
					endcase
				end
				default: begin end
				endcase
			end

			read_data: begin
				case (counter)
					2:
						data[7:4] <= lpc_ad[3:0];
					1: begin
						out_clock_enable <= 1;
						data[3:0] <= lpc_ad[3:0];
					end
				endcase
			end

			idle: begin
				out_clock_enable <= 0;
			end

			default: begin end
		endcase
	end
	assign out_cyctype_dir = cyctype_dir;
	assign out_data = data;
	assign out_addr = addr;
endmodule
