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

//assert a reset on the bus, async to the clock
task lpc_assert_reset;
   begin
      lpc_reset = 1;
      #1 lpc_reset = 0;
      #1 lpc_reset = 1;
   end;
endtask

task lpc_ctdir;
   input integer ad;
   begin
      lpc_ad = ad;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
   end
endtask

task lpc_size;
   input integer sz;
   begin
      lpc_ad = sz;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
   end
endtask
      
// abort a cycle
task lpc_abort;
   begin
      lpc_ad = 4'b1111;
      lpc_frame = 0;
      #1 lpc_clock = 1;
      #1 lpc_clock = 0;
      lpc_frame = 1;
   end
endtask

// watch for data on rising edge of out_clock
//  result_addr, result_data, result_datasize, result_ct_dir -- last data we got on rising edge of out_clock_enable
//  result_number - number of results
//  addr, data, data_size, ct_dir - output data from lpc.v instance
task watch_results;
   begin
      //      $display("#DBG LPC output addr %x data %x data_size %d ct_dir %x", addr, data, data_size, ct_dir);
      result_addr = addr;
      result_data = data;
      result_datasize = data_size;
      result_ct_dir = ct_dir;
      result_number = result_number + 1;	 
   end
endtask // if

//check for the results
// needed global variables:
//  result_addr, result_data, result_datasize, result_ct_dir -- last data we got on rising edge of out_clock_enable
//  result_number - number of results
//  expected_addr, expected_data, expected_datasize, expected_ct_dir -- expected values for the result_* variables
//  if expected_number == 0 --> ignore the other expected_* vars
//  if expected_number > 1 --> expected_* vars are the last data
task check_results;
   begin
      if (result_number != expected_number) begin
	 $display("#ERR got %d results, expected %d", result_number, expected_number);
	 $stop; // if we call vvp with -N this will produce an exit code of 1
      end else begin
	 if (expected_number > 0) begin
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
	    end // if ((result_addr != expected_addr) || (result_data != expected_data) ||...
	 end // if (expected_number > 0)
      end // else: !if(result_number != expected_number)
   end
endtask
