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
# Module: intel_emif_reset_block
#
# Description: _hw.tcl file for emif reset generator
#
## *********************************************************************************

package require -exact qsys 18.1

# set module properties
set_module_property   DESCRIPTION                   "Combines system reset with a user reset to produce the EMIF reset"
set_module_property   NAME                          intel_emif_reset_block
set_module_property   VERSION                       99.0
set_module_property   INTERNAL                      false
set_module_property   OPAQUE_ADDRESS_MAP            true
set_module_property   DISPLAY_NAME                  "EMIF reset block"
set_module_property   INSTANTIATE_IN_SYSTEM_MODULE  true
set_module_property   EDITABLE                      true
set_module_property   REPORT_TO_TALKBACK            false
set_module_property   ALLOW_GREYBOX_GENERATION      false
set_module_property   REPORT_HIERARCHY              false

set_module_property   ELABORATION_CALLBACK          elaborate
set_module_property   VALIDATION_CALLBACK           validate

# add file sets
add_fileset           QUARTUS_SYNTH                       QUARTUS_SYNTH                   ""      ""
set_fileset_property  QUARTUS_SYNTH                       TOP_LEVEL                       intel_emif_reset_block
set_fileset_property  QUARTUS_SYNTH                       ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  QUARTUS_SYNTH                       ENABLE_FILE_OVERWRITE_MODE      false
add_fileset_file      intel_emif_reset_block.sv           SYSTEM_VERILOG                  PATH \
                      "src_hdl/intel_emif_reset_block.sv"  TOP_LEVEL_FILE

add_fileset           SIM_VERILOG                         SIM_VERILOG                     ""      ""
set_fileset_property  SIM_VERILOG                         TOP_LEVEL                       intel_emif_reset_block
set_fileset_property  SIM_VERILOG                         ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VERILOG                         ENABLE_FILE_OVERWRITE_MODE      false
add_fileset_file      intel_emif_reset_block.sv           SYSTEM_VERILOG                  PATH \
                      "src_hdl/intel_emif_reset_block.sv"  TOP_LEVEL_FILE

add_fileset           SIM_VHDL                            SIM_VHDL                        ""      ""
set_fileset_property  SIM_VHDL                            TOP_LEVEL                       intel_emif_reset_block
set_fileset_property  SIM_VHDL                            ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VHDL                            ENABLE_FILE_OVERWRITE_MODE      false
add_fileset_file      intel_emif_reset_block.sv           SYSTEM_VERILOG                  PATH \
                      "src_hdl/intel_emif_reset_block.sv"  TOP_LEVEL_FILE

# add parameters
add_parameter           SYSTEM_RESET_ACTIVE_HIGH  BOOLEAN               1
set_parameter_property  SYSTEM_RESET_ACTIVE_HIGH  DISPLAY_NAME          "System Reset Active High"
set_parameter_property  SYSTEM_RESET_ACTIVE_HIGH  DESCRIPTION           "System Reset Active High"
set_parameter_property  SYSTEM_RESET_ACTIVE_HIGH  HDL_PARAMETER         true
set_parameter_property  SYSTEM_RESET_ACTIVE_HIGH  AFFECTS_VALIDATION    FALSE
set_parameter_property  SYSTEM_RESET_ACTIVE_HIGH  AFFECTS_ELABORATION   FALSE

add_parameter           USER_RESET_ACTIVE_HIGH    BOOLEAN               1
set_parameter_property  USER_RESET_ACTIVE_HIGH    DISPLAY_NAME          "User Reset Active High"
set_parameter_property  USER_RESET_ACTIVE_HIGH    DESCRIPTION           "User Reset Active High"
set_parameter_property  USER_RESET_ACTIVE_HIGH    HDL_PARAMETER         true
set_parameter_property  USER_RESET_ACTIVE_HIGH    AFFECTS_VALIDATION    FALSE
set_parameter_property  USER_RESET_ACTIVE_HIGH    AFFECTS_ELABORATION   FALSE

add_parameter           RESET_REQUEST_OUTPUT      BOOLEAN               0
set_parameter_property  RESET_REQUEST_OUTPUT      DISPLAY_NAME          "Reset Request Output"
set_parameter_property  RESET_REQUEST_OUTPUT      DESCRIPTION           "Reset Request Output"
set_parameter_property  RESET_REQUEST_OUTPUT      HDL_PARAMETER         FALSE
set_parameter_property  RESET_REQUEST_OUTPUT      AFFECTS_VALIDATION    FALSE
set_parameter_property  RESET_REQUEST_OUTPUT      AFFECTS_ELABORATION   TRUE

# add interfaces
add_interface           system_reset  reset                 sink
set_interface_property  system_reset  synchronousEdges      NONE
set_interface_property  system_reset  ENABLED               true
set_interface_property  system_reset  EXPORT_OF             ""
set_interface_property  system_reset  PORT_NAME_MAP         ""
set_interface_property  system_reset  CMSIS_SVD_VARIABLES   ""
set_interface_property  system_reset  SVD_ADDRESS_GROUP     ""

add_interface_port      system_reset  system_reset          reset   Input   1

add_interface           user_reset    conduit               end
set_interface_property  user_reset    ENABLED               true
set_interface_property  user_reset    EXPORT_OF             ""
set_interface_property  user_reset    PORT_NAME_MAP         ""
set_interface_property  user_reset    CMSIS_SVD_VARIABLES   ""
set_interface_property  user_reset    SVD_ADDRESS_GROUP     ""

add_interface_port      user_reset    user_reset            export  Input   1

proc elaborate {} {
    set v_reset_request_output [get_parameter_value RESET_REQUEST_OUTPUT]

    if {${v_reset_request_output}} {
        add_interface           reset_req_out   conduit                         end
        set_interface_property  reset_req_out   associatedClock                 ""
        set_interface_property  reset_req_out   associatedReset                 ""
        set_interface_property  reset_req_out   ENABLED                         true
        set_interface_property  reset_req_out   EXPORT_OF                       ""
        set_interface_property  reset_req_out   PORT_NAME_MAP                   ""
        set_interface_property  reset_req_out   CMSIS_SVD_VARIABLES             ""
        set_interface_property  reset_req_out   SVD_ADDRESS_GROUP               ""
        set_interface_property  reset_req_out   IPXACT_REGISTER_MAP_VARIABLES   ""
        set_interface_property  reset_req_out   SV_INTERFACE_TYPE               ""
        set_interface_property  reset_req_out   SV_INTERFACE_MODPORT_TYPE       ""

        add_interface_port      reset_req_out   reset_out     local_reset_req   Output  1
    } else {
        add_interface           reset_out       reset                           source
        set_interface_property  reset_out       associatedDirectReset           ""
        set_interface_property  reset_out       associatedResetSinks            ""
        set_interface_property  reset_out       synchronousEdges                NONE
        set_interface_property  reset_out       ENABLED                         true
        set_interface_property  reset_out       EXPORT_OF                       ""
        set_interface_property  reset_out       PORT_NAME_MAP                   ""
        set_interface_property  reset_out       CMSIS_SVD_VARIABLES             ""
        set_interface_property  reset_out       SVD_ADDRESS_GROUP               ""

        add_interface_port      reset_out       reset_out         reset         Output  1
    }
}

proc validate {} {
}
