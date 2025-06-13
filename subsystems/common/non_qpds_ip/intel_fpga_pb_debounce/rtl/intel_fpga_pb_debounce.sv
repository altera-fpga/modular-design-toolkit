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
module intel_fpga_pb_debounce
//****************************************************************************//
# (
  parameter int P_CLK_FREQ_HZ   = 20_000_000,
  parameter int P_NUM_CHANNELS  = 1
) (
  input  wire                             clk,
  input  wire  [P_NUM_CHANNELS - 1 : 0]   i_pb,
  output logic [P_NUM_CHANNELS - 1 : 0]   o_pb
);

timeunit 1ns;
timeprecision 1ps;

//****************************************************************************//

localparam C_SAMP_TIMER_LIMIT = P_CLK_FREQ_HZ / 1000 - 1;
localparam C_SAMP_TIMER_WIDTH = $clog2(C_SAMP_TIMER_LIMIT);

logic [C_SAMP_TIMER_WIDTH - 1 : 0]  samp_timer_count    = 'd0;
logic                               sample_en           = 1'b0;
logic [P_NUM_CHANNELS - 1 : 0]      i_pb_meta;
logic [P_NUM_CHANNELS - 1 : 0]      i_pb_safe;
logic [P_NUM_CHANNELS - 1 : 0]      i_pb_samp;

//----------------------------------------------------------------------------//

always_ff @(posedge clk) begin
  i_pb_meta <= i_pb;
  i_pb_safe <= i_pb_meta;
end //always_ff

always_ff @(posedge clk) begin
  if (samp_timer_count == 'd0) begin
    samp_timer_count <= C_SAMP_TIMER_LIMIT;
    sample_en        <= 1'b1;
  end else begin
    samp_timer_count <= samp_timer_count - 1'b1;
    sample_en        <= 1'b0;
  end //if
end //always_ff

always_ff @(posedge clk) begin
  if (sample_en == 'd1) begin

  end //if
end //always_ff

generate
  for (genvar i = 0; i < P_NUM_CHANNELS; i++) begin : GEN_CHANNELS
    intel_fpga_pb_debounce_channel intel_fpga_pb_debounce_channel_inst
    (
      .clk        (clk),
      .sample_en  (sample_en),
      .i_pb       (i_pb_safe[i]),
      .o_pb       (o_pb[i])
    );
  end //for
endgenerate

//****************************************************************************//
endmodule : intel_fpga_pb_debounce
//****************************************************************************//

`default_nettype wire
