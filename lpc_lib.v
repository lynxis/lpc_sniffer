// some common LPC bus tasks
// you must have these global variables defined in the including module: lpc_ad, lpc_clock

// put a 16 bit address on the bus
// assume that lpc_clock is 0 when called
// lpc_clock is 0 afterwards
task lpc_addr16;
   input integer addr;
   
   begin
      // four cycles for the address - highest nibble first!
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
endtask // lpc_addr16

//put a 32 bit address on the bus
// assume that lpc_clock is 0 when called
// lpc_clock is 0 afterwards
task lpc_addr32;
   input integer addr;
   begin
      lpc_addr16((addr >> 16) & 'hffff);
      lpc_addr16(addr & 'hffff);
   end
endtask

//put a 8 bit data on the bus
// assume that lpc_clock is 0 when called
// lpc_clock is 0 afterwards
task lpc_data;
   input integer data;
   begin
      // two cycles for data - lower nibble first!

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

//put a nowait sync (ad == 0) on the bus
// assume that lpc_clock is 0 when called
// lpc_clock is 0 afterwards
task lpc_sync;
   begin
      lpc_ad = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
   end
endtask

//put nr_sync many short sync (lpc_ad == 5) on the bus
// assume that lpc_clock is 0 when called
// lpc_clock is 0 afterwards
task lpc_shortsync;
   input integer nr_sync;
   begin
      lpc_ad = 5;
      repeat(nr_sync) begin
	 #1 lpc_clock = 1;
	 #1 lpc_clock = 0;
      end
   end
endtask   

//put two tar cycles on the bus
task lpc_tar;
   begin
      lpc_ad = 4'bzzzz;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
   end
endtask
   
//put nr_sync many long sync (lpc_ad == 6) on the bus
// assume that lpc_clock is 0 when called
// lpc_clock is 0 afterwards
task lpc_longsync;
   input integer nr_sync;
   begin
      lpc_ad = 6;
      repeat(nr_sync) begin
	 #1 lpc_clock = 1;
	 #1 lpc_clock = 0;
      end
   end
endtask   
