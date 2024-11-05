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
module scoreboard(fifomult2024_bfm bfm);
	 
//------------------------------------------------------------------------------
// imports  
//------------------------------------------------------------------------------

	import fifomult2024_tb_pkg::*;
	  
//------------------------------------------------------------------------------
// local typdefs
//------------------------------------------------------------------------------

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
// local variables
//------------------------------------------------------------------------------

	bit	            sb_valid_counter = 1'b0;
	test_result_t	test_result = TEST_PASSED;

//------------------------------------------------------------------------------
// calculate expected results
//------------------------------------------------------------------------------

	/* calculate expected result */
	function bit signed [31:0] get_expected_out(
			bit signed [15:0] A,
			bit signed [15:0] B
		);
		return A * B;
	`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d)",$time, A, B);
	`endif
	endfunction : get_expected_out
	
	/* calculate expected result parity */
	function bit get_expected_out_parity(
			bit signed [15:0] A,
			bit signed [15:0] B
		);
		bit signed [31:0] res;
		res = get_expected_out(A,B);
		return ^res;
	endfunction : get_expected_out_parity
	
	/* calculate expected input parity error */
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

//-------------------------------------------------------------------
// Scoreboard, part 1 command receiver and reference model function
//-------------------------------------------------------------------

    st_data_in_packet_t    sb_data_q        [$];

    always @(posedge bfm.clk) begin:scoreboard_fe_blk
	    /* sample data only after two consecutive 'valid' signal occurences */
        priority if (bfm.data_in_valid == 1'b1 && sb_valid_counter == 1'b0) begin
            sb_valid_counter = 1'b1; 
        end
        else if (bfm.data_in_valid == 1'b1 && sb_valid_counter == 1'b1) begin
            sb_data_q.push_front(bfm.data_in_packet);
	        sb_valid_counter = 1'b0;		
        end
        else begin
	        sb_valid_counter = sb_valid_counter;
        end
        if (bfm.rst_n == 1'b0) begin
	        sb_valid_counter = 1'b0;
	        sb_data_q.delete();
        end
    end

//---------------------------------------------------------------
// Scoreboard, part 2 - data checker
//---------------------------------------------------------------

    always @(negedge bfm.clk) begin : scoreboard_be_blk

		bit signed [31:0] expected_out;
		bit               expected_out_parity;
		bit               expected_input_parity_error;

        if(bfm.data_out_valid) begin:verify_result
	        
            st_data_in_packet_t dp;

            dp = sb_data_q.pop_back();
	        
            expected_out                = get_expected_out(dp.A, dp.B);
	        expected_out_parity         = get_expected_out_parity(dp.A, dp.B);
	        expected_input_parity_error = get_expected_input_parity_error(dp.A, dp.A_parity, dp.B, dp.B_parity);

			if( bfm.data_out == expected_out &&
				bfm.data_out_parity == expected_out_parity &&
				bfm.data_in_parity_error == expected_input_parity_error) begin
			`ifdef DEBUG
				$display("Test passed for A=%0d A_parity=%d B=%0d B_parity=%0d", dp.A, dp.A_parity, dp.B, dp.B_parity);
			`endif
			end
			else begin
				$display("Test failed for A=%0d A_parity=%d B=%0d B_parity=%0d", dp.A, dp.A_parity, dp.B, dp.B_parity);
				$display("Expected out: %d  received out: %d", expected_out, bfm.data_out);
				$display("Expected out parity:      %d  received out parity:      %d", expected_out_parity, bfm.data_out_parity);
				$display("Expected in parity error: %d  received in parity error: %d", expected_input_parity_error, bfm.data_in_parity_error);
				test_result = TEST_FAILED;
			end;
        end
    end : scoreboard_be_blk
    
//------------------------------------------------------------------------------
// used to modify the color printed on the terminal
//------------------------------------------------------------------------------

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

//------------------------------------------------------------------------------
// print the PASSED/FAILED in color
//------------------------------------------------------------------------------

	function void print_test_result (test_result_t test_result);
	    if(test_result == TEST_PASSED) begin
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

//------------------------------------------------------------------------------
// print the test result at the simulation end
//------------------------------------------------------------------------------
final begin : finish_of_the_test
    print_test_result(test_result);
end    
endmodule : scoreboard
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  