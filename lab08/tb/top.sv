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
module top;
import uvm_pkg::*;
`include "uvm_macros.svh"
import fifomult2024_tb_pkg::*;
`include "fifomult2024_macros.svh"

fifomult2024_bfm class_bfm();

fifomult2024 class_dut (.clk(class_bfm.clk), 
				 	.rst_n(class_bfm.rst_n), 
				 	.data_in(class_bfm.data_in), 
				 	.data_in_parity(class_bfm.data_in_parity), 
					.data_in_valid(class_bfm.data_in_valid), 
					.busy_out(class_bfm.busy_out), 
					.data_out(class_bfm.data_out), 
					.data_out_parity(class_bfm.data_out_parity), 
					.data_out_valid(class_bfm.data_out_valid), 
					.data_in_parity_error(class_bfm.data_in_parity_error));

fifomult2024_bfm module_bfm();

fifomult2024 module_dut (.clk(module_bfm.clk), 
				 	.rst_n(module_bfm.rst_n), 
				 	.data_in(module_bfm.data_in), 
				 	.data_in_parity(module_bfm.data_in_parity), 
					.data_in_valid(module_bfm.data_in_valid), 
					.busy_out(module_bfm.busy_out), 
					.data_out(module_bfm.data_out), 
					.data_out_parity(module_bfm.data_out_parity), 
					.data_out_valid(module_bfm.data_out_valid), 
					.data_in_parity_error(module_bfm.data_in_parity_error));

// stimulus generator for module_dut
fifomult2024_tpgen_module stim_module(module_bfm);

initial begin
    uvm_config_db #(virtual fifomult2024_bfm)::set(null, "*", "class_bfm", class_bfm);
	uvm_config_db #(virtual fifomult2024_bfm)::set(null, "*", "module_bfm", module_bfm);
    run_test("dual_test");
end

endmodule : top


