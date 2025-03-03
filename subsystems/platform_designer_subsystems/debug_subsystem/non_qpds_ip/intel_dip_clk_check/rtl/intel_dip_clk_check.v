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
// File Revision:               $Revision: #24 $
//
// Description:
// Top level of the DIP clock checker block
// ##########################################################################


module intel_dip_clk_check #
  (
   parameter LO_COUNT_THR          = 32'd0,
   parameter HI_COUNT_THR          = 32'd300010000,
   parameter REF_CLK_TC            = 32'd100000000
   )
  (
   // System clock interface
   input  wire                   ref_clk,        // Fixed reference clock input
   input  wire                   ref_rst_n,      // Reset for ref_clk domain
   // Top level avalon_slave ports
   input  wire             [1:0] csr_addr,       // Address for avalon read port
   output wire            [31:0] csr_readdata,   // Read data output for avalon
   // Clock under test interface
   input  wire                   cut_clk,        // Clock under test input
   input  wire                   cut_rst_n,      // Reset for cut_clk domain
   // FLAG Interface
   output wire                   error,          // error flag, indicates error on cut_clk
   output wire                   error_n,        // Inverse of error, i.e. differential signal
   output wire                   freq_too_high,  // Flag to indicate if cut_clk too high/low
   output wire                   check_running,  // Flag to show that check is in progress
   output wire                   check_done,     // Flag to show that a check phase has finished
   output wire                   int_error       // Flag to indicate an core internal error
   );


   // Avalon Slave interface instance
   // DID1.1
   // The avalon slave interface below is a stripped down version of the altera standard
   // Avalon slave template

   wire [31:0] core_status;
   wire [31:0] ref_clk_tc_reg;
   wire [31:0] cut_count_end_val;
   wire [2:0]  control_fsm_state;
   wire [31:0] cut_count_store;
   wire        cut_clock_stopped;
   wire        flag_int_error;
   wire        param_error;
   wire        en_flag_gen;
   wire        en_ref_clk_count;
   wire        en_cut_count;


   // Wire status bits into core_status bus
   assign       core_status[31:8] = 24'b0;
   assign       core_status[7] = param_error;
   assign       core_status[6] = flag_int_error;
   assign       core_status[5:4] = {error_n, error};
   assign       core_status[3] = freq_too_high;
   assign       core_status[2:0] = control_fsm_state;
   assign       ref_clk_tc_reg = REF_CLK_TC[23:0];
   assign       check_running = en_cut_count;
   assign       check_done = en_flag_gen;



   intel_dip_clk_check_slave_if u_dip_clk_slave_if
     (
      //Avalon connections
      .csr_addr                 (csr_addr),
      .csr_readdata             (csr_readdata),
      //Internal connections
      .core_status              (core_status),
      .cut_count_store          (cut_count_store),
      //Terminal count parameter wired into slave interface to allow CPU read back of
      //fixed parameterization
      .ref_clk_tc_reg           (ref_clk_tc_reg)
      );


   // Clock under test counter
   // DID2.1 Range of clock checking
   // DID2.2 Online count checking

   // Internal connections to clock under test counter
   wire         reset_cut_count;
   wire         cut_count_available;
   wire         reset_ack;


   intel_dip_clk_check_cut_count u_intel_dip_clk_check_cut_count
     (
      .cut_clk                  (cut_clk),
      .cut_rst_n                (cut_rst_n),
      .ref_clk                  (ref_clk),
      .ref_rst_n                (ref_rst_n),
      .reset_cut_count          (reset_cut_count),
      .en_cut_count             (en_cut_count),
      .en_flag_gen              (en_flag_gen),
      .reset_ack                (reset_ack),
      .cut_count_available      (cut_count_available),
      .cut_count_end_val        (cut_count_end_val),
      .cut_count_store          (cut_count_store)
      );


   // Ref clk counter
   // DID3.1 Range of reference clock
   // DID3.2 Online count checking
   // DID5.1 Terminal count checker
   wire         reset_ref_clk_count;
   wire         ref_clk_tc_reached;

   intel_dip_clk_check_ref_clk_count #
     (
      .REF_CLK_TC (REF_CLK_TC)
      )

     u_intel_dip_clk_check_ref_clk_count
       (
        .ref_clk                  (ref_clk),
        .ref_rst_n                (ref_rst_n),
        .reset_ref_clk_count      (reset_ref_clk_count),
        .en_ref_clk_count         (en_ref_clk_count),
        .ref_clk_tc_reached       (ref_clk_tc_reached)
        );




   // CUT clock frequency comparator
   // DID9.1 CUT Freq too high
   // DID10.1 CUT Freq too low
   wire         comp_too_high;
   wire         comp_too_low;

   intel_dip_clk_check_freq_comp #
     (
      .LO_COUNT_THR (LO_COUNT_THR),
      .HI_COUNT_THR (HI_COUNT_THR)
      )

     u_intel_dip_clk_check_freq_comp
       (
        .cut_count_end_val        (cut_count_end_val),
        .comp_too_high            (comp_too_high),
        .comp_too_low             (comp_too_low),
        .param_error              (param_error)
        );




   // Flag generation block
   // DID9.2 CUT Freq too high
   // DID10.2 CUT Freq too low

   intel_dip_clk_check_flag_gen u_intel_dip_clk_check_flag_gen
     (
      .ref_clk                  (ref_clk),
      .ref_rst_n                (ref_rst_n),
      .comp_too_high            (comp_too_high),
      .comp_too_low             (comp_too_low),
      .en_flag_gen              (en_flag_gen),
      .cut_clock_stopped        (cut_clock_stopped),
      .error                    (error),
      .error_n                  (error_n),
      .freq_too_high            (freq_too_high),
      .flag_int_error           (flag_int_error)
      );

   assign int_error = flag_int_error;


   // Control state machine
   // DID7.1 Range of reference clock
   // DID8.1 Online count checking
   // DID13.1 Reset interface definition
   intel_dip_clk_check_fsm u_intel_dip_clk_check_fsm
     (
      .ref_clk                  (ref_clk),
      .ref_rst_n                (ref_rst_n),
      // FSM inputs
      .ref_clk_tc_reached       (ref_clk_tc_reached),
      .cut_count_available      (cut_count_available),
      .flag_int_error           (flag_int_error),
      .reset_ack                (reset_ack),
      // FSM outputs
      .reset_ref_clk_count      (reset_ref_clk_count),
      .reset_cut_count          (reset_cut_count),
      .en_cut_count             (en_cut_count),
      .en_ref_clk_count         (en_ref_clk_count),
      .en_flag_gen              (en_flag_gen),
      .control_fsm_state        (control_fsm_state),
      .cut_clock_stopped        (cut_clock_stopped)
      );




endmodule
