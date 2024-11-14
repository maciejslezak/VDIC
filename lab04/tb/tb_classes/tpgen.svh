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
class tpgen;
	 
	protected virtual fifomult2024_bfm bfm;

    function new (virtual fifomult2024_bfm b);
        bfm = b;
    endfunction : new

	/* --- get_op --- */
	protected function operation_t get_op();
		
		/* --- init local variables --- */
		bit [3:0] randomizer;
		
		/* --- get operation --- */
		randomizer = 4'($random);
		case (randomizer)
			4'b0000 : return rst_op; // reset 12.5% propability
			default: return mul_op; // mult  87.5% propability
		endcase // case (randomizer)
		
	endfunction : get_op

	/* --- get_data_in_packet --- */
	protected function st_data_in_packet_t get_data_in_packet();
		
		/* --- init local variables --- */
		bit signed [15:0] A;
		bit               A_parity;
		bit signed [15:0] B;
		bit               B_parity;			
		bit        [ 2:0] randomizer;
		
		/* --- get A value --- */
		randomizer = 3'($random);
		case (randomizer)
			3'b000 : A = 16'h0000;     // all zeroes   12.5% propability
			3'b001 : A = 16'h8000;     // min value    12.5% propability
			3'b110 : A = 16'h7FFF;     // max value    12.5% propability
			3'b111 : A = 16'hFFFF;     // all ones     12.5% propability
			default: A = 16'($random); // random value 50%   propability
		endcase // case (randomizer)
		
		/* --- get A parity --- */
		A_parity = ^A;
		// randomize parity correctness
		randomizer = 3'($random);
		if (3'b000 == randomizer) A_parity = !A_parity; // wrong parity 12.5% propability
		
		/* --- get B value --- */
		randomizer = 3'($random);
		case (randomizer)
			3'b000 : B = 16'h0000;     // all zeroes   12.5% propability
			3'b001 : B = 16'h8000;     // min value    12.5% propability
			3'b110 : B = 16'h7FFF;     // max value    12.5% propability
			3'b111 : B = 16'hFFFF;     // all ones     12.5% propability
			default: B = 16'($random); // random value 50%   propability
		endcase // case (randomizer)
		
		/* --- get B parity --- */
		B_parity = ^B;
		// randomize parity correctness
		randomizer = 3'($random);
		if (3'b000 == randomizer) B_parity = !B_parity; // wrong parity 12.5% propability		
		
		/* --- return --- */
		return '{A, A_parity, B, B_parity};
		
	endfunction : get_data_in_packet
	
//------------------------------------------------------------------------------
// main
//------------------------------------------------------------------------------

	task execute();
		operation_t op_set;
		st_data_in_packet_t idata_in_packet;
		bfm.reset_dut();
		repeat (2000) begin : random_loop
			op_set          = get_op();
			idata_in_packet = get_data_in_packet();
			bfm.send_data(op_set, idata_in_packet); // idata_in_packet, iop_set
		end : random_loop
	endtask // initial begin

endclass : tpgen



