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

# # create script specific parameters and default values

# non user parameters, do not change (used for EMIF IP parameterization only)
# changes in the preset will NOT be reflected in the pin assignments
# This is for the DDR4 memory soldered to the board, hence cannot be changed from this preset.
# Allows the use of the memory though instantiating only an EMIF subsystem in the HPS
# port without the user needing to provide parameters in the board subsystem
set_shell_parameter PORT                        "hps"

# preset for use with HPS subsystem
set_shell_parameter DDR4_PRESET_HPS             "DDR4-1600L_800MHz_CL12_alloff_component_1CS_DDP_32Gb_2Gx16_EMIF"
set_shell_parameter DDR4_PRESET_HPS_FILE        "DDR4-1600L_800MHz_CL12_alloff_component_1CS_DDP_32Gb_2Gx16_EMIF.qprs"

# preset for use with EMIF subsystem
set_shell_parameter DDR4_PRESET_BANK_2B         "Custom Preset"
set_shell_parameter DDR4_PRESET_BANK_2B_FILE    "DDR4_MT40A2G16TBB_XDM_XWDI_ACPARITY_800MHZ.qprs"

set_shell_parameter DDR4_PRESET_BANK_3A         "Custom Preset"
set_shell_parameter DDR4_PRESET_BANK_3A_FILE    "DDR4_MT40A2G16TBB_XDM_XWDI_ACPARITY_800MHZ.qprs"

set_shell_parameter DDR4_PRESET_BANK_3B         "Custom Preset"
set_shell_parameter DDR4_PRESET_BANK_3B_FILE    "DDR4_MT40A2G16TBB_XDM_XWDI_ACPARITY_800MHZ.qprs"

# Internal parameter do not edit externally
set_shell_parameter INT_REF_CLK_FREQ            {100}


# define the procedures used by the create_subsystems_qsys.tcl script

proc pre_creation_step {} {
    transfer_files
    evaluate_terp
}

proc creation_step {} {
    create_board_subsystem
}

proc post_creation_step {} {
    edit_top_level_qsys
    add_auto_connections
    edit_top_v_file
}


# resolve interdependencies
proc derive_parameters {param_array} {
    upvar $param_array p_array

    # enable board HPS DDR interface if there is an HPS subsystem,
    # or an EMIF subsystem with the HPS port selected
    set_shell_parameter DRV_HPS_DDR_EN       "0"
    set_shell_parameter DRV_DDR4_PRESET_FILE    ""

    set_shell_parameter DRV_FPGA_DDR_EN         "0"

    set v_ddr_enabled_banks {}

    for {set id 0} {$id < $p_array(project,id)} {incr id} {

        # hps subsystem present
        if {$p_array($id,type) == "hps"} {
            lappend v_ddr_enabled_banks "HPS"
        }

        # EMIF subsystem(s) present
        if {$p_array($id,type) == "emif"} {
            set params $p_array($id,params)

            foreach v_pair ${params} {
                set v_name  [lindex ${v_pair} 0]
                set v_value [lindex ${v_pair} 1]
                set v_temp_array(${v_name}) ${v_value}
            }

            # check the port the EMIF requires
            if {[info exists v_temp_array(PORT)]} {
                lappend v_ddr_enabled_banks $v_temp_array(PORT)
            }
        }
    }

    # check for invalid enabled banks (HPS/BANK_3A)
    if {([lsearch ${v_ddr_enabled_banks} "HPS"] >= 0) && ([lsearch ${v_ddr_enabled_banks} "BANK_3A"] >= 0)} {
        send_message ERROR "board_create: cannot have HPS subsystem and \
                            EMIF subsystem targeting BANK_3A in the same project"
    }

    # check for duplicate enabled banks
    set v_unique_banks {}

    foreach v_bank ${v_ddr_enabled_banks} {
        if {[lsearch ${v_unique_banks} ${v_bank}] >= 0} {
            send_message ERROR "board_create: duplicate DDR bank selected (${v_bank})"
        } else {
            lappend v_unique_banks ${v_bank}
        }
    }

    set_shell_parameter DRV_DDR_ENABLED_BANKS ${v_ddr_enabled_banks}
}

# copy files from the shell install directory to the target project directory
proc transfer_files {} {
    set v_project_name          [get_shell_parameter PROJECT_NAME]
    set v_shell_design_root     [get_shell_parameter SHELL_DESIGN_ROOT]
    set v_project_path          [get_shell_parameter PROJECT_PATH]
    set v_instance_name         [get_shell_parameter INSTANCE_NAME]
    set v_ddr_preset_file       [get_shell_parameter DRV_DDR4_PRESET_FILE]
    set v_drv_ddr_enabled_banks [get_shell_parameter DRV_DDR_ENABLED_BANKS]
    set v_subsys_dir            "${v_shell_design_root}/board_subsystem"

    # copy Non-QPDS IP files
    file_copy   ${v_subsys_dir}/non_qpds_ip/intel_vip_reset_gen_block \
                ${v_project_path}/non_qpds_ip/shell

    file_copy   ${v_subsys_dir}/non_qpds_ip/board_subsystem.ipx \
                ${v_project_path}/non_qpds_ip/shell

    # copy Board variant files
    file_copy   ${v_subsys_dir}/boards/AGX_5E_Modular_Devkit/board_subsystem.qsf.terp \
                ${v_project_path}/quartus/shell/${v_instance_name}.qsf.terp

    file_copy   ${v_subsys_dir}/boards/AGX_5E_Modular_Devkit/board_subsystem.sdc.terp \
                ${v_project_path}/sdc/shell/${v_instance_name}.sdc.terp

    # copy Top level RTL files
    file_copy   ${v_subsys_dir}/boards/AGX_5E_Modular_Devkit/top.v.terp \
                ${v_project_path}/rtl/${v_project_name}.v.terp

    # copy DDR memory preset files
    set v_ddr_preset_files_copied {}

    foreach v_bank ${v_drv_ddr_enabled_banks} {
        if {[lsearch -exact ${v_ddr_preset_files_copied} ${v_bank}] >= 0} {
            continue
        }

        set v_ddr_preset_file [get_shell_parameter DDR4_PRESET_${v_bank}_FILE]

        file_copy   ${v_subsys_dir}/boards/AGX_5E_Modular_Devkit/${v_ddr_preset_file} \
                    ${v_project_path}/non_qpds_ip/shell/${v_ddr_preset_file}

        lappend v_ddr_preset_files_copied ${v_ddr_preset_file}
    }

    # speculatively include the JTAG constraints in case it is enabled
    file_copy   ${v_subsys_dir}/boards/AGX_5E_Modular_Devkit/jtag.sdc \
                ${v_project_path}/sdc/shell/jtag.sdc
}

# convert terp files to their native format
proc evaluate_terp {} {
    set v_project_name          [get_shell_parameter PROJECT_NAME]
    set v_project_path          [get_shell_parameter PROJECT_PATH]
    set v_instance_name         [get_shell_parameter INSTANCE_NAME]
    set v_drv_ddr_enabled_banks [get_shell_parameter DRV_DDR_ENABLED_BANKS]

    # evaluate files
    evaluate_terp_file  ${v_project_path}/quartus/shell/${v_instance_name}.qsf.terp \
                        [list ${v_project_name} ${v_drv_ddr_enabled_banks}] 0 1

    evaluate_terp_file  ${v_project_path}/sdc/shell/${v_instance_name}.sdc.terp \
                        [list ${v_project_name}] 0 1

    evaluate_terp_file  ${v_project_path}/rtl/${v_project_name}.v.terp \
                        [list ${v_project_name} ${v_instance_name}] 0 1
}

# create the subsystem
proc create_board_subsystem {} {
    set v_project_path  [get_shell_parameter PROJECT_PATH]
    set v_instance_name [get_shell_parameter INSTANCE_NAME]

    create_system ${v_instance_name}
    save_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    # Add Instances
    add_instance  board_clk_bridge          altera_clock_bridge
    add_instance  board_pb_reset_generator  intel_vip_reset_gen_block
    add_instance  board_init_generator      intel_user_rst_clkgate
    add_instance  board_init_reset_bridge   altera_reset_bridge
    add_instance  board_reset_controller    altera_reset_controller

    # Set Parameters
    # board_clk_bridge
    set_instance_parameter_value  board_clk_bridge          EXPLICIT_CLOCK_RATE     {100000000.0}
    set_instance_parameter_value  board_clk_bridge          NUM_CLOCK_OUTPUTS       2
    # board_pb_reset_generator
    set_instance_parameter_value  board_pb_reset_generator  CNTR_WIDTH              23
    # board_init_generator
    set_instance_parameter_value  board_init_generator      outputType              {Reset Interface}
    # board_init_reset_bridge
    set_instance_parameter_value  board_init_reset_bridge   NUM_RESET_OUTPUTS       {2}
    # board_reset_controller
    set_instance_parameter_value  board_reset_controller    NUM_RESET_INPUTS        {2}
    set_instance_parameter_value  board_reset_controller    MIN_RST_ASSERTION_TIME  {3}
    set_instance_parameter_value  board_reset_controller    OUTPUT_RESET_SYNC_EDGES {deassert}
    set_instance_parameter_value  board_reset_controller    SYNC_DEPTH              {2}
    set_instance_parameter_value  board_reset_controller    RESET_REQUEST_PRESENT   {0}
    set_instance_parameter_value  board_reset_controller    USE_RESET_REQUEST_INPUT {0}

    # Create Connections
    # board_clk_bridge
    add_connection board_clk_bridge.out_clk_1           board_pb_reset_generator.clk
    add_connection board_clk_bridge.out_clk_1           board_init_reset_bridge.clk
    add_connection board_clk_bridge.out_clk_1           board_reset_controller.clk
    # board_pb_reset_generator
    add_connection board_pb_reset_generator.reset       board_reset_controller.reset_in0
    # board_init_generator
    add_connection board_init_generator.ninit_done      board_init_reset_bridge.in_reset
    # board_init_reset_bridge
    add_connection board_init_reset_bridge.out_reset    board_reset_controller.reset_in1

    # Create Exports
    # board_clk_bridge
    add_interface             i_clk               clock         sink
    set_interface_property    i_clk               export_of     board_clk_bridge.in_clk
    add_interface             o_clk               clock         source
    set_interface_property    o_clk               export_of     board_clk_bridge.out_clk
    # board_pb_reset_generator
    add_interface             ia_reset_pb_n       reset         sink
    set_interface_property    ia_reset_pb_n       export_of     board_pb_reset_generator.pb_resetn
    # board_reset_controller
    add_interface             o_reset             reset         source
    set_interface_property    o_reset             export_of     board_reset_controller.reset_out
    # board_init_reset_bridge
    add_interface             o_rst_device_ready  reset         source
    set_interface_property    o_rst_device_ready  export_of     board_init_reset_bridge.out_reset_1

    # Optional Extras
    set v_user_led_to_avmm_en       [get_shell_parameter USER_LED_TO_AVMM_EN]
    set v_user_pb_to_avmm_en        [get_shell_parameter USER_PB_TO_AVMM_EN]

    # avmm bridge required due to multiple agents
    set v_avmm_num                  [expr ${v_user_led_to_avmm_en} + ${v_user_pb_to_avmm_en} ]

    if {${v_avmm_num} > 1} {
        set v_avmm_bridge_en 1
    } else {
        set v_avmm_bridge_en 0
    }

    # clk and rst bridges for board io
    if {${v_avmm_bridge_en}} {
        # Add Instances
        add_instance io_data_clk_bridge     altera_clock_bridge
        add_instance io_data_rst_bridge     altera_reset_bridge
        add_instance io_data_avmm_bridge    altera_avalon_mm_bridge

        # Set Parameters
        # io_data_clk_bridge
        set_instance_parameter_value  io_data_clk_bridge    NUM_CLOCK_OUTPUTS         1
        # io_data_rst_bridge
        set_instance_parameter_value  io_data_rst_bridge    NUM_RESET_OUTPUTS         1
        # io_data_avmm_bridge
        set_instance_parameter_value  io_data_avmm_bridge   SYNC_RESET                0
        set_instance_parameter_value  io_data_avmm_bridge   DATA_WIDTH                32
        set_instance_parameter_value  io_data_avmm_bridge   SYMBOL_WIDTH              8
        set_instance_parameter_value  io_data_avmm_bridge   ADDRESS_WIDTH             0
        set_instance_parameter_value  io_data_avmm_bridge   USE_AUTO_ADDRESS_WIDTH    1
        set_instance_parameter_value  io_data_avmm_bridge   ADDRESS_UNITS             SYMBOLS
        set_instance_parameter_value  io_data_avmm_bridge   MAX_BURST_SIZE            1
        set_instance_parameter_value  io_data_avmm_bridge   LINEWRAPBURSTS            0
        set_instance_parameter_value  io_data_avmm_bridge   MAX_PENDING_RESPONSES     4
        set_instance_parameter_value  io_data_avmm_bridge   PIPELINE_COMMAND          1
        set_instance_parameter_value  io_data_avmm_bridge   PIPELINE_RESPONSE         1
        set_instance_parameter_value  io_data_avmm_bridge   USE_RESPONSE              0

        # Create Connections
        # io_data_clk_bridge
        add_connection      io_data_clk_bridge.out_clk       io_data_avmm_bridge.clk
        add_connection      io_data_clk_bridge.out_clk       io_data_rst_bridge.clk
        # io_data_rst_bridge
        add_connection      io_data_rst_bridge.out_reset     io_data_avmm_bridge.reset

        # Create Exports
        # io_data_clk_bridge
        add_interface             i_clk_board_data    clock         sink
        set_interface_property    i_clk_board_data    export_of     io_data_clk_bridge.in_clk
        # io_data_rst_bridge
        add_interface             i_rst_board_data    reset         sink
        set_interface_property    i_rst_board_data    export_of     io_data_rst_bridge.in_reset
        # io_data_avmm_bridge
        add_interface             i_avmm_board_data   avalon        agent
        set_interface_property    i_avmm_board_data   export_of     io_data_avmm_bridge.s0
    }

    # LEDs
    if {${v_user_led_to_avmm_en}} {
        # Add Instances
        add_instance user_led_pio       altera_avalon_pio

        # Set Parameters
        set_instance_parameter_value    user_led_pio        WIDTH              8
        set_instance_parameter_value    user_led_pio        DIRECTION          Output
        set_instance_parameter_value    user_led_pio        resetValue         0x0
        set_instance_parameter_value    user_led_pio        bitModifyingOutReg 0

        # Create Exports
        add_interface                   o_leds              conduit         end
        set_interface_property          o_leds              export_of       user_led_pio.external_connection

        if {${v_avmm_bridge_en}} {
            # Create Connections
            # io_data_clk_bridge
            add_connection              io_data_clk_bridge.out_clk          user_led_pio.clk
            # io_data_rst_bridge
            add_connection              io_data_rst_bridge.out_reset        user_led_pio.reset
            # io_data_avmm_bridge
            add_connection              io_data_avmm_bridge.m0              user_led_pio.s1
        } else {
            # Create Exports
            # user_led_pio
            add_interface               i_clk_board_data    clock           sink
            set_interface_property      i_clk_board_data    export_of       user_led_pio.clk
            add_interface               i_rst_board_data    reset           sink
            set_interface_property      i_rst_board_data    export_of       user_led_pio.reset
            add_interface               i_avmm_board_data   avalon          agent
            set_interface_property      i_avmm_board_data   export_of       user_led_pio.s1
        }
    }

    # Push Buttons
    if {${v_user_pb_to_avmm_en}} {
        # Add Instances
        add_instance user_pb_pio        altera_avalon_pio

        # Set Parameters
        set_instance_parameter_value    user_pb_pio         WIDTH                8
        set_instance_parameter_value    user_pb_pio         DIRECTION            Input
        set_instance_parameter_value    user_pb_pio         captureEdge          0
        set_instance_parameter_value    user_pb_pio         generateIRQ          0
        set_instance_parameter_value    user_pb_pio         simDoTestBenchWiring 0

        # Create Exports
        add_interface                   ia_pb               conduit         end
        set_interface_property          ia_pb               export_of       user_pb_pio.external_connection

        if {${v_avmm_bridge_en}} {
            # Create Connections
            # io_data_clk_bridge
            add_connection              io_data_clk_bridge.out_clk          user_pb_pio.clk
            # io_data_rst_bridge
            add_connection              io_data_rst_bridge.out_reset        user_pb_pio.reset
            # io_data_avmm_bridge
            add_connection              io_data_avmm_bridge.m0              user_pb_pio.s1
        } else {
            # Create Exports
            # user_pb_pio
            add_interface               i_clk_board_data    clock           sink
            set_interface_property      i_clk_board_data    export_of       user_pb_pio.clk
            add_interface               i_rst_board_data    reset           sink
            set_interface_property      i_rst_board_data    export_of       user_pb_pio.reset
            add_interface               i_avmm_board_data   avalon          agent
            set_interface_property      i_avmm_board_data   export_of       user_pb_pio.s1
        }

    }

    sync_sysinfo_parameters
    save_system
}

proc edit_top_level_qsys {} {
    set v_project_name          [get_shell_parameter PROJECT_NAME]
    set v_project_path          [get_shell_parameter PROJECT_PATH]
    set v_instance_name         [get_shell_parameter INSTANCE_NAME]
    set v_user_led_to_avmm_en   [get_shell_parameter USER_LED_TO_AVMM_EN]
    set v_user_pb_to_avmm_en    [get_shell_parameter USER_PB_TO_AVMM_EN]

    load_system     ${v_project_path}/rtl/${v_project_name}_qsys.qsys

    add_instance    ${v_instance_name}  ${v_instance_name}

    # add interfaces to the boundary of the subsystem
    add_interface               ${v_instance_name}_i_clk            clock       sink
    set_interface_property      ${v_instance_name}_i_clk            export_of   ${v_instance_name}.i_clk

    add_interface               ${v_instance_name}_ia_reset_pb_n    reset       sink
    set_interface_property      ${v_instance_name}_ia_reset_pb_n    export_of   ${v_instance_name}.ia_reset_pb_n

    if {${v_user_led_to_avmm_en}} {
        add_interface               ${v_instance_name}_o_leds       conduit     end
        set_interface_property      ${v_instance_name}_o_leds       export_of   ${v_instance_name}.o_leds
    }

    if {${v_user_pb_to_avmm_en}} {
        add_interface               ${v_instance_name}_ia_pb        conduit     end
        set_interface_property      ${v_instance_name}_ia_pb        export_of   ${v_instance_name}.ia_pb
    }

    sync_sysinfo_parameters
    save_system
}

# enable a subset of subsystem interfaces to be available for auto-connection
# to other subsystems at the top qsys level
proc add_auto_connections {} {
    set v_instance_name           [get_shell_parameter INSTANCE_NAME]
    set v_user_led_to_avmm_en     [get_shell_parameter USER_LED_TO_AVMM_EN]
    set v_user_pb_to_avmm_en      [get_shell_parameter USER_PB_TO_AVMM_EN]

    set v_avmm_host               [get_shell_parameter AVMM_HOST]
    set v_avmm_output_en          [expr ${v_user_led_to_avmm_en} + ${v_user_pb_to_avmm_en}]

    add_auto_connection         ${v_instance_name}    o_clk                 ref_clk
    add_auto_connection         ${v_instance_name}    o_reset               board_rst

    add_auto_connection         ${v_instance_name}    o_rst_device_ready    device_ready_rst

    if {${v_avmm_output_en} > 0} {
        add_auto_connection     ${v_instance_name}      i_clk_board_data    100000000
        add_auto_connection     ${v_instance_name}      i_rst_board_data    100000000

        add_avmm_connections    i_avmm_board_data       ${v_avmm_host}
    }
}

# insert lines of code into the top level hdl file
proc edit_top_v_file {} {
    set v_instance_name             [get_shell_parameter INSTANCE_NAME]
    set v_user_led_to_avmm_en       [get_shell_parameter USER_LED_TO_AVMM_EN]
    set v_user_pb_to_avmm_en        [get_shell_parameter USER_PB_TO_AVMM_EN]
    set v_drv_ddr_enabled_banks     [get_shell_parameter DRV_DDR_ENABLED_BANKS]

    # add the EMIF interfaces
    foreach v_bank ${v_drv_ddr_enabled_banks} {
        if {${v_bank} == "BANK_2B"} {
            set v_dq_width    32
            set v_dqs_width   4
        } elseif {(${v_bank} == "BANK_3A") || (${v_bank} == "HPS") } {
            set v_dq_width    40
            set v_dqs_width   5
        } elseif {${v_bank} == "BANK_3B"} {
            set v_dq_width    40
            set v_dqs_width   5
        }

        set v_bank_lower    [string tolower ${v_bank}]
        set v_dq_width_max  [expr ${v_dq_width}-1]
        set v_dqs_width_max [expr ${v_dqs_width}-1]

        add_top_port_list input    ""                           "${v_bank_lower}_mem_pll_ref_clk"
        add_top_port_list input    ""                           "${v_bank_lower}_mem_oct_rzqin"
        add_top_port_list output   "\[ 0:0\]"                   "${v_bank_lower}_mem_ck"
        add_top_port_list output   "\[ 0:0\]"                   "${v_bank_lower}_mem_ck_n"
        add_top_port_list output   "\[16:0\]"                   "${v_bank_lower}_mem_a"
        add_top_port_list output   ""                           "${v_bank_lower}_mem_act_n"
        add_top_port_list output   "\[ 1:0\]"                   "${v_bank_lower}_mem_ba"
        add_top_port_list output   "\[ 1:0\]"                   "${v_bank_lower}_mem_bg"
        add_top_port_list output   "\[ 0:0\]"                   "${v_bank_lower}_mem_cke"
        add_top_port_list output   "\[ 0:0\]"                   "${v_bank_lower}_mem_cs_n"
        add_top_port_list output   "\[ 0:0\]"                   "${v_bank_lower}_mem_odt"
        add_top_port_list output   ""                           "${v_bank_lower}_mem_reset_n"
        add_top_port_list output   ""                           "${v_bank_lower}_mem_par"
        add_top_port_list input    ""                           "${v_bank_lower}_mem_alert_n"
        add_top_port_list inout    "\[${v_dq_width_max}:0\]"    "${v_bank_lower}_mem_dq"
        add_top_port_list inout    "\[${v_dqs_width_max}:0\]"   "${v_bank_lower}_mem_dqs"
        add_top_port_list inout    "\[${v_dqs_width_max}:0\]"   "${v_bank_lower}_mem_dqs_n"
        add_top_port_list inout    "\[${v_dqs_width_max}:0\]"   "${v_bank_lower}_mem_dbi_n"
    }

    if {${v_user_led_to_avmm_en}} {
        add_declaration_list wire   "\[3:0\]"                           "user_led_export"
        add_assignments_list        "user_led"                          "~user_led_export\[3:0\]"
        add_qsys_inst_exports_list  "${v_instance_name}_o_leds_export"  "user_led_export"
    }

    if {${v_user_pb_to_avmm_en}} {
        add_qsys_inst_exports_list  "${v_instance_name}_ia_pb_export"   "~user_pb_n"
    }
}

