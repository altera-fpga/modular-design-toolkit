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

# use command "jtag_debug_reset_system <service-path>"" in system-console
set_shell_parameter REMOTE_RESET_EN "0"
set_shell_parameter NUM_GEN_CLOCKS "0"

for {set v_i 0} {${v_i} < 10} {incr v_i} {
    set_shell_parameter GEN_CLK${v_i}_NAME        "clk_${v_i}"
    set_shell_parameter GEN_CLK${v_i}_FREQ        "0.0"
    set_shell_parameter GEN_CLK${v_i}_PS_UNITS    "ps"
    set_shell_parameter GEN_CLK${v_i}_PHASE_SHIFT "0"
    set_shell_parameter GEN_CLK${v_i}_DUTY_CYCLE  "50.0"
}

set_shell_parameter EXPORT_TO_TOP       "0"
set_shell_parameter RESET_MIN_LENGTH    "10"
# Agilex only
set_shell_parameter IO_BANK_PLL         "0"


# resolve interdependencies
proc derive_parameters {param_array} {
    upvar $param_array p_array

    # get the input reference frequency from the board subsystem
    set v_drv_ref_clk_freq 0

    for {set id 0} {$id < $p_array(project,id)} {incr id} {

        if {$p_array($id,type) == "board"} {

            set params $p_array($id,params)

            foreach v_pair ${params} {
                set v_name  [lindex ${v_pair} 0]
                set v_value [lindex ${v_pair} 1]
                set v_temp_array(${v_name}) ${v_value}
            }

            if {[info exists v_temp_array(INT_REF_CLK_FREQ)]} {
                set v_drv_ref_clk_freq $v_temp_array(INT_REF_CLK_FREQ)
                break
            }
        }
    }

    if {${v_drv_ref_clk_freq} == 0} {
        send_message ERROR "could not find reference clock frequency (INT_REF_CLK_FREQ) from the board subsystem"
    }

    set_shell_parameter DRV_REF_CLK_FREQ    ${v_drv_ref_clk_freq}
    set_shell_parameter DRV_REF_CLK_FREQ_HZ [expr int(${v_drv_ref_clk_freq} * 1000000)]

    set v_io_bank_pll [get_shell_parameter IO_BANK_PLL]

    if {${v_io_bank_pll}} {
        set_shell_parameter DRV_PLL_LOCATION_TYPE     "I/O Bank"
        set_shell_parameter DRV_PLL_BANDWIDTH_PRESET  "Low"
    } else {
        set_shell_parameter DRV_PLL_LOCATION_TYPE     "Fabric-Feeding"
        set_shell_parameter DRV_PLL_BANDWIDTH_PRESET  "Medium"
    }

    set v_family          [get_shell_parameter FAMILY]
    set v_num_gen_clocks  [get_shell_parameter NUM_GEN_CLOCKS]

    # get the maximum number of generated clocks for each PLL (depends on device family)
    if {(${v_family} == "Agilex") || (${v_family} == "Agilex 7")} {
        set v_drv_max_iopll_clks 3
    } else {
        set v_drv_max_iopll_clks 8
    }

    set v_drv_num_ioplls [expr 1 + (${v_num_gen_clocks} - 1) / ${v_drv_max_iopll_clks}]

    set_shell_parameter DRV_MAX_IOPLL_CLKS  ${v_drv_max_iopll_clks}
    set_shell_parameter DRV_NUM_IOPLLS      ${v_drv_num_ioplls}
}


# define the procedures used by the create_subsystems_qsys.tcl script

proc pre_creation_step {} {
    transfer_files
}

proc creation_step {} {
    create_clock_subsystem
}

proc post_creation_step {} {
    edit_top_level_qsys
    add_auto_connections
    edit_top_v_file
}


# copy files from the shell install directory to the target project directory
proc transfer_files {} {
    set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]
    set v_project_path      [get_shell_parameter PROJECT_PATH]
    set v_subsys_dir        "${v_shell_design_root}/clock_subsystem"

    file_copy ${v_subsys_dir}/non_qpds_ip/intel_iopll_locked_shim           ${v_project_path}/non_qpds_ip/shell
    file_copy ${v_subsys_dir}/non_qpds_ip/intel_issp_reset_shim             ${v_project_path}/non_qpds_ip/shell
    file_copy ${v_subsys_dir}/non_qpds_ip/intel_vip_reset_sync_block        ${v_project_path}/non_qpds_ip/shell
    file_copy ${v_subsys_dir}/non_qpds_ip/intel_vvp_reset_extend            ${v_project_path}/non_qpds_ip/shell
    file_copy ${v_subsys_dir}/non_qpds_ip/clock_subsystem.ipx               ${v_project_path}/non_qpds_ip/shell
}


# create the clock subsystem, add the required IP, parameterize it as appropriate,
# add internal connections, and add interfaces to the boundary of the subsystem
proc create_clock_subsystem {} {
    set v_project_path              [get_shell_parameter PROJECT_PATH]
    set v_instance_name             [get_shell_parameter INSTANCE_NAME]
    set v_family                    [get_shell_parameter FAMILY]

    set v_reset_min_length          [get_shell_parameter RESET_MIN_LENGTH]
    set v_num_gen_clocks            [get_shell_parameter NUM_GEN_CLOCKS]
    set v_export_to_top             [get_shell_parameter EXPORT_TO_TOP]

    set v_drv_ref_clk_freq          [get_shell_parameter DRV_REF_CLK_FREQ]
    set v_drv_ref_clk_freq_hz       [get_shell_parameter DRV_REF_CLK_FREQ_HZ]
    set v_drv_max_iopll_clks        [get_shell_parameter DRV_MAX_IOPLL_CLKS]
    set v_drv_num_ioplls            [get_shell_parameter DRV_NUM_IOPLLS]

    set v_drv_pll_bandwidth_preset  [get_shell_parameter DRV_PLL_BANDWIDTH_PRESET]

    create_system ${v_instance_name}
    save_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    # the clock subsystem consists of 5 layers:
    #
    # - input layer
    #   - the reference clock (typically 100MHz from the board subsystem)
    #   - the input reset (typically a push button from the board subsystem)
    #   - optional remote reset source (JTAG master reset - via system_console "jtag_debug_reset_system $jd_path")
    #
    # - generation layer
    #   - PLLs required to create the requested clocks
    #   - PLL lock to reset
    #
    # - iopll reset sync layer
    #   - PLL locked interfaces combined to single reset
    #   - reset extended to minimum length
    #
    # - local reset sync layer
    #   - extended reset is synced to each clock domain
    #
    # - output layer
    #   - clocks and resets exported to top level
    #   - optional bridges to export clock / reset to top.v


    #===============================================================================================
    # input layer

    set v_remote_reset_en       [get_shell_parameter REMOTE_RESET_EN]

    # Add Instances
    add_instance input_clk_bridge   altera_clock_bridge
    add_instance input_rst_bridge   altera_reset_bridge
    add_instance input_rst_ctrl     altera_reset_controller

    # Set Parameters
    # input_clk_bridge
    set_instance_parameter_value  input_clk_bridge  EXPLICIT_CLOCK_RATE         ${v_drv_ref_clk_freq_hz}
    set_instance_parameter_value  input_clk_bridge  NUM_CLOCK_OUTPUTS           1
    # input_rst_bridge
    set_instance_parameter_value  input_rst_bridge  ACTIVE_LOW_RESET            0
    set_instance_parameter_value  input_rst_bridge  SYNCHRONOUS_EDGES           none
    set_instance_parameter_value  input_rst_bridge  NUM_RESET_OUTPUTS           1
    set_instance_parameter_value  input_rst_bridge  USE_RESET_REQUEST           0
    set_instance_parameter_value  input_rst_bridge  SYNC_RESET                  0
    # input_rst_ctrl
    set_instance_parameter_value  input_rst_ctrl    NUM_RESET_INPUTS            [expr {1 + ${v_remote_reset_en}}]
    set_instance_parameter_value  input_rst_ctrl    MIN_RST_ASSERTION_TIME      {3}
    set_instance_parameter_value  input_rst_ctrl    OUTPUT_RESET_SYNC_EDGES     {deassert}
    set_instance_parameter_value  input_rst_ctrl    SYNC_DEPTH                  {2}
    set_instance_parameter_value  input_rst_ctrl    RESET_REQUEST_PRESENT       {0}
    set_instance_parameter_value  input_rst_ctrl    USE_RESET_REQUEST_INPUT     {0}

    # Create Connections
    # input_clk_bridge
    add_connection input_clk_bridge.out_clk   input_rst_ctrl.clk
    # input_rst_bridge
    add_connection input_rst_bridge.out_reset input_rst_ctrl.reset_in0

    # Create Exports
    # input_clk_bridge
    add_interface          i_ref_clk        clock       sink
    set_interface_property i_ref_clk        export_of   input_clk_bridge.in_clk
    # input_rst_bridge
    add_interface          ia_board_reset   reset       sink
    set_interface_property ia_board_reset   export_of   input_rst_bridge.in_reset

    # add optional JTAG master for remote reset
    if {${v_remote_reset_en}} {
        # Add Instances
        add_instance  input_jtag_reset  altera_jtag_avalon_master

        # Create Connections
        # input_clk_bridge
        add_connection input_clk_bridge.out_clk       input_jtag_reset.clk
        # input_rst_bridge
        add_connection input_rst_bridge.out_reset     input_jtag_reset.clk_reset
        # input_jtag_reset
        add_connection input_jtag_reset.master_reset  input_rst_ctrl.reset_in1
    }


    #===============================================================================================
    # generation layer

    for {set v_i 0} {${v_i} < ${v_num_gen_clocks}} {incr v_i} {
        set v_pll_index         [expr ${v_i} / ${v_drv_max_iopll_clks}]
        set v_pll_output_index  [expr ${v_i} % ${v_drv_max_iopll_clks}]

        # if current clock is the first output of the PLL, setup the PLL instance
        if {${v_pll_output_index} == 0} {
            # calculate the number of clock outputs required from the PLL instance
            if {${v_num_gen_clocks} <= [expr (${v_pll_index} + 1) * ${v_drv_max_iopll_clks}]} {
                set v_gui_number_of_clocks [expr ${v_num_gen_clocks} - ${v_pll_index} * ${v_drv_max_iopll_clks}]
            } else {
                set v_gui_number_of_clocks ${v_drv_max_iopll_clks}
            }

            # Add Instance
            add_instance  iopll_${v_pll_index}              altera_iopll
            add_instance  iopll_locked_shim_${v_pll_index}  intel_iopll_locked_shim

            # Set Parameters
            # PLL tab
            set_instance_parameter_value  iopll_${v_pll_index}  gui_reference_clock_frequency ${v_drv_ref_clk_freq}
            set_instance_parameter_value  iopll_${v_pll_index}  gui_use_locked                1
            set_instance_parameter_value  iopll_${v_pll_index}  gui_en_adv_params             0
            set_instance_parameter_value  iopll_${v_pll_index}  gui_operation_mode            direct
            set_instance_parameter_value  iopll_${v_pll_index}  gui_number_of_clocks          ${v_gui_number_of_clocks}
            set_instance_parameter_value  iopll_${v_pll_index}  gui_fix_vco_frequency         0
            set_instance_parameter_value  iopll_${v_pll_index}  gui_clock_name_global         0
            set_instance_parameter_value  iopll_${v_pll_index}  gui_clock_name_instantiation  0

            # Settings tab (unused/default parameters commented out)
            set_instance_parameter_value  iopll_${v_pll_index}  gui_pll_bandwidth_preset  ${v_drv_pll_bandwidth_preset}
            set_instance_parameter_value  iopll_${v_pll_index}  gui_pll_auto_reset        0
            set_instance_parameter_value  iopll_${v_pll_index}  gui_refclk_switch         0

            # setting the Agilex only parameters
            if {(${v_family} == "Agilex") || (${v_family} == "Agilex 7")} {
                set v_drv_pll_location_type     [get_shell_parameter DRV_PLL_LOCATION_TYPE]

                set_instance_parameter_value  iopll_${v_pll_index}  gui_location_type   ${v_drv_pll_location_type}
                set_instance_parameter_value  iopll_${v_pll_index}  gui_lock_setting    {Low Lock Time}

                if {${v_drv_num_ioplls} > 1} {
                    set_instance_parameter_value  iopll_${v_pll_index}  gui_use_coreclk   1
                } else {
                    set_instance_parameter_value  iopll_${v_pll_index}  gui_use_coreclk   0
                }
            }

            # Create Connections
            add_connection  input_clk_bridge.out_clk  iopll_${v_pll_index}.refclk
            add_connection  input_rst_ctrl.reset_out  iopll_${v_pll_index}.reset

            add_connection  iopll_${v_pll_index}.locked iopll_locked_shim_${v_pll_index}.locked_in

            # Create Exports
            add_interface           o_iopll_${v_pll_index}_locked  conduit    end
            set_interface_property  o_iopll_${v_pll_index}_locked  export_of \
                                    iopll_locked_shim_${v_pll_index}.locked_out

            if {${v_export_to_top}} {
                add_interface           o_iopll_${v_pll_index}_locked_export  conduit    end
                set_interface_property  o_iopll_${v_pll_index}_locked_export  export_of \
                                        iopll_locked_shim_${v_pll_index}.locked_out_1
            }
        }

        # setting the PLL clock output parameters
        set v_clk_name        [get_shell_parameter GEN_CLK${v_i}_NAME]
        set v_clk_freq        [get_shell_parameter GEN_CLK${v_i}_FREQ]
        set v_clk_ps_units    [get_shell_parameter GEN_CLK${v_i}_PS_UNITS]
        set v_clk_phase_shift [get_shell_parameter GEN_CLK${v_i}_PHASE_SHIFT]
        set v_clk_duty_cycle  [get_shell_parameter GEN_CLK${v_i}_DUTY_CYCLE]

        set_instance_parameter_value  iopll_${v_pll_index}      gui_clock_name_string${v_pll_output_index} \
                                                                ${v_clk_name}
        set_instance_parameter_value  iopll_${v_pll_index}      gui_output_clock_frequency${v_pll_output_index} \
                                                                ${v_clk_freq}
        set_instance_parameter_value  iopll_${v_pll_index}      gui_ps_units${v_pll_output_index} \
                                                                ${v_clk_ps_units}
        set_instance_parameter_value  iopll_${v_pll_index}      gui_phase_shift${v_pll_output_index} \
                                                                ${v_clk_phase_shift}
        set_instance_parameter_value  iopll_${v_pll_index}      gui_duty_cycle${v_pll_output_index} \
                                                                ${v_clk_duty_cycle}
    }


    #===============================================================================================
    # iopll reset sync layer

    # note: this includes the board reset (and remote reset) in the synchronization
    # the reset extender is always required

    # Add Instance
    add_instance  reset_extender  intel_vvp_reset_extend

    # Set Parameters
    set_instance_parameter_value  reset_extender  RESYNC_RESET_IN         0
    set_instance_parameter_value  reset_extender  SYNC_LEN                3
    set_instance_parameter_value  reset_extender  RESET_MIN_LENGTH        ${v_reset_min_length}
    set_instance_parameter_value  reset_extender  DUAL_CONDUIT_OUT        0

    # Create Connections
    add_connection  input_clk_bridge.out_clk  reset_extender.clk

    # a reset controller is required only if there is a PLL instantiated,
    # otherwise the board reset is directly fed to the reset extender
    set v_num_reset_sources [expr ${v_drv_num_ioplls} + 1]

    if {${v_num_reset_sources} > 1} {
        # Add Instance
        add_instance  reset_sync   altera_reset_controller

        # Set Parameters
        set_instance_parameter_value  reset_sync  NUM_RESET_INPUTS          ${v_num_reset_sources}
        set_instance_parameter_value  reset_sync  OUTPUT_RESET_SYNC_EDGES   deassert
        set_instance_parameter_value  reset_sync  SYNC_DEPTH                2
        set_instance_parameter_value  reset_sync  RESET_REQUEST_PRESENT     0
        set_instance_parameter_value  reset_sync  USE_RESET_REQUEST_INPUT   0

        # Create Connections
        add_connection  input_clk_bridge.out_clk  reset_sync.clk
        add_connection  input_rst_ctrl.reset_out  reset_sync.reset_in0

        for {set v_i 0} {${v_i} < ${v_drv_num_ioplls}} {incr v_i} {
            set v_j [expr ${v_i} + 1]
            add_connection  iopll_locked_shim_${v_i}.reset  reset_sync.reset_in${v_j}
        }

        add_connection  reset_sync.reset_out  reset_extender.in_reset
    } else {
        add_connection  input_rst_ctrl.reset_out  reset_extender.in_reset
    }


    #===============================================================================================
    # local reset sync layer

    # reference clock / reset
    # Add Instance
    add_instance  ref_clk_reset_sync  intel_vip_reset_sync_block

    # Set Parameters
    set_instance_parameter_value  ref_clk_reset_sync  GEN_OUT_CLK             1
    set_instance_parameter_value  ref_clk_reset_sync  ASYNC_RESET             1
    set_instance_parameter_value  ref_clk_reset_sync  INPUT_CLOCK_FREQUENCY   ${v_drv_ref_clk_freq_hz}
    set_instance_parameter_value  ref_clk_reset_sync  SYNC_DEPTH              3
    set_instance_parameter_value  ref_clk_reset_sync  ADDITIONAL_DEPTH        2
    set_instance_parameter_value  ref_clk_reset_sync  DISABLE_GLOBAL_NETWORK  1

    # Create Connections
    add_connection  input_clk_bridge.out_clk  ref_clk_reset_sync.clock_in
    add_connection  reset_extender.out_reset  ref_clk_reset_sync.reset_in

    # iopll output clock / reset{v_i}
    for {set v_i 0} {${v_i} < ${v_num_gen_clocks}} {incr v_i} {
        set v_pll_index         [expr ${v_i} / ${v_drv_max_iopll_clks}]
        set v_pll_output_index  [expr ${v_i} % ${v_drv_max_iopll_clks}]
        set v_clk_freq          [get_shell_parameter GEN_CLK${v_i}_FREQ]
        set v_clk_freq_hz       [expr int(${v_clk_freq} * 1000000)]
        set v_name              gen_clk_${v_i}

        # Add Instance
        add_instance  ${v_name}_reset_sync  intel_vip_reset_sync_block

        # Set Parameters
        set_instance_parameter_value  ${v_name}_reset_sync  GEN_OUT_CLK             1
        set_instance_parameter_value  ${v_name}_reset_sync  ASYNC_RESET             1
        set_instance_parameter_value  ${v_name}_reset_sync  INPUT_CLOCK_FREQUENCY   ${v_clk_freq_hz}
        set_instance_parameter_value  ${v_name}_reset_sync  SYNC_DEPTH              3
        set_instance_parameter_value  ${v_name}_reset_sync  ADDITIONAL_DEPTH        2
        set_instance_parameter_value  ${v_name}_reset_sync  DISABLE_GLOBAL_NETWORK  1

        # Create Connections
        add_connection  iopll_${v_pll_index}.outclk${v_pll_output_index}  ${v_name}_reset_sync.clock_in
        add_connection  reset_extender.out_reset                          ${v_name}_reset_sync.reset_in
    }


    #===============================================================================================
    # output layer

    if {${v_export_to_top} == 0} {
        # Create Exports
        # reference clock / reset
        add_interface          o_ref_clk  clock       source
        set_interface_property o_ref_clk  export_of   ref_clk_reset_sync.clock_out

        add_interface          o_ref_rst  reset       source
        set_interface_property o_ref_rst  export_of   ref_clk_reset_sync.reset_out

        # iopll reset sync output clock / reset
        for {set v_i 0} {${v_i} < ${v_num_gen_clocks}} {incr v_i} {
            set v_pll_index         [expr ${v_i} / ${v_drv_max_iopll_clks}]
            set v_pll_output_index  [expr ${v_i} % ${v_drv_max_iopll_clks}]
            set v_name              gen_clk_${v_i}

            add_interface          o_${v_name}_clk  clock      source
            set_interface_property o_${v_name}_clk  export_of  ${v_name}_reset_sync.clock_out

            add_interface          o_${v_name}_rst  reset      source
            set_interface_property o_${v_name}_rst  export_of  ${v_name}_reset_sync.reset_out
        }
    } else {
        # extra bridges need to duplicate the clock / reset if exported to top

        # reference clock / reset
        # Add Instance
        add_instance  ref_clk_export_bridge  altera_clock_bridge
        add_instance  ref_rst_export_bridge  altera_reset_bridge

        # Set Parameters
        # ref_clk_export_bridge
        set_instance_parameter_value  ref_clk_export_bridge   EXPLICIT_CLOCK_RATE   ${v_drv_ref_clk_freq_hz}
        set_instance_parameter_value  ref_clk_export_bridge   NUM_CLOCK_OUTPUTS     2
        # ref_rst_export_bridge
        set_instance_parameter_value  ref_rst_export_bridge   ACTIVE_LOW_RESET      0
        set_instance_parameter_value  ref_rst_export_bridge   SYNCHRONOUS_EDGES     deassert
        set_instance_parameter_value  ref_rst_export_bridge   NUM_RESET_OUTPUTS     2
        set_instance_parameter_value  ref_rst_export_bridge   USE_RESET_REQUEST     0
        set_instance_parameter_value  ref_rst_export_bridge   SYNC_RESET            0

        # Create Connections
        add_connection  ref_clk_reset_sync.clock_out  ref_clk_export_bridge.in_clk
        add_connection  ref_clk_reset_sync.clock_out  ref_rst_export_bridge.clk
        add_connection  ref_clk_reset_sync.reset_out  ref_rst_export_bridge.in_reset

        # Create Exports
        # ref_clk_export_bridge
        add_interface          o_ref_clk  clock       source
        set_interface_property o_ref_clk  export_of   ref_clk_export_bridge.out_clk
        add_interface          o_ref_clk_export   clock       source
        set_interface_property o_ref_clk_export   export_of   ref_clk_export_bridge.out_clk_1
        # ref_rst_export_bridge
        add_interface          o_ref_rst  reset       source
        set_interface_property o_ref_rst  export_of   ref_rst_export_bridge.out_reset
        add_interface          o_ref_rst_export   reset       source
        set_interface_property o_ref_rst_export   export_of   ref_rst_export_bridge.out_reset_1

        # iopll reset sync output clock / reset
        for {set v_i 0} {${v_i} < ${v_num_gen_clocks}} {incr v_i} {
            set v_pll_index         [expr ${v_i} / ${v_drv_max_iopll_clks}]
            set v_pll_output_index  [expr ${v_i} % ${v_drv_max_iopll_clks}]
            set v_clk_freq          [get_shell_parameter GEN_CLK${v_i}_FREQ]
            set v_clk_freq_hz       [expr int(${v_clk_freq} * 1000000)]
            set v_name              gen_clk_${v_i}

            # Add Instance
            add_instance  ${v_name}_clk_export_bridge  altera_clock_bridge
            add_instance  ${v_name}_rst_export_bridge  altera_reset_bridge

            # Set Parameters
            # _clk_export_bridge
            set_instance_parameter_value  ${v_name}_clk_export_bridge   EXPLICIT_CLOCK_RATE   ${v_clk_freq_hz}
            set_instance_parameter_value  ${v_name}_clk_export_bridge   NUM_CLOCK_OUTPUTS     2
            # _rst_export_bridge
            set_instance_parameter_value  ${v_name}_rst_export_bridge   ACTIVE_LOW_RESET      0
            set_instance_parameter_value  ${v_name}_rst_export_bridge   SYNCHRONOUS_EDGES     deassert
            set_instance_parameter_value  ${v_name}_rst_export_bridge   NUM_RESET_OUTPUTS     2
            set_instance_parameter_value  ${v_name}_rst_export_bridge   USE_RESET_REQUEST     0
            set_instance_parameter_value  ${v_name}_rst_export_bridge   SYNC_RESET            0

            # Create Connections
            add_connection  ${v_name}_reset_sync.clock_out  ${v_name}_clk_export_bridge.in_clk
            add_connection  ${v_name}_reset_sync.clock_out  ${v_name}_rst_export_bridge.clk
            add_connection  ${v_name}_reset_sync.reset_out  ${v_name}_rst_export_bridge.in_reset

            # Create Exports
            # _clk_export_bridge
            add_interface          o_${v_name}_clk  clock      source
            set_interface_property o_${v_name}_clk  export_of  ${v_name}_clk_export_bridge.out_clk
            add_interface          o_${v_name}_clk_export  clock       source
            set_interface_property o_${v_name}_clk_export  export_of   ${v_name}_clk_export_bridge.out_clk_1
            # _rst_export_bridge
            add_interface          o_${v_name}_rst  reset      source
            set_interface_property o_${v_name}_rst  export_of  ${v_name}_rst_export_bridge.out_reset
            add_interface          o_${v_name}_rst_export  reset       source
            set_interface_property o_${v_name}_rst_export  export_of   ${v_name}_rst_export_bridge.out_reset_1
        }
    }

    sync_sysinfo_parameters
    save_system
}


# insert the clock subsystem into the top level Platform Designer system, and add interfaces
# to the boundary of the top level Platform Designer system
proc edit_top_level_qsys {} {
    set v_project_name      [get_shell_parameter PROJECT_NAME]
    set v_project_path      [get_shell_parameter PROJECT_PATH]
    set v_instance_name     [get_shell_parameter INSTANCE_NAME]

    set v_num_gen_clocks    [get_shell_parameter NUM_GEN_CLOCKS]
    set v_export_to_top     [get_shell_parameter EXPORT_TO_TOP]

    set v_drv_max_iopll_clks  [get_shell_parameter DRV_MAX_IOPLL_CLKS]

    load_system ${v_project_path}/rtl/${v_project_name}_qsys.qsys

    add_instance ${v_instance_name} ${v_instance_name}

    if {${v_export_to_top}} {
        add_interface          ${v_instance_name}_o_ref_clk   clock       source
        set_interface_property ${v_instance_name}_o_ref_clk   export_of   ${v_instance_name}.o_ref_clk_export

        add_interface          ${v_instance_name}_o_ref_rst   reset       source
        set_interface_property ${v_instance_name}_o_ref_rst   export_of   ${v_instance_name}.o_ref_rst_export

        for {set v_i 0} {${v_i} < ${v_num_gen_clocks}} {incr v_i} {
            set v_pll_index         [expr ${v_i} / ${v_drv_max_iopll_clks}]
            set v_pll_output_index  [expr ${v_i} % ${v_drv_max_iopll_clks}]

            if {${v_pll_output_index} == 0} {
                set v_name  o_iopll_${v_pll_index}_locked

                add_interface          ${v_instance_name}_${v_name}  conduit    end
                set_interface_property ${v_instance_name}_${v_name}  export_of  ${v_instance_name}.${v_name}_export
            }

            set v_name  gen_clk_${v_i}

            add_interface           ${v_instance_name}_o_${v_name}_clk   clock       source
            set_interface_property  ${v_instance_name}_o_${v_name}_clk   export_of \
                                    ${v_instance_name}.o_${v_name}_clk_export

            add_interface           ${v_instance_name}_o_${v_name}_rst   reset       source
            set_interface_property  ${v_instance_name}_o_${v_name}_rst   export_of \
                                    ${v_instance_name}.o_${v_name}_rst_export
        }
    }

    sync_sysinfo_parameters
    save_system
}


# enable a subset of subsystem interfaces to be available for auto-connection
# to other subsystems at the top qsys level
proc add_auto_connections {} {
    set v_instance_name       [get_shell_parameter INSTANCE_NAME]
    set v_num_gen_clocks      [get_shell_parameter NUM_GEN_CLOCKS]

    set v_drv_ref_clk_freq_hz [get_shell_parameter DRV_REF_CLK_FREQ_HZ]
    set v_drv_max_iopll_clks    [get_shell_parameter DRV_MAX_IOPLL_CLKS]

    # input clock / reset (from board subsystem)
    add_auto_connection ${v_instance_name} i_ref_clk       ref_clk
    add_auto_connection ${v_instance_name} ia_board_reset  board_rst

    # output ref clock / reset
    add_auto_connection ${v_instance_name} o_ref_clk ${v_drv_ref_clk_freq_hz}
    add_auto_connection ${v_instance_name} o_ref_rst ${v_drv_ref_clk_freq_hz}

    # output gen clocks / resets
    for {set v_i 0} {${v_i} < ${v_num_gen_clocks}} {incr v_i} {
        set v_pll_index         [expr ${v_i} / ${v_drv_max_iopll_clks}]
        set v_pll_output_index  [expr ${v_i} % ${v_drv_max_iopll_clks}]

        if {${v_pll_output_index} == 0} {
            set v_name  iopll_${v_pll_index}_locked

            add_auto_connection ${v_instance_name}  o_${v_name}  ${v_name}
        }

        set v_freq    [get_shell_parameter GEN_CLK${v_i}_FREQ]
        set v_freq_hz [expr int(${v_freq} * 1000000)]

        set v_ps_units    [get_shell_parameter GEN_CLK${v_i}_PS_UNITS]
        set v_phase_shift [get_shell_parameter GEN_CLK${v_i}_PHASE_SHIFT]
        set v_duty_cycle  [get_shell_parameter GEN_CLK${v_i}_DUTY_CYCLE]

        set v_label ${v_freq_hz}

        if {${v_phase_shift} != 0.0} {
            append v_label _${v_phase_shift}${v_ps_units}
        }

        if {${v_duty_cycle} != 50.0} {
            append v_label _${v_duty_cycle}%
        }

        set v_name gen_clk_${v_i}

        add_auto_connection ${v_instance_name} o_${v_name}_clk   ${v_label}
        add_auto_connection ${v_instance_name} o_${v_name}_rst   ${v_label}
    }
}


# insert lines of code into the top level hdl file
proc edit_top_v_file {} {
    set v_instance_name     [get_shell_parameter INSTANCE_NAME]
    set v_num_gen_clocks    [get_shell_parameter NUM_GEN_CLOCKS]
    set v_export_to_top     [get_shell_parameter EXPORT_TO_TOP]

    set v_drv_max_iopll_clks  [get_shell_parameter DRV_MAX_IOPLL_CLKS]

    if {${v_export_to_top}} {
        add_declaration_list wire ""  ${v_instance_name}_ref_clk
        add_declaration_list wire ""  ${v_instance_name}_ref_rst

        add_qsys_inst_exports_list          ${v_instance_name}_o_ref_clk_clk    ${v_instance_name}_ref_clk
        add_qsys_inst_exports_list          ${v_instance_name}_o_ref_rst_reset  ${v_instance_name}_ref_rst

        for {set v_i 0} {${v_i} < ${v_num_gen_clocks}} {incr v_i} {
            set v_pll_index         [expr ${v_i} / ${v_drv_max_iopll_clks}]
            set v_pll_output_index  [expr ${v_i} % ${v_drv_max_iopll_clks}]

            if {${v_pll_output_index} == 0} {
                set v_name  iopll_${v_pll_index}_locked

                add_declaration_list wire ""      ${v_instance_name}_${v_name}
                add_qsys_inst_exports_list        ${v_instance_name}_o_${v_name}_export    ${v_instance_name}_${v_name}
            }

            set v_name gen_clk_${v_i}

            add_declaration_list wire ""      ${v_instance_name}_${v_name}_clk
            add_declaration_list wire ""      ${v_instance_name}_${v_name}_rst

            add_qsys_inst_exports_list        ${v_instance_name}_o_${v_name}_clk_clk    ${v_instance_name}_${v_name}_clk
            add_qsys_inst_exports_list        ${v_instance_name}_o_${v_name}_rst_reset  ${v_instance_name}_${v_name}_rst
        }
    }
}

