module lpc_proto(lpc_ad, lpc_clk, lpc_frame, lpc_reset, out_mode, out_direction, out_addr, out_data);
	input [3:0] lpc_ad;
	input lpc_clk;
	input lpc_frame;
	input lpc_reset;

	/* 1 for i/o, 0 for memory */
	output out_mode;
	/* 1 for write, 0 for read */
	output out_direction;

	/* addr + data written or read */
	output [15:0] out_addr;
	output [7:0] out_data;

	/* state machine */
	reg [3:0] state;
	parameter reset = 4'h1, start = 4'h2, address = 4'h3, tar = 4'h4, sync = 4'h5, io_data = 4'h6;

	/* counter used by some states */
	reg [3:0] counter;

	/* 1 for write, 0 for read */
	wire direction;

	/* 1 for i/o, 0 for memory */
	wire mode;

	wire [3:0] addr;
	wire [3:0] data;

	always @(posedge lpc_clk or posedge lpc_reset)
	begin
		if (lpc_reset) begin
			state <= reset;
		end
		else begin
			case (state)
				// wait for start segment
				reset: begin
					if (lpc_frame == 1'b1 && lpc_ad == 4'b0000) begin
						state <= start;
					end
				end

				// read out mode (i/o memory dma)
				start: begin
					if (lpc_ad[3:2] == 1'b00) begin
						mode <= 1'b1;
						direction <= lpc_ad[1];
						state <= address;
						counter <= 4'b0;
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
								addr[15:12] <= lpc_ad[3:0];
							1:
								addr[11:8] <= lpc_ad[3:0];
							2:
								addr[7:4] <= lpc_ad[3:0];
							3:
								addr[3:0] <= lpc_ad[3:0];
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
					if (lpc_ad == 1'b0000) begin
						state <= io_data;
					end
				end

				io_data: begin
					if (counter >= 2) begin
						state <= reset;
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
	assign out_mode = mode;
	assign out_direction = direction;
	assign out_data = data;
	assign out_addr = addr;
endmodule
