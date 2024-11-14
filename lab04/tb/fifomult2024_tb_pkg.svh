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

`include "coverage.svh"
`include "tpgen.svh"
`include "scoreboard.svh"
`include "testbench.svh"

endpackage