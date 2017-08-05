module helloworldwriter(
	output out_clock_enable,
	output [47:0] out_data);

	always @(*) begin
		out_clock_enable = 1;
		out_data = 48'h68656c6c6f21;
	end
endmodule
