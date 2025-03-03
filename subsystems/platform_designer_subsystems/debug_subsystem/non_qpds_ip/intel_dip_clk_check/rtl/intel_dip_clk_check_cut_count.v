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

// ##########################################################################
// SAFETY-CRITICAL APPLICATIONS.� The Material may be used to create end
// products used in safety-critical applications designed to comply with
// functional safety standards or requirements (�Safety-Critical
// Applications�).� It is Your responsibility to design, manage and assure
// system-level safeguards to anticipate, monitor and control system failures,
// and You agree that You are solely responsible for all applicable regulatory
// standards and safety-related requirements concerning Your use of the
// Material in Safety Critical Applications.� You agree to indemnify and hold
// Intel and its representatives harmless against any damages, costs, and
// expenses arising in any way out of Your use of the Material in
// Safety-Critical Applications.
// ##########################################################################
//
// File Revision:               $Revision: #19 $
//
// Description:
// Clock under test counter module
// ##########################################################################


// Clock under test counter
// DID2.1 Range of clock checking

module intel_dip_clk_check_cut_count
  (
   input   wire            cut_clk,             // Clock under test
   input   wire            cut_rst_n,           // Reset for cut clock domain
   input   wire            ref_clk,             // system clock, i.e. avalon clock
   input   wire            ref_rst_n,           // reset for system clock domain
   input   wire            reset_cut_count,     // reset from FSM for counter (ref domain)
   input   wire            en_cut_count,        // enable from FSM for counter (ref_domain)
   input   wire            en_flag_gen,         // signal from FSM to enable count storage (ref_domain)

   output  wire            cut_count_available, // flag from cut count to indicate count stable (ref_domain)
   output  wire            reset_ack,           // acknowledge that reset is performed (ref_domain)
   output  wire [31:0]     cut_count_end_val,   // final value of count, goes to compare block (cut_domain)
   output  wire [31:0]     cut_count_store      // register storage for final value (ref_domain)
   );


   // Clock Domain Crossing (CDC) block
   // enable, reset, store, available have to be transferred over
   // clock domains.  This block double registers the signals to
   // overcome CRC/metastability issues.
   // See Section 6.7.1 in FS_IPFD_Clock_checker.doc for detail
   reg    en_cut_count_dly;
   reg    en_cut_count_cdc;
   reg    reset_cut_count_dly;
   reg    reset_cut_count_cdc;
   // NOTE ref_clk domain
   always @ (posedge cut_clk or negedge cut_rst_n)
     begin
        if (cut_rst_n == 1'b0) begin
           en_cut_count_dly <= 1'b0;
           en_cut_count_cdc <= 1'b0;
           reset_cut_count_dly <= 1'b0;
           reset_cut_count_cdc <= 1'b0;
        end
        else begin
           en_cut_count_dly <= en_cut_count;
           en_cut_count_cdc <= en_cut_count_dly;

           reset_cut_count_dly <= reset_cut_count;
           reset_cut_count_cdc <= reset_cut_count_dly;
        end // else: !if(cut_rst_n == 1'b0)
     end // always @ (posedge cut_clk or negedge cut_rst_n)


   // Clock Under Test (CUT) counter implementation
   //DID2.1 Range of clock checking
   reg          cut_count_disabled;
   //Disable clock domain transfer Design Rule Check as REQ / ACK handshake is used
   reg [31:0]   cut_count /* synthesis altera_attribute="disable_da_rule=D101" */;
   // NOTE cut_clk domain
   always @ (posedge cut_clk or negedge cut_rst_n)
     begin
        if (cut_rst_n == 1'b0) begin
           cut_count <= 32'h000000;
           cut_count_disabled <= 1'b1;
           end
        else begin
           // sync reset from FSM block
           if (reset_cut_count_cdc) begin
              cut_count <= 32'h000000;
              cut_count_disabled <= 1'b1;
           end
           else if (en_cut_count_cdc) begin
              cut_count <= cut_count + 32'd1;
              cut_count_disabled <= 1'b0;
           end
           else begin
              cut_count_disabled <= 1'b1;
           end
        end // else: !if(~cut_rst_n)
     end // always @ (posedge cut_clk or negedge cut_rst_n)

   // note this is on cut clock domain
   assign cut_count_end_val = cut_count;


   // Method of handshaking between FSM and cut domain logic
   reg  cut_count_disabled_dly;
   reg  reset_ack_dly;
   reg  reset_ack_reg;
   reg  cut_count_available_reg;
   // NOTE ref_clk domain
   always @ (posedge ref_clk or negedge ref_rst_n)
     begin
        if (ref_rst_n == 1'b0) begin
           cut_count_disabled_dly <= 1'b1;
           cut_count_available_reg <= 1'b0;

           reset_ack_dly <= 1'b0;
           reset_ack_reg <= 1'b0;

        end
        else begin
           cut_count_disabled_dly <= cut_count_disabled;
           cut_count_available_reg <= cut_count_disabled_dly;

           reset_ack_dly <= reset_cut_count_cdc;
           reset_ack_reg <= reset_ack_dly;
        end
     end // always @ (posedge ref_clk or negedge ref_rst_n)


   // assign internal registers to output ports
   assign cut_count_available = cut_count_available_reg;
   assign reset_ack = reset_ack_reg;



   // Store cut count value for Processor read back
   // NOTE ref_clk domain
   reg [31:0]   cut_count_store_reg;

   always @ (posedge ref_clk or negedge ref_rst_n)
     begin
        if (ref_rst_n == 1'b0) begin
           cut_count_store_reg <= 32'h000000;
        end
        else begin
           // Note that when en_flag_gen is active, the cut_count value
           // is guaranteed stable (via handshake)  This overcomes any
           // clock domain crossing issues.
           if (en_flag_gen) cut_count_store_reg <= cut_count;
        end
     end

   // assign internal registers to output ports
   assign cut_count_store = cut_count_store_reg;


endmodule
