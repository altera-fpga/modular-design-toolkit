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

package provide subsystems_pkg 1.0
package require Tcl            8.0

set v_script_directory [file dirname [info script]]
lappend auto_path [file join ${v_script_directory} ".."]

package require avmm_connect_pkg     1.0
package require hls_build_pkg        1.0
package require irq_connect_pkg      1.0
package require software_manager_pkg 1.0
package require utils_pkg            1.0

# Helper to wrap subsystem scripts inside namespaces

namespace eval subsystems_pkg {

    namespace export create_namespaces

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # Create a namespace for each subsystem TCL script and return the list of namespaces

    proc ::subsystems_pkg::create_namespaces {parameter_array {derive_parameters 1}} {

        upvar ${parameter_array} v_parameter_array

        set v_namespace_list {}

        for {set v_id 0} {${v_id} < $v_parameter_array(project,id)} {incr v_id} {

            set v_result [catch {create_namespace_wrapper ${v_id} v_parameter_array} v_subsystem_namespace]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_subsystem_namespace}
            }

            lappend v_namespace_list ${v_subsystem_namespace}

        }

        if {${derive_parameters} == 1} {
            foreach v_namespace ${v_namespace_list} {
                set v_procedure_list [namespace eval ::${v_namespace} "info procs"]
                if {[lsearch ${v_procedure_list} "derive_parameters"] >= 0} {
                    set v_result [catch {::${v_namespace}::derive_parameters v_parameter_array} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }
                }
            }
        }

        return ${v_namespace_list}

    }

}

proc create_namespace_wrapper {id parameter_array} {

    upvar ${parameter_array} v_parameter_array

    # Namespace needs to be named after instance name
    set v_namespace_name $v_parameter_array(${id},name)

    # Create a new namespace
    namespace eval ${v_namespace_name} {

        array set v_parameter_array {}

        array set v_connection_array          {}
        set v_connection_array(general)       {}
        set v_connection_array(memory_mapped) {}
        set v_connection_array(interrupts)    {}

        array set v_verilog_insert_array         {}
        set v_verilog_insert_array(ports)        {}
        set v_verilog_insert_array(declarations) {}
        set v_verilog_insert_array(assignments)  {}
        set v_verilog_insert_array(exports)      {}
        set v_verilog_insert_array(generic)      {}

        proc pre_creation_step    {} {}
        proc creation_step        {} {}
        proc post_creation_step   {} {}
        proc post_connection_step {} {}

        #==============================================

        # Add/Modify a parameter

        proc set_shell_parameter {parameter_name parameter_value {add 1}} {
            set v_current_namespace [namespace current]
            if {([info exists ${v_current_namespace}::v_parameter_array(${parameter_name})] == 1) || (${add} == 1)} {
                set ${v_current_namespace}::v_parameter_array(${parameter_name}) ${parameter_value}
            }
            return -code ok
        }

        # Get the value of a parameter

        proc get_shell_parameter {parameter_name} {
            set v_current_namespace [namespace current]
            if {[info exists ${v_current_namespace}::v_parameter_array(${parameter_name})]} {
                return [set ${v_current_namespace}::v_parameter_array(${parameter_name})]
            }
            return -code error "Parameter ${parameter_name} does not exist in ${v_current_namespace}"
        }

        # Get the parameter array

        proc get_shell_parameter_array {} {
            set v_current_namespace [namespace current]
            return [set ${v_current_namespace}::v_parameter_array]
        }

        # Add/Update parameter array from a list of parameters

        proc set_multiple_shell_parameters {parameter_list {add 0}} {
            foreach {parameter_name parameter_value} [join ${parameter_list}] {
                set_shell_parameter ${parameter_name} ${parameter_value} ${add}
            }
            return -code ok
        }

        # Check a parameter exists. Return 1 if the parameter exists, otherwise 0

        proc check_shell_parameter_exists {parameter_name} {
            set v_current_namespace [namespace current]
            return [info exists ${v_current_namespace}::v_parameter_array(${parameter_name})]
        }

        #======================================================

        # Add a generic interface for automatic connection

        proc add_auto_connection {instance interface label} {
            set v_current_namespace [namespace current]
            lappend ${v_current_namespace}::v_connection_array(general) [list ${instance} ${interface} ${label}]
            return -code ok
        }

        # Add an interrupt interface for automatic connection

        proc add_irq_connection {instance interface priority label} {
            set v_current_namespace [namespace current]
            set v_interrupt [list ${instance} ${interface} ${priority} ${label}]
            lappend ${v_current_namespace}::v_connection_array(interrupts) ${v_interrupt}
            return -code ok
        }

        # Add an interrupt interface for automatic connection

        proc add_avmm_connections {interface hosts} {
            set v_current_namespace [namespace current]
            set v_instance          [get_shell_parameter INSTANCE_NAME]

            if {[string equal "host" ${hosts}] == 1} {
                set v_connection [list ${v_instance} ${interface} X auto_avmm_host]
                lappend ${v_current_namespace}::v_connection_array(memory_mapped) ${v_connection}
                set v_connection [list ${v_instance} ${interface} X "${v_instance}_avmm_host"]
                lappend ${v_current_namespace}::v_connection_array(memory_mapped) ${v_connection}
            } else {
                foreach {host offset} [join ${hosts}] {
                    set v_connection [list ${v_instance} ${interface} ${offset} "${host}_avmm_host"]
                    lappend ${v_current_namespace}::v_connection_array(memory_mapped) ${v_connection}
                }
            }
            return -code ok
        }

        # Get the automatic connection array

        proc get_connection_array {} {
            set v_current_namespace [namespace current]
            return [array get ${v_current_namespace}::v_connection_array]
        }

        #======================================================

        # Add a port (to the top level hdl file)

        proc add_top_port_list {type width signal} {
            set v_current_namespace [namespace current]
            lappend ${v_current_namespace}::v_verilog_insert_array(ports) [list ${type} ${width} ${signal}]
            return -code ok
        }

        # Add a declaration (to the top level hdl file)

        proc add_declaration_list {type width signal} {
            set v_current_namespace [namespace current]
            lappend ${v_current_namespace}::v_verilog_insert_array(declarations) [list ${type} ${width} ${signal}]
            return -code ok
        }

        # Add an assignment (to the top level hdl file)

        proc add_assignments_list {signal expression} {
            set v_current_namespace [namespace current]
            lappend ${v_current_namespace}::v_verilog_insert_array(assignments) [list ${signal} ${expression}]
            return -code ok
        }

        # Add an export to the Platform Designer component (in the top level hdl file)

        proc add_qsys_inst_exports_list {port signal} {
            set v_current_namespace [namespace current]
            lappend ${v_current_namespace}::v_verilog_insert_array(exports) [list ${port} ${signal}]
            return -code ok
        }

        # Add a generic Verilog code block (to the top level hdl file)

        proc add_code_insert_list {code} {
            set v_current_namespace [namespace current]
            lappend ${v_current_namespace}::v_verilog_insert_array(generic) ${code}
            return -code ok
        }

        # Get the Verilog insertion array

        proc get_verilog_insert_array {} {
            set v_current_namespace [namespace current]
            return [array get ${v_current_namespace}::v_verilog_insert_array]
        }

        #==========================================================

        # Write namespace parameters back to the global parameter array
        # - Allows parameters set internally (i.e. not in XML design file)
        #   to be visible to other subsystems for derive_parameters procedure

        proc write_back_parameters {id parameter_array} {

            upvar ${parameter_array} v_global_parameter_array
            set v_current_namespace [namespace current]

            set v_parameter_list {}
            foreach {parameter_name parameter_value} [array get ${v_current_namespace}::v_parameter_array] {
                lappend v_parameter_list [list ${parameter_name} ${parameter_value}]
            }

            set v_global_parameter_array(${id},params) ${v_parameter_list}
            return -code ok

        }

        # Initialize parameters and source the subsystem script within the namespace

        proc constructor {id parameter_array} {

            upvar ${parameter_array} v_global_parameter_array
            set v_current_namespace  [namespace current]

            set v_project_name $v_global_parameter_array(project,name)
            set v_project_path $v_global_parameter_array(project,path)

            set v_subsystem_name   $v_global_parameter_array(${id},name)
            set v_subsystem_script $v_global_parameter_array(${id},script)
            set v_subsystem_type   $v_global_parameter_array(${id},type)

            set v_global_parameter_list $v_global_parameter_array(project,params)
            set v_local_parameter_list  $v_global_parameter_array(${id},params)

            # Default parameters required by all subsystems
            set_shell_parameter SHELL_DESIGN_ROOT ""
            set_shell_parameter PROJECT_NAME      ""
            set_shell_parameter PROJECT_PATH      ""
            set_shell_parameter INSTANCE_NAME     ""
            set_shell_parameter FAMILY            ""
            set_shell_parameter DEVICE            ""
            set_shell_parameter QUARTUS_VERSION   ""
            set_shell_parameter DEVKIT            ""
            set_shell_parameter SPEED_GRADE       ""

            set_shell_parameter IRQ_PRIORITY      ""

            # Update subsystem parameters from global parameters
            # - This will only UPDATE default parameters
            # - Required before sourcing subsystem script as some subsystems
            #   will source additional scripts (i.e. based on DEVKIT)
            set v_result [catch {${v_current_namespace}::set_multiple_shell_parameters ${v_global_parameter_list} 0}\
                                 v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            # Source the subsystem script
            set v_result [catch {source ${v_subsystem_script}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            # Update subsystem parameters from global parameters
            # - Required for globally set subsystem parameters
            #   that are shared by multiple subsystems
            set v_result [catch {${v_current_namespace}::set_multiple_shell_parameters ${v_global_parameter_list} 0}\
                                 v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            # Update subsystem parameters from local parameters
            set v_result [catch {${v_current_namespace}::set_multiple_shell_parameters ${v_local_parameter_list} 0}\
                                 v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            # Check if the subsystem uses a special initialization procedure
            # - Run initialization and update the parameters
            # - Required if the subsystem script uses non-default parameters
            #   to source a secondary script
            if {[llength [info procs subsystem_init]] > 0} {

                set v_result [catch {${v_current_namespace}::subsystem_init} v_result_text]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_result_text}
                }

                set v_result [catch {${v_current_namespace}::set_multiple_shell_parameters\
                                     ${v_global_parameter_list} 0} v_result_text]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_result_text}
                }

                set v_result [catch {${v_current_namespace}::set_multiple_shell_parameters\
                                     ${v_local_parameter_list} 0} v_result_text]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_result_text}
                }
            }

            set v_result [catch {${v_current_namespace}::write_back_parameters ${id} v_global_parameter_array}\
                                 v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            # Create useful subsystem parameters
            switch ${v_subsystem_type} {
                top     {set v_folder ""}
                user    {set v_folder "user"}
                default {set v_folder "shell"}
            }

            set_shell_parameter SUBSYSTEM_NAME         ${v_subsystem_name}
            set_shell_parameter SUBSYSTEM_SOURCE_PATH  [file dirname ${v_subsystem_script}]
            set_shell_parameter SUBSYSTEM_IP_PATH      [file join ${v_project_path} non_qpds_ip ${v_folder}]
            set_shell_parameter SUBSYSTEM_RTL_PATH     [file join ${v_project_path} rtl ${v_folder}]
            set_shell_parameter SUBSYSTEM_QUARTUS_PATH [file join ${v_project_path} quartus ${v_folder}]

            set_shell_parameter PROJECT_PD_FILE [file join ${v_project_path} rtl "${v_project_name}_qsys.qsys"]

            return -code ok

        }

        # Evaluate a terp template file

        proc evaluate_terp_file {terp_file parameters run delete} {

            set v_current_namespace  [namespace current]

            set v_output_file [file rootname ${terp_file}]

            set v_result [catch {${v_current_namespace}::get_terp_content ${terp_file} ${parameters}} v_file_contents]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_file_contents}
            }

            set v_result [catch {open ${v_output_file} w+} v_fid]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_fid}
            }

            puts  ${v_fid} ${v_file_contents}
            close ${v_fid}

            # Evaluate the output file as a tcl script
            if {${run} == 1} {
                source ${v_output_file}
            }

            # Delete the source .terp file
            if {${delete} == 1} {
                file delete -force -- ${terp_file}
            }

            return -code ok

        }

        # Generate an output string from a terp file

        proc get_terp_content {terp_file parameters} {

            set v_result [catch {open ${terp_file}} v_fid]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_fid}
            }

            set v_terp_file_contents [read ${v_fid}]
            close ${v_fid}

            array set v_terp_parameter_array {}

            for {set v_index 0} {${v_index} < [llength ${parameters}]} {incr v_index} {
                set v_terp_parameter_array(param${v_index}) [lindex ${parameters} ${v_index}]
            }

            set v_result [catch {altera_terp ${v_terp_file_contents} v_terp_parameter_array} v_output_file_contents]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_output_file_contents}
            }

            return ${v_output_file_contents}

        }

        interp alias {} file_copy {} ::utils_pkg::file_copy

    }

    # Add the subsystem script contents to the namespace and initialize the parameters
    set v_result [catch {${v_namespace_name}::constructor ${id} v_parameter_array} v_result_text]
    if {${v_result} != 0} {
        return -code ${v_result} ${v_result_text}
    }

    # Remove the constructor procedure so it cannot be used
    namespace forget ${v_namespace_name} constructor

    return ${v_namespace_name}

}
