//##################################################################################
// INTEL CONFIDENTIAL
// 
// Copyright (C) 2022 Intel Corporation
// 
// This software and the related documents are Intel copyrighted materials, and 
// your use of them is governed by the express license under which they were 
// provided to you ("License"). Unless the License provides otherwise, you may 
// not use, modify, copy, publish, distribute, disclose or transmit this software 
// or the related documents without Intel's prior written permission.
// 
// This software and the related documents are provided as is, with no express 
// or implied warranties, other than those that are expressly stated in the License.
//##################################################################################

/* ##########################################################################
*
* Module: intel_vip_reset_gen_block
*
* Description: generates reset of minimum pulse length from a push button
*              switch
*
* ##########################################################################
*/

module intel_vip_reset_gen_block #(parameter CNTR_WIDTH = 8) (
  input   logic pb_resetn,
  input   logic clk,
  output  logic reset,
  output  logic reset_n
);

  bit local_reset;
  bit [CNTR_WIDTH-1:0] cntr;

  intel_vip_reset_gen_sync_block #(
    .ASYNC_RESET_ACTIVE_HI(1'b0)
  ) reset_sync (
    .clk          (clk),
    .async_reset  (pb_resetn),
    .sync_reset   (local_reset)
  );

  always_ff @ (posedge clk or posedge local_reset) begin
    if (local_reset) begin
      reset   <= 1'b1;
      reset_n <= 1'b0;
      cntr    <= {CNTR_WIDTH{1'b0}};
    end else begin
      reset   <= ~cntr[CNTR_WIDTH-1];
      reset_n <=  cntr[CNTR_WIDTH-1];
      if (reset) begin
        cntr <= cntr + 1'b1;
      end
    end
  end

endmodule