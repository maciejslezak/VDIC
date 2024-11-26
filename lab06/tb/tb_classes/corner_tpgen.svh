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
 */
class corner_tpgen extends random_tpgen;
    `uvm_component_utils(corner_tpgen)
    
//------------------------------------------------------------------------------
// function: get_data_in_packet - generate data packet with corner values for the tpgen
//------------------------------------------------------------------------------    
	protected function st_data_in_packet_t get_data_in_packet();
		
		/* --- init local variables --- */
		bit signed [15:0] A;
		bit               A_parity;
		bit signed [15:0] B;
		bit               B_parity;			
		bit        [ 1:0] data_randomizer;
		bit        [ 2:0] parity_randomizer;
		
		/* --- get A value --- */
		data_randomizer = 2'($random);
		case (data_randomizer)
			2'b00 : A = 16'h0000;	// all zeroes
			2'b01 : A = 16'h8000;	// min value
			2'b10 : A = 16'h7FFF;	// max value
			2'b11 : A = 16'hFFFF;	// all ones
			default: A = 16'h0000;
		endcase // case (data_randomizer)
		
		/* --- get A parity --- */
		A_parity = ^A;
		// randomize parity correctness
		parity_randomizer = 3'($random);
		if (3'b000 == parity_randomizer) A_parity = !A_parity;
		
		/* --- get B value --- */
		data_randomizer = 2'($random);
		case (data_randomizer)
			2'b00 : B = 16'h0000;	// all zeroes
			2'b01 : B = 16'h8000;	// min value
			2'b10 : B = 16'h7FFF;	// max value
			2'b11 : B = 16'hFFFF;	// all ones
			default: B = 16'h0000;
		endcase // case (data_randomizer)
		
		/* --- get B parity --- */
		B_parity = ^B;
		// randomize parity correctness
		parity_randomizer = 3'($random);
		if (3'b000 == parity_randomizer) B_parity = !B_parity; // wrong parity 12.5% propability		
		
		/* --- return --- */
		return '{A, A_parity, B, B_parity};
		
	endfunction : get_data_in_packet  
    
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
    
endclass : corner_tpgen