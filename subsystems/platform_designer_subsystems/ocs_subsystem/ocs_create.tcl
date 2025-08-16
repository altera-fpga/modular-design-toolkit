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

# create script specific parameters and default values
set_shell_parameter AVMM_HOST     {{AUTO X}}
set_shell_parameter HPS_AXI_CLK   {100000000}


# define the procedures used by the create_subsystems_qsys.tcl script
proc pre_creation_step {} {
    transfer_files
}

proc creation_step {} {
    create_ocs_subsystem
}

proc post_creation_step {} {
    edit_top_level_qsys
    add_auto_connections
}


# copy files from the shell install directory to the target project directory
proc transfer_files {} {
    set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]
    set v_project_path      [get_shell_parameter PROJECT_PATH]
    set v_subsys_dir        "${v_shell_design_root}/ocs_subsystem"

    file_copy   ${v_subsys_dir}/non_qpds_ip/intel_offset_capability         ${v_project_path}/non_qpds_ip/shell
    file_copy   ${v_subsys_dir}/non_qpds_ip/intel_offset_capability.ipx     ${v_project_path}/non_qpds_ip/shell
}


# create the ocs subsystem, add the required IP, parameterize it as appropriate,
# add internal connections, and add interfaces to the boundary of the subsystem
proc create_ocs_subsystem {} {
    set v_project_path  [get_shell_parameter PROJECT_PATH]
    set v_instance_name [get_shell_parameter INSTANCE_NAME]
    set v_hps_axi_clk   [get_shell_parameter HPS_AXI_CLK]

    create_system ${v_instance_name}
    save_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    ############################
    #### Add Instances      ####
    ############################

    add_instance  hps_clk_bridge                      altera_clock_bridge
    add_instance  hps_rst_bridge                      altera_reset_bridge
    add_instance  hps_avmm_bridge                     altera_avalon_mm_bridge
    add_instance  hps_intel_offset_capability_auto    intel_offset_capability
    add_instance  hps_intel_offset_capability_manual  intel_offset_capability

    ############################
    #### Set Parameters     ####
    ############################

    set_instance_parameter_value      hps_clk_bridge        EXPLICIT_CLOCK_RATE     ${v_hps_axi_clk}
    set_instance_parameter_value      hps_clk_bridge        NUM_CLOCK_OUTPUTS       {1}

    set_instance_parameter_value      hps_rst_bridge        ACTIVE_LOW_RESET        {0}
    set_instance_parameter_value      hps_rst_bridge        NUM_RESET_OUTPUTS       {1}
    set_instance_parameter_value      hps_rst_bridge        SYNCHRONOUS_EDGES       {deassert}
    set_instance_parameter_value      hps_rst_bridge        SYNC_RESET              {0}
    set_instance_parameter_value      hps_rst_bridge        USE_RESET_REQUEST       {0}

    set_instance_parameter_value      hps_avmm_bridge       ADDRESS_UNITS           {SYMBOLS}
    set_instance_parameter_value      hps_avmm_bridge       ADDRESS_WIDTH           {10}
    set_instance_parameter_value      hps_avmm_bridge       DATA_WIDTH              {32}
    set_instance_parameter_value      hps_avmm_bridge       LINEWRAPBURSTS          {0}
    set_instance_parameter_value      hps_avmm_bridge       MAX_BURST_SIZE          {1}
    set_instance_parameter_value      hps_avmm_bridge       MAX_PENDING_RESPONSES   {4}
    set_instance_parameter_value      hps_avmm_bridge       MAX_PENDING_WRITES      {0}
    set_instance_parameter_value      hps_avmm_bridge       PIPELINE_COMMAND        {1}
    set_instance_parameter_value      hps_avmm_bridge       PIPELINE_RESPONSE       {1}
    set_instance_parameter_value      hps_avmm_bridge       SYMBOL_WIDTH            {8}
    set_instance_parameter_value      hps_avmm_bridge       SYNC_RESET              {0}
    set_instance_parameter_value      hps_avmm_bridge       USE_AUTO_ADDRESS_WIDTH  {1}
    set_instance_parameter_value      hps_avmm_bridge       USE_RESPONSE            {0}
    set_instance_parameter_value      hps_avmm_bridge       USE_WRITERESPONSE       {0}

    # Auto Cap ID
    set_instance_parameter_value      hps_intel_offset_capability_auto    C_AUTO              {1}
    set_instance_parameter_value      hps_intel_offset_capability_auto    C_BASEADDR          {0x0000}
    set_instance_parameter_value      hps_intel_offset_capability_auto    C_NUM_CAPS          {1}
    set_instance_parameter_value      hps_intel_offset_capability_auto    C_NEXT              {8192}

    # Manual Cap ID - Original Instance in the script
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_AUTO              {0}
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_BASEADDR          {0x2000}
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_NUM_CAPS          {1}
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_NEXT              {0}

    set_instance_parameter_value      hps_intel_offset_capability_manual  C_CAP0_BASE         {0}
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_CAP0_SIZE         {0}
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_CAP0_TYPE         {0}
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_CAP0_VERSION      {0}
    set_instance_parameter_value      hps_intel_offset_capability_manual  C_CAP0_ID_COMPONENT {0}

    ############################
    #### Create Connections ####
    ############################

    add_connection      hps_clk_bridge.out_clk      hps_rst_bridge.clk
    add_connection      hps_clk_bridge.out_clk      hps_avmm_bridge.clk
    add_connection      hps_clk_bridge.out_clk      hps_intel_offset_capability_auto.av_mm_control_agent_clock
    add_connection      hps_clk_bridge.out_clk      hps_intel_offset_capability_manual.av_mm_control_agent_clock

    add_connection      hps_rst_bridge.out_reset    hps_avmm_bridge.reset
    add_connection      hps_rst_bridge.out_reset    hps_intel_offset_capability_auto.av_mm_control_agent_reset
    add_connection      hps_rst_bridge.out_reset    hps_intel_offset_capability_manual.av_mm_control_agent_reset

    add_connection      hps_avmm_bridge.m0          hps_intel_offset_capability_auto.av_mm_control_agent
    add_connection      hps_avmm_bridge.m0          hps_intel_offset_capability_manual.av_mm_control_agent

    ##########################
    ##### Create Exports #####
    ##########################

    add_interface             i_hps_clk             clock       sink
    set_interface_property    i_hps_clk             EXPORT_OF   hps_clk_bridge.in_clk

    add_interface             i_hps_rst             reset       sink
    set_interface_property    i_hps_rst             EXPORT_OF   hps_rst_bridge.in_reset

    add_interface             i_hps_avmm_agent      avalon      agent
    set_interface_property    i_hps_avmm_agent      export_of   hps_avmm_bridge.s0

    #################################
    ##### Assign Base Addresses #####
    #################################

    # note: this assumes that the word address width of the roms are 11bit
    #       offset is configured by the hps avmm bridge
    set_connection_parameter_value    hps_avmm_bridge.m0/hps_intel_offset_capability_auto.av_mm_control_agent \
                                                                                        baseAddress {0x0000}
    set_connection_parameter_value    hps_avmm_bridge.m0/hps_intel_offset_capability_manual.av_mm_control_agent \
                                                                                        baseAddress {0x2000}

    lock_avalon_base_address    hps_intel_offset_capability_auto.av_mm_control_agent
    lock_avalon_base_address    hps_intel_offset_capability_manual.av_mm_control_agent

    #############################
    ##### Sync / Validation #####
    #############################

    sync_sysinfo_parameters
    save_system
}

# insert the ocs subsystem into the top level qsys system, and add interfaces
# to the boundary of the top level qsys system
proc edit_top_level_qsys {} {
    set v_project_name    [get_shell_parameter PROJECT_NAME]
    set v_project_path    [get_shell_parameter PROJECT_PATH]
    set v_instance_name   [get_shell_parameter INSTANCE_NAME]

    load_system   ${v_project_path}/rtl/${v_project_name}_qsys.qsys

    add_instance  ${v_instance_name}  ${v_instance_name}

    sync_sysinfo_parameters
    save_system
}

# enable a subset of subsystem interfaces to be available for auto-connection
# to other subsystems at the top qsys level
proc add_auto_connections {} {
    set v_instance_name   [get_shell_parameter INSTANCE_NAME]
    set v_avmm_host       [get_shell_parameter AVMM_HOST]
    set v_hps_axi_clk     [get_shell_parameter HPS_AXI_CLK]

    add_auto_connection   ${v_instance_name}  i_hps_clk ${v_hps_axi_clk}
    add_auto_connection   ${v_instance_name}  i_hps_rst ${v_hps_axi_clk}

    add_avmm_connections  i_hps_avmm_agent    ${v_avmm_host}
}
