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

set_module_property    NAME                         intel_fpga_shared_mem
set_module_property    DESCRIPTION                  "Intel FPGA Shared Memory"
set_module_property    DISPLAY_NAME                 "Intel FPGA Shared Memory"
set_module_property    VERSION                      1.0
set_module_property    GROUP                        "Safe Drive on Chip"
set_module_property    EDITABLE                     false
set_module_property    AUTHOR                       "Intel Corporation"
set_module_property    INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property    INTERNAL                     false

set_module_property    VALIDATION_CALLBACK          my_validate
set_module_property    ELABORATION_CALLBACK         my_elab

add_fileset            SIM_VERILOG   SIM_VERILOG    "" ""
set_fileset_property   SIM_VERILOG   TOP_LEVEL      intel_fpga_shared_mem

add_fileset            QUARTUS_SYNTH QUARTUS_SYNTH  my_generate ""
set_fileset_property   QUARTUS_SYNTH TOP_LEVEL      intel_fpga_shared_mem

add_fileset_file "rtl/intel_fpga_shared_mem_dpram.sv"  SYSTEMVERILOG  PATH  "./rtl/intel_fpga_shared_mem_dpram.sv"
add_fileset_file "rtl/intel_fpga_shared_mem.sv"        SYSTEMVERILOG  PATH  "./rtl/intel_fpga_shared_mem.sv"


# ---------------------------------------------------------------------------- #
# Parameters
# ---------------------------------------------------------------------------- #
add_parameter          P_S_AXI_ADDR_WIDTH  INTEGER              4
set_parameter_property P_S_AXI_ADDR_WIDTH  DEFAULT_VALUE        4
set_parameter_property P_S_AXI_ADDR_WIDTH  ALLOWED_RANGES       {3:32}
set_parameter_property P_S_AXI_ADDR_WIDTH  DISPLAY_NAME         "AXI / APB Address Width"
set_parameter_property P_S_AXI_ADDR_WIDTH  ENABLED              true
set_parameter_property P_S_AXI_ADDR_WIDTH  UNITS                None
set_parameter_property P_S_AXI_ADDR_WIDTH  VISIBLE              false
set_parameter_property P_S_AXI_ADDR_WIDTH  AFFECTS_ELABORATION  true
set_parameter_property P_S_AXI_ADDR_WIDTH  HDL_PARAMETER        true

add_parameter          P_S_AXI_DATA_WIDTH  INTEGER              32
set_parameter_property P_S_AXI_DATA_WIDTH  DEFAULT_VALUE        32
set_parameter_property P_S_AXI_DATA_WIDTH  DISPLAY_NAME         "AXI / APB Data Width"
set_parameter_property P_S_AXI_DATA_WIDTH  ENABLED              false
set_parameter_property P_S_AXI_DATA_WIDTH  UNITS                None
set_parameter_property P_S_AXI_DATA_WIDTH  VISIBLE              false
set_parameter_property P_S_AXI_DATA_WIDTH  AFFECTS_ELABORATION  true
set_parameter_property P_S_AXI_DATA_WIDTH  HDL_PARAMETER        true

add_parameter          P_USE_ECC           INTEGER              1
set_parameter_property P_USE_ECC           DEFAULT_VALUE        1
set_parameter_property P_USE_ECC           DISPLAY_NAME         "Enable ECC"
set_parameter_property P_USE_ECC           DESCRIPTION          "And ECC encode and decode"
set_parameter_property P_USE_ECC           ALLOWED_RANGES       {0:1}
set_parameter_property P_USE_ECC           DISPLAY_HINT         "Boolean"
set_parameter_property P_USE_ECC           AFFECTS_ELABORATION  true
set_parameter_property P_USE_ECC           HDL_PARAMETER        true
set_parameter_property P_USE_ECC           VISIBLE              true


add_parameter          S0_BUS_TYPE         STRING               "AXI4-Lite"
set_parameter_property S0_BUS_TYPE         DEFAULT_VALUE        "AXI4-Lite"
set_parameter_property S0_BUS_TYPE         DISPLAY_NAME         "S0 Interface bus type"
set_parameter_property S0_BUS_TYPE         DESCRIPTION          "S0 Interface bus type"
set_parameter_property S0_BUS_TYPE         ALLOWED_RANGES       {"AXI4-Lite" "APB"}
set_parameter_property S0_BUS_TYPE         AFFECTS_ELABORATION  true
set_parameter_property S0_BUS_TYPE         HDL_PARAMETER        false
set_parameter_property S0_BUS_TYPE         VISIBLE              true
set_parameter_property S0_BUS_TYPE         ENABLED              true

add_parameter          P_S0_BUS_IS_AXI     INTEGER              1
set_parameter_property P_S0_BUS_IS_AXI     DEFAULT_VALUE        1
set_parameter_property P_S0_BUS_IS_AXI     ALLOWED_RANGES       {0:1}
set_parameter_property P_S0_BUS_IS_AXI     AFFECTS_ELABORATION  true
set_parameter_property P_S0_BUS_IS_AXI     HDL_PARAMETER        true
set_parameter_property P_S0_BUS_IS_AXI     VISIBLE              false
set_parameter_property P_S0_BUS_IS_AXI     ENABLED              true
set_parameter_property P_S0_BUS_IS_AXI     DERIVED              true

add_parameter          S1_BUS_TYPE         STRING               "AXI4-Lite"
set_parameter_property S1_BUS_TYPE         DEFAULT_VALUE        "AXI4-Lite"
set_parameter_property S1_BUS_TYPE         DISPLAY_NAME         "S1 Interface bus type"
set_parameter_property S1_BUS_TYPE         DESCRIPTION          "S1 Interface bus type"
set_parameter_property S1_BUS_TYPE         ALLOWED_RANGES       {"AXI4-Lite" "APB"}
set_parameter_property S1_BUS_TYPE         AFFECTS_ELABORATION  true
set_parameter_property S1_BUS_TYPE         HDL_PARAMETER        false
set_parameter_property S1_BUS_TYPE         VISIBLE              true
set_parameter_property S1_BUS_TYPE         ENABLED              true

add_parameter          P_S1_BUS_IS_AXI     INTEGER              1
set_parameter_property P_S1_BUS_IS_AXI     DEFAULT_VALUE        1
set_parameter_property P_S1_BUS_IS_AXI     ALLOWED_RANGES       {0:1}
set_parameter_property P_S1_BUS_IS_AXI     AFFECTS_ELABORATION  true
set_parameter_property P_S1_BUS_IS_AXI     HDL_PARAMETER        true
set_parameter_property P_S1_BUS_IS_AXI     VISIBLE              false
set_parameter_property P_S1_BUS_IS_AXI     ENABLED              true
set_parameter_property P_S1_BUS_IS_AXI     DERIVED              true

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
# ECC Error Conduit
# ---------------------------------------------------------------------------- #
add_interface            c_memory_fault  conduit           start
set_interface_property   c_memory_fault  ENABLED           true
add_interface_port       c_memory_fault  memory_fault_p    p              Output 1
add_interface_port       c_memory_fault  memory_fault_n    n              Output 1

# Conduit End from Safety to Shared Memory
add_interface            c_safety_mem    conduit          end
set_interface_property   c_safety_mem    ENABLED          true
add_interface_port       c_safety_mem    reset_safety_n   reset_safety_n  Input 1

# ---------------------------------------------------------------------------- #
# AXI4Lite interface 0
# ---------------------------------------------------------------------------- #
add_interface          s0_axi axi4lite             end
set_interface_property s0_axi associatedClock      s_axi_aclk
set_interface_property s0_axi associatedReset      s_axi_aresetn
set_interface_property s0_axi ENABLED              true
set_interface_property s0_axi EXPORT_OF            ""
set_interface_property s0_axi PORT_NAME_MAP        ""
set_interface_property s0_axi CMSIS_SVD_VARIABLES  ""
set_interface_property s0_axi SVD_ADDRESS_GROUP    ""

add_interface_port s0_axi s0_axi_awaddr  awaddr  Input   P_S_AXI_ADDR_WIDTH
add_interface_port s0_axi s0_axi_awvalid awvalid Input   1
add_interface_port s0_axi s0_axi_awready awready Output  1
add_interface_port s0_axi s0_axi_wdata   wdata   Input   P_S_AXI_DATA_WIDTH
add_interface_port s0_axi s0_axi_wready  wready  Output  1
add_interface_port s0_axi s0_axi_wvalid  wvalid  Input   1
add_interface_port s0_axi s0_axi_wstrb   wstrb   Input   (P_S_AXI_DATA_WIDTH/8)
add_interface_port s0_axi s0_axi_bresp   bresp   Output  2
add_interface_port s0_axi s0_axi_bvalid  bvalid  Output  1
add_interface_port s0_axi s0_axi_bready  bready  Input   1
add_interface_port s0_axi s0_axi_rdata   rdata   Output  P_S_AXI_DATA_WIDTH
add_interface_port s0_axi s0_axi_rresp   rresp   Output  2
add_interface_port s0_axi s0_axi_rvalid  rvalid  Output  1
add_interface_port s0_axi s0_axi_rready  rready  Input   1
add_interface_port s0_axi s0_axi_araddr  araddr  Input   P_S_AXI_ADDR_WIDTH
add_interface_port s0_axi s0_axi_arvalid arvalid Input   1
add_interface_port s0_axi s0_axi_arready arready Output  1
add_interface_port s0_axi s0_axi_awprot  awprot  Input   3
add_interface_port s0_axi s0_axi_arprot  arprot  Input   3

# ---------------------------------------------------------------------------- #
# APB interface 0
# ---------------------------------------------------------------------------- #
add_interface          s0_apb apb                  end
set_interface_property s0_apb associatedClock      s_axi_aclk
set_interface_property s0_apb associatedReset      s_axi_aresetn
set_interface_property s0_apb ENABLED              false
set_interface_property s0_apb EXPORT_OF            ""
set_interface_property s0_apb PORT_NAME_MAP        ""
set_interface_property s0_apb CMSIS_SVD_VARIABLES  ""
set_interface_property s0_apb SVD_ADDRESS_GROUP    ""

add_interface_port s0_apb s0_apb_paddr    paddr   Input   P_S_AXI_ADDR_WIDTH
add_interface_port s0_apb s0_apb_pwrite   pwrite  Input   1
add_interface_port s0_apb s0_apb_psel     psel    Input   1
add_interface_port s0_apb s0_apb_penable  penable Input   1
add_interface_port s0_apb s0_apb_pwdata   pwdata  Input   P_S_AXI_DATA_WIDTH
add_interface_port s0_apb s0_apb_prdata   prdata  Output  P_S_AXI_DATA_WIDTH
add_interface_port s0_apb s0_apb_pready   pready  Output  1

# ---------------------------------------------------------------------------- #
# AXI4Lite interface 1
# ---------------------------------------------------------------------------- #
add_interface          s1_axi axi4lite             end
set_interface_property s1_axi associatedClock      s_axi_aclk
set_interface_property s1_axi associatedReset      s_axi_aresetn
set_interface_property s1_axi ENABLED true
set_interface_property s1_axi EXPORT_OF            ""
set_interface_property s1_axi PORT_NAME_MAP        ""
set_interface_property s1_axi CMSIS_SVD_VARIABLES  ""
set_interface_property s1_axi SVD_ADDRESS_GROUP    ""

add_interface_port s1_axi s1_axi_awaddr  awaddr  Input   P_S_AXI_ADDR_WIDTH
add_interface_port s1_axi s1_axi_awvalid awvalid Input   1
add_interface_port s1_axi s1_axi_awready awready Output  1
add_interface_port s1_axi s1_axi_wdata   wdata   Input   P_S_AXI_DATA_WIDTH
add_interface_port s1_axi s1_axi_wready  wready  Output  1
add_interface_port s1_axi s1_axi_wvalid  wvalid  Input   1
add_interface_port s1_axi s1_axi_wstrb   wstrb   Input   (P_S_AXI_DATA_WIDTH/8)
add_interface_port s1_axi s1_axi_bresp   bresp   Output  2
add_interface_port s1_axi s1_axi_bvalid  bvalid  Output  1
add_interface_port s1_axi s1_axi_bready  bready  Input   1
add_interface_port s1_axi s1_axi_rdata   rdata   Output  P_S_AXI_DATA_WIDTH
add_interface_port s1_axi s1_axi_rresp   rresp   Output  2
add_interface_port s1_axi s1_axi_rvalid  rvalid  Output  1
add_interface_port s1_axi s1_axi_rready  rready  Input   1
add_interface_port s1_axi s1_axi_araddr  araddr  Input   P_S_AXI_ADDR_WIDTH
add_interface_port s1_axi s1_axi_arvalid arvalid Input   1
add_interface_port s1_axi s1_axi_arready arready Output  1
add_interface_port s1_axi s1_axi_awprot  awprot  Input   3
add_interface_port s1_axi s1_axi_arprot  arprot  Input   3

# ---------------------------------------------------------------------------- #
# APB interface 0
# ---------------------------------------------------------------------------- #
add_interface          s1_apb apb                  end
set_interface_property s1_apb associatedClock      s_axi_aclk
set_interface_property s1_apb associatedReset      s_axi_aresetn
set_interface_property s1_apb ENABLED              false
set_interface_property s1_apb EXPORT_OF            ""
set_interface_property s1_apb PORT_NAME_MAP        ""
set_interface_property s1_apb CMSIS_SVD_VARIABLES  ""
set_interface_property s1_apb SVD_ADDRESS_GROUP    ""

add_interface_port s1_apb s1_apb_paddr    paddr   Input   P_S_AXI_ADDR_WIDTH
add_interface_port s1_apb s1_apb_pwrite   pwrite  Input   1
add_interface_port s1_apb s1_apb_psel     psel    Input   1
add_interface_port s1_apb s1_apb_penable  penable Input   1
add_interface_port s1_apb s1_apb_pwdata   pwdata  Input   P_S_AXI_DATA_WIDTH
add_interface_port s1_apb s1_apb_prdata   prdata  Output  P_S_AXI_DATA_WIDTH
add_interface_port s1_apb s1_apb_pready   pready  Output  1

proc my_generate { entity } {

}

proc my_elab {} {

  if { [get_parameter_value S0_BUS_TYPE] == "AXI4-Lite"} {
    set_interface_property  s0_axi     ENABLED    true
    set_interface_property  s0_apb     ENABLED    false
    set_parameter_value     P_S0_BUS_IS_AXI 1

    add_hdl_instance             axil2apb_s0  intel_fpga_axil2apb
    set_instance_parameter_value axil2apb_s0 {P_S_AXI_ADDR_WIDTH} [get_parameter_value P_S_AXI_ADDR_WIDTH]
    set_instance_parameter_value axil2apb_s0 {P_S_AXI_DATA_WIDTH} [get_parameter_value P_S_AXI_DATA_WIDTH]
    set_instance_parameter_value axil2apb_s0 {P_WATCHDOG_EN}      {1}

  } else {
    set_interface_property  s0_axi     ENABLED    false
    set_interface_property  s0_apb     ENABLED    true
    set_parameter_value     P_S0_BUS_IS_AXI 0
  }

  if { [get_parameter_value S1_BUS_TYPE] == "AXI4-Lite"} {
    set_interface_property  s1_axi     ENABLED    true
    set_interface_property  s1_apb     ENABLED    false
    set_parameter_value     P_S1_BUS_IS_AXI 1

    add_hdl_instance             axil2apb_s1  intel_fpga_axil2apb
    set_instance_parameter_value axil2apb_s1 {P_S_AXI_ADDR_WIDTH} [get_parameter_value P_S_AXI_ADDR_WIDTH]
    set_instance_parameter_value axil2apb_s1 {P_S_AXI_DATA_WIDTH} [get_parameter_value P_S_AXI_DATA_WIDTH]
    set_instance_parameter_value axil2apb_s1 {P_WATCHDOG_EN}      {1}

  } else {
    set_interface_property  s1_axi     ENABLED    false
    set_interface_property  s1_apb     ENABLED    true
    set_parameter_value     P_S1_BUS_IS_AXI 0
  }

  # Add the ECC blocks if enabled
  if { [get_parameter_value P_USE_ECC] == 1} {
    add_hdl_instance             ecc_encoder altecc
    set_instance_parameter_value ecc_encoder {CBX_AUTO_BLACKBOX} {ALL}
    set_instance_parameter_value ecc_encoder {ERR_BYPASS}        {0}
    set_instance_parameter_value ecc_encoder {GUI_USE_ACLR}      {1}
    set_instance_parameter_value ecc_encoder {GUI_USE_CLKEN}     {1}
    set_instance_parameter_value ecc_encoder {GUI_USE_SYN_E}     {0}
    set_instance_parameter_value ecc_encoder {LPM_PIPELINE}      {1}
    set_instance_parameter_value ecc_encoder {MODULE_TYPE}       {ALTECC_ENCODER}
    set_instance_parameter_value ecc_encoder {WIDTH_CODEWORD}    {39}
    set_instance_parameter_value ecc_encoder {WIDTH_DATAWORD}    {32}
    # set_instance_property        ecc_encoder AUTO_EXPORT         true

    add_hdl_instance             ecc_decoder altecc
    set_instance_parameter_value ecc_decoder {CBX_AUTO_BLACKBOX} {ALL}
    set_instance_parameter_value ecc_decoder {ERR_BYPASS}        {0}
    set_instance_parameter_value ecc_decoder {GUI_USE_ACLR}      {1}
    set_instance_parameter_value ecc_decoder {GUI_USE_CLKEN}     {1}
    set_instance_parameter_value ecc_decoder {GUI_USE_SYN_E}     {1}
    set_instance_parameter_value ecc_decoder {LPM_PIPELINE}      {1}
    set_instance_parameter_value ecc_decoder {MODULE_TYPE}       {ALTECC_DECODER}
    set_instance_parameter_value ecc_decoder {WIDTH_CODEWORD}    {39}
    set_instance_parameter_value ecc_decoder {WIDTH_DATAWORD}    {32}
    # set_instance_property        ecc_decoder AUTO_EXPORT         true

    set_interface_property  c_memory_fault   ENABLED    true
    set_interface_property  c_safety_mem     ENABLED    true

  } else {

    set_interface_property  c_memory_fault   ENABLED    false
    set_interface_property  c_safety_mem     ENABLED    false

  }
}

proc my_validate {} {

}
