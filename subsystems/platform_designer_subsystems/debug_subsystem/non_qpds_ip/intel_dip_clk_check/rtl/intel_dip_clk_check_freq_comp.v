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
// File Revision:               $Revision: #18 $
//
// Description:
// Clock Frequency comparator module
// ##########################################################################

module intel_dip_clk_check_freq_comp #
  (
   parameter LO_COUNT_THR          = 32'd0,
   parameter HI_COUNT_THR          = 32'd300010000
   )
  (
   // CUT clock frequency comparator
   // DID9.1 CUT Freq too high
   // DID10.1 CUT Freq too low

    input  wire [31:0]  cut_count_end_val,  // Value of cut_count at end of test phase
    output wire         comp_too_high,      // Output of high level comparator
    output wire         comp_too_low,       // Output of low level comparator
    output wire         param_error         // Flag output for param error
    );

   wire [31:0] lo_thr_wire;
   wire [31:0] hi_thr_wire;

   assign      lo_thr_wire = LO_COUNT_THR[31:0];
   assign      hi_thr_wire = HI_COUNT_THR[31:0];


   // if HI and LO count parameters are incorrectly set, the core indicates
   // this as a param_error
   assign param_error = (LO_COUNT_THR > HI_COUNT_THR);


   reg    comp_too_high_reg /* synthesis preserve noprune keep */;  // Prevents register being optimised
   reg    comp_too_low_reg /* synthesis preserve noprune keep */;  // Prevents register being optimised

   always @ (*)
     begin
        comp_too_high_reg = (cut_count_end_val > hi_thr_wire);
     end

   always @ (*)
     begin
        comp_too_low_reg = (cut_count_end_val < lo_thr_wire);
     end

   assign comp_too_low = comp_too_low_reg;
   assign comp_too_high = comp_too_high_reg;



endmodule
