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
class scoreboard extends uvm_subscriber #(result_transaction);
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

	uvm_tlm_analysis_fifo #(command_transaction) cmd_f;
	
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

    local function result_transaction predict_result(command_transaction cmd);
        result_transaction predicted;

        predicted = new("predicted");
	    
	    predicted.data_out = cmd.A * cmd.B;
	    predicted.data_out_parity = ^predicted.data_out;
		if (^cmd.A != cmd.A_parity)
			predicted.data_in_parity_error = 1'b1;
		else if (^cmd.B != cmd.B_parity)
			predicted.data_in_parity_error = 1'b1;
		else
			predicted.data_in_parity_error = 1'b0;
		
		return predicted;
		
    endfunction : predict_result

//------------------------------------------------------------------------------
// subscriber write function
//------------------------------------------------------------------------------

    function void write(result_transaction t);
        string data_str;
        command_transaction cmd;
        result_transaction predicted;

        do begin       
            if (!cmd_f.try_get(cmd))
                $fatal(1, "Missing command in self checker");
            end
        while (cmd.op == rst_op);

        predicted = predict_result(cmd);
        
        data_str  = { cmd.convert2string(),
            " ==>  Actual " , t.convert2string(),
            "/Predicted ",predicted.convert2string()};

        if (!predicted.compare(t)) begin
            `uvm_error("SELF CHECKER", {"FAIL: ",data_str})
            test_result = TEST_FAILED;
        end
        else
            `uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)

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
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  