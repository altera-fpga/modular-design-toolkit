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
 * Module: intel_vip_reset_sync_block
 *
 * Description: synchronizes reset, prevents promotion of reset to global net
 *
 * ##################################################################################
*/

`default_nettype none

module intel_vip_reset_sync_block (
  clk_in,
  reset_in,
  clk_out,
  reset_out
);

  parameter   ASYNC_RESET             =  1;

  // needs to be at least two but on new FPGAs should be at least 3
  parameter   SYNC_DEPTH              =  3;

  // needs to be at least two stages, increase this if recovery errors occur even with
  // DISABLE_GLOBAL_NETWORK is set to 1
  parameter   ADDITIONAL_DEPTH        =  2;

  // set to 1 to prevent synchronized reset from getting promoted to global network, enable
  // this if recovery errors occur from FFs hooked up to reset_out
  parameter   DISABLE_GLOBAL_NETWORK  =  1;

  input    wire  clk_in;
  input    wire  reset_in;
  output   wire  clk_out;
  output   wire  reset_out;

  (* preserve *) reg   [SYNC_DEPTH-1 : 0]   synchronizer_reg;

  generate

    if (ASYNC_RESET > 0) begin

      always @ (posedge clk_in or posedge reset_in) begin
        if (reset_in) begin
          synchronizer_reg                  <= {SYNC_DEPTH{1'b1}};
        end else begin
          synchronizer_reg[0]               <= 1'b0;
          // right shift by 1
          synchronizer_reg[SYNC_DEPTH-1:1]  <= synchronizer_reg[SYNC_DEPTH-2:0];
        end
      end

    end else begin

      always @ (posedge clk_in) begin
        synchronizer_reg[0]               <= reset_in;
        // right shift by 1
        synchronizer_reg[SYNC_DEPTH-1:1]  <= synchronizer_reg[SYNC_DEPTH-2:0];
      end

    end

    if (DISABLE_GLOBAL_NETWORK == 0) begin

      reg [ADDITIONAL_DEPTH-1:0] output_pipeline_reg;

      always @ (posedge clk_in) begin
        // feeding the synchronizer output into this pipeline's MSB
        output_pipeline_reg[ADDITIONAL_DEPTH-1]   <= synchronizer_reg[SYNC_DEPTH-1];
        // right shift by 1
        output_pipeline_reg[ADDITIONAL_DEPTH-2:0] <= output_pipeline_reg[ADDITIONAL_DEPTH-1:1];
      end

      assign reset_out = output_pipeline_reg[0];

    end else begin

      (* altera_attribute = "-name GLOBAL_SIGNAL OFF" *) reg [ADDITIONAL_DEPTH-1:0] output_pipeline_reg;

      always @ (posedge clk_in) begin
        // feeding the synchronizer output into this pipeline's MSB
        output_pipeline_reg[ADDITIONAL_DEPTH-1]   <= synchronizer_reg[SYNC_DEPTH-1];
        // right shift by 1
        output_pipeline_reg[ADDITIONAL_DEPTH-2:0] <= output_pipeline_reg[ADDITIONAL_DEPTH-1:1];
      end

      assign reset_out = output_pipeline_reg[0];

    end

  endgenerate

  // this signal is included to make it easier to export a clock and reset to the level above it
  assign clk_out = clk_in;

endmodule

`default_nettype wire

