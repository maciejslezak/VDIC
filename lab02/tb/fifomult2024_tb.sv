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

 History:
 2021-10-05 RSz, AGH UST - test modified to send all the data on negedge clk
 and check the data on the correct clock edge (covergroup on posedge
 and scoreboard on negedge). Scoreboard and coverage removed.
 */
module top;

//------------------------------------------------------------------------------
// Type definitions
//------------------------------------------------------------------------------

	typedef struct {
		bit signed [15:0] A;
		bit               A_parity;
		bit signed [15:0] B;
		bit               B_parity;		
	} st_data_in_packet_t;
	
	typedef enum bit {
		mul_op = 1'b0,
		rst_op = 1'b1
	} operation_t;

	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result_t;

	typedef enum {
		COLOR_BOLD_BLACK_ON_GREEN,
		COLOR_BOLD_BLACK_ON_RED,
		COLOR_BOLD_BLACK_ON_YELLOW,
		COLOR_BOLD_BLUE_ON_WHITE,
		COLOR_BLUE_ON_WHITE,
		COLOR_DEFAULT
	} print_color_t;

//------------------------------------------------------------------------------
// Local variables
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
	
	// testbench control signals
	//operation_t       op;
	test_result_t     test_result = TEST_PASSED;

//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------

	fifomult2024 DUT (.clk, .rst_n, .data_in, .data_in_parity, .data_in_valid,
		.busy_out, .data_out, .data_out_parity, .data_out_valid, .data_in_parity_error);

//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------

	initial begin : clk_gen_blk
		clk = 0;
		forever begin : clk_frv_blk
			#10;
			clk = ~clk;
		end
	end

// timestamp monitor
	initial begin
		longint clk_counter;
		clk_counter = 0;
		forever begin
			@(posedge clk) clk_counter++;
			if(clk_counter % 1000 == 0) begin
				$display("%0t Clock cycles elapsed: %0d", $time, clk_counter);
			end
		end
	end

//------------------------------------------------------------------------------
// Tester
//------------------------------------------------------------------------------

//---------------------------------
// Random data generation functions

	function operation_t get_op();
		
		/* --- init local variables --- */
		bit [2:0] randomizer;
		
		/* --- get operation --- */
		randomizer = 3'($random);
		case (randomizer)
			3'b000 : return rst_op; // reset 12.5% propability
			default: return mul_op; // mult  87.5% propability
		endcase // case (randomizer)
		
	endfunction : get_op

//---------------------------------
	function st_data_in_packet_t get_data_in_packet();
		
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

//------------------------
// Tester main

	initial begin : tpgen
		
		/* --- initial reset --- */
		reset_dut();
		
		/* --- generation loop --- */
		repeat (1000) begin : tpgen_main_blk
			
			/* --- generate data --- */
			data_in_packet = get_data_in_packet();
			
			/* --- latch data in A --- */
			wait(!busy_out);
			@(negedge clk)
			begin
				data_in        = data_in_packet.A;
				data_in_parity = data_in_packet.A_parity;
				data_in_valid  = 1'b1;
			end
			@(negedge clk)
			data_in_valid = 1'b0;
			
			/* --- latch data in B --- */
			wait(!busy_out);
			@(negedge clk)
			begin
				data_in        = data_in_packet.B;
				data_in_parity = data_in_packet.B_parity;
				data_in_valid  = 1'b1;
			end
			
			/* --- handle operation --- */
			case (get_op())
				rst_op: begin : case_rst_op_blk
					/* --- reset dut--- */
					reset_dut();
				end
				default: begin : case_default_blk
					/* --- send data and wait for result --- */
					// clear 'valid' signal after 1 cycle
					@(negedge clk)
					data_in_valid = 1'b0;
					// wait for result
					wait(data_out_valid);
				end : case_default_blk
			endcase // case (op_set)
		// print coverage after each loop
		// $strobe("%0t coverage: %.4g\%",$time, $get_coverage());
		// if($get_coverage() == 100) break;
		end : tpgen_main_blk
		$finish;
	end : tpgen

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
// calculate expected results
//------------------------------------------------------------------------------

	// calculate expected result
	function bit signed [31:0] get_expected_out(
			bit signed [15:0] A,
			bit signed [15:0] B
		);
		return A * B;
	`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d)",$time, A, B);
	`endif
	endfunction : get_expected_out
	
	// calculate expected result parity
	function bit get_expected_out_parity(
			bit signed [15:0] A,
			bit signed [15:0] B
		);
		bit signed [31:0] res;
		res = get_expected_out(A,B);
		return ^res;
	endfunction : get_expected_out_parity
	
	// calculate expected input parity error
	function bit get_expected_input_parity_error(
			bit signed [15:0] A,
			bit               A_parity,
			bit signed [15:0] B,
			bit               B_parity
		);
		if (^A != A_parity)
			return 1'b1;
		else if (^B != B_parity)
			return 1'b1;
		else
			return 1'b0;
	endfunction : get_expected_input_parity_error

//------------------------------------------------------------------------------
// Temporary. The scoreboard will be later used for checking the data
	final begin : finish_of_the_test
		print_test_result(test_result);
	end

//------------------------------------------------------------------------------
// Other functions
//------------------------------------------------------------------------------

// used to modify the color of the text printed on the terminal
	function void set_print_color ( print_color_t c );
		string ctl;
		case(c)
			COLOR_BOLD_BLACK_ON_GREEN : ctl  = "\033\[1;30m\033\[102m";
			COLOR_BOLD_BLACK_ON_RED : ctl    = "\033\[1;30m\033\[101m";
			COLOR_BOLD_BLACK_ON_YELLOW : ctl = "\033\[1;30m\033\[103m";
			COLOR_BOLD_BLUE_ON_WHITE : ctl   = "\033\[1;34m\033\[107m";
			COLOR_BLUE_ON_WHITE : ctl        = "\033\[0;34m\033\[107m";
			COLOR_DEFAULT : ctl              = "\033\[0m\n";
			default : begin
				$error("set_print_color: bad argument");
				ctl                          = "";
			end
		endcase
		$write(ctl);
	endfunction

	function void print_test_result (test_result_t r);
		if(r == TEST_PASSED) begin
			set_print_color(COLOR_BOLD_BLACK_ON_GREEN);
			$write ("-----------------------------------\n");
			$write ("----------- Test PASSED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
		else begin
			set_print_color(COLOR_BOLD_BLACK_ON_RED);
			$write ("-----------------------------------\n");
			$write ("----------- Test FAILED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
	endfunction

//-------------------------------------------------------------------
// Scoreboard, part 1 command receiver and reference model function
//-------------------------------------------------------------------

    bit	                   valid_counter = 1'b0;
    st_data_in_packet_t    sb_data_q        [$];

    always @(posedge clk) begin:scoreboard_fe_blk
	    
        priority if (data_in_valid == 1'b1 && valid_counter == 1'b0) begin
            valid_counter = 1'b1; 
        end
        else if (data_in_valid == 1'b1 && valid_counter == 1'b1) begin
            sb_data_q.push_front(data_in_packet);
	        valid_counter = 1'b0;		
        end
        else begin
	        valid_counter = valid_counter;
        end
        if (rst_n == 1'b0) begin
	        valid_counter = 1'b0;
	        sb_data_q.delete();
        end
    end

//---------------------------------------------------------------
// Scoreboard, part 2 - data checker
//---------------------------------------------------------------

    always @(negedge clk) begin : scoreboard_be_blk

		bit signed [31:0] expected_out;
		bit               expected_out_parity;
		bit               expected_input_parity_error;

        if(data_out_valid) begin:verify_result
	        
            st_data_in_packet_t dp;

            dp = sb_data_q.pop_back();
	        
            expected_out                = get_expected_out(dp.A, dp.B);
	        expected_out_parity         = get_expected_out_parity(dp.A, dp.B);
	        expected_input_parity_error = get_expected_input_parity_error(dp.A, dp.A_parity, dp.B, dp.B_parity);

			if( data_out == expected_out &&
				data_out_parity == expected_out_parity &&
				data_in_parity_error == expected_input_parity_error) begin
			`ifdef DEBUG
				$display("Test passed for A=%0d A_parity=%d B=%0d B_parity=%0d", dp.A, dp.A_parity, dp.B, dp.B_parity);
			`endif
			end
			else begin
				$display("Test failed for A=%0d A_parity=%d B=%0d B_parity=%0d", dp.A, dp.A_parity, dp.B, dp.B_parity);
				$display("Expected out: %d  received out: %d", expected_out, data_out);
				$display("Expected out parity:      %d  received out parity:      %d", expected_out_parity, data_out_parity);
				$display("Expected in parity error: %d  received in parity error: %d", expected_input_parity_error, data_in_parity_error);
				test_result = TEST_FAILED;
			end;
        end
    end : scoreboard_be_blk

endmodule : top
