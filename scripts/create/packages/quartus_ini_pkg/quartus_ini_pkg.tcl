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

package provide quartus_ini_pkg 1.0

package require Tcl             8.0

set script_dir    [file dirname [info script]]
lappend auto_path [file join ${script_dir} ".."]

package require subsystems_pkg 1.0

# Helper to collect all Quartus options in the design and create a single output file (quartus.ini)

namespace eval quartus_ini_pkg {

    namespace export generate_quartus_ini_file

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    proc ::quartus_ini_pkg::get_quartus_options_from_file {ini_file} {

        set v_options {}

        if {[file exists ${ini_file}] != 1} {
            return -code error "File does not exist (${ini_file})"
        }

        set v_result [catch {open ${ini_file} r} fid]
        if {${v_result} != 0} {
            return -code error "Unable to open file (${ini_file}):"
        }

        set v_file_data [read ${fid}]
        close ${fid}

        set v_lines [split ${v_file_data} "\n"]

        foreach v_line ${v_lines} {
            set v_line [string trim ${v_line}]

            if {[string length ${v_line}] != 0} {
                lappend v_options ${v_line}
            }
        }

        return ${v_options}

    }

    # Get Quartus options in the design (QUARTUS_INI_COMMAND / QUARTUS_INI_FILE parameters)

    proc ::quartus_ini_pkg::get_quartus_ini_options {parameter_array} {

        upvar ${parameter_array} v_parameter_array

        set v_consolidated_options {}
        set v_local_options        {}

        # Get project level parameters
        set v_parameter_list         $v_parameter_array(project,params)
        set v_updated_parameter_list {}

        foreach v_parameter_pair ${v_parameter_list} {
            set v_name  [lindex ${v_parameter_pair} 0]
            set v_value [lindex ${v_parameter_pair} 1]

            if {${v_name} == "QUARTUS_INI_COMMAND"}  {
                set v_local_options [list {*}${v_local_options} {*}${v_value}]

            } elseif {${v_name} == "QUARTUS_INI_FILE"} {
                set v_xml_path $v_parameter_array(project,xml_path)

                foreach v_file ${v_value} {
                    set v_file          [file join ${v_xml_path} ${v_file}]
                    set v_options       [::quartus_ini_pkg::get_quartus_options_from_file ${v_file}]
                    set v_local_options [list {*}${v_local_options} {*}${v_options}]
                }

            } else {
                lappend v_updated_parameter_list ${v_parameter_pair}
            }
        }

        if {[llength ${v_local_options}] > 0} {
            lappend v_consolidated_options "# project options"
            set v_consolidated_options     [list {*}${v_consolidated_options} {*}${v_local_options}]
            lappend v_consolidated_options ""
        }

        # Remove Quartus ini parameters from project, preventing subsystem parameters from being overwritten
        set v_parameter_array(project,params) ${v_updated_parameter_list}

        # Get subsystem level parameters

        # create a temporary version of the subsystems to query their parameters
        set v_result [catch {::subsystems_pkg::create_namespaces v_parameter_array 0} v_subsystems_list]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_subsystems_list}
        }

        foreach v_subsystem ${v_subsystems_list} {

            set v_local_options {}

            # Note [set ...] is required to get the value of the array in the namespace
            if {[info exists ${v_subsystem}::param_array(QUARTUS_INI_COMMAND)] == 1} {
                set v_options       [set ${v_subsystem}::param_array(QUARTUS_INI_COMMAND)]
                set v_local_options [list {*}${v_local_options} {*}${v_options}]
            }

            if {[info exists ${v_subsystem}::param_array(QUARTUS_INI_FILE)] == 1} {
                set v_files    [set ${v_subsystem}::param_array(QUARTUS_INI_FILE)]
                set v_xml_path [set ${v_subsystem}::param_array(SUBSYSTEM_SOURCE_PATH)]

                foreach v_file ${v_files} {
                    set v_file          [file join ${v_xml_path} ${v_file}]
                    set v_options       [::quartus_ini_pkg::get_quartus_options_from_file ${v_file}]
                    set v_local_options [list {*}${v_local_options} {*}${v_options}]
                }
            }

            if {[llength ${v_local_options}] > 0} {
                set v_instance_name            [set ${v_subsystem}::param_array(INSTANCE_NAME)]
                lappend v_consolidated_options "# ${v_instance_name} options"
                set v_consolidated_options     [list {*}${v_consolidated_options} {*}${v_local_options}]
                lappend v_consolidated_options ""
            }

            set v_result [catch {namespace delete ::${v_subsystem}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

        }

        # remove trailing empty string
        set v_consolidated_options [lrange ${v_consolidated_options} 0 end-1]

        return ${v_consolidated_options}

    }

    # Create Quartus.ini file using information from the parameter array

    proc ::quartus_ini_pkg::create_quartus_ini_file {parameter_array} {

        upvar ${parameter_array} v_parameter_array

        array set v_temporary_array [join $v_parameter_array(project,params)]
        set v_output_path [file join $v_temporary_array(PROJECT_PATH) "quartus"]

        set v_result [catch {::quartus_ini_pkg::get_quartus_ini_options v_parameter_array} v_consolidated_options]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_consolidated_options}
        }

        if {[llength ${v_consolidated_options}] == 0} {
            return -code ok
        }

        if {[file exists ${v_output_path}] == 0} {
            set v_result [catch {file mkdir ${v_output_path}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }
        } elseif {[file isdirectory ${v_output_path}] != 1} {
            return -code error "Output path (${v_output_path}) is not a directory"
        }

        set v_output_file [file join ${v_output_path} "quartus.ini"]

        if {[file exists ${v_output_file}] == 1} {
            return -code error "File already exists (${v_output_file})"
        }

        set v_result [catch {open ${v_output_file} w} v_fid]
        if {${v_result} != 0} {
            return -code error "Unable to open file (${v_output_file}):\n${v_fid}"
        }

        foreach v_option ${v_consolidated_options} {
            puts ${v_fid} ${v_option}
        }

        close ${v_fid}

        return -code ok

    }

}
