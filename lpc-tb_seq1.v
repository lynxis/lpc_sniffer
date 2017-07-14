/* longer sequence:
   - 32bit memory read
   - 8bit memory write - interrupted by a reset
   - io read
 */
`timescale 1 ns / 100 ps

module lpc_tb_rw_seq1 ();

   reg [3:0]   lpc_ad;
   reg 	       lpc_clock;
   reg 	       lpc_frame;
   reg 	       lpc_reset;
   wire [3:0]  ct_dir;
   wire [31:0] addr;
   wire [31:0]  data;
   wire [2:0] 	data_size;
   wire        out_clock;

   localparam test_addr = 'h7fe5, test_data = 'h6c;
   
   /* expected results */
   integer  expected_addr = test_addr;
   integer  expected_data = test_data;
   integer  expected_datasize = 1;
   integer  expected_ct_dir = 4'b0000;
   integer  expected_number = 2; // we expect two datasets

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
      $dumpfile ("lpc-tb_rw_seq1.vcd");
      $dumpvars (0, lpc_tb_rw_seq1);

      lpc_assert_reset;
      
      lpc_clock = 0; // all tasks require to have lpc_clock zero before
      
      // LPC start: frame asserted for one cycle with ad == 0000
      lpc_start(1, 0, 0);

      // mem read access
      // bit 3:2 = 01 --> mem, bit 1 = 0 --> read
      lpc_ctdir(4'b0100);

      lpc_size(3); // 4 byte
      
      lpc_addr32('h12345678);
      
      lpc_tar;

      lpc_sync; //no-wait sync
      
      lpc_data32('h9abcdef0);
      
      lpc_tar;
      
      // LPC start: frame asserted for one cycle with ad == 0000
      lpc_start(1, 0, 0);

      // mem write access
      // bit 3:2 = 01 --> mem, bit 1 = 1 --> write
      lpc_ctdir(4'b0110);

      lpc_size(0); // 1 byte
      
      lpc_addr16(test_addr-4);

      lpc_assert_reset;
      
      // LPC start: frame asserted for one cycle with ad == 0000
      lpc_start(1, 0, 0);

      // io read access
      // bit 3:2 = 0 --> i/o, bit 1 = 0 --> read
      lpc_ctdir(4'b0000);

      lpc_addr16(test_addr);
      
      lpc_tar;

      lpc_shortsync(4);
      lpc_sync;
      
      lpc_data(test_data);
      
      lpc_tar;
      
      check_results;
      
      $finish;
      
   end // initial begin

   always @(posedge out_clock) begin
      watch_results;
   end
 
endmodule    
      
     
       
  
