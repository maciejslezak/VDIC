/******************************************************************************
 * (C) Copyright 2024 AGH University All Rights Reserved
 *
 * MODULE:    tinyalu_tb_pkg
 * DEVICE:
 * PROJECT:
 * AUTHOR:    mslezak
 * DATE:      2024 12:20:30
 *
 *******************************************************************************/
`timescale 1ns/1ps

package fifomult2024_tb_pkg;
	
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
//------------------------------------------------------------------------------
// package typedefs
//------------------------------------------------------------------------------

    /* operation codes */
	typedef enum bit {
		mul_op = 1'b0,
		rst_op = 1'b1
	} operation_t;
	
	typedef struct {
		bit signed [15:0] A;
		bit               A_parity;
		bit signed [15:0] B;
		bit               B_parity;		
	} st_data_in_packet_t;
	
	/* data out packet */
	typedef struct {
		bit signed [31:0] data_out;
		bit               data_out_parity;
		bit               data_in_parity_error;
	} st_data_out_packet_t;
	
	/* command packet */
	typedef struct {
		bit signed [15:0] A;
		bit               A_parity;
		bit signed [15:0] B;
		bit               B_parity;		
		operation_t			op;
	} command_s;

    // terminal print colors
    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color;
	
//------------------------------------------------------------------------------
// package functions
//------------------------------------------------------------------------------

    // used to modify the color of the text printed on the terminal

    function void set_print_color ( print_color c );
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
// testbench classes
//------------------------------------------------------------------------------

// configs
`include "env_config.svh"
`include "fifomult2024_agent_config.svh"

// transactions
`include "command_transaction.svh"
`include "corner_command_transaction.svh"
`include "result_transaction.svh"

// testbench components
`include "coverage.svh"
`include "scoreboard.svh"
`include "tpgen.svh"
`include "driver.svh"
`include "command_monitor.svh"
`include "result_monitor.svh"
`include "fifomult2024_agent.svh"
`include "env.svh"

//------------------------------------------------------------------------------
// test classes
//------------------------------------------------------------------------------
`include "dual_test.svh"

endpackage : fifomult2024_tb_pkg