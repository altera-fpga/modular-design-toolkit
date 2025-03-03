###################################################################################
# INTEL CONFIDENTIAL
# 
# Copyright (C) 2022 Intel Corporation
# 
# This software and the related documents are Intel copyrighted materials, and 
# your use of them is governed by the express license under which they were 
# provided to you ("License"). Unless the License provides otherwise, you may 
# not use, modify, copy, publish, distribute, disclose or transmit this software 
# or the related documents without Intel's prior written permission.
# 
# This software and the related documents are provided as is, with no express 
# or implied warranties, other than those that are expressly stated in the License.
###################################################################################
#############################################################################
# SAFETY-CRITICAL APPLICATIONS.� The Material may be used to create end
# products used in safety-critical applications designed to comply with
# functional safety standards or requirements (�Safety-Critical
# Applications�).� It is Your responsibility to design, manage and assure
# system-level safeguards to anticipate, monitor and control system failures,
# and You agree that You are solely responsible for all applicable regulatory
# standards and safety-related requirements concerning Your use of the
# Material in Safety Critical Applications.� You agree to indemnify and hold
# Intel and its representatives harmless against any damages, costs, and
# expenses arising in any way out of Your use of the Material in
# Safety-Critical Applications.
#############################################################################
#
# File Revision:               $Revision: #2 $
#
# Description:
# HW TCL description file for Clk Check DIP core
#############################################################################


set_module_property DESCRIPTION ""
set_module_property NAME intel_dip_clk_check
set_module_property VERSION 1.0
set_module_property AUTHOR "Intel Corporation"
set_module_property DESCRIPTION "Clock Checker"
set_module_property INTERNAL false
set_module_property GROUP "Industrial Safety"
set_module_property DISPLAY_NAME "Clock Checker"
set_module_property TOP_LEVEL_HDL_FILE rtl/intel_dip_clk_check.v
set_module_property TOP_LEVEL_HDL_MODULE intel_dip_clk_check
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ELABORATION_CALLBACK elaborate
set_module_property VALIDATION_CALLBACK validate
# |
# +-----------------------------------

# +-----------------------------------
# | files
# |
# add_file ../avalon_perfmon.qip SYNTHESIS

add_file rtl/intel_dip_clk_check.v {SYNTHESIS SIMULATION}
add_file rtl/intel_dip_clk_check_slave_if.v {SYNTHESIS SIMULATION}
add_file rtl/intel_dip_clk_check_cut_count.v {SYNTHESIS SIMULATION}
add_file rtl/intel_dip_clk_check_ref_clk_count.v {SYNTHESIS SIMULATION}
add_file rtl/intel_dip_clk_check_freq_comp.v {SYNTHESIS SIMULATION}
add_file rtl/intel_dip_clk_check_flag_gen.v {SYNTHESIS SIMULATION}
add_file rtl/intel_dip_clk_check_fsm.v {SYNTHESIS SIMULATION}
# |
# +-----------------------------------


# +-----------------------------------
# | parameters
# |

add_parameter           DATA_WIDTH      INTEGER                 32 "Set to data width of Avalon bus to be connected to"
set_parameter_property  DATA_WIDTH      ALLOWED_RANGES          {8:512}
set_parameter_property  DATA_WIDTH      DISPLAY_NAME            "Data Width"
set_parameter_property  DATA_WIDTH      AFFECTS_ELABORATION     TRUE
set_parameter_property  DATA_WIDTH      VISIBLE                 FALSE


add_parameter           LO_COUNT_THR    INTEGER                 "The value above which the clock under test counter must count for no error to be indicated."
set_parameter_property  LO_COUNT_THR    DISPLAY_NAME            "Low count threshold"
set_parameter_property  LO_COUNT_THR    AFFECTS_ELABORATION     TRUE
set_parameter_property  LO_COUNT_THR    ALLOWED_RANGES          {0:500000000}

add_parameter           HI_COUNT_THR    INTEGER                 "The value below which the clock under test counter must count for no error to be indicated."
set_parameter_property  HI_COUNT_THR    DISPLAY_NAME            "High count threshold"
set_parameter_property  HI_COUNT_THR    AFFECTS_ELABORATION     TRUE
set_parameter_property  HI_COUNT_THR    ALLOWED_RANGES          {0:500000000}

add_parameter           REF_CLK_TC      INTEGER                 "Terminal count value of the reference clock. This count value determines the time period over which the IP core performs the clock test."
set_parameter_property  REF_CLK_TC      DISPLAY_NAME            "Ref clock terminal count"
set_parameter_property  REF_CLK_TC      AFFECTS_ELABORATION     TRUE
set_parameter_property  REF_CLK_TC      ALLOWED_RANGES          {0:500000000}



# +-----------------------------------
# |
# | Validation callback

proc validate {} {

   set lo_count_thr [get_parameter_value LO_COUNT_THR]
   if { $lo_count_thr < 0 } {
	   send_message warning "If the wizard displays a negative number for Low count threshold, the actual value is 2^32 greater ($lo_count_thr + 2^32)."
   }

   set hi_count_thr [get_parameter_value HI_COUNT_THR]
   if { $hi_count_thr < 0 } {
	   send_message warning "If the wizard displays a negative number for High count threshold, the actual value is 2^32 greater ($hi_count_thr + 2^32)."
   }

   set ref_clk_tc [get_parameter_value REF_CLK_TC]
   if { $ref_clk_tc < 0 } {
	   send_message warning "If the wizard displays a negative number for Ref clock terminal count, the actual value is 2^32 greater ($ref_clk_tc + 2^32)."
   }

}

# |
# +-----------------------------------

# +-----------------------------------
# |
# | Elaboration callback
proc elaborate {} {
    set data_width          [get_parameter_value DATA_WIDTH]
    set hi_count_thr        [get_parameter_value HI_COUNT_THR ]
    set lo_count_thr        [get_parameter_value LO_COUNT_THR]
    set ref_clk_tc          [get_parameter_value REF_CLK_TC]

    # must create section establishing the counter limits
    set_parameter_property  LO_COUNT_THR    HDL_PARAMETER     $lo_count_thr
    set_parameter_property  HI_COUNT_THR    HDL_PARAMETER     $hi_count_thr
    set_parameter_property  REF_CLK_TC      HDL_PARAMETER     $ref_clk_tc

    add_interface cut_clk clock sink
    add_interface_port cut_clk cut_clk clk Input 1

    add_interface cut_clk_resetn reset sink cut_clk
    add_interface_port cut_clk_resetn cut_rst_n reset_n Input 1

    # +-----------------------------------
    # | connection point ref_clk
    # |
    add_interface ref_clk clock sink
    add_interface_port ref_clk ref_clk clk Input 1

    add_interface ref_clk_resetn reset sink ref_clk
    add_interface_port ref_clk_resetn ref_rst_n reset_n Input 1
    # |
    # +-----------------------------------

    # +-----------------------------------
    # | connection point control_status
    # |
    add_interface control_status avalon agent
    set_interface_property control_status addressAlignment DYNAMIC
    set_interface_property control_status holdTime 0
    set_interface_property control_status isMemoryDevice false
    set_interface_property control_status isNonVolatileStorage false
    set_interface_property control_status printableDevice false
    set_interface_property control_status readWaitTime 0
    set_interface_property control_status setupTime 0
    set_interface_property control_status timingUnits Cycles
    set_interface_property control_status writeWaitTime 0

    set_interface_property control_status ASSOCIATED_CLOCK ref_clk
    #set_interface_property control_status ASSOCIATED_RESET ref_clk_resetn
    set_interface_property control_status ENABLED true

    set wait_states 0
    if {${wait_states} < 0} {
    set_interface_property control_status readWaitStates 0
    set_interface_property control_status writeWaitStates 0
    add_interface_port control_status avs_waitrequest waitrequest Output 1
    } else {
    set_interface_property control_status readWaitStates ${wait_states}
    set_interface_property control_status writeWaitStates ${wait_states}
    }

    set word_addr_width 2
    if {[expr $word_addr_width] > 0} {
    add_interface_port control_status csr_addr address Input [expr $word_addr_width]
    }


    set byte_width 0
    if {${byte_width} > 0} {
    add_interface_port control_status avs_byteenable byteenable Input ${byte_width}
    }

    add_interface_port control_status csr_readdata readdata Output ${data_width}
    set read_latency 0
    if {${read_latency} < 0} {
    set_interface_property control_status readLatency 0
    set_interface_property control_status maximumPendingReadTransactions 32
    add_interface_port control_status avs_readvalid readdatavalid Output 1
    } else {
    set_interface_property control_status maximumPendingReadTransactions 0
    set_interface_property control_status readLatency ${read_latency}
    }


    add_interface flags conduit end
    set_interface_property flags ENABLED true
    add_interface_port flags error           export Output 1
    add_interface_port flags error_n         export Output 1
    add_interface_port flags freq_too_high   export Output 1
    add_interface_port flags check_running   export Output 1
    add_interface_port flags check_done      export Output 1
    add_interface_port flags int_error       export Output 1


    # |
    # +-----------------------------------
}
# |
# +-----------------------------------
