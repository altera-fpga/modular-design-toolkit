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

package require -exact qsys 18.0

set_module_property NAME                         intel_offset_capability
set_module_property VERSION                      1.1
set_module_property GROUP                        "Video and Image Processing"
set_module_property EDITABLE                     false
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property INTERNAL                     false

#
# file sets
#
add_fileset          QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL intel_offset_capability

add_fileset_file src_hdl/intel_offset_capability.vhd VHDL PATH src_hdl/intel_offset_capability.vhd

add_fileset          SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL intel_offset_capability

add_fileset_file src_hdl/intel_offset_capability.vhd VHDL PATH src_hdl/intel_offset_capability.vhd

set_module_property DESCRIPTION  "Offset Capability"
set_module_property DISPLAY_NAME "Offset Capability (Intel)"

set_module_property ELABORATION_CALLBACK my_elaboration_callback
set_module_property VALIDATION_CALLBACK  my_validation_callback

# +-----------------------------------
# | connection point av_mm_control_agent_clock
# |
add_interface          av_mm_control_agent_clock clock sink
set_interface_property av_mm_control_agent_clock ENABLED true
add_interface_port     av_mm_control_agent_clock s_avlmm_clk clk Input 1

add_interface          av_mm_control_agent_reset reset sink
set_interface_property av_mm_control_agent_reset ENABLED true
set_interface_property av_mm_control_agent_reset ASSOCIATED_CLOCK av_mm_control_agent_clock
add_interface_port     av_mm_control_agent_reset s_avlmm_reset reset Input 1
# |
# +-----------------------------------

# +-----------------------------------
# | connection point av_mm_control_agent
# |
add_interface          av_mm_control_agent avalon                         agent
set_interface_property av_mm_control_agent addressAlignment               DYNAMIC
set_interface_property av_mm_control_agent associatedClock                av_mm_control_agent_clock
set_interface_property av_mm_control_agent burstOnBurstBoundariesOnly     false
set_interface_property av_mm_control_agent explicitAddressSpan            0
set_interface_property av_mm_control_agent holdTime                       0
set_interface_property av_mm_control_agent isMemoryDevice                 false
set_interface_property av_mm_control_agent isNonVolatileStorage           false
set_interface_property av_mm_control_agent linewrapBursts                 false
set_interface_property av_mm_control_agent maximumPendingReadTransactions 1
set_interface_property av_mm_control_agent printableDevice                false
set_interface_property av_mm_control_agent readLatency                    0
set_interface_property av_mm_control_agent readWaitTime                   1
set_interface_property av_mm_control_agent setupTime                      0
set_interface_property av_mm_control_agent timingUnits                    Cycles
set_interface_property av_mm_control_agent writeWaitTime                  0

set_interface_property av_mm_control_agent ASSOCIATED_CLOCK av_mm_control_agent_clock
set_interface_property av_mm_control_agent ENABLED          true

add_interface_port av_mm_control_agent s_avlmm_base_addr     address       Input  11
add_interface_port av_mm_control_agent s_avlmm_burstcount    burstcount    Input  8
add_interface_port av_mm_control_agent s_avlmm_waitrequest   waitrequest   Output 1
add_interface_port av_mm_control_agent s_avlmm_byteenable    byteenable    Input  4
add_interface_port av_mm_control_agent s_avlmm_write         write         Input  1
add_interface_port av_mm_control_agent s_avlmm_writedata     writedata     Input  32
add_interface_port av_mm_control_agent s_avlmm_read          read          Input  1
add_interface_port av_mm_control_agent s_avlmm_readdatavalid readdatavalid Output 1
add_interface_port av_mm_control_agent s_avlmm_readdata      readdata      Output 32
# |
# +-----------------------------------


add_parameter                 C_AUTO     integer          1
set_parameter_property        C_AUTO     DISPLAY_NAME     "Automatic Assignment"
set_parameter_property        C_AUTO     HDL_PARAMETER    true
set_parameter_property        C_AUTO     ALLOWED_RANGES   0:1
set_parameter_update_callback C_AUTO     update_caps

add_parameter                 C_NUM_CAPS integer          1
set_parameter_property        C_NUM_CAPS DISPLAY_NAME     "Number of Offset Capabilites to map"
set_parameter_property        C_NUM_CAPS HDL_PARAMETER    true
set_parameter_property        C_NUM_CAPS ALLOWED_RANGES   1:128
set_parameter_update_callback C_NUM_CAPS update_caps

add_parameter                 C_BASEADDR STD_LOGIC_VECTOR 0
set_parameter_property        C_BASEADDR DISPLAY_NAME     "Base Address of Capability Structure"
set_parameter_property        C_BASEADDR WIDTH            32
set_parameter_property        C_BASEADDR HDL_PARAMETER    true
set_parameter_property        C_BASEADDR UNITS            ADDRESS

add_parameter                 C_NEXT     integer          0
set_parameter_property        C_NEXT     DISPLAY_NAME     "Next Capability Structure (0=end)"
set_parameter_property        C_NEXT     HDL_PARAMETER    true
set_parameter_property        C_NEXT     UNITS            ADDRESS

add_display_item "Configuration" C_AUTO     parameter
add_display_item "Configuration" C_NUM_CAPS parameter
add_display_item "Configuration" C_BASEADDR parameter
add_display_item "Configuration" C_NEXT     parameter

# Top level tabs
add_display_item "" "Capabilities" GROUP tab

# Capability Tabs
for {set v_i 0} {${v_i} < 128} {incr v_i} {
    add_display_item "Capabilities" "Capability ${v_i}" GROUP tab

    set v_param "C_CAP${v_i}_TYPE"

    foreach v_ending {TYPE VERSION BASE IRQ SIZE ID_ASSOCIATED ID_COMPONENT \
                        IRQ_ENABLE_EN IRQ_ENABLE IRQ_STATUS_EN IRQ_STATUS } {

        set v_param C_CAP${v_i}_${v_ending}

        add_display_item "Capability ${v_i}" ${v_param} GROUP
        if {${v_ending} == "IRQ"} {
            add_parameter ${v_param} INTEGER 255
        } else {
            add_parameter ${v_param} INTEGER 0
        }
        set_parameter_property ${v_param} DISPLAY_NAME ${v_ending}
        set_parameter_property ${v_param} HDL_PARAMETER true

        if {${v_ending} == "BASE"} {
            set_parameter_property ${v_param} UNITS ADDRESS
        } elseif {${v_ending} == "TYPE"} {
            set_parameter_property ${v_param} ALLOWED_RANGES 0:32767
            set_parameter_property ${v_param} DISPLAY_UNITS {[0-32767]}
        } elseif {${v_ending} == "ID_ASSOCIATED"} {
            set_parameter_property ${v_param} ALLOWED_RANGES 0:65535
            set_parameter_property ${v_param} DISPLAY_UNITS {[0-65535]}
        } elseif {${v_ending} == "ID_ASSOCIATED"} {
            set_parameter_property ${v_param} ALLOWED_RANGES 0:65535
            set_parameter_property ${v_param} DISPLAY_UNITS {[0-65535]}
        } elseif {${v_ending} == "SIZE"} {
            set_parameter_property ${v_param} ALLOWED_RANGES 0:16777215
            set_parameter_property ${v_param} DISPLAY_UNITS {[0-16777215]}
        } elseif {(${v_ending} == "IRQ_ENABLE") || (${v_ending} == "IRQ_STATUS")} {
            set_parameter_property ${v_param} ALLOWED_RANGES 0:32767
            set_parameter_property ${v_param} DISPLAY_UNITS {[0-32767]}
        } elseif {(${v_ending} == "IRQ_ENABLE_EN") || (${v_ending} == "IRQ_STATUS_EN")} {
            set_parameter_property ${v_param} ALLOWED_RANGES 0:1
            set_parameter_property ${v_param} DISPLAY_HINT boolean--
        } else {
            # VERSION, IRQ
            set_parameter_property ${v_param} ALLOWED_RANGES 0:255
            set_parameter_property ${v_param} DISPLAY_UNITS {[0-255]}
        }
    }
}

# Refresh which tabs should appear/disappear
proc update_caps {} {
    set v_caps [get_parameter_value C_NUM_CAPS]

    for {set v_i 0} {${v_i} < 128} {incr v_i} {
        if {${v_i} >= ${v_caps}} {
            set_display_item_property "Capability ${v_i}" VISIBLE false
        } else {
            set_display_item_property "Capability ${v_i}" VISIBLE true
        }
    }
}

proc my_validation_callback {} {
    update_caps
}

proc my_elaboration_callback {} {
}
