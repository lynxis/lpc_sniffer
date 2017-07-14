`timescale 1 ns / 100 ps

module lpc_tb ();

   reg [3:0]   lpc_ad;
   reg 	       lpc_clock;
   reg 	       lpc_frame;
   reg 	       lpc_reset;
   wire [3:0]  ct_dir;
   wire [31:0] addr;
   wire [31:0]  data;
   wire [3:0] 	data_size;
   wire        out_clock;


   integer  test_addr;
   integer  test_data;

   
   lpc UUT (
	    .lpc_ad(lpc_ad),
	    .lpc_clock(lpc_clock),
	    .lpc_frame(lpc_frame),
	    .lpc_reset(lpc_reset),
	    .out_cyctype_dir(ct_dir),
	    .out_addr(addr),
	    .out_data(data),
	    .out_data_size(data_size),
	    .out_clock_enable(out_clock)
	    );

`include "lpc_lib.v"
   
   initial begin
      $dumpfile ("lpc_tb.vcd");
      $dumpvars (0, lpc_tb);
      
      // test data and address
      test_addr = 32'h7fe5;
      test_data = 32'h6c;
      
      // start with a LPC reset
      lpc_reset = 1;
      #1 lpc_reset = 0;
      #1 lpc_reset = 1;

      lpc_clock = 0; // all tasks require to have lpc_clock zero before
      
      // LPC start: frame asserted for one cycle with ad == 0000
      lpc_start(1, 0, 0);
      
      // start with i/o read access
      lpc_ad = 4'b0000; // bit 3:2 = 0 --> i/o, bit 1 = 0 --> read
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      
      lpc_addr16(test_addr);
      
      // tar
      lpc_ad = 4'bzzzz;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;

      // sync from target - no wait
      lpc_ad = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;

      lpc_data(test_data);
      
      
     // tar
      lpc_ad = 4'bzzzz;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;

      // idle clock
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      
      $finish;
      
   end // initial begin

   always @(posedge out_clock) begin
      $display("#DBG LPC output addr %x data %x data_size %d ct_dir %x", addr, data, data_size, ct_dir);
      //TODO: check for correct values
   end
 
endmodule    
      
     
       
  
