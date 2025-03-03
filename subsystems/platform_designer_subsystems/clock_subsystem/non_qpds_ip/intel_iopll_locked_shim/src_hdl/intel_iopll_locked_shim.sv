/* ##################################################################################
 * Copyright (C) 2025 Intel Corporation
 *
 * This software and the related documents are Intel copyrighted materials, and
 * your use of them is governed by the express license under which they were
 * provided to you ("License"). Unless the License provides otherwise, you may
 * not use, modify, copy, publish, distribute, disclose or transmit this software
 * or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express
 * or implied warranties, other than those that are expressly stated in the License.
 * ##################################################################################

 * ##################################################################################
 *
 * Module: intel_iopll_locked_shim
 *
 * Description: Creates a reset from a PLL locked signal
 *
 * ##################################################################################
*/

`default_nettype none

module intel_iopll_locked_shim (
  locked_in,
  reset_out,
  locked_out,
  locked_out_1
);

  input    wire        locked_in;
  output   wire        reset_out;
  output   wire        locked_out;
  output   wire        locked_out_1;

  assign reset_out     = ~locked_in;
  assign locked_out    = locked_in;
  assign locked_out_1  = locked_in;

endmodule

`default_nettype wire
