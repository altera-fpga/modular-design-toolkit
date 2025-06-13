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
# Module: intel_iopll_locked_shim
#
# Description: _hw.tcl file for a reset from a PLL locked signal
#
## *********************************************************************************

package require -exact qsys 20.1

# set module properties

set_module_property   NAME                          intel_iopll_locked_shim
set_module_property   DISPLAY_NAME                  "IOPLL locked shim"
set_module_property   DESCRIPTION                   "Creates a reset from a PLL locked signal"
set_module_property   VERSION                       99.0
set_module_property   INTERNAL                      false
set_module_property   OPAQUE_ADDRESS_MAP            true
set_module_property   INSTANTIATE_IN_SYSTEM_MODULE  true
set_module_property   EDITABLE                      true
set_module_property   REPORT_TO_TALKBACK            false
set_module_property   ALLOW_GREYBOX_GENERATION      false
set_module_property   REPORT_HIERARCHY              false
set_module_property   ELABORATION_CALLBACK          elaboration_callback

# add file sets

add_fileset           QUARTUS_SYNTH                 QUARTUS_SYNTH                   ""    ""
set_fileset_property  QUARTUS_SYNTH                 TOP_LEVEL                       intel_iopll_locked_shim
set_fileset_property  QUARTUS_SYNTH                 ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  QUARTUS_SYNTH                 ENABLE_FILE_OVERWRITE_MODE      false

add_fileset_file      intel_iopll_locked_shim.sv    SYSTEM_VERILOG                  PATH \
                      "src_hdl/intel_iopll_locked_shim.sv"                          TOP_LEVEL_FILE

add_fileset           SIM_VERILOG                   SIM_VERILOG                     ""    ""
set_fileset_property  SIM_VERILOG                   TOP_LEVEL                       intel_iopll_locked_shim
set_fileset_property  SIM_VERILOG                   ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VERILOG                   ENABLE_FILE_OVERWRITE_MODE      false

add_fileset_file      intel_iopll_locked_shim.sv    SYSTEM_VERILOG                  PATH \
                      "src_hdl/intel_iopll_locked_shim.sv"

add_fileset           SIM_VHDL                      SIM_VHDL                        ""    ""
set_fileset_property  SIM_VHDL                      TOP_LEVEL                       intel_iopll_locked_shim
set_fileset_property  SIM_VHDL                      ENABLE_RELATIVE_INCLUDE_PATHS   false
set_fileset_property  SIM_VHDL                      ENABLE_FILE_OVERWRITE_MODE      false

add_fileset_file      intel_iopll_locked_shim.sv    SYSTEM_VERILOG                  PATH \
                      "src_hdl/intel_iopll_locked_shim.sv"

# add interfaces

proc elaboration_callback {} {

    add_interface           locked_in     conduit             end
    add_interface_port      locked_in     locked_in           export          Input       1

    add_interface           reset         reset               source
    add_interface_port      reset         reset_out           reset           Output      1
    set_interface_property  reset         synchronousEdges    "none"

    add_interface           locked_out    conduit             end
    add_interface_port      locked_out    locked_out          export          Output      1

    add_interface           locked_out_1  conduit             end
    add_interface_port      locked_out_1  locked_out_1        export          Output      1

}

