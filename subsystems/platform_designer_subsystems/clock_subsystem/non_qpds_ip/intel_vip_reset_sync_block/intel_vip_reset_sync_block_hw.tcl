###################################################################################
# Copyright (C) 2025 Altera Corporation
#
# This software and the related documents are Altera copyrighted materials, and
# your use of them is governed by the express license under which they were
# provided to you ("License"). Unless the License provides otherwise, you may
# not use, modify, copy, publish, distribute, disclose or transmit this software
# or the related documents without Altera's prior written permission.
#
# This software and the related documents are provided as is, with no express
# or implied warranties, other than those that are expressly stated in the License.
###################################################################################

## *********************************************************************************
#
# Module: intel_vip_reset_sync_block
#
# Description: _hw.tcl file for custom Platform Designer reset synchronizer
#
## *********************************************************************************

package require -exact qsys 18.1

#
# module custom_reset_synchronizer
#
set_module_property  DESCRIPTION                   "Reset synchronizer that stops promotion  \
                                                    to global nets and adds extra reset pipelining"
set_module_property  NAME                          intel_vip_reset_sync_block
set_module_property  VERSION                       99.0
set_module_property  INTERNAL                      false
set_module_property  OPAQUE_ADDRESS_MAP            true
set_module_property  DISPLAY_NAME                  "Custom Reset Synchronizer"
set_module_property  INSTANTIATE_IN_SYSTEM_MODULE  true
set_module_property  EDITABLE                      true
set_module_property  REPORT_TO_TALKBACK            false
set_module_property  ALLOW_GREYBOX_GENERATION      false
set_module_property  REPORT_HIERARCHY              false
set_module_property  ELABORATION_CALLBACK          elaborate
set_module_property  VALIDATION_CALLBACK           validate

#
# file sets
#
add_fileset           QUARTUS_SYNTH                   QUARTUS_SYNTH                   ""    ""
set_fileset_property  QUARTUS_SYNTH                   TOP_LEVEL                       intel_vip_reset_sync_block
set_fileset_property  QUARTUS_SYNTH                   ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  QUARTUS_SYNTH                   ENABLE_FILE_OVERWRITE_MODE      false

add_fileset_file      intel_vip_reset_sync_block.v    VERILOG                         PATH \
                      "src_hdl/intel_vip_reset_sync_block.v"                          TOP_LEVEL_FILE

add_fileset_file      intel_vip_reset_sync_block.sdc  SDC_ENTITY                      PATH \
                      "src_hdl/intel_vip_reset_sync_block.sdc"

add_fileset           SIM_VERILOG                     SIM_VERILOG                     ""    ""
set_fileset_property  SIM_VERILOG                     TOP_LEVEL                       intel_vip_reset_sync_block
set_fileset_property  SIM_VERILOG                     ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VERILOG                     ENABLE_FILE_OVERWRITE_MODE      false

add_fileset_file      intel_vip_reset_sync_block.v    VERILOG                         PATH \
                      "src_hdl/intel_vip_reset_sync_block.v"

add_fileset           SIM_VHDL                        SIM_VHDL                        ""    ""
set_fileset_property  SIM_VHDL                        TOP_LEVEL                       intel_vip_reset_sync_block
set_fileset_property  SIM_VHDL                        ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VHDL                        ENABLE_FILE_OVERWRITE_MODE      false

add_fileset_file      intel_vip_reset_sync_block.v    VERILOG                         PATH \
                      "src_hdl/intel_vip_reset_sync_block.v"

#
# parameters
#
add_parameter           GEN_OUT_CLK             INTEGER              1
set_parameter_property  GEN_OUT_CLK             DISPLAY_NAME         "Create output copy of input clock"
set_parameter_property  GEN_OUT_CLK             UNITS                None
set_parameter_property  GEN_OUT_CLK             HDL_PARAMETER        false
set_parameter_property  GEN_OUT_CLK             DISPLAY_HINT         BOOLEAN
set_parameter_property  GEN_OUT_CLK             AFFECTS_VALIDATION   FALSE
set_parameter_property  GEN_OUT_CLK             AFFECTS_ELABORATION  TRUE
set_parameter_property  GEN_OUT_CLK             DESCRIPTION          "Set this option to create an output \
                                                                     clock that is a copy of the input clock"

add_parameter           ASYNC_RESET             INTEGER              1
set_parameter_property  ASYNC_RESET             DISPLAY_NAME         "Use asynchronous reset"
set_parameter_property  ASYNC_RESET             UNITS                None
set_parameter_property  ASYNC_RESET             HDL_PARAMETER        true
set_parameter_property  ASYNC_RESET             DISPLAY_HINT         BOOLEAN
set_parameter_property  ASYNC_RESET             AFFECTS_VALIDATION   FALSE
set_parameter_property  ASYNC_RESET             AFFECTS_ELABORATION  TRUE
set_parameter_property  ASYNC_RESET             DESCRIPTION          "Set this option to use an asynchronous \
                                                                     reset scheme (pre-Stratix 10 devices)"

add_parameter           INPUT_CLOCK_FREQUENCY   INTEGER              50000000
set_parameter_property  INPUT_CLOCK_FREQUENCY   DISPLAY_NAME         "Input clock frequency"
set_parameter_property  INPUT_CLOCK_FREQUENCY   UNITS                "Hertz"
set_parameter_property  INPUT_CLOCK_FREQUENCY   HDL_PARAMETER        false
set_parameter_property  INPUT_CLOCK_FREQUENCY   AFFECTS_VALIDATION   FALSE
set_parameter_property  INPUT_CLOCK_FREQUENCY   AFFECTS_ELABORATION  TRUE
set_parameter_property  INPUT_CLOCK_FREQUENCY   DESCRIPTION          "Input clock frequency in Hz"

add_parameter           SYNC_DEPTH              INTEGER              3
set_parameter_property  SYNC_DEPTH              DISPLAY_NAME         "Synchronizer Depth"
set_parameter_property  SYNC_DEPTH              UNITS                None
set_parameter_property  SYNC_DEPTH              HDL_PARAMETER        true
set_parameter_property  SYNC_DEPTH              AFFECTS_VALIDATION   TRUE
set_parameter_property  SYNC_DEPTH              AFFECTS_ELABORATION  FALSE
set_parameter_property  SYNC_DEPTH              DESCRIPTION          "Must be set to at least 2 but recommended \
                                                                     depth is 3 or greater"

add_parameter           ADDITIONAL_DEPTH        INTEGER              2
set_parameter_property  ADDITIONAL_DEPTH        DISPLAY_NAME         "Reset Pipeline Depth"
set_parameter_property  ADDITIONAL_DEPTH        UNITS                None
set_parameter_property  ADDITIONAL_DEPTH        HDL_PARAMETER        true
set_parameter_property  ADDITIONAL_DEPTH        AFFECTS_VALIDATION   TRUE
set_parameter_property  ADDITIONAL_DEPTH        AFFECTS_ELABORATION  FALSE
set_parameter_property  ADDITIONAL_DEPTH        DESCRIPTION          "Must be set to at least 2"

add_parameter           DISABLE_GLOBAL_NETWORK  INTEGER              1
set_parameter_property  DISABLE_GLOBAL_NETWORK  DISPLAY_NAME         "Inhibit Reset Promotion to Global Network"
set_parameter_property  DISABLE_GLOBAL_NETWORK  UNITS                None
set_parameter_property  DISABLE_GLOBAL_NETWORK  HDL_PARAMETER        true
set_parameter_property  DISABLE_GLOBAL_NETWORK  DISPLAY_HINT         BOOLEAN
set_parameter_property  DISABLE_GLOBAL_NETWORK  AFFECTS_VALIDATION   FALSE
set_parameter_property  DISABLE_GLOBAL_NETWORK  AFFECTS_ELABORATION  FALSE
set_parameter_property  DISABLE_GLOBAL_NETWORK  DESCRIPTION          "Set this option to prevent the reset output \
                                                                     from being promoted to the global network. \
                                                                     This may prevent recovery timing failures \
                                                                     for any registers reset by this reset \
                                                                     synchronizer."

#
# connection point clock_in
#
add_interface           clock_in    clock                sink
set_interface_property  clock_in    clockRate            0
set_interface_property  clock_in    ENABLED              true
set_interface_property  clock_in    EXPORT_OF            ""
set_interface_property  clock_in    PORT_NAME_MAP        ""
set_interface_property  clock_in    CMSIS_SVD_VARIABLES  ""
set_interface_property  clock_in    SVD_ADDRESS_GROUP    ""

add_interface_port      clock_in    clk_in   clk   Input 1

#
# connection point reset_in
#
add_interface           reset_in    reset                sink
set_interface_property  reset_in    associatedClock      ""
set_interface_property  reset_in    synchronousEdges     NONE
set_interface_property  reset_in    ENABLED              true
set_interface_property  reset_in    EXPORT_OF            ""
set_interface_property  reset_in    PORT_NAME_MAP        ""
set_interface_property  reset_in    CMSIS_SVD_VARIABLES  ""
set_interface_property  reset_in    SVD_ADDRESS_GROUP    ""

add_interface_port      reset_in    reset_in  reset   Input 1

#
# connection point reset_out
#
add_interface           reset_out   reset                   source
set_interface_property  reset_out   associatedDirectReset   ""
set_interface_property  reset_out   associatedResetSinks    "reset_in"
set_interface_property  reset_out   ENABLED                 true
set_interface_property  reset_out   EXPORT_OF               ""
set_interface_property  reset_out   PORT_NAME_MAP           ""
set_interface_property  reset_out   CMSIS_SVD_VARIABLES     ""
set_interface_property  reset_out   SVD_ADDRESS_GROUP       ""

add_interface_port      reset_out   reset_out   reset Output   1


proc elaborate {} {

    if { [get_parameter_value GEN_OUT_CLK] > 0 } {
        add_interface           clock_out   clock                source
        set_interface_property  clock_out   clockRate            0
        set_interface_property  clock_out   ENABLED              true
        set_interface_property  clock_out   EXPORT_OF            ""
        set_interface_property  clock_out   PORT_NAME_MAP        ""
        set_interface_property  clock_out   CMSIS_SVD_VARIABLES  ""
        set_interface_property  clock_out   SVD_ADDRESS_GROUP    ""

        add_interface_port      clock_out   clk_out  clk   Output   1

        set_interface_property  reset_out   associatedClock         "clock_out"
        set_interface_property  clock_out   associatedDirectClock   "clock_in"
        set_port_property       clk_out     DRIVEN_BY               "clk_in"
        set_interface_property  clock_out   clockRate               [ get_parameter_value INPUT_CLOCK_FREQUENCY ]
    } else {
        set_interface_property  reset_out   associatedClock         "clock_in"
    }

    if { [ get_parameter_value ASYNC_RESET ] > 0 }  {
        set_interface_property  reset_out   synchronousEdges  DEASSERT
    } else {
        set_interface_property  reset_out   synchronousEdges  BOTH
    }

}

proc validate {} {

    if { [ get_parameter_value SYNC_DEPTH ] < 2 }  {
        send_message error "You must set the synchronizer depth to be 2 or larger."
    }

    if { [ get_parameter_value ADDITIONAL_DEPTH ] < 2 }  {
        send_message error "You must set the reset pipeline depth to be 2 or larger."
    }

}

