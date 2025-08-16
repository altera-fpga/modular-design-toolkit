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
# Module: intel_vip_intel_vip_reset_gen_block_block
#
# Description: _hw.tcl file for reset generator of a minimum pulse length from a
#              push button switch
#
## *********************************************************************************

package require -exact qsys 18.1

# set module properties

set_module_property   DESCRIPTION                   "Generates a reset signal of minimum pulse length \
                                                    from a push button switch"
set_module_property   NAME                          intel_vip_reset_gen_block
set_module_property   VERSION                       99.0
set_module_property   INTERNAL                      false
set_module_property   OPAQUE_ADDRESS_MAP            true
set_module_property   DISPLAY_NAME                  "Push button reset generator"
set_module_property   INSTANTIATE_IN_SYSTEM_MODULE  true
set_module_property   EDITABLE                      true
set_module_property   REPORT_TO_TALKBACK            false
set_module_property   ALLOW_GREYBOX_GENERATION      false
set_module_property   REPORT_HIERARCHY              false

set_module_property   ELABORATION_CALLBACK          elaborate
set_module_property   VALIDATION_CALLBACK           validate

# add file sets

add_fileset           QUARTUS_SYNTH                       QUARTUS_SYNTH                   ""      ""
set_fileset_property  QUARTUS_SYNTH                       TOP_LEVEL                       intel_vip_reset_gen_block
set_fileset_property  QUARTUS_SYNTH                       ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  QUARTUS_SYNTH                       ENABLE_FILE_OVERWRITE_MODE      false
add_fileset_file      intel_vip_reset_gen_block.sv        SYSTEM_VERILOG \
                                      PATH    "src_hdl/intel_vip_reset_gen_block.sv"        TOP_LEVEL_FILE
add_fileset_file      intel_vip_reset_gen_sync_block.sv   SYSTEM_VERILOG \
                                      PATH    "src_hdl/intel_vip_reset_gen_sync_block.sv"   TOP_LEVEL_FILE

add_fileset           SIM_VERILOG                         SIM_VERILOG                     ""      ""
set_fileset_property  SIM_VERILOG                         TOP_LEVEL                       intel_vip_reset_gen_block
set_fileset_property  SIM_VERILOG                         ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VERILOG                         ENABLE_FILE_OVERWRITE_MODE      false
add_fileset_file      intel_vip_reset_gen_block.sv        SYSTEM_VERILOG \
                                      PATH    "src_hdl/intel_vip_reset_gen_block.sv"        TOP_LEVEL_FILE
add_fileset_file      intel_vip_reset_gen_sync_block.sv   SYSTEM_VERILOG \
                                      PATH    "src_hdl/intel_vip_reset_gen_sync_block.sv"   TOP_LEVEL_FILE

add_fileset           SIM_VHDL                            SIM_VHDL                        ""      ""
set_fileset_property  SIM_VHDL                            TOP_LEVEL                       intel_vip_reset_gen_block
set_fileset_property  SIM_VHDL                            ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VHDL                            ENABLE_FILE_OVERWRITE_MODE      false
add_fileset_file      intel_vip_reset_gen_block.sv        SYSTEM_VERILOG \
                                      PATH    "src_hdl/intel_vip_reset_gen_block.sv"        TOP_LEVEL_FILE
add_fileset_file      intel_vip_reset_gen_sync_block.sv   SYSTEM_VERILOG \
                                      PATH    "src_hdl/intel_vip_reset_gen_sync_block.sv"   TOP_LEVEL_FILE

# add parameters

add_parameter           CNTR_WIDTH  INTEGER                 8
set_parameter_property  CNTR_WIDTH  DISPLAY_NAME            "Counter Width"
set_parameter_property  CNTR_WIDTH  ALLOWED_RANGES          2:64
set_parameter_property  CNTR_WIDTH  DESCRIPTION             "Counter Width"
set_parameter_property  CNTR_WIDTH  HDL_PARAMETER           true
set_parameter_property  CNTR_WIDTH  AFFECTS_VALIDATION      FALSE
set_parameter_property  CNTR_WIDTH  AFFECTS_ELABORATION     FALSE

# add interfaces

add_interface           clk         clock                   sink
set_interface_property  clk         clockRate               0
set_interface_property  clk         ENABLED                 true
set_interface_property  clk         EXPORT_OF               ""
set_interface_property  clk         PORT_NAME_MAP           ""
set_interface_property  clk         CMSIS_SVD_VARIABLES     ""
set_interface_property  clk         SVD_ADDRESS_GROUP       ""

add_interface_port      clk         clk                     clk       Input   1

add_interface           pb_resetn   reset                   sink
set_interface_property  pb_resetn   synchronousEdges        NONE
set_interface_property  pb_resetn   ENABLED                 true
set_interface_property  pb_resetn   EXPORT_OF               ""
set_interface_property  pb_resetn   PORT_NAME_MAP           ""
set_interface_property  pb_resetn   CMSIS_SVD_VARIABLES     ""
set_interface_property  pb_resetn   SVD_ADDRESS_GROUP       ""

add_interface_port      pb_resetn   pb_resetn               reset     Input   1

add_interface           reset       reset                   source
set_interface_property  reset       associatedClock         "clk"
set_interface_property  reset       associatedDirectReset   ""
set_interface_property  reset       associatedResetSinks    "pb_resetn"
set_interface_property  reset       synchronousEdges        BOTH
set_interface_property  reset       ENABLED                 true
set_interface_property  reset       EXPORT_OF               ""
set_interface_property  reset       PORT_NAME_MAP           ""
set_interface_property  reset       CMSIS_SVD_VARIABLES     ""
set_interface_property  reset       SVD_ADDRESS_GROUP       ""

add_interface_port      reset       reset                   reset     Output  1

add_interface           reset_n     reset                   source
set_interface_property  reset_n     associatedClock         "clk"
set_interface_property  reset_n     associatedDirectReset   ""
set_interface_property  reset_n     associatedResetSinks    "pb_resetn"
set_interface_property  reset_n     synchronousEdges        BOTH
set_interface_property  reset_n     ENABLED                 true
set_interface_property  reset_n     EXPORT_OF               ""
set_interface_property  reset_n     PORT_NAME_MAP           ""
set_interface_property  reset_n     CMSIS_SVD_VARIABLES     ""
set_interface_property  reset_n     SVD_ADDRESS_GROUP       ""

add_interface_port      reset_n     reset_n                 reset_n   Output  1

proc elaborate {} {

}

proc validate {} {

}
