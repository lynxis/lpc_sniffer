module lpc_proto(lpc_ad, lpc_clk, lpc_frame, lpc_reset, out_mode, out_direction, out_addr, out_data);
	input [3:0] lpc_ad;
	input lpc_clk;
	input lpc_frame;
	input lpc_reset;

	reg [3:0] state;
	reg [3:0] counter;

	parameter reset = 4'h1, start = 4'h2, address = 4'h3;

	// 0 = read, 1 = write
	wire write;

	// type of operation
	wire io;

	always @(posedge lpc_clk or posedge lpc_rst)
	begin
		if (lpc_rst) begin
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
						io <= 1'b1;
						write <= lpc_ad[1];
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
								address[15:12] <= lpc_ad[3:0];
							1:
								address[11:8] <= lpc_ad[3:0];
							2:
								address[7:4] <= lpc_ad[3:0];
							3:
								address[3:0] <= lpc_ad[3:0];
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
					if (lpc_add <= 1'b0000) begin
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
endmodule
