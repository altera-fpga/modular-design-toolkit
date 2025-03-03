###################################################################################
# Copyright (C) 2025 Intel Corporation
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

package require -exact qsys 18.1

set_module_property    NAME                         intel_fpga_pb_debounce
set_module_property    DESCRIPTION                  "Intel FPGA Push-button Debounce"
set_module_property    DISPLAY_NAME                 "Intel FPGA Push-button Debounce"
set_module_property    VERSION                      1.0
set_module_property    GROUP                        "Safe Drive on Chip"
set_module_property    EDITABLE                     false
set_module_property    AUTHOR                       "Intel Corporation"
set_module_property    INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property    INTERNAL                     false
set_module_property    VALIDATION_CALLBACK          my_validate
set_module_property    ELABORATION_CALLBACK         my_elab
add_fileset            SIM_VERILOG   SIM_VERILOG    "" ""
set_fileset_property   SIM_VERILOG   TOP_LEVEL      intel_fpga_pb_debounce
add_fileset            QUARTUS_SYNTH QUARTUS_SYNTH  my_generate ""
set_fileset_property   QUARTUS_SYNTH TOP_LEVEL      intel_fpga_pb_debounce

add_fileset_file "rtl/intel_fpga_pb_debounce.sv"         SYSTEMVERILOG PATH    "./rtl/intel_fpga_pb_debounce.sv"
add_fileset_file "rtl/intel_fpga_pb_debounce_channel.sv" SYSTEMVERILOG PATH    "./rtl/intel_fpga_pb_debounce_channel.sv"
add_fileset_file "sdc/intel_fpga_pb_debounce.sdc"        SDC_ENTITY     PATH   "./sdc/intel_fpga_pb_debounce.sdc" \
                                                                                {NO_SDC_PROMOTION}

# ---------------------------------------------------------------------------- #
# Parameters
# ---------------------------------------------------------------------------- #
add_parameter          P_NUM_CHANNELS  INTEGER              1
set_parameter_property P_NUM_CHANNELS  DEFAULT_VALUE        1
set_parameter_property P_NUM_CHANNELS  ALLOWED_RANGES       {1:32}
set_parameter_property P_NUM_CHANNELS  DISPLAY_NAME         "Number of channels"
set_parameter_property P_NUM_CHANNELS  ENABLED              true
set_parameter_property P_NUM_CHANNELS  UNITS                None
set_parameter_property P_NUM_CHANNELS  VISIBLE              true
set_parameter_property P_NUM_CHANNELS  AFFECTS_ELABORATION  true
set_parameter_property P_NUM_CHANNELS  HDL_PARAMETER        true

add_parameter          P_CLK_FREQ_HZ   INTEGER              0
set_parameter_property P_CLK_FREQ_HZ   DEFAULT_VALUE        0
set_parameter_property P_CLK_FREQ_HZ   DISPLAY_NAME         "Clock Frequency (Hz)"
set_parameter_property P_CLK_FREQ_HZ   ENABLED              false
set_parameter_property P_CLK_FREQ_HZ   UNITS                Hertz
set_parameter_property P_CLK_FREQ_HZ   VISIBLE              true
set_parameter_property P_CLK_FREQ_HZ   AFFECTS_ELABORATION  true
set_parameter_property P_CLK_FREQ_HZ   HDL_PARAMETER        true
set_parameter_property P_CLK_FREQ_HZ   DERIVED              true

add_parameter DERIVED_CLOCK_RATE INTEGER 0
set_parameter_property DERIVED_CLOCK_RATE DISPLAY_NAME "Derived clock rate"
set_parameter_property DERIVED_CLOCK_RATE DESCRIPTION {Clock rate derived from system_info}
set_parameter_property DERIVED_CLOCK_RATE UNITS Hertz
set_parameter_property DERIVED_CLOCK_RATE SYSTEM_INFO { CLOCK_RATE "i_clk" }
set_parameter_property DERIVED_CLOCK_RATE SYSTEM_INFO_TYPE {CLOCK_RATE}
set_parameter_property DERIVED_CLOCK_RATE ENABLED false
set_parameter_property DERIVED_CLOCK_RATE VISIBLE false

# ---------------------------------------------------------------------------- #
# Clock
# ---------------------------------------------------------------------------- #
add_interface            i_clk  clock           end
set_interface_property   i_clk  clockRate       0
set_interface_property   i_clk  ENABLED         true
add_interface_port       i_clk  clk             clk  Input 1

add_interface            i_pb   conduit         end
set_interface_property   i_pb   ENABLED         true
add_interface_port       i_pb   i_pb            pb0  Input  P_NUM_CHANNELS

add_interface            o_pb   conduit         start
set_interface_property   o_pb   ENABLED         true
add_interface_port       o_pb   o_pb            pb0  Output P_NUM_CHANNELS

proc my_generate { entity } {

}

proc my_elab {} {
  set v_clock_rate    [ get_parameter_value DERIVED_CLOCK_RATE ]
  set_parameter_value P_CLK_FREQ_HZ ${v_clock_rate}
}

proc my_validate {} {

}
