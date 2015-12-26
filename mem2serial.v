module mem2serial #(parameter AW = 8)
	(
		output reg read_clock,
		input [7:0] read_data,
		output [AW-1:0] read_addr,
		input [AW-1-3:0] target_addr,
		output reg read_done,
		input read_empty,
		input reset,
		input clock,

		input uart_ready,
		output reg [7:0] uart_data,
		output reg uart_latch);

	parameter idle = 0,
		start_byte_1 = 1, complete_tx_start_byte_1 = 2,
		start_byte_2 = 3, complete_tx_start_byte_2 = 4,
		read_lpc_memory = 5, complete_tx_read_lpc_memory = 6;
	reg [2:0] state;
	reg [2:0] lower_addr;

	always @(negedge reset or posedge clock) begin
		if (~reset) begin
			state <= idle;
			uart_latch <= 0;
			read_clock <= 0;
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
					if (uart_ready)
						uart_data <= 8'hff;
						state <= complete_tx_start_byte_1;
						uart_latch <= 1;
				end
				complete_tx_start_byte_1: begin
					if (~uart_ready) begin
						state <= start_byte_2;
						uart_latch <= 0;
					end
				end
				start_byte_2: begin
					if (uart_ready) begin
						uart_data <= 8'hff;
						state <= complete_tx_start_byte_2;
						uart_latch <= 1;
					end
				end
				complete_tx_start_byte_2: begin
					if (~uart_ready) begin
						state <= read_lpc_memory;
						uart_latch <= 0;
					end
				end
				read_lpc_memory: begin
					if (lower_addr > 6) begin
						state <= idle; /* finished lpc frame */
						read_done <= 1;
					end
					else if (uart_ready) begin
						uart_data <= read_data;
						uart_latch <= 1;
						state <= complete_tx_read_lpc_memory;
					end
				end
				complete_tx_read_lpc_memory: begin
					if (~uart_ready) begin
						state <= read_lpc_memory; /* last state check in read_lpc_memory */
						uart_latch <= 0;
						lower_addr <= lower_addr + 1;
					end
				end
			endcase
	end

	assign read_addr[2:0] = lower_addr;
	assign read_addr[AW-1:3] = target_addr;
endmodule
