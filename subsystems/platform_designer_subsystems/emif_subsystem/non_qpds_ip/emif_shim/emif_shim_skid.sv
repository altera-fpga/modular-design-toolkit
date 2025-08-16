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
 * Module: emif_shim_skid
 *
 * Description: Creates a shim around for the EMIF interface
 *
 * ##################################################################################
*/

`default_nettype none

module emif_shim_skid #( parameter P_WIDTH = 10 ) (
  input  wire                  clk,
  input  wire                  rst,

  input  wire                  in_valid,
  input  wire  [P_WIDTH-1:0]   in_data,
  output reg                   in_ready,

  output  reg                  out_valid,
  output  reg   [P_WIDTH-1:0]  out_data,
  input   wire                 out_ready
);

  (* noprune *) logic [P_WIDTH-1:0]  in_data_hld;
  (* noprune *) logic [P_WIDTH-1:0]  out_data_reg;
  wire                 out_valid_nxt;
  wire                 in_ready_nxt;

  assign out_valid_nxt = in_valid  | (out_valid & (~in_ready  | ~out_ready));
  assign in_ready_nxt  = out_ready | (in_ready &  (~out_valid | ~in_valid));

  always_ff @(posedge clk) begin
    if (rst) begin
      in_ready  <= 1'b1;
      out_valid <= 1'b0;
    end else begin
      out_valid <= out_valid_nxt;
      in_ready  <= in_ready_nxt;
    end

    if (in_ready) begin
      in_data_hld <= in_data;
    end

    if (out_ready | ~out_valid) begin
       if (!in_ready) begin
         out_data_reg <= in_data_hld;
       end else begin
         out_data_reg <= in_data;
       end
    end
  end

  assign out_data = out_data_reg;

endmodule

`default_nettype wire
