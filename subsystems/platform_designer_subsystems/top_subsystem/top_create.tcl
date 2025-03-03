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

# create script specific parameters and default values

# define the procedures used by the create_subsystems_qsys.tcl script

proc pre_creation_step {} {
    transfer_files
    evaluate_terp
}

proc creation_step {} {
    create_top_system
}


# resolve interdependencies
proc derive_parameters {param_array} {
    upvar $param_array p_array

    set_shell_parameter OCS_ENABLED 0

    # search for OCS subsystems, which requires a package to automatically populate
    for {set id 0} {$id < $p_array(project,id)} {incr id} {
        if {$p_array($id,type) == "ocs"} {
            set_shell_parameter OCS_ENABLED 1
            break
        }
    }

    set_shell_parameter SW_ENABLED 0

    # search for CPU subsystems, which requires a package to automatically populate
    for {set id 0} {$id < $p_array(project,id)} {incr id} {
        if {($p_array($id,type) == "cpu") || ($p_array($id,type) == "niosv") || ($p_array($id,type) == "hps")} {
            set_shell_parameter SW_ENABLED 1
            break
        }
    }
}


# copy files from the shell install directory to the target project directory
proc transfer_files {} {
    set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]
    set v_project_name      [get_shell_parameter PROJECT_NAME]
    set v_project_path      [get_shell_parameter PROJECT_PATH]

    set v_ocs_enabled       1;
    set v_sw_enabled        1;

    set v_shell_script_root [file join [file dirname ${v_shell_design_root}] ..]
    set v_shell_script_root [file join [file dirname ${v_shell_script_root}] ..]
    set v_subsys_dir        "${v_shell_design_root}/top_subsystem"

    file mkdir ${v_project_path}/scripts/packages
    file_copy   ${v_shell_script_root}/scripts/build/packages/logging_pkg/ \
                ${v_project_path}/scripts/packages

    file_copy   ${v_shell_script_root}/scripts/build/packages/timer_pkg/ \
                ${v_project_path}/scripts/packages

    file_copy   ${v_shell_script_root}/scripts/build/packages/archive_pkg/ \
                ${v_project_path}/scripts/packages

    if {${v_ocs_enabled}} {
        file_copy   ${v_shell_script_root}/scripts/build/packages/capability_structure_pkg/ \
                    ${v_project_path}/scripts/packages
    }

    if {$v_sw_enabled} {
        file_copy   ${v_shell_script_root}/scripts/build/packages/software_build_pkg/ \
                    ${v_project_path}/scripts/packages
    }

    file_copy   ${v_shell_script_root}/scripts/build/build_shell.tcl \
                ${v_project_path}/scripts/build_shell.tcl

    file_copy   ${v_shell_design_root}/top_subsystem/top_supplemental.qsf.terp \
                ${v_project_path}/quartus/shell/${v_project_name}_supplemental.qsf.terp
}


# convert terp files to their native format
proc evaluate_terp {} {
    set v_project_name [get_shell_parameter PROJECT_NAME]
    set v_project_path [get_shell_parameter PROJECT_PATH]

    evaluate_terp_file ${v_project_path}/quartus/shell/${v_project_name}_supplemental.qsf.terp {} 0 1
}


# create the top system and leave blank, other subsystems will populate this system.
proc create_top_system {} {
    set v_project_name  [get_shell_parameter PROJECT_NAME]
    set v_project_path  [get_shell_parameter PROJECT_PATH]

    create_system ${v_project_name}_qsys
    save_system   ${v_project_path}/rtl/${v_project_name}_qsys.qsys
}

