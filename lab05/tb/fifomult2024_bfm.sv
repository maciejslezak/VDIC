/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 Last modification: 2024-11-05 AGH MSle
 */
interface fifomult2024_bfm;

//------------------------------------------------------------------------------
// imports  
//------------------------------------------------------------------------------
	import fifomult2024_tb_pkg::*;

//------------------------------------------------------------------------------
// signals declarations 
//------------------------------------------------------------------------------
	// dut control signals
	bit clk;
	bit rst_n;
	// dut data in signals
	bit signed [15:0] data_in;
	bit               data_in_parity;
	bit               data_in_valid;
	// dut data out signals
    bit               busy_out;
    bit signed [31:0] data_out;
    bit               data_out_parity;
    bit               data_out_valid;
    bit               data_in_parity_error;
	// testbench data in signals
	st_data_in_packet_t data_in_packet;
	operation_t         op_set;
	
//------------------------------------------------------------------------------
// modport definition  
//------------------------------------------------------------------------------
	modport tlm (import reset_dut, send_data);
	
//------------------------------------------------------------------------------
// clock generator  
//------------------------------------------------------------------------------	

	initial begin : clk_gen_blk
		clk = 0;
		forever begin : clk_frv_blk
			#10;
			clk = ~clk;
		end
	end

//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------

	task reset_dut();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_dut", $time);
	`endif
		data_in_valid = 1'b0;
		rst_n         = 1'b0;
		@(negedge clk);
		rst_n         = 1'b1;
	endtask : reset_dut

//------------------------------------------------------------------------------
// send data
//------------------------------------------------------------------------------

	task send_data(input operation_t iop, input st_data_in_packet_t idata_in_packet);
		
		static bit valid_counter = 0;
		
		op_set = iop;
		data_in_packet = idata_in_packet;
		
		while (1) begin : sender_loop
			/* --- latch data in A --- */
			priority if (busy_out == 1'b0 && valid_counter == 1'b0) begin
				/* latch A */
				data_in             = data_in_packet.A;
				data_in_parity      = data_in_packet.A_parity;
				valid_counter       = 1'b1;
				data_in_valid       = 1'b1;
				@(negedge clk);
			end
			else if (busy_out == 1'b0 && valid_counter == 1'b1) begin
				data_in             = data_in_packet.B;
				data_in_parity      = data_in_packet.B_parity;
				valid_counter       = 1'b0;
				data_in_valid       = 1'b1;
				@(negedge clk);
				/* exit loop if both multiplicands were sent */
				break;
			end
			else begin
				data_in             = data_in;
				data_in_parity      = data_in_parity;
				valid_counter       = valid_counter;
				data_in_valid       = 1'b0;
				@(negedge clk);
			end
			/* --- handle operation --- */
			case (op_set)
				rst_op: begin : case_rst_op_blk
					/* --- reset dut--- */
					data_in_valid  = 1'b0;
					reset_dut();
					valid_counter = 1'b0;
					/* exit loop if reset */
					break;
				end
				default: begin : case_default_blk
					/* --- send data --- */
					data_in_valid = data_in_valid;
				end : case_default_blk
			endcase // case (op_set)
		end : sender_loop
	endtask : send_data
	
endinterface : fifomult2024_bfm




