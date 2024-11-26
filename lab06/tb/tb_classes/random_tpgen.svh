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
class random_tpgen extends base_tpgen;
    `uvm_component_utils (random_tpgen)
    
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
    
//------------------------------------------------------------------------------
// function: get_data_in_packet - generate random data for the tpgen
//------------------------------------------------------------------------------
	protected function st_data_in_packet_t get_data_in_packet();
		
		/* --- init local variables --- */
		bit signed [15:0] A;
		bit               A_parity;
		bit signed [15:0] B;
		bit               B_parity;			
		bit        [ 2:0] randomizer;
		
		/* --- get A value --- */
		A = 16'($random);

		/* --- get A parity --- */
		A_parity = ^A;
		// randomize parity correctness
		randomizer = 3'($random);
		if (3'b000 == randomizer) A_parity = !A_parity; // wrong parity 12.5% propability
		
		/* --- get B value --- */
		B = 16'($random); // random value 50%   propability
		
		/* --- get B parity --- */
		B_parity = ^B;
		// randomize parity correctness
		randomizer = 3'($random);
		if (3'b000 == randomizer) B_parity = !B_parity; // wrong parity 12.5% propability		
		
		/* --- return --- */
		return '{A, A_parity, B, B_parity};
		
	endfunction : get_data_in_packet
	
//------------------------------------------------------------------------------
// function: get_op - generate random opcode for the tpgen
//------------------------------------------------------------------------------
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
	
endclass : random_tpgen
	