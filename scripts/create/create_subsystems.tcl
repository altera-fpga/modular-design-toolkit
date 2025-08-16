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

package require altera_terp
package require qsys

set v_script_directory [file join [lindex ${::argv} 0] "scripts" "create" "packages"]
lappend auto_path ${v_script_directory}

package require auto_connect_pkg   1.0
package require avmm_connect_pkg   1.0
package require irq_connect_pkg    1.0
package require pd_handler_pkg     1.0
package require subsystems_pkg     1.0
package require verilog_insert_pkg 1.0

# Subsystem creation script (to be executed by qsys-script)

namespace eval create_subsystems {

    variable  v_parameter_array
    array set v_parameter_array [lindex ${::argv} 1]

    set v_subsystems_list {}

    proc ::create_subsystems::main {} {

        variable v_parameter_array

        set v_temporary_file_directory [lindex ${::argv} 2]
        set v_quartus_process_id       [lindex ${::argv} 3]

        set v_result [catch {::pd_handler_pkg::init ${v_temporary_file_directory}\
                                                    ${v_quartus_process_id}} v_result_text]
        if {${v_result} != 0} {
            ::create_subsystems::exit_script ${v_result_text}
        }

        set v_result [catch {::subsystems_pkg::create_namespaces v_parameter_array} v_subsystems_list]
        if {${v_result} != 0} {
            ::create_subsystems::exit_script ${v_subsystems_list}
        }

        set ::create_subsystems::v_subsystems_list ${v_subsystems_list}

        set v_result [catch {::create_subsystems::create_subsystems_stage} v_result_text]
        if {${v_result} != 0} {
            ::create_subsystems::exit_script ${v_result_text}
        }

        set v_result [catch {::create_subsystems::connect_subsystems_stage} v_result_text]
        if {${v_result} != 0} {
            ::create_subsystems::exit_script ${v_result_text}
        }

        set v_result [catch {::create_subsystems::post_processing_stage} v_result_text]
        if {${v_result} != 0} {
            ::create_subsystems::exit_script ${v_result_text}
        }

        ::pd_handler_pkg::endProcess

    }

    # Create Platform Designer subsystems

    proc ::create_subsystems::create_subsystems_stage {} {

        set v_result [catch {::create_subsystems::run_namespace_procedure "pre_creation_step" {}\
                                                                          "Initializing subsystems"} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        reload_ip_catalog

        set v_result [catch {::create_subsystems::run_namespace_procedure "creation_step" {}\
                                                                          "Creating subsystems"} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        reload_ip_catalog

        set v_result [catch {::create_subsystems::run_namespace_procedure "post_creation_step" {}\
                                                                          "Post-processing subsystems"} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Perform inter-subsystem connections

    proc ::create_subsystems::connect_subsystems_stage {} {

        variable v_parameter_array

        ::pd_handler_pkg::sendMessage "Connecting subsystems"

        set v_file [file join $v_parameter_array(project,path) "rtl" "$v_parameter_array(project,name)_qsys.qsys"]

        set v_result [catch {::create_subsystems::run_namespace_procedure "get_connection_array" {}\
                                                                          ""} v_connection_list]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_connection_list}
        }

        array set v_connection_array {}

        # Merge subsystem connections into a global array
        foreach v_subsystem_connections ${v_connection_list} {
            foreach {v_name v_value} ${v_subsystem_connections} {
                if {[info exists v_connection_array(${v_name})]} {
                    set v_connection_array(${v_name}) [concat $v_connection_array(${v_name}) ${v_value}]
                } else {
                    set v_connection_array(${v_name}) ${v_value}
                }
            }
        }

        set v_result [catch {::auto_connect_pkg::run_connections ${v_file}\
                               $v_connection_array(general)} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::irq_connect_pkg::run_connections ${v_file}\
                               $v_connection_array(interrupts)} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::run_connections ${v_file}\
                               $v_connection_array(memory_mapped)} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::create_subsystems::run_namespace_procedure "post_connection_step" {} ""} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::create_subsystems::memory_map_resolve} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Perform top level verilog code insertion

    proc ::create_subsystems::post_processing_stage {} {

        set v_result [catch {::create_subsystems::verilog_insert_step} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Auto-assign base addresses and sync system info parameters.
    # Multiple iterations are required to ensure that bus widths are propagated
    # through bridges with the AUTO_WIDTH parameter enabled, which are commonly
    # used at the boundaries of subsystems.

    proc ::create_subsystems::memory_map_resolve {} {

        ::pd_handler_pkg::sendMessage "Assigning base addresses"

        sync_sysinfo_parameters
        auto_assign_system_base_addresses

        variable v_parameter_array

        for {set v_loop 0} {${v_loop} < 2} {incr v_loop} {
            for {set v_id 0} {${v_id} < $v_parameter_array(project,id)} {incr v_id} {

                set v_subsystem_name $v_parameter_array(${v_id},name)
                set v_subsystem_type $v_parameter_array(${v_id},type)
                set v_subsystem_path ""

                switch ${v_subsystem_type} {
                    top     {set v_subsystem_path [file join $v_parameter_array(project,path) "rtl"\
                                                             "$v_parameter_array(project,name)_qsys.qsys"]}
                    user    {set v_subsystem_path [file join $v_parameter_array(project,path) "rtl" "user"\
                                                             "${v_subsystem_name}.qsys"]}
                    import  {set v_subsystem_path [file join $v_parameter_array(project,path) "rtl" "import"\
                                                             "${v_subsystem_name}.qsys"]}
                    default {set v_subsystem_path [file join $v_parameter_array(project,path) "rtl" "shell"\
                                                             "${v_subsystem_name}.qsys"]}
                }

                # Subsystem scripts are not required to have a Platform Designer subsystem
                if {[file exists ${v_subsystem_path}]} {

                    load_system ${v_subsystem_path}
                    sync_sysinfo_parameters
                    auto_assign_system_base_addresses
                    save_system

                }
            }
        }

        return -code ok

    }

    # Insert verilog code into top level verilog file

    proc ::create_subsystems::verilog_insert_step {} {

        variable v_parameter_array

        ::pd_handler_pkg::sendMessage "Generating top-level Verilog file"

        array set v_project_parameters {}

        foreach v_parameter_pair $v_parameter_array(project,params) {
            set v_name  [lindex ${v_parameter_pair} 0]
            set v_value [lindex ${v_parameter_pair} 1]
            set v_project_parameters(${v_name}) ${v_value}
        }

        foreach v_subsystem ${::create_subsystems::v_subsystems_list} {

            set v_result [catch {::create_subsystems::run_namespace_procedure\
                                   "get_verilog_insert_array" ${v_subsystem} ""} v_verilog_insert_list]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_verilog_insert_list}
            }

            array set v_verilog_insert_array [join ${v_verilog_insert_list}]

            set v_file_path [file join $v_project_parameters(PROJECT_PATH) "rtl"\
                                       "$v_project_parameters(PROJECT_NAME).v"]
            set v_label     ${v_subsystem}
            set v_name      "$v_project_parameters(PROJECT_NAME)_qsys"

            set v_result [catch {::verilog_insert_pkg::verilog_insert ${v_file_path} ${v_label}\
                                   ${v_name} v_verilog_insert_array} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

        }

        return -code ok

    }

    # Evaluate a procedure in the subsystem namespace

    proc ::create_subsystems::run_namespace_procedure {procedure {subsystem_list {}} {message ""}} {

        set v_combined_result {}

        if {[llength ${subsystem_list}] == 0} {
            set subsystem_list ${::create_subsystems::v_subsystems_list}
        }

        if {[string equal "" ${message}] != 1} {
            ::pd_handler_pkg::sendMessage "${message}:"
        }

        foreach v_subsystem ${subsystem_list} {

            if {[string equal "" ${message}] != 1} {
                ::pd_handler_pkg::sendMessage " - ${v_subsystem}"
            }

            set v_procedure_list [namespace eval ::${v_subsystem} "info procs"]

            if {[lsearch ${v_procedure_list} ${procedure}] < 0} {
                return -code error "Unable to find procedure (${procedure}) in subsystem namespace (${v_subsystem})"
            }

            set v_result [catch {namespace eval ::${v_subsystem} ${procedure}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            } else {
                lappend v_combined_result ${v_result_text}
            }

            ::pd_handler_pkg::waitForInstruction

        }

        return ${v_combined_result}

    }

    # Terminate script execution (via pd_handler_pkg)

    proc ::create_subsystems::exit_script {error_message} {

        ::pd_handler_pkg::setError ${error_message}
        ::pd_handler_pkg::waitforInstruction
        exit

    }

}

::create_subsystems::main
