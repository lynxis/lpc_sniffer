module mem2serial #(parameter AW = 16)
	(
		input [7:0] read_data,
		output [AW-1:0] read_addr,
		input [AW-1-3:0] target_addr,
		output read_done,
		input read_empty,
		input reset,
		input clock,

		input uart_ready,
		output [7:0] uart_data,
		output uart_latch);

	parameter idle = 3'h0, start_byte_1 = 3'h1, start_byte_2 = 3'h2,
		  read_lpc_memory = 3'h3;
	reg [2:0] state;
	reg [3:0] lower_addr;

	always @(negedge reset or posedge clock) begin
		if (~reset) begin
			state <= idle;
			uart_latch <= 0;
		end
		else
			case (state)
				idle: begin
					if (~read_empty) begin
						state <= start_byte_1;
						lower_addr <= 0;
						read_done <= 0;
					end
				end
				start_byte_1: begin
					uart_data <= 8'hff;
					state <= start_byte_2;
					uart_latch <= 1;
				end
				start_byte_2: begin
					uart_data <= 8'hff;
					state <= read_lpc_memory;
					uart_latch <= 1;
				end
				read_lpc_memory: begin
					if (uart_latch)
						uart_latch <= 0;
					else begin
						if (lower_addr > 6) begin
							state <= idle;
							read_done <= 1;
						end
						else begin
							lower_addr <= lower_addr + 1;
							uart_data <= read_data;
							uart_latch <= 1;
						end
					end
				end
			endcase
	end

	assign read_addr[2:0] = lower_addr;
	assign read_addr[AW-1:3] = target_addr;
	assign uart_latch = uart_latch;
endmodule
