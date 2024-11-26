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
class scoreboard extends uvm_subscriber #(st_data_out_packet_t);
	 `uvm_component_utils(scoreboard)
	 
//------------------------------------------------------------------------------
// local typdefs
//------------------------------------------------------------------------------
	protected typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result_t;
	  
//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

	uvm_tlm_analysis_fifo #(command_s) cmd_f;
	
	protected test_result_t	test_result = TEST_PASSED;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

//------------------------------------------------------------------------------
// calculate expected results
//------------------------------------------------------------------------------
	/* calculate expected result */
	protected function bit signed [31:0] get_expected_out(
			bit signed [15:0] A,
			bit signed [15:0] B
		);
		return A * B;
	`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d)",$time, A, B);
	`endif
	endfunction : get_expected_out
	
	/* calculate expected result parity */
	protected function bit get_expected_out_parity(
			bit signed [15:0] A,
			bit signed [15:0] B
		);
		bit signed [31:0] res;
		res = get_expected_out(A,B);
		return ^res;
	endfunction : get_expected_out_parity
	
	/* calculate expected input parity error */
	protected function bit get_expected_input_parity_error(
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
// subscriber write function
//------------------------------------------------------------------------------

    function void write(st_data_out_packet_t t);
		bit signed [31:0] expected_out;
		bit               expected_out_parity;
		bit               expected_input_parity_error;
        command_s cmd;
        cmd.data_in_packet	= '{0,0,0,0};
        cmd.op				= rst_op;
	    //cmd_f.flush();
        do
            if (!cmd_f.try_get(cmd))
                $fatal(1, "Missing command in self checker");
        while (cmd.op == rst_op);

        expected_out                = get_expected_out(cmd.data_in_packet.A, cmd.data_in_packet.B);
        expected_out_parity         = get_expected_out_parity(cmd.data_in_packet.A, cmd.data_in_packet.B);
        expected_input_parity_error = get_expected_input_parity_error(cmd.data_in_packet.A, cmd.data_in_packet.A_parity, cmd.data_in_packet.B, cmd.data_in_packet.B_parity);

        SCOREBOARD_CHECK:
		if( t.data_out == expected_out &&
			t.data_out_parity == expected_out_parity &&
			t.data_in_parity_error == expected_input_parity_error) begin
		`ifdef DEBUG
			$display("Test passed for A=%0d A_parity=%d B=%0d B_parity=%0d", dp.A, dp.A_parity, dp.B, dp.B_parity);
		`endif
		end
		else begin
			$display("Test failed for A=%0d A_parity=%d B=%0d B_parity=%0d", cmd.data_in_packet.A, cmd.data_in_packet.A_parity, cmd.data_in_packet.B, cmd.data_in_packet.B_parity);
			$display("Expected out: %d  received out: %d", expected_out, t.data_out);
			$display("Expected out parity:      %d  received out parity:      %d", expected_out_parity, t.data_out_parity);
			$display("Expected in parity error: %d  received in parity error: %d", expected_input_parity_error, t.data_in_parity_error);
			test_result = TEST_FAILED;
        end
    endfunction : write
	
//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        cmd_f = new ("cmd_f", this);
    endfunction : build_phase
    
//------------------------------------------------------------------------------
// print the PASSED/FAILED in color
//------------------------------------------------------------------------------
	protected function void print_test_result (test_result_t test_result);
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
// report phase
//------------------------------------------------------------------------------
	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
    	print_test_result(test_result);
	endfunction : report_phase
		
endclass : scoreboard
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  