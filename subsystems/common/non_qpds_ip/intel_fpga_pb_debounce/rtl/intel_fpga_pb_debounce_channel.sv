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

`default_nettype none

//****************************************************************************//
module intel_fpga_pb_debounce_channel
//****************************************************************************//
(
  input  wire  clk,
  input  wire  sample_en,
  input  wire  i_pb,
  output logic o_pb         = 1'b0
);

timeunit 1ns;
timeprecision 1ps;
//****************************************************************************//
logic           pb              = 1'b0;
logic           holdoff         = 1'b0;
logic           clear_holdoff;
logic [5 : 0]   holdoff_counter = 'd0;
//----------------------------------------------------------------------------//

always_ff @(posedge clk) begin
  if (sample_en == 'd1) begin
    pb <= i_pb;
  end //if
end //always_ff

always_ff @(posedge clk) begin
  if (sample_en == 'd1) begin
    if ( (pb != o_pb) && (holdoff == 1'b0) ) begin
      o_pb <= pb;
    end //if
  end //if
end //always_ff

always_ff @ (posedge clk) begin
  if (sample_en == 'd1) begin
    if (clear_holdoff == 1'b1) begin
      holdoff <= 1'b0;
    end else if (pb != o_pb) begin
      holdoff <= 1'b1;
    end //if
  end //if
end //always_ff

always_ff @ (posedge clk) begin
  if (sample_en == 'd1) begin
    if ((pb != o_pb) && (holdoff == 1'b0)) begin
      holdoff_counter <= '{default : 'b1};
    // end else if (clear_holdoff == 1'b0) begin
    end else if (holdoff == 1'b1) begin
      holdoff_counter <= holdoff_counter - 1'b1;
    end //if
  end //if
end //always_ff

always_comb begin
  if (holdoff_counter == 'd0) begin
    clear_holdoff = 1'b1;
  end else begin
    clear_holdoff = 1'b0;
  end //if
end //always_ff

//****************************************************************************//
endmodule : intel_fpga_pb_debounce_channel
//****************************************************************************//

`default_nettype wire
