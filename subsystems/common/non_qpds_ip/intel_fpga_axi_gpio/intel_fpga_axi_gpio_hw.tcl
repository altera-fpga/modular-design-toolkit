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

package require -exact qsys 18.1

set_module_property    NAME                         intel_fpga_axi_gpio
set_module_property    DESCRIPTION                  "Intel FPGA AXI4Lite GPIO"
set_module_property    DISPLAY_NAME                 "Intel FPGA AXI4Lite GPIO"
set_module_property    VERSION                      1.0
set_module_property    GROUP                        "Safe Drive on Chip"
set_module_property    EDITABLE                     false
set_module_property    AUTHOR                       "Intel Corporation"
set_module_property    INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property    INTERNAL                     false

set_module_property    VALIDATION_CALLBACK          my_validate
set_module_property    ELABORATION_CALLBACK         my_elab

add_fileset            SIM_VERILOG   SIM_VERILOG    "" ""
set_fileset_property   SIM_VERILOG   TOP_LEVEL      intel_fpga_axi_gpio
add_fileset            QUARTUS_SYNTH QUARTUS_SYNTH  my_generate ""
set_fileset_property   QUARTUS_SYNTH TOP_LEVEL      intel_fpga_axi_gpio

add_fileset_file rtl/intel_fpga_axi_gpio.sv   SYSTEMVERILOG     PATH    rtl/intel_fpga_axi_gpio.sv
add_fileset_file sdc/intel_fpga_axi_gpio.sdc  SDC_ENTITY        PATH    sdc/intel_fpga_axi_gpio.sdc {NO_SDC_PROMOTION}

# ---------------------------------------------------------------------------- #
# Parameters
# ---------------------------------------------------------------------------- #
add_parameter          P_S_AXI_ADDR_WIDTH  INTEGER              4
set_parameter_property P_S_AXI_ADDR_WIDTH  DEFAULT_VALUE        4
set_parameter_property P_S_AXI_ADDR_WIDTH  ALLOWED_RANGES       {3:32}
set_parameter_property P_S_AXI_ADDR_WIDTH  DISPLAY_NAME         "AXI / APB Address Width"
set_parameter_property P_S_AXI_ADDR_WIDTH  ENABLED              false
set_parameter_property P_S_AXI_ADDR_WIDTH  UNITS                None
set_parameter_property P_S_AXI_ADDR_WIDTH  VISIBLE              true
set_parameter_property P_S_AXI_ADDR_WIDTH  AFFECTS_ELABORATION  true
set_parameter_property P_S_AXI_ADDR_WIDTH  HDL_PARAMETER        true

add_parameter          P_S_AXI_DATA_WIDTH  INTEGER              32
set_parameter_property P_S_AXI_DATA_WIDTH  DEFAULT_VALUE        32
set_parameter_property P_S_AXI_DATA_WIDTH  DISPLAY_NAME         "AXI / APB Data Width"
set_parameter_property P_S_AXI_DATA_WIDTH  ENABLED              false
set_parameter_property P_S_AXI_DATA_WIDTH  UNITS                None
set_parameter_property P_S_AXI_DATA_WIDTH  VISIBLE              true
set_parameter_property P_S_AXI_DATA_WIDTH  AFFECTS_ELABORATION  true
set_parameter_property P_S_AXI_DATA_WIDTH  HDL_PARAMETER        true

add_parameter          P_EN_GPI            INTEGER              1
set_parameter_property P_EN_GPI            DEFAULT_VALUE        1
set_parameter_property P_EN_GPI            DISPLAY_NAME         "Enable the GP Inputs"
set_parameter_property P_EN_GPI            ALLOWED_RANGES       {0:1}
set_parameter_property P_EN_GPI            DISPLAY_HINT         "Boolean"
set_parameter_property P_EN_GPI            HDL_PARAMETER        false
set_parameter_property P_EN_GPI            AFFECTS_ELABORATION  true
set_parameter_property P_EN_GPI            AFFECTS_VALIDATION   true
set_parameter_property P_EN_GPI            ENABLED              true
set_parameter_property P_EN_GPI            VISIBLE              true

add_parameter          P_GPI_WIDTH         INTEGER              32
set_parameter_property P_GPI_WIDTH         DEFAULT_VALUE        1
set_parameter_property P_GPI_WIDTH         DISPLAY_NAME         "GPI Width"
set_parameter_property P_GPI_WIDTH         ALLOWED_RANGES       1:32
set_parameter_property P_GPI_WIDTH         HDL_PARAMETER        true
set_parameter_property P_GPI_WIDTH         AFFECTS_ELABORATION  true
set_parameter_property P_GPI_WIDTH         AFFECTS_VALIDATION   true
set_parameter_property P_GPI_WIDTH         DESCRIPTION          "Number of GPI bits"
set_parameter_property P_GPI_WIDTH         ENABLED              true
set_parameter_property P_GPI_WIDTH         VISIBLE              true

add_parameter          P_EN_GPO            INTEGER              1
set_parameter_property P_EN_GPO            DEFAULT_VALUE        1
set_parameter_property P_EN_GPO            DISPLAY_NAME         "Enable the GP Outputs"
set_parameter_property P_EN_GPO            ALLOWED_RANGES       {0:1}
set_parameter_property P_EN_GPO            DISPLAY_HINT         "Boolean"
set_parameter_property P_EN_GPO            HDL_PARAMETER        false
set_parameter_property P_EN_GPO            AFFECTS_ELABORATION  true
set_parameter_property P_EN_GPO            AFFECTS_VALIDATION   true
set_parameter_property P_EN_GPO            ENABLED              true
set_parameter_property P_EN_GPO            VISIBLE              true

add_parameter          P_GPO_WIDTH         INTEGER              32
set_parameter_property P_GPO_WIDTH         DEFAULT_VALUE        1
set_parameter_property P_GPO_WIDTH         DISPLAY_NAME         "GPO Width"
set_parameter_property P_GPO_WIDTH         ALLOWED_RANGES       1:32
set_parameter_property P_GPO_WIDTH         HDL_PARAMETER        true
set_parameter_property P_GPO_WIDTH         AFFECTS_ELABORATION  true
set_parameter_property P_GPO_WIDTH         AFFECTS_VALIDATION   true
set_parameter_property P_GPO_WIDTH         DESCRIPTION          "Number of GPO bits"
set_parameter_property P_GPO_WIDTH         ENABLED              true
set_parameter_property P_GPO_WIDTH         VISIBLE              true

add_parameter          P_GPO_DEFAULT       STD_LOGIC_VECTOR      0
set_parameter_property P_GPO_DEFAULT       DEFAULT_VALUE         0
set_parameter_property P_GPO_DEFAULT       WIDTH                 32
set_parameter_property P_GPO_DEFAULT       HDL_PARAMETER         true
set_parameter_property P_GPO_DEFAULT       DISPLAY_NAME          "GPO Default"
set_parameter_property P_GPO_DEFAULT       AFFECTS_ELABORATION   true
set_parameter_property P_GPO_DEFAULT       AFFECTS_VALIDATION    true
set_parameter_property P_GPO_DEFAULT       DESCRIPTION           "Default value for the GPO interface"
set_parameter_property P_GPO_DEFAULT       ENABLED               true
set_parameter_property P_GPO_DEFAULT       VISIBLE               true

# ---------------------------------------------------------------------------- #
# Clock
# ---------------------------------------------------------------------------- #
add_interface            s_axi_aclk  clock           end
set_interface_property   s_axi_aclk  clockRate       0
set_interface_property   s_axi_aclk  ENABLED         true
add_interface_port       s_axi_aclk  s_axi_aclk clk  Input 1

# ---------------------------------------------------------------------------- #
# Reset
# ---------------------------------------------------------------------------- #
add_interface            s_axi_aresetn   reset             end
set_interface_property   s_axi_aresetn   associatedClock   s_axi_aclk
set_interface_property   s_axi_aresetn   synchronousEdges  DEASSERT
set_interface_property   s_axi_aresetn   ENABLED           true
add_interface_port       s_axi_aresetn   s_axi_aresetn     reset_n     Input   1

# ---------------------------------------------------------------------------- #
# AXI4Lite interface 0
# ---------------------------------------------------------------------------- #
add_interface          s_axi axi4lite             end
set_interface_property s_axi associatedClock      s_axi_aclk
set_interface_property s_axi associatedReset      s_axi_aresetn
set_interface_property s_axi ENABLED              true
set_interface_property s_axi EXPORT_OF            ""
set_interface_property s_axi PORT_NAME_MAP        ""
set_interface_property s_axi CMSIS_SVD_VARIABLES  ""
set_interface_property s_axi SVD_ADDRESS_GROUP    ""

add_interface_port s_axi s_axi_awaddr  awaddr  Input   P_S_AXI_ADDR_WIDTH
add_interface_port s_axi s_axi_awvalid awvalid Input   1
add_interface_port s_axi s_axi_awready awready Output  1
add_interface_port s_axi s_axi_wdata   wdata   Input   P_S_AXI_DATA_WIDTH
add_interface_port s_axi s_axi_wready  wready  Output  1
add_interface_port s_axi s_axi_wvalid  wvalid  Input   1
add_interface_port s_axi s_axi_wstrb   wstrb   Input   (P_S_AXI_DATA_WIDTH/8)
add_interface_port s_axi s_axi_bresp   bresp   Output  2
add_interface_port s_axi s_axi_bvalid  bvalid  Output  1
add_interface_port s_axi s_axi_bready  bready  Input   1
add_interface_port s_axi s_axi_rdata   rdata   Output  P_S_AXI_DATA_WIDTH
add_interface_port s_axi s_axi_rresp   rresp   Output  2
add_interface_port s_axi s_axi_rvalid  rvalid  Output  1
add_interface_port s_axi s_axi_rready  rready  Input   1
add_interface_port s_axi s_axi_araddr  araddr  Input   P_S_AXI_ADDR_WIDTH
add_interface_port s_axi s_axi_arvalid arvalid Input   1
add_interface_port s_axi s_axi_arready arready Output  1
add_interface_port s_axi s_axi_awprot  awprot  Input   3
add_interface_port s_axi s_axi_arprot  arprot  Input   3

add_interface          i_gpi conduit              end
set_interface_property i_gpi associatedClock      ""
set_interface_property i_gpi associatedReset      ""
set_interface_property i_gpi ENABLED              true

add_interface_port     i_gpi gpi  gpi  Input   P_GPI_WIDTH

add_interface          o_gpo conduit              end
set_interface_property o_gpo associatedClock      ""
set_interface_property o_gpo associatedReset      ""
set_interface_property o_gpo ENABLED              true

add_interface_port     o_gpo gpo  gpo  Output   P_GPO_WIDTH

proc my_generate { entity } {

}

proc my_elab {} {

  if {[get_parameter_value P_EN_GPO] == 0} {
    set_interface_property o_gpo ENABLED   false
  } else {
    set_interface_property o_gpo ENABLED   true
  }

  if {[get_parameter_value P_EN_GPI] == 0} {
    set_interface_property i_gpi ENABLED   false
  } else {
    set_interface_property i_gpi ENABLED   true
  }

}

proc my_validate {} {

  if {[get_parameter_value P_EN_GPO] == 0} {
    set_parameter_property P_GPO_WIDTH     ENABLED    false
  } else {
    set_parameter_property P_GPO_WIDTH     ENABLED    true
  }
  if {[get_parameter_value P_EN_GPI] == 0} {
    set_parameter_property P_GPI_WIDTH     ENABLED    false
  } else {
    set_parameter_property P_GPI_WIDTH     ENABLED    true
  }

}
