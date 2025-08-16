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
 * Module: intel_emif_reset_block
 *
 * Description: combines system reset with a user reset to produce the emif reset
 *              (required following si5338 clock generator reconfiguration)
 *
 * ##################################################################################
*/

`default_nettype none

module intel_emif_reset_block #(
  parameter SYSTEM_RESET_ACTIVE_HIGH = 1'b0,
  parameter USER_RESET_ACTIVE_HIGH   = 1'b0
) (
  input   logic system_reset,
  input   logic user_reset,
  output  logic reset_out
);

  wire reset_a;
  wire reset_b;
  wire reset_c;

  assign reset_a = SYSTEM_RESET_ACTIVE_HIGH ? system_reset : ~system_reset;
  assign reset_b = USER_RESET_ACTIVE_HIGH   ? user_reset   : ~user_reset;

  assign reset_c = (reset_a || reset_b);

  assign reset_out = reset_c;

endmodule

`default_nettype wire
