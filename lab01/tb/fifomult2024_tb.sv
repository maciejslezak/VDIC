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
	bit signed [15:0] data_in_A;
	bit               A_parity;
	bit signed [15:0] data_in_B;
	bit               B_parity;
	
	// testbench control signals
	operation_t       op;
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
		bit [2:0] op_choice;
		op_choice = 3'($random);
		case (op_choice)
			3'b000 : return rst_op; // reset 12.5% propability
			default: return mul_op; // mult  87.5% propability
		endcase // case (op_choice)
	endfunction : get_op

//---------------------------------
	function bit signed [15:0] get_data_in();
		bit [2:0] value;
		value = 3'($random);
		case (value)
			3'b000 : return 16'h0000;     // all zeroes   12.5% propability
			3'b001 : return 16'h8000;     // min value    12.5% propability
			3'b110 : return 16'h7FFF;     // max value    12.5% propability
			3'b111 : return 16'hFFFF;     // all ones     12.5% propability
			default: return 16'($random); // random value 50%   propability
		endcase // case (value)
	endfunction : get_data_in
	
//---------------------------------
	function bit get_in_parity();
		return 1'($random); // good/wrong parity 50% propability
	endfunction : get_in_parity

//------------------------
// Tester main

	initial begin : tpgen
		reset_dut();
		data_in_valid = 1'b0;
		repeat (1000) begin : tpgen_main_blk
			// generate input data
			data_in_A = get_data_in();
			A_parity  = get_in_parity();
			data_in_B = get_data_in();
			B_parity  = get_in_parity();
			op        = get_op();
			// latch first multiplicand
			wait(!busy_out);
			@(negedge clk)
			begin
				data_in        = data_in_A;
				data_in_parity = A_parity;
				data_in_valid  = 1'b1;
			end
			@(negedge clk)
			data_in_valid = 1'b0;
			// latch second multiplicand
			wait(!busy_out);
			@(negedge clk)
			begin
				data_in        = data_in_B;
				data_in_parity = B_parity;
				data_in_valid  = 1'b1;
			end
			@(negedge clk)
			data_in_valid = 1'b0;		
			case (op) // handle the start signal
				rst_op: begin : case_rst_op_blk
					// reset dut
					reset_dut();
				end
				default: begin : case_default_blk
					// wait for result
					wait(data_out_valid);
					//------------------------------------------------------------------------------
					// temporary data check - scoreboard will do the job later
					begin
						automatic bit signed [31:0] expected_out                = get_expected_out(data_in_A, data_in_B);
						automatic bit               expected_out_parity         = get_expected_out_parity(data_in_A, data_in_B);
						automatic bit               expected_input_parity_error = get_expected_input_parity_error(data_in_A, A_parity, data_in_B, B_parity);
						if( data_out == expected_out &&
							data_out_parity == expected_out_parity &&
							data_in_parity_error == expected_input_parity_error) begin
						`ifdef DEBUG
							$display("Test passed for A=%0d A_parity=%d B=%0d B_parity=%0d", data_in_A, A_parity, data_in_B, B_parity);
						`endif
						end
						else begin
							$display("Test failed for A=%0d A_parity=%d B=%0d B_parity=%0d", data_in_A, A_parity, data_in_B, B_parity);
							$display("Expected out: %d  received out: %d", expected_out, data_out);
							$display("Expected out parity:      %d  received out parity:      %d", expected_out_parity, data_out_parity);
							$display("Expected in parity error: %d  received in parity error: %d", expected_input_parity_error, data_in_parity_error);
							test_result = TEST_FAILED;
						end;
					end

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


endmodule : top
