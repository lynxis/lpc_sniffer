`timescale 1 ns / 100 ps

module lpc_tb ();

   reg [3:0]   lpc_ad;
   reg 	       lpc_clock;
   reg 	       lpc_frame;
   reg 	       lpc_reset;
   wire [3:0]  ct_dir;
   wire [31:0] addr;
   wire [7:0]  data;
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
	    .out_clock_enable(out_clock)
	    );

   // put a 16 bit address on the bus
   // assume that lpc_clock is 0 when called
   // lpc_clock is 0 afterwards
   task load_addr16;
      input integer addr;
      
     begin
	// four cycles for the address - highest nibble first!
	$display("#DBG load_addr16: %x", addr);	 
	lpc_ad = (addr >> 12) & 'hf;
	#1 lpc_clock = 1;
	#1 lpc_clock = 0;
	lpc_ad = (addr >> 8) & 'hf;
	#1 lpc_clock = 1;
	#1 lpc_clock = 0;
	lpc_ad = (addr >> 4) & 'hf;
	#1 lpc_clock = 1;
	#1 lpc_clock = 0;
	lpc_ad = addr & 'hf;
	#1 lpc_clock = 1;
	#1 lpc_clock = 0;
	
     end
   endtask // load_addr16

   //put a 32 bit address on the bus
   // assume that lpc_clock is 0 when called
   // lpc_clock is 0 afterwards
   task load_addr32;
      input integer addr;
      begin
	 $display("#DBG load_addr32: %x", addr);	 
	 load_addr16((addr >> 16) & 'hffff);
	 load_addr16(addr & 'hffff);
      end
   endtask //load_addr32
   
   //put a 8 bit data on the bus
   // assume that lpc_clock is 0 when called
   // lpc_clock is 0 afterwards
   task load_data;
      input integer data;
      begin
	 // two cycles for data - lower nibble first!
	 $display("#DBG load_data: %x", data);	 

	 lpc_ad = data & 'hf;
	 #1 lpc_clock = 1;
	 #1 lpc_clock = 0;
	 lpc_ad = (data >> 4) & 'hf;
	 #1 lpc_clock = 1;
	 #1 lpc_clock = 0;
      end
   endtask // load_data

   // send a lpc start frame
   // assume that lpc_clock is 0 when called
   // lpc_clock is 0 afterwards

   task lpc_start;
      input integer nr_frame_clks; // how many clocks shall frame be asserted?
      input integer start_value; // the value of lpc_ad when frame is asserted in all but the last cycles
      input integer start_value_last; // the value of lpc_ad when frame is asserted in the last cycle
      
      begin
	 $display("lpc_start: nr %d start %x start_last %x", nr_frame_clks, start_value, start_value_last);
	 
	 lpc_frame = 0;
	 if (nr_frame_clks > 1) begin
	    lpc_ad = start_value;
	    repeat(nr_frame_clks - 1) begin
	       #1 lpc_clock = 1;
	       #1 lpc_clock = 0;
	    end
	 end
	 lpc_ad = start_value_last;
	 #1 lpc_clock = 1;
	 #1 lpc_clock = 0;
	 lpc_frame = 1;
      end
   endtask // lpc_start
   

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
 /*     
      lpc_frame = 0;
      lpc_ad = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      lpc_frame = 1;
*/      
      // start with i/o read access
      lpc_ad = 4'b0000; // bit 3:2 = 0 --> i/o, bit 1 = 0 --> read
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      
      load_addr16(test_addr);
      
      // tar
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;

      // sync from target - no wait
      lpc_ad = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;

      load_data(test_data);
      
      
     // tar
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;

      $finish;
      
   end // initial begin

   always @(posedge out_clock) begin
      $display("#DBG LPC output addr %x data %x ct_dir %x", addr, data, ct_dir);
      //TODO: check for correct values
   end
 
endmodule    
      
     
       
  
