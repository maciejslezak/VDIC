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
 
 Last modification: 2024-11-14 AGH MSle
 */
class coverage extends uvm_subscriber #(command_transaction);
	`uvm_component_utils(coverage)

//------------------------------------------------------------------------------
// local type definitions
//------------------------------------------------------------------------------
	protected typedef enum bit [1:0] {
		A_B_INCORRECT = 2'b00,
		A_INCORRECT   = 2'b01,
		B_INCORRECT   = 2'b10,
		CORRECT       = 2'b11
	} parity_corr_t;

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

	protected parity_corr_t parity_corr;
	  
	protected bit signed [15:0] A;
	protected bit               A_parity;
	protected bit signed [15:0] B;
	protected bit               B_parity;	
	protected operation_t op;
	
//------------------------------------------------------------------------------
// covergroups
//------------------------------------------------------------------------------	
	/* Covergroup checking the op codes and their sequences */
    covergroup op_cov;

        option.name = "cg_op_cov";

        coverpoint op {
            // #A1 test mult operation
            bins A1_mul  	= {mul_op};

            // #A2 test mult operation after reset
            bins A2_rst_mul = (rst_op => mul_op);

            // #A3 test reset after mult operation
            bins A3_mul_rst	= (mul_op => rst_op);
        }

    endgroup

	/* Covergroup checking for min, max, all-0 and all-1 values of the inputs */
    covergroup data_in_corners_cov;

        option.name = "cg_data_in_corners_cov";

        a_leg: coverpoint A {
	        bins min    = {16'sh8000};
            bins zeros  = {16'sh0000};
            bins ones   = {16'shFFFF};
	        bins max    = {16'sh7FFF};
            bins others = default;
        }

        b_leg: coverpoint B {
	        bins min    = {16'sh8000};
            bins zeros  = {16'sh0000};
            bins ones   = {16'shFFFF};
	        bins max    = {16'sh7FFF};
            bins others = default;
        }

        B_A_B: cross a_leg, b_leg {

            // #B1 Simulate multiplication of minimum values
            bins B1	= binsof (a_leg.min) && binsof (b_leg.min);

            // #B2 Simulate multiplication of maximum values
            bins B2	= binsof (a_leg.max) && binsof (b_leg.max);
	        
            // #B3 Simulate multiplication of minimum value as first input and maximum value as second input
            bins B3	= binsof (a_leg.min) && binsof (b_leg.max);
	        
            // #B4 Simulate multiplication of maximum value as first input and minimum value as second input
            bins B4	= binsof (a_leg.max) && binsof (b_leg.min);
	        
            // #B5 Simulate all zeroes as inputs
            bins B5	= binsof (a_leg.zeros) && binsof (b_leg.zeros);
	        
            // #B6 Simulate all ones as inputs
            bins B6	= binsof (a_leg.ones) && binsof (b_leg.ones);

        }

    endgroup

	/* Covergroup checking for min, max, all-0 and all-1 values of the inputs */
    covergroup parity_cov;
	    
	    option.name = "cg_parity_cov";
	    
	    // B7 - B10
	    parity : coverpoint parity_corr;
	    
    endgroup

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
	    super.new(name, parent);
	    op_cov				= new();
	    data_in_corners_cov	= new();
	    parity_cov			= new();
    endfunction : new

//------------------------------------------------------------------------------
// functions
//------------------------------------------------------------------------------
	/* parity check function */
	protected function parity_corr_t check_parity_cov (
				bit signed [15:0] A,
				bit               A_parity,
				bit signed [15:0] B,
				bit               B_parity
		);
		
		automatic bit expected_A_parity = ^A;
		automatic bit expected_B_parity = ^B;
		
		if (expected_A_parity == A_parity &&
			expected_B_parity == B_parity) begin
			return CORRECT;
		end
		else if (expected_A_parity != A_parity &&
				 expected_B_parity == B_parity) begin
			return A_INCORRECT;
		end
		else if (expected_A_parity == A_parity &&
				 expected_B_parity != B_parity) begin
			return B_INCORRECT;
		end
		else begin
			return A_B_INCORRECT;
		end
				 
	endfunction : check_parity_cov

//------------------------------------------------------------------------------
// subscriber write function
//------------------------------------------------------------------------------
    function void write(command_transaction t);
        A        = t.A;
	    A_parity = t.A_parity;
	    B        = t.B;
	    B_parity = t.B_parity;
        op       = t.op;
        op_cov.sample();
	    if (op != rst_op) begin
		    parity_corr = check_parity_cov(A, A_parity, B, B_parity);
        	parity_cov.sample();
        	data_in_corners_cov.sample();
	    end
    endfunction : write
    
endclass : coverage





