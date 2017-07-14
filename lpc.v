/* a lpc decoder
 * lpc signals:
 * lpc_ad: 4 data lines
 * lpc_frame: frame to start a new transaction. active low
 * lpc_reset: reset line. active low
 * output signals:
 * out_cyctype_dir: type and direction. same as in LPC Spec 1.1
 * out_addr: 32 bit address (for IO access only the lower 16 bit are used)
 * out_data: data read or written (1,2 or 4 byte)
 * out_data_size: 1,2,4
 * out_clock_enable: on rising edge all data are valid.
 */

module lpc(
	   input [3:0] 	 lpc_ad,
	   input 	 lpc_clock,
	   input 	 lpc_frame,
	   input 	 lpc_reset,
	   output [3:0]  out_cyctype_dir,
	   output [31:0] out_addr,
	   output [31:0] out_data,
	   output [3:0]  out_data_size, 
	   output reg 	 out_clock_enable);

   /* type and direction. same as in LPC Spec 1.1 */

   /* addr + data written or read */

   /* state machine */
   localparam
     idle = 0, 
     cycle_dir = 1,
     size = 2,
     addr7 = 3, // bit 31-28 of address
     addr6 = 4, // bit 27-24
     addr5 = 5,
     addr4 = 6,
     addr3 = 7,
     addr2 = 8,
     addr1 = 9,
     addr0 = 10,
	  
     tarA_1 = 11, // first tar cycle after address (only in case of read access)
     tarA_2 = 12, // second tar cycle after address (only in case of read access)

     syncR = 13, // sync for read access
	  
     data0 = 14, //first data cycle: bit 3:0
     data1 = 15, //second data cycle: bit 7:4
     data2 = 16, //bit 11:8
     data3 = 17,
     data4 = 18,
     data5 = 19,
     data6 = 20,
     data7 = 21,
	  
     tarD_1 = 22, // first tar cycle after data (both read and write)
     tarD_2 = 23, // second tar cycle after data
     syncW = 24, // sync for write access
     tarE_1 = 25, // first tar cycle after data + sync (only in case of write access)
     tarE_2 = 26; // first tar cycle after data + sync (only in case of write access)
   
   reg [4:0] 		 state = idle;

   /* mode + direction. same as in LPC Spec 1.1 */
   reg [3:0] 		 cyctype_dir;
   reg [3:0] 		 data_size;
   localparam size_1 = 0, size_2 = 1, size_4 = 3; // possible values for data_size (in bytes)

   // translate size lpc_ad (0,1,3) into values 1,2 or 4
   // return 0 for invalid ad values
   function get_size;
      input  ad;
      case (ad)
	 0: get_size = 1;
	 1: get_size = 2;
	 3: get_size = 4;
	 default: get_size = 0;
      endcase; // case (ad)
   endfunction
   
   // return 1 if  ct_dir encodes a write access
   function is_write;
      input [3:0] 	 ct_dir;
      is_write = ct_dir[1];
   endfunction
   
   reg [31:0] 		 addr;
   reg [31:0] 		 data;

   initial begin
      $monitor("lpc: state %d lpc_clock %d lpc_reset %d lpc_frame %d lpc_ad %x cyctype_dir %x", state, lpc_clock, lpc_reset, lpc_frame, lpc_ad, cyctype_dir);   
   end

   always @(negedge lpc_reset) begin
      state <= idle;
      out_clock_enable <= 0;
   end
   
   always @(posedge lpc_clock) begin
      if (~lpc_reset) begin
	 state <= idle;
	 out_clock_enable <= 0;
      end
      else begin
	 if (~lpc_frame && lpc_ad == 4'b1111) begin
	    //bus cycle abort by master
	    state <= idle;
	 end else
	   case (state)
	     
	     idle:
	       // wait for start condition
	       if (~lpc_frame && lpc_ad == 4'b0000)
		 state <= cycle_dir;
	     
	     cycle_dir: begin
		if (~lpc_frame) begin
		   // frame is asserted over 2+ cycles - we only stay in state cycle_dir if the AD value of the last cycle is 4'b0000
		   if (lpc_ad != 4'b0000) begin
		      state <= idle;
		   end
		end else begin
		   cyctype_dir <= lpc_ad;
		   case(lpc_ad[3:2])
		     2'b00: begin /* i/o */
			addr[31:16] <= 0;
			state <= addr3;
			data_size <= 1; // we set data_size here as there is no size state for i/o cycles
		     end
		     2'b01: /* memory */
		       state <= size;
		     2'b1x: /* dma or reserved */
		       state <= idle;
		   endcase
		end
	     end // case: cycle_dir

	     size: begin
		data_size <= get_size(lpc_ad);
		if (data_size != 0)
		  // valid data size
		  state <= addr7; //memory access always have 32 bit addresses
		else
		  state <= idle; // invalid size
	     end
	     
	     addr7: begin
		addr[31:28] <= lpc_ad;
		state <= addr6;
	     end
	     
	     addr6: begin
		addr[27:24] <= lpc_ad;
		state <= addr5;
	     end
	     
	     addr5: begin
		addr[23:20] <= lpc_ad;
		state <= addr4;
	     end
	     
	     addr4: begin
		addr[19:16] <= lpc_ad;
		state <= addr3;
	     end
	     
	     addr3: begin
		addr[15:12] <= lpc_ad;
		state <= addr2;
	     end
	     
	     addr2: begin
		addr[11:8] <= lpc_ad;
		state <= addr1;
	     end
	     
	     addr1: begin
		addr[7:4] <= lpc_ad;
		state <= addr0;
	     end
	     
	     addr0: begin
		addr[3:0] <= lpc_ad;
		data [31:0] <= 0; //initialize all bits, I don't want to switch over data_size
		state <= is_write(cyctype_dir) ? data0 : tarA_1;
	     end
	     
	     tarA_1:
	       state <= tarA_2;

	     tarA_2:
	       state <= syncR;

	     syncR: // we stay in state syncR for short and long waits
	       state <= (lpc_ad[3:0] == 4'b0000) ? data0 : syncR;
	     

	     data0: begin
		data [3:0] <= lpc_ad;
		state <= data1;
	     end

	     data1: begin
		data [7:4] <= lpc_ad;
		state <= (data_size == 2 || data_size == 4) ? data2 : tarD_1;
	     end

	     data2: begin
		data [11:8] <= lpc_ad;
		state <= data3;
	     end

	     data3: begin
		data [15:12] <= lpc_ad;
		state <= (data_size == 4) ? data4 : tarD_1;
	     end

	     data4: begin
		data [19:16] <= lpc_ad;
		state <= data5;
	     end
	     data5: begin
		data [23:20] <= lpc_ad;
		state <= data6;
	     end
	     data6: begin
		data [27:24] <= lpc_ad;
		state <= data7;
	     end
	     data7: begin
		data [31:28] <= lpc_ad;
		state <= tarD_1;
	     end

	     tarD_1:
	       state <= tarD_2;
	     tarD_2: begin
		if (is_write(cyctype_dir))
		  state <= syncW;
		else begin
		   out_clock_enable <= 1;
		   state <= idle;
		end
	     end
	     
	     syncW: // we stay in state syncW for short and long waits
	       state <= (lpc_ad[3:0] == 4'b0000) ? tarE_1 : syncW;

	     tarE_1:
	       state <= tarE_2;

	     tarE_2: begin
		out_clock_enable <= 1;
		state <= idle;
	     end
	   endcase // case (state)
      end // else: !if(~lpc_reset)
   end
   assign out_cyctype_dir = cyctype_dir;
   assign out_data = data;
   assign out_data_size = data_size;
   assign out_addr = addr;
endmodule
