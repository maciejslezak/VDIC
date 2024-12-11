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
class corner_command_transaction extends command_transaction;
    `uvm_object_utils(corner_command_transaction)

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

    constraint data {
        A inside {16'h0000, 16'h8000, 16'h7FFF, 16'hFFFF};
        B inside {16'h0000, 16'h8000, 16'h7FFF, 16'hFFFF};
	    op dist {mul_op:=500, rst_op:=1};
    }

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name="");
        super.new(name);
    endfunction
    
    
endclass : corner_command_transaction


