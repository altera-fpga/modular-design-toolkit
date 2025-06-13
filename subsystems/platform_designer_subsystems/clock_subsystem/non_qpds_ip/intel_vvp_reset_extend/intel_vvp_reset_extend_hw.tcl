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
# Module: intel_vvp_reset_extend
#
# Description: _hw.tcl file for reset extend generator with a minimum assert period
#
## *********************************************************************************

package require -exact qsys 20.1

# set module properties
set_module_property  NAME                           intel_vvp_reset_extend
set_module_property  DISPLAY_NAME                   "Generic reset extender"
set_module_property  DESCRIPTION                    "Creates an output reset with a minimum assert period"
set_module_property  VERSION                        99.0
set_module_property  INTERNAL                       false
set_module_property  OPAQUE_ADDRESS_MAP             true
set_module_property  INSTANTIATE_IN_SYSTEM_MODULE   true
set_module_property  EDITABLE                       true
set_module_property  REPORT_TO_TALKBACK             false
set_module_property  ALLOW_GREYBOX_GENERATION       false
set_module_property  REPORT_HIERARCHY               false

set_module_property  ELABORATION_CALLBACK           elaboration_callback

# add file sets
add_fileset           QUARTUS_SYNTH                 QUARTUS_SYNTH                     ""    ""
set_fileset_property  QUARTUS_SYNTH                 TOP_LEVEL                         intel_vvp_reset_extend
set_fileset_property  QUARTUS_SYNTH                 ENABLE_RELATIVE_INCLUDE_PATHS     false
set_fileset_property  QUARTUS_SYNTH                 ENABLE_FILE_OVERWRITE_MODE        false

add_fileset_file      intel_vvp_reset_extend.sv     SYSTEM_VERILOG                    PATH \
                      "src_hdl/intel_vvp_reset_extend.sv"                             TOP_LEVEL_FILE

add_fileset_file      intel_vvp_reset_extend.sdc    SDC_ENTITY                        PATH \
"src_hdl/intel_vvp_reset_extend.sdc"

add_fileset           SIM_VERILOG                   SIM_VERILOG                       ""    ""
set_fileset_property  SIM_VERILOG                   TOP_LEVEL                         intel_vvp_reset_extend
set_fileset_property  SIM_VERILOG                   ENABLE_RELATIVE_INCLUDE_PATHS     false
set_fileset_property  SIM_VERILOG                   ENABLE_FILE_OVERWRITE_MODE        false

add_fileset_file      intel_vvp_reset_extend.sv     SYSTEM_VERILOG                    PATH \
                      "src_hdl/intel_vvp_reset_extend.sv"

add_fileset           SIM_VHDL                      SIM_VHDL                          ""    ""
set_fileset_property  SIM_VHDL                      TOP_LEVEL                         intel_vvp_reset_extend
set_fileset_property  SIM_VHDL                      ENABLE_RELATIVE_INCLUDE_PATHS     false
set_fileset_property  SIM_VHDL                      ENABLE_FILE_OVERWRITE_MODE        false

add_fileset_file      intel_vvp_reset_extend.sv     SYSTEM_VERILOG                    PATH \
"src_hdl/intel_vvp_reset_extend.sv"

# add parameters
add_parameter            RESYNC_RESET_IN      INTEGER                   0
set_parameter_property   RESYNC_RESET_IN      DISPLAY_NAME              "Re-synchronize incoming reset to the clock"
set_parameter_property   RESYNC_RESET_IN      ALLOWED_RANGES            0:1
set_parameter_property   RESYNC_RESET_IN      DISPLAY_HINT              boolean
set_parameter_property   RESYNC_RESET_IN      HDL_PARAMETER             true
set_parameter_property   RESYNC_RESET_IN      AFFECTS_ELABORATION       false

add_parameter            SYNC_LEN             INTEGER                   3
set_parameter_property   SYNC_LEN             DISPLAY_NAME              "Re-synchronizer length"
set_parameter_property   SYNC_LEN             ALLOWED_RANGES            2:16
set_parameter_property   SYNC_LEN             HDL_PARAMETER             true
set_parameter_property   SYNC_LEN             AFFECTS_ELABORATION       false

add_parameter            RESET_MIN_LENGTH     INTEGER                   256
set_parameter_property   RESET_MIN_LENGTH     DISPLAY_NAME              "Extended reset duration (clock cycles)"
set_parameter_property   RESET_MIN_LENGTH     ALLOWED_RANGES            2:1000000
set_parameter_property   RESET_MIN_LENGTH     HDL_PARAMETER             true
set_parameter_property   RESET_MIN_LENGTH     AFFECTS_ELABORATION       false

add_parameter            DUAL_CONDUIT_OUT     INTEGER                   0
set_parameter_property   DUAL_CONDUIT_OUT     DISPLAY_NAME              "Use conduit for reset out"
set_parameter_property   DUAL_CONDUIT_OUT     DISPLAY_HINT              boolean
set_parameter_property   DUAL_CONDUIT_OUT     ALLOWED_RANGES            0:1
set_parameter_property   DUAL_CONDUIT_OUT     HDL_PARAMETER             false
set_parameter_property   DUAL_CONDUIT_OUT     AFFECTS_ELABORATION       true

# add interfaces
proc elaboration_callback {} {

    set   v_en_conduit_out [get_parameter_value DUAL_CONDUIT_OUT]

    add_interface       clk            clock         end
    add_interface_port  clk            clk           clk           Input   1

    add_interface       in_reset       reset         end
    add_interface_port  in_reset       rst_in        reset         Input   1

    add_interface       out_reset_dup  conduit       start
    add_interface_port  out_reset_dup  rst_out_dup   device_ready  Output  1

    if { ${v_en_conduit_out} == 0 } {

        add_interface           out_reset       reset                   start
        add_interface_port      out_reset       rst_out                 reset           Output  1

        set_port_property       rst_out         DRIVEN_BY               rst_in

        set_interface_property  out_reset       associatedClock         "clk"
        set_interface_property  out_reset       synchronousEdges        "both"
        set_interface_property  out_reset       associatedDirectReset   "in_reset"
        set_interface_property  out_reset       associatedResetSinks    "in_reset"

        set_interface_property  out_reset_dup   ENABLED                 false

    } else {

        add_interface           out_reset       conduit      start
        add_interface_port      out_reset       rst_out      device_ready    Output  1

        set_interface_property  out_reset_dup   ENABLED      true

    }

    set_port_property       clk         TERMINATION         false

    set_interface_property  in_reset    synchronousEdges    "none"
}

