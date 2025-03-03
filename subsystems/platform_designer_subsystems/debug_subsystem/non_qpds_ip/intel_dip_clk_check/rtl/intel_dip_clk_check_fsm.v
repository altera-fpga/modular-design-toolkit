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
// State machine control for DIP core
// ##########################################################################


// Control state machine
// DID7.1 State machine output to indicate test complete
// DID8.1 State machine output to indicate test in progress


module intel_dip_clk_check_fsm
  (
   input wire        ref_clk,             // Fixed reference clock
   input wire        ref_rst_n,           // Reset for ref_clk domain
   // FSM input
   input wire        ref_clk_tc_reached,  // Indication that ref_clk counter reached terminal count
   input wire        cut_count_available, // Indication from cut_counter that value is stable
   input wire        flag_int_error,      // Input from flag gen block indicating internal error
   input wire        reset_ack,           // Acknowledge from cut counter that count is reset
   // FSM output
   output wire       reset_ref_clk_count, // Reset to reference clock counter
   output wire       reset_cut_count,     // Reset to cut clock counter
   output wire       en_cut_count,        // Enable signal for cut clock counter
   output wire       en_ref_clk_count,    // Enable for reference clock counter
   output wire       en_flag_gen,         // Enable to flag gen block, active at end of test phase
   output wire [2:0] control_fsm_state,   // Wiring of FSM state to slave interface block
   output wire       cut_clock_stopped    // Indication to flag gen block that cut clock is stuck
   );

   localparam [2:0] RESET               = 3'b000;
   localparam [2:0] COUNT_ACK           = 3'b001;
   localparam [2:0] COUNTING            = 3'b010;
   localparam [2:0] TC_REACHED          = 3'b011;
   localparam [2:0] FLAG_GEN            = 3'b100;
   localparam [2:0] UNEXP_ERROR         = 3'b101;
   localparam [2:0] CUT_CLK_STOPPED     = 3'b110;

   reg [2:0]        state;
   reg              reset_ref_clk_count_reg;
   reg              reset_cut_count_reg;
   reg              en_cut_count_reg;
   reg              en_ref_clk_count_reg;
   reg              en_flag_gen_reg;
   reg              cut_clock_stopped_reg;




   always @ (posedge ref_clk or negedge ref_rst_n)
     begin
        if (ref_rst_n == 1'b0) begin
           state                        <= RESET;
           reset_ref_clk_count_reg      <= 1'b0;
           reset_cut_count_reg          <= 1'b0;
           en_cut_count_reg             <= 1'b0;
           en_ref_clk_count_reg         <= 1'b0;
           cut_clock_stopped_reg        <= 1'b0;
           en_flag_gen_reg              <= 1'b0;
        end
        else begin

           case (state)
             RESET : begin
                // reset the ref_clk counter ahead of next state
                reset_ref_clk_count_reg  <= 1'b1;
                // reset the cut_clk counter ahead of next state
                reset_cut_count_reg      <= 1'b1;
                en_cut_count_reg         <= 1'b0;
                en_ref_clk_count_reg     <= 1'b0;
                cut_clock_stopped_reg    <= 1'b0;
                en_flag_gen_reg          <= 1'b0;
                state <= COUNT_ACK;
             end


             COUNT_ACK : begin
                // In this state the cut_counter should acknowledge the reset
                // If not, we assume the cut clock has stopped

                reset_cut_count_reg     <= 1'b1;
                // ref_clk counter is used for timeout, so enable here
                en_ref_clk_count_reg    <= 1'b1;
                // ref_clk counter is used for timeout, so de-assert reset
                reset_ref_clk_count_reg <= 1'b0;
                en_flag_gen_reg         <= 1'b0;

                // if ack, then in normal condition, go to counting state

                // If an ack is seem, transition to COUNTING state
                if (reset_ack) begin
                   state <= COUNTING;
                   // reset the ref_clk counter before the real counting phase
                   reset_ref_clk_count_reg <= 1'b1;
                end

                // if no ack, then cut clock is stopped or very very slow
                else if (ref_clk_tc_reached) begin
                   state <= CUT_CLK_STOPPED;
                   cut_clock_stopped_reg <= 1'b1;
                end


             end

             // in this state, we wait for the ref_clk counter to reach a terminal count
             COUNTING : begin
                reset_ref_clk_count_reg <= 1'b0;
                reset_cut_count_reg     <= 1'b0;
                en_cut_count_reg        <= 1'b1;
                en_ref_clk_count_reg    <= 1'b1;
                en_flag_gen_reg         <= 1'b0;

                if (ref_clk_tc_reached) begin
                   state <= FLAG_GEN;
                   // reset the ref_clk ahead of it being reused for timeout
                   // in FLAG_GEN state
                   reset_ref_clk_count_reg <= 1'b1;
                end

             end

             // In flag gen state we reuse ref_clk counter for timeout again
             FLAG_GEN : begin
                en_cut_count_reg     <= 1'b0;
                en_ref_clk_count_reg <= 1'b1;
                reset_ref_clk_count_reg <= 1'b0;

                if (cut_count_available) begin
                   state <= RESET;
                   en_flag_gen_reg <= 1'b1;
                end
                // if the terminal count is reached before cut_count is available
                // we assume cut_clk is stopped
                else if (ref_clk_tc_reached == 1'b1 & !reset_ref_clk_count_reg) begin
                   state <= CUT_CLK_STOPPED;
                end

             end // case: FLAG_GEN

             CUT_CLK_STOPPED : begin
                state <= RESET;
                en_flag_gen_reg <= 1'b1;
                cut_clock_stopped_reg <= 1'b1;
             end // case: FLAG_GEN

             UNEXP_ERROR : begin
                // this state is latched until core reset
                state <= UNEXP_ERROR;
             end

             default : state <= RESET;

           endcase // case(state)

           // This test falls outside of the main case statement
           // If an internal error is seen, transition to this state.
           // Note, only a core reset can transition out of this state

           if (flag_int_error == 1'b1) begin
              state <= UNEXP_ERROR;
           end

        end // else: !if(ref_rst_n)
     end // always @ (posedge ref_clk or posedge ref_rst_n)

   assign control_fsm_state = state;
   assign reset_ref_clk_count = reset_ref_clk_count_reg;
   assign reset_cut_count = reset_cut_count_reg;
   assign en_cut_count = en_cut_count_reg;
   assign en_ref_clk_count = en_ref_clk_count_reg;
   assign cut_clock_stopped = cut_clock_stopped_reg;
   assign en_flag_gen = en_flag_gen_reg;

endmodule
