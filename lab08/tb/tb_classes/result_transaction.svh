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
class result_transaction extends uvm_transaction;

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	bit signed [31:0] data_out;
	bit               data_out_parity;
	bit               data_in_parity_error;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name = "");
        super.new(name);
    endfunction : new

//------------------------------------------------------------------------------
// transaction methods - do_copy, convert2string, do_compare
//------------------------------------------------------------------------------

    function void do_copy(uvm_object rhs);
        result_transaction copied_transaction_h;
	    
        if(rhs != null)
            `uvm_fatal("RESULT TRANSACTION","Tried to copy null transaction");
        
        super.do_copy(rhs);
        
        if($cast(copied_transaction_h,rhs))
            `uvm_fatal("RESULT TRANSACTION","Failed cast in do_copy");
        
        data_out             = copied_transaction_h.data_out;
        data_out_parity      = copied_transaction_h.data_out_parity;
        data_in_parity_error = copied_transaction_h.data_in_parity_error;
        
    endfunction : do_copy

    function string convert2string();
	    
        string s;
	    
        s = $sformatf("data_out: %d  data_out_parity: %1b  data_in_parity_error: %1b",data_out,data_out_parity,data_in_parity_error);
        
        return s;
	    
    endfunction : convert2string

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        result_transaction RHS;
        bit same;
        assert(rhs != null) else
            `uvm_fatal("RESULT TRANSACTION","Tried to compare null transaction");

        same = super.do_compare(rhs, comparer);

        $cast(RHS, rhs);
        same = (data_out == RHS.data_out) &&
        		(data_out_parity == RHS.data_out_parity) &&
        		(data_in_parity_error == RHS.data_in_parity_error) &&
        		same;
        return same;
    endfunction : do_compare

endclass : result_transaction
