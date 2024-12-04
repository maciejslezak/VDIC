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
class command_transaction extends uvm_transaction;
    `uvm_object_utils(command_transaction)

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

	rand bit signed [15:0] A;
	rand bit               A_parity;
	rand bit signed [15:0] B;
	rand bit               B_parity;	
    rand operation_t op;

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

    constraint data {
        ! (A inside {16'h0000, 16'h8000, 16'h7FFF, 16'hFFFF});
        ! (B inside {16'h0000, 16'h8000, 16'h7FFF, 16'hFFFF});
	    op dist {mul_op:=500, rst_op:=1};
    }
    
//------------------------------------------------------------------------------
// transaction functions: do_copy, clone_me, do_compare, convert2string
//------------------------------------------------------------------------------

    function void do_copy(uvm_object rhs);
        command_transaction copied_transaction_h;

        if(rhs == null)
            `uvm_fatal("COMMAND TRANSACTION", "Tried to copy from a null pointer")

        super.do_copy(rhs); // copy all parent class data

        if(!$cast(copied_transaction_h,rhs))
            `uvm_fatal("COMMAND TRANSACTION", "Tried to copy wrong type.")

        A	     = copied_transaction_h.A;
        A_parity = copied_transaction_h.A_parity;
        B        = copied_transaction_h.B;
        B_parity = copied_transaction_h.B_parity;
        op       = copied_transaction_h.op;

    endfunction : do_copy


    function command_transaction clone_me();
        
        command_transaction clone;
        uvm_object tmp;

        tmp = this.clone();
        $cast(clone, tmp);
        return clone;
        
    endfunction : clone_me


    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        
        command_transaction compared_transaction_h;
        bit same;

        if (rhs==null) `uvm_fatal("RANDOM TRANSACTION",
                "Tried to do comparison to a null pointer");

        if (!$cast(compared_transaction_h,rhs))
            same = 0;
        else
            same = super.do_compare(rhs, comparer) &&
            (compared_transaction_h.A == A) &&
            (compared_transaction_h.A_parity == A_parity) &&
            (compared_transaction_h.B == B) &&
            (compared_transaction_h.B_parity == B_parity) &&
            (compared_transaction_h.op == op);

        return same;
        
    endfunction : do_compare


    function string convert2string();
        string s;
        s = $sformatf("A: %d  A_parity: %1b  B: %d  B_parity: %1b  op: %s", A, A_parity, B, B_parity, op.name());
        return s;
    endfunction : convert2string

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new (string name = "");
        super.new(name);
    endfunction : new

endclass : command_transaction
