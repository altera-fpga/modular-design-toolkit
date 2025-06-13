/* ##################################################################################
 * Copyright (C) 2025 Altera Corporation
 *
 * This software and the related documents are Altera copyrighted materials, and
 * your use of them is governed by the express license under which they were
 * provided to you ("License"). Unless the License provides otherwise, you may
 * not use, modify, copy, publish, distribute, disclose or transmit this software
 * or the related documents without Altera's prior written permission.
 *
 * This software and the related documents are provided as is, with no express
 * or implied warranties, other than those that are expressly stated in the License.
* ##################################################################################
*/

//----------------------------------------------------------------------------//
//                         intel_fpga_shared_mem_dpram
// True dual port memory
//----------------------------------------------------------------------------//
`default_nettype none

//****************************************************************************//
module intel_fpga_shared_mem_dpram
//****************************************************************************//
# (
  string P_RAMSTYLE    = "M20K", // also could be "MLAB" in principle but MLAB
                                 // can't support true dual port
  int    P_ADDR_WIDTH  = 4,
  int    P_DATA_WIDTH  = 32
) (
    input  wire                         clk,
    input  wire  [P_DATA_WIDTH - 1 : 0] data_in_a,
    input  wire  [P_DATA_WIDTH - 1 : 0] data_in_b,
    input  wire  [P_ADDR_WIDTH - 1 : 0] addr_a,
    input  wire  [P_ADDR_WIDTH - 1 : 0] addr_b,
    input  wire                         re_a,
    input  wire                         we_a,
    input  wire                         re_b,
    input  wire                         we_b,
    output logic [P_DATA_WIDTH - 1 : 0] data_out_a,
    output logic [P_DATA_WIDTH - 1 : 0] data_out_b

);

timeunit 1ns;
timeprecision 1ps;
//****************************************************************************//

// Declare the RAM variable
(* ramstyle = P_RAMSTYLE *) logic [P_DATA_WIDTH - 1 : 0] ram [2**P_ADDR_WIDTH - 1 : 0];
reg [P_DATA_WIDTH - 1 : 0] data_out_a_reg;
reg [P_DATA_WIDTH - 1 : 0] data_out_b_reg;

//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//
//                              PORT A
//----------------------------------------------------------------------------//
// Port A write
// can't be always_ff as "ram" is driven in two blocks
always @ (posedge clk) begin
  if (we_a) begin
    // this has to be instantaneous assignment (not "<=") in order for inference
    // to work correctly
    ram[addr_a] = data_in_a;
  end
end //always

// Port A read
always_ff @ (posedge clk) begin
  if (re_a == 1'b1) begin
    data_out_a_reg <= ram[addr_a];
  end //if
end //always

assign data_out_a = data_out_a_reg;

//----------------------------------------------------------------------------//
//                              PORT B
//----------------------------------------------------------------------------//
// Port B write
// can't be always_ff as "ram" is driven in two blocks
always @ (posedge clk) begin
  if (we_b) begin
    // this has to be instantaneous assignment (not "<=") in order for inference
    // to work correctly
    ram[addr_b] = data_in_b;
  end //if
end //always

// Port B read
always_ff @ (posedge clk) begin
  if (re_b == 1'b1) begin
    data_out_b_reg <= ram[addr_b];
  end //if
end //always

assign data_out_b = data_out_b_reg;

//****************************************************************************//
endmodule
//****************************************************************************//

`default_nettype wire
