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

 * ##################################################################################
 *
 * Module: intel_vip_reset_gen_sync_block
 *
 * Description: synchronizes asynchronous reset to clock
 *
 * ##################################################################################
*/

`default_nettype none

module intel_vip_reset_gen_sync_block #(parameter ASYNC_RESET_ACTIVE_HI = 1'b1) (
  clk,
  async_reset,
  sync_reset
);

  input   logic clk;
  input   logic async_reset;
  output  logic sync_reset;

  logic [1:0] reset_pipe;
  logic active_high_reset;

  assign active_high_reset = ASYNC_RESET_ACTIVE_HI ? async_reset : ~async_reset;

  always_ff @(posedge clk or posedge active_high_reset) begin
    if (active_high_reset) begin
      reset_pipe  <= 2'b11;
    end else begin
      reset_pipe  <= {reset_pipe[0] , 1'b0};
    end
  end

  assign sync_reset = reset_pipe[1];

endmodule

`default_nettype wire
