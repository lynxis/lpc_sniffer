module power_on_reset(input clock, output reg reset);

reg [7:0] counter = 254;

always @(*) begin
	if (counter == 0)
		reset = 1;
	else
		reset = 0;
end

always @(posedge clock) begin
	if (counter != 0)
		counter <= counter - 1;
end

endmodule
