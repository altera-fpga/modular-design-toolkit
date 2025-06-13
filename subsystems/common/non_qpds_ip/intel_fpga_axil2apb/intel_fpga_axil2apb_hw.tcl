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

set_module_property    NAME                         intel_fpga_axil2apb
set_module_property    DESCRIPTION                  "Intel FPGA AXI4Lite to APB bridge"
set_module_property    DISPLAY_NAME                 "Intel FPGA AXI4Lite to APB bridge"
set_module_property    VERSION                      1.0
set_module_property    GROUP                        "Safe Drive on Chip"
set_module_property    EDITABLE                     false
set_module_property    AUTHOR                       "Intel Corporation"
set_module_property    INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property    INTERNAL                     false
set_module_property    VALIDATION_CALLBACK          my_validate
set_module_property    ELABORATION_CALLBACK         my_elab

add_fileset            SIM_VERILOG   SIM_VERILOG    "" ""
set_fileset_property   SIM_VERILOG   TOP_LEVEL      intel_fpga_axil2apb
add_fileset            QUARTUS_SYNTH QUARTUS_SYNTH  my_generate ""
set_fileset_property   QUARTUS_SYNTH TOP_LEVEL      intel_fpga_axil2apb

add_fileset_file "rtl/intel_fpga_axil2apb.sv"  SYSTEMVERILOG     PATH    "./rtl/intel_fpga_axil2apb.sv"


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

add_parameter          P_WATCHDOG_EN       INTEGER              1
set_parameter_property P_WATCHDOG_EN       DEFAULT_VALUE        1
set_parameter_property P_WATCHDOG_EN       DISPLAY_NAME         "Enable the watchdog"
set_parameter_property P_WATCHDOG_EN       ALLOWED_RANGES       {0:1}
set_parameter_property P_WATCHDOG_EN       DISPLAY_HINT         "Boolean"
set_parameter_property P_WATCHDOG_EN       AFFECTS_ELABORATION  true
set_parameter_property P_WATCHDOG_EN       HDL_PARAMETER        true
set_parameter_property P_WATCHDOG_EN       VISIBLE              true

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

# ---------------------------------------------------------------------------- #
# APB interface 0
# ---------------------------------------------------------------------------- #
add_interface          m_apb apb                  start
set_interface_property m_apb associatedClock      s_axi_aclk
set_interface_property m_apb associatedReset      s_axi_aresetn
set_interface_property m_apb ENABLED              true
set_interface_property m_apb EXPORT_OF            ""
set_interface_property m_apb PORT_NAME_MAP        ""
set_interface_property m_apb CMSIS_SVD_VARIABLES  ""
set_interface_property m_apb SVD_ADDRESS_GROUP    ""

add_interface_port m_apb m_apb_paddr    paddr   Output  P_S_AXI_ADDR_WIDTH
add_interface_port m_apb m_apb_pwrite   pwrite  Output  1
add_interface_port m_apb m_apb_psel     psel    Output  1
add_interface_port m_apb m_apb_penable  penable Output  1
add_interface_port m_apb m_apb_pwdata   pwdata  Output  P_S_AXI_DATA_WIDTH
add_interface_port m_apb m_apb_prdata   prdata  Input   P_S_AXI_DATA_WIDTH
add_interface_port m_apb m_apb_pready   pready  Input   1

proc my_generate { entity } {

}

proc my_elab {} {

}

proc my_validate {} {

}
