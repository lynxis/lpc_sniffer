module mem2serial #(parameter AW = 8)
	(
		output reg read_clock_enable,
		input [47:0] read_data,
		input read_empty,
		input reset,
		input clock,

		input uart_ready,
		output reg [7:0] uart_data,
		output reg uart_clock_enable);

	parameter idle = 0,
		start_byte_1 = 1, complete_tx_start_byte_1 = 2,
		start_byte_2 = 3, complete_tx_start_byte_2 = 4,
		read_lpc_memory = 5, complete_tx_read_lpc_memory = 6;
	reg [2:0] state;
	reg [2:0] lower_addr;

	always @(negedge reset or posedge clock) begin
		if (~reset) begin
			state <= idle;
			uart_clock_enable <= 0;
			read_clock_enable <= 0;
		end
		else
			case (state)
				idle: begin
					if (~read_empty) begin
						state <= start_byte_1;
						lower_addr <= 0;
						read_clock_enable <= 0;
					end
				end
				start_byte_1: begin
					if (uart_ready)
						uart_data <= 8'hff;
						state <= complete_tx_start_byte_1;
						uart_clock_enable <= 1;
				end
				complete_tx_start_byte_1: begin
					if (~uart_ready) begin
						state <= start_byte_2;
						uart_clock_enable <= 0;
					end
				end
				start_byte_2: begin
					if (uart_ready) begin
						uart_data <= 8'hff;
						state <= complete_tx_start_byte_2;
						uart_clock_enable <= 1;
					end
				end
				complete_tx_start_byte_2: begin
					if (~uart_ready) begin
						state <= read_lpc_memory;
						uart_clock_enable <= 0;
					end
				end
				read_lpc_memory: begin
					if (lower_addr >= 6) begin
						state <= idle; /* finished lpc frame */
						read_clock_enable <= 1;
					end
					else if (uart_ready) begin
						case (lower_addr)
							0:
								uart_data <= read_data[7:0];
							1:
								uart_data <= read_data[15:8];
							2:
								uart_data <= read_data[23:16];
							3:
								uart_data <= read_data[31:24];
							4:
								uart_data <= read_data[39:32];
							5:
								uart_data <= read_data[47:40];
						endcase
						uart_clock_enable <= 1;
						state <= complete_tx_read_lpc_memory;
					end
				end
				complete_tx_read_lpc_memory: begin
					if (~uart_ready) begin
						state <= read_lpc_memory; /* last state check in read_lpc_memory */
						uart_clock_enable <= 0;
						lower_addr <= lower_addr + 1;
					end
				end
			endcase
	end
endmodule
