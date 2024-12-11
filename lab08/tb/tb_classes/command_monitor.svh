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
class command_monitor extends uvm_component;
    `uvm_component_utils(command_monitor)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    protected virtual fifomult2024_bfm bfm;
    uvm_analysis_port #(command_transaction) ap;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction

//------------------------------------------------------------------------------
// monitoring function called from BFM
//------------------------------------------------------------------------------
    // this variable is defined here as static for that you can see it in the
    // Simvision waveforms.
    static command_transaction cmd;
    
    function void write_to_monitor( bit signed [15:0] A,
									bit               A_parity,
									bit signed [15:0] B,
									bit               B_parity,
									operation_t op);
//        command_transaction cmd;
        `uvm_info("COMMAND MONITOR",$sformatf("MONITOR: A: %2h  A_parity: %2h  B: %2h  B_parity: %2h  op: %s",
                A, A_parity, B, B_parity, op.name()), UVM_HIGH);
        cmd				= new("cmd");
        cmd.A			= A;
	    cmd.A_parity	= A_parity;
        cmd.B			= B;
	    cmd.B_parity	= B_parity;
        cmd.op = op;
        ap.write(cmd);
    endfunction : write_to_monitor

//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
	    
	    fifomult2024_agent_config agent_config_h;
	    	
	    // get the BFM
        if(!uvm_config_db #(fifomult2024_agent_config)::get(this, "","config", agent_config_h))
            `uvm_fatal("COMMAND MONITOR", "Failed to get CONFIG");

        // pass the command_monitor handler to the BFM
        agent_config_h.bfm.command_monitor_h = this;

        ap                    = new("ap",this);
    endfunction : build_phase

endclass : command_monitor

