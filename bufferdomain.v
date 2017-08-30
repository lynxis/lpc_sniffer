module bufferdomain #(parameter AW = 8, COUNTER = 4)
	(
		input [AW-1:0] input_data,
		output reg [AW-1:0] output_data,
		input reset, // active low
		output reg output_enable,
		input clock,
		input input_enable);


	reg [2:0] counter;

	always @(posedge input_enable or negedge clock) begin
		if (input_enable) begin
			output_data <= input_data;
			output_enable <= 1;
			counter <= COUNTER;
		end else begin
			if (~reset) begin
				counter <= 1;
				output_enable <= 0;
				output_data <= 0;
			end else begin
				if (counter == 1)
					output_enable <= 0;
				else
					counter <= counter - 1;
			end
		end
	end
endmodule
