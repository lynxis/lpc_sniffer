/* simple 16 bit memory write */
`timescale 1 ns / 100 ps

module lpc_tb_write_mem2 ();

   reg [3:0]   lpc_ad;
   reg 	       lpc_clock;
   reg 	       lpc_frame;
   reg 	       lpc_reset;
   wire [3:0]  ct_dir;
   wire [31:0] addr;
   wire [31:0]  data;
   wire [2:0] 	data_size;
   wire        out_clock;

   localparam test_addr = 'h12347fe5, test_data = 'hd569;
   
   /* expected results */
   integer     expected_addr = test_addr;
   integer  expected_data = test_data;
   integer  expected_datasize = 2;
   integer  expected_ct_dir = 4'b0110;
   integer  expected_number = 1;
   
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
      $dumpfile ("lpc-tb_write_mem2.vcd");
      $dumpvars (0, lpc_tb_write_mem2);
            
      lpc_assert_reset;
      
      lpc_clock = 0; // all tasks require to have lpc_clock zero before
      
      // LPC start: frame asserted for one cycle with ad == 0000
      lpc_start(1, 0, 0);

      // start with mem read access
      // bit 3:2 = 1 --> mem, bit 1 = 1 --> write
      lpc_ctdir(4'b0110);
      
      lpc_size(1); // 2 bytes
      
      lpc_addr32(test_addr);
      
      lpc_data16(test_data);
      
      lpc_tar;
      
      lpc_sync;
      
      lpc_tar;
      
      
      // idle clock
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;

      check_results;
      
      $finish;
      
   end // initial begin

   always @(posedge out_clock) begin
      watch_results;
   end
 
endmodule    
      
     
       
  
