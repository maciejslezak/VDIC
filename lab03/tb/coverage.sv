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
 module coverage(fifomult2024_bfm bfm);
	 
//------------------------------------------------------------------------------
// imports  
//------------------------------------------------------------------------------

	import fifomult2024_tb_pkg::*;

//------------------------------------------------------------------------------
// type definitions  
//------------------------------------------------------------------------------

	typedef enum bit [1:0] {
		A_B_INCORRECT = 2'b00,
		A_INCORRECT   = 2'b01,
		B_INCORRECT   = 2'b10,
		CORRECT       = 2'b11
	} parity_corr_t;
	 
//------------------------------------------------------------------------------
// variables  
//------------------------------------------------------------------------------	 

	bit                 valid_counter;
	parity_corr_t       parity_corr;
	
//------------------------------------------------------------------------------
// functions  
//------------------------------------------------------------------------------

	/* parity check function */
	function parity_corr_t check_parity_cov (
			st_data_in_packet_t data_in
		);
		
		automatic bit expected_A_parity = ^data_in.A;
		automatic bit expected_B_parity = ^data_in.B;
		
		if (expected_A_parity == data_in.A_parity &&
			expected_B_parity == data_in.B_parity) begin
			return CORRECT;
		end
		else if (expected_A_parity != data_in.A_parity &&
				 expected_B_parity == data_in.B_parity) begin
			return A_INCORRECT;
		end
		else if (expected_A_parity == data_in.A_parity &&
				 expected_B_parity != data_in.B_parity) begin
			return B_INCORRECT;
		end
		else begin
			return A_B_INCORRECT;
		end
				 
	endfunction : check_parity_cov

//------------------------------------------------------------------------------
// covergroups  
//------------------------------------------------------------------------------

	/* Covergroup checking the op codes and their sequences */
    covergroup op_cov;

        option.name = "cg_op_cov";

        coverpoint bfm.op_set {
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

        a_leg: coverpoint bfm.data_in_packet.A {
	        bins min    = {16'sh8000};
            bins zeros  = {16'sh0000};
            bins ones   = {16'shFFFF};
	        bins max    = {16'sh7FFF};
            bins others = default;
        }

        b_leg: coverpoint bfm.data_in_packet.B {
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
// covergroups definitions
//------------------------------------------------------------------------------

    op_cov              oc;
    data_in_corners_cov	corners_c;
    parity_cov          parity_c;

//------------------------------------------------------------------------------
// coverage check
//------------------------------------------------------------------------------

    initial begin : coverage_block
        oc        = new();
        corners_c = new();
	    parity_c  = new();
	    valid_counter = 1'b0;
        forever begin : sampling_block
            @(posedge bfm.clk);
	        /* sample data only when both inputs are correctly latched */
	        priority if (bfm.data_in_valid == 1'b1 && valid_counter == 1'b0) begin
		        // wait for data B to be latched
	            valid_counter = 1'b1; 
	        end
	        else if (bfm.data_in_valid == 1'b1 && valid_counter == 1'b1) begin
	            parity_corr = check_parity_cov(bfm.data_in_packet);
	            oc.sample();
	            corners_c.sample();
		        parity_c.sample();
		        valid_counter = 1'b0;		
	        end
	        else begin
		        valid_counter = valid_counter;
	        end
	        /* additionally sample operation at the reset occurence */
	        if (bfm.rst_n == 1'b0) begin
		        valid_counter = 1'b0;
		        oc.sample();
	        end
        end : sampling_block
    end : coverage_block
    
endmodule : coverage





