module helloworldwriter(
	output out_clock_enable,
	output [47:0] out_data);

	assign out_clock_enable = 1;
	assign out_data = 48'h216f6c6c6568;
endmodule
