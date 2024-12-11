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

fifomult2024_bfm bfm();

fifomult2024 DUT (	.clk(bfm.clk), 
				 	.rst_n(bfm.rst_n), 
				 	.data_in(bfm.data_in), 
				 	.data_in_parity(bfm.data_in_parity), 
					.data_in_valid(bfm.data_in_valid), 
					.busy_out(bfm.busy_out), 
					.data_out(bfm.data_out), 
					.data_out_parity(bfm.data_out_parity), 
					.data_out_valid(bfm.data_out_valid), 
					.data_in_parity_error(bfm.data_in_parity_error));


initial begin
    uvm_config_db #(virtual fifomult2024_bfm)::set(null, "*", "bfm", bfm);
    run_test();
end

endmodule : top