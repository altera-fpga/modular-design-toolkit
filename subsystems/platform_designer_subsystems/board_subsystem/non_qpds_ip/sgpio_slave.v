/* ##################################################################################
 * Copyright (C) 2025 Intel Altera Corporation
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
 * Module: sgpio_slave
 *
 * Description: synchronized serial interface with four signals, act as slave
 *
 * ##################################################################################
*/

`default_nettype none

module sgpio_slave (
  input         i_rstn,
  output[7:0]   o_user_sw,        //the value of user_sw that slave gets from master
  input [7:0]   i_user_led,       //the value of user_led that slave intends to drive
  output        o_user_sw_valid,  //=1: o_user_sw is the active value driven by master
  output        o_miso,           //master input slave output of the synchronized serial interface
  input         i_clk,            //clock of the synchronized serial interface
  input         i_sync,           //frame start of the synchronized serial interface, =1: the start of a frame
  input         i_mosi            //master output slave input of the synchronized serial interface
);

  reg [7:0] S_o_data_shift;
  reg [7:0] S_i_data_shift;
  reg [7:0] S_o_user_sw;
  reg [1:0] S_o_user_sw_valid;

  assign o_miso          = S_o_data_shift[0];
  assign o_user_sw       = S_o_user_sw;
  assign o_user_sw_valid = S_o_user_sw_valid[1];

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      S_o_user_sw     <= 8'd0;
    end else if (i_sync) begin
      S_o_user_sw     <= S_i_data_shift;
    end else begin
      S_o_user_sw     <= S_o_user_sw;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      S_i_data_shift  <= 8'd0;
    end else begin
      S_i_data_shift  <= {i_mosi , S_i_data_shift[7:1]};
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      S_o_user_sw_valid   <= 2'b00;
    end else if (i_sync && (!S_o_user_sw_valid[1])) begin
      S_o_user_sw_valid   <= S_o_user_sw_valid + 1'b1;
    end else begin
      S_o_user_sw_valid   <= S_o_user_sw_valid;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      S_o_data_shift  <= 8'b11111111;
    end else if (i_sync) begin
      S_o_data_shift  <= i_user_led;
    end else begin
      S_o_data_shift  <= {1'b1 , S_o_data_shift[7:1]};
    end
  end

endmodule

`default_nettype wire

