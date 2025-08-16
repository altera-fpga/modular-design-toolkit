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
# Module: emif_shim
#
# Description: _hw.tcl file for the emif shim
#
## *********************************************************************************

package require -exact qsys 23.4

# set module properties
set_module_property   NAME                          emif_shim
set_module_property   DESCRIPTION                   "EMIF Shim to default all interface signals"
set_module_property   DISPLAY_NAME                  "EMIF shim"
set_module_property   VERSION                       99.0
set_module_property   EDITABLE                      false
set_module_property   INSTANTIATE_IN_SYSTEM_MODULE  true
set_module_property   INTERNAL                      false
set_module_property   ELABORATION_CALLBACK          my_elaboration_callback

add_parameter           ADDR_W           INTEGER                 33
set_parameter_property  ADDR_W           DISPLAY_NAME            "Address width"
set_parameter_property  ADDR_W           ALLOWED_RANGES          20:35
set_parameter_property  ADDR_W           HDL_PARAMETER           true
set_parameter_property  ADDR_W           AFFECTS_ELABORATION     true

# Procedures to generate interfaces
proc add_clk { v_name } {
    add_interface             ${v_name}   clock       end
    set_interface_property    ${v_name}   clockRate   0
    set_interface_property    ${v_name}   ENABLED     true
    add_interface_port        ${v_name}   ${v_name}   clk   Input   1
}

proc add_rst { v_name v_clk } {
    add_interface           ${v_name}   reset             end
    set_interface_property  ${v_name}   associatedClock   ${v_clk}
    set_interface_property  ${v_name}   synchronousEdges  DEASSERT
    set_interface_property  ${v_name}   ENABLED           true
    add_interface_port      ${v_name}   ${v_name}         reset   Input   1
}

proc add_axi4_interface { v_prefix v_clk v_rst {v_dir slave} {v_address_width 33} }  {
    if {${v_dir} == "master"} {
        set v_master_out  "Output"
        set v_master_in   "Input"
        set v_direction   "start"
    } else {
        set v_master_out  "Input"
        set v_master_in   "Output"
        set v_direction   "end"
    }

    add_interface           ${v_prefix}   axi4              ${v_direction}
    set_interface_property  ${v_prefix}   associatedClock   ${v_clk}
    set_interface_property  ${v_prefix}   associatedReset   ${v_rst}

    if {${v_dir} == "master"} {
        set_interface_property  ${v_prefix}   readIssuingCapability          64
        set_interface_property  ${v_prefix}   writeIssuingCapability         64
        set_interface_property  ${v_prefix}   combinedIssuingCapability      64
        set_interface_property  ${v_prefix}   issuesFIXEDBursts              0
        set_interface_property  ${v_prefix}   issuesWRAPBursts               0
    } else {
        set_interface_property  ${v_prefix}   readAcceptanceCapability       64
        set_interface_property  ${v_prefix}   writeAcceptanceCapability      64
        set_interface_property  ${v_prefix}   combinedAcceptanceCapability   64
    }

    set_interface_property  ${v_prefix}   ENABLED               true
    set_interface_property  ${v_prefix}   EXPORT_OF             ""
    set_interface_property  ${v_prefix}   PORT_NAME_MAP         ""
    set_interface_property  ${v_prefix}   CMSIS_SVD_VARIABLES   ""
    set_interface_property  ${v_prefix}   SVD_ADDRESS_GROUP     ""

    add_interface_port  ${v_prefix}   ${v_prefix}_awaddr    awaddr    ${v_master_out}   ${v_address_width}
    add_interface_port  ${v_prefix}   ${v_prefix}_awburst   awburst   ${v_master_out}   2
    add_interface_port  ${v_prefix}   ${v_prefix}_awid      awid      ${v_master_out}   7
    add_interface_port  ${v_prefix}   ${v_prefix}_awlen     awlen     ${v_master_out}   8
    add_interface_port  ${v_prefix}   ${v_prefix}_awlock    awlock    ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_awqos     awqos     ${v_master_out}   4
    add_interface_port  ${v_prefix}   ${v_prefix}_awsize    awsize    ${v_master_out}   3
    add_interface_port  ${v_prefix}   ${v_prefix}_awvalid   awvalid   ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_awuser    awuser    ${v_master_out}   4
    add_interface_port  ${v_prefix}   ${v_prefix}_awprot    awprot    ${v_master_out}   3
    add_interface_port  ${v_prefix}   ${v_prefix}_awready   awready   ${v_master_in}    1

    add_interface_port  ${v_prefix}   ${v_prefix}_araddr    araddr    ${v_master_out}   ${v_address_width}
    add_interface_port  ${v_prefix}   ${v_prefix}_arburst   arburst   ${v_master_out}   2
    add_interface_port  ${v_prefix}   ${v_prefix}_arid      arid      ${v_master_out}   7
    add_interface_port  ${v_prefix}   ${v_prefix}_arlen     arlen     ${v_master_out}   8
    add_interface_port  ${v_prefix}   ${v_prefix}_arlock    arlock    ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_arqos     arqos     ${v_master_out}   4
    add_interface_port  ${v_prefix}   ${v_prefix}_arsize    arsize    ${v_master_out}   3
    add_interface_port  ${v_prefix}   ${v_prefix}_arvalid   arvalid   ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_aruser    aruser    ${v_master_out}   4
    add_interface_port  ${v_prefix}   ${v_prefix}_arprot    arprot    ${v_master_out}   3
    add_interface_port  ${v_prefix}   ${v_prefix}_arready   arready   ${v_master_in}    1

    add_interface_port  ${v_prefix}   ${v_prefix}_bready    bready    ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_bid       bid       ${v_master_in}    7
    add_interface_port  ${v_prefix}   ${v_prefix}_bresp     bresp     ${v_master_in}    2
    add_interface_port  ${v_prefix}   ${v_prefix}_bvalid    bvalid    ${v_master_in}    1

    add_interface_port  ${v_prefix}   ${v_prefix}_rready    rready    ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_ruser     ruser     ${v_master_in}    64
    add_interface_port  ${v_prefix}   ${v_prefix}_rid       rid       ${v_master_in}    7
    add_interface_port  ${v_prefix}   ${v_prefix}_rlast     rlast     ${v_master_in}    1
    add_interface_port  ${v_prefix}   ${v_prefix}_rresp     rresp     ${v_master_in}    2
    add_interface_port  ${v_prefix}   ${v_prefix}_rvalid    rvalid    ${v_master_in}    1
    add_interface_port  ${v_prefix}   ${v_prefix}_rdata     rdata     ${v_master_in}    256

    add_interface_port  ${v_prefix}   ${v_prefix}_wuser     wuser     ${v_master_out}   64
    add_interface_port  ${v_prefix}   ${v_prefix}_wdata     wdata     ${v_master_out}   256
    add_interface_port  ${v_prefix}   ${v_prefix}_wstrb     wstrb     ${v_master_out}   32
    add_interface_port  ${v_prefix}   ${v_prefix}_wlast     wlast     ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_wvalid    wvalid    ${v_master_out}   1
    add_interface_port  ${v_prefix}   ${v_prefix}_wready    wready    ${v_master_in}    1
}

# add file sets
add_fileset          QUARTUS_SYNTH          QUARTUS_SYNTH         ""    ""
set_fileset_property QUARTUS_SYNTH          TOP_LEVEL             emif_shim

add_fileset_file     emif_shim.sv          SYSTEM_VERILOG    PATH       emif_shim.sv         TOP_LEVEL_FILE
add_fileset_file     emif_shim_skid.sv     SYSTEM_VERILOG    PATH       emif_shim_skid.sv

proc my_elaboration_callback {} {
    # add interfaces

    set v_address_width    [ get_parameter_value ADDR_W ]

    add_clk   axi_clk
    add_rst   axi_reset   axi_clk

    add_axi4_interface  s_axi   axi_clk   axi_reset   slave  ${v_address_width}
    add_axi4_interface  m_axi   axi_clk   axi_reset   master ${v_address_width}
}
