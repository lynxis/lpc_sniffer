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

   localparam test_addr = 'h7fe5, test_data = 'h6c;
   
   /* expected results */
   integer     expected_addr = test_addr;
   integer  expected_data = test_data;
   integer  expected_datasize = 1;
   integer  expected_ct_dir = 0;

   /* the actual results we get */
   integer  result_addr;
   integer  result_data;
   integer  result_datasize;
   integer  result_ct_dir;
   integer  result_number = 0;
   
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

      if (result_number != 1) begin
	 $display("#ERR got %d results", result_number);
	 $stop; // if we call vvp with -N this will produce an exit code of 1
      end else begin
	 if ((result_addr != expected_addr) || (result_data != expected_data) ||
	     (result_datasize != expected_datasize) || (result_ct_dir != expected_ct_dir)) begin
	    if (result_addr != expected_addr)
	       $display("#ERR got addr %x, expected %x", result_addr, expected_addr);
	    if (result_data != expected_data)
	      $display("#ERR got data %x, expected %x", result_data, expected_data);
	    if (result_datasize != expected_datasize)
	      $display("#ERR got datasize %d, expected %d", result_datasize, expected_datasize);
	    if (result_ct_dir != expected_ct_dir)
	      $display("#ERR got ct_dir %x, expected %x", result_ct_dir, expected_ct_dir);
	    
	    $stop; // if we call vvp with -N this will produce an exit code of 1
	 end
      end
      $finish;
      
   end // initial begin

   always @(posedge out_clock) begin
//      $display("#DBG LPC output addr %x data %x data_size %d ct_dir %x", addr, data, data_size, ct_dir);
      result_addr = addr;
      result_data = data;
      result_datasize = data_size;
      result_ct_dir = ct_dir;
      result_number = result_number + 1;
      
      //TODO: check for correct values
   end
 
endmodule    
      
     
       
  
