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

package provide quartus_verification_pkg 1.0

package require Tcl                      8.0

# Helper to check Quartus versions supported by the design against the current Quartus version

namespace eval quartus_verification_pkg {

    namespace export evaluate_quartus ip_list_generate

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # Get Quartus version running current script

    proc ::quartus_verification_pkg::get_quartus_version {} {

        if {[info exists ::quartus(version)]} {
            set v_version $::quartus(version)
        } else {
            return -code error "Unable to retrieve Quartus version"
        }

        # Sub version is optional, only include if present
        set v_result [regexp {(\d+)\.(\d+)(?:\.(\d+))?} ${v_version} match major_version minor_version sub_version]
        if {${v_result} != 1} {
            return -code error "Unable to decode Quartus version"
        }

        set v_version [list ${major_version} ${minor_version}]

        if {[string equal ${sub_version} ""] == 0} {
            lappend v_version ${sub_version}
        }

        return ${v_version}

    }

    # Check design supports the current Quartus version

    proc ::quartus_verification_pkg::check_quartus_compatibility {parameter_array} {

        upvar ${parameter_array} v_parameter_array

        set v_result [catch {::quartus_verification_pkg::get_quartus_version} v_quartus_version_list]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_quartus_version_list}
        }

        set v_quartus_version [join ${v_quartus_version_list} "."]

        lappend v_parameter_array(project,params) [list QUARTUS_VERSION ${v_quartus_version}]

        array set v_temp_array [join $v_parameter_array(project,params)]

        if {[info exists v_temp_array(VERSION)] != 1} {
            post_message -type warning "The design does not have a Quartus versions list, assuming current version\
                                        (${v_quartus_version}) is supported"
            return -code ok
        } else {
            set v_supported_versions $v_temp_array(VERSION)
        }

        if {[llength ${v_supported_versions}] == 0} {
            post_message -type warning "The design does not have a Quartus versions list, assuming current version\
                                        (${v_quartus_version}) is supported"
            return -code ok
        }

        # Allow for partial match; supported version is inclusive of all lower level versions
        # i.e. supported version 24.3 is compatible with 24.3.X
        foreach v_supported_version ${v_supported_versions} {
            set v_match [string match "${v_supported_version}*" ${v_quartus_version}]
            if {${v_match} == 1} {
                return -code ok
            }
        }

        return -code error "Quartus version (${v_quartus_version}) is not supported by the design\
                            (${v_supported_versions})"

    }

    # Generate report of all IP used in the design

    proc ::quartus_verification_pkg::ip_list_generate {project_directory project_name} {

        set v_project    [file join ${project_directory} "quartus" "${project_name}.qpf"]
        set v_pd_project [file join ${project_directory} "rtl"     "${project_name}_qsys.qsys"]

        # Platform Designer script to get ip information
        set v_script {

            package require qsys

            proc extract_xml_value {xml keys} {
                set v_index  0
                set v_length [llength ${keys}]

                foreach v_line [split ${xml} "\n"] {
                    set v_key [lindex ${keys} ${v_index}]
                    if {[regexp "<${v_key}>" ${v_line}] == 1} {
                        incr v_index
                        if {${v_index} == ${v_length}} {
                            set v_result [regexp "<${v_key}>(.*)</${v_key}>" ${v_line} match sub_match]
                            if {${v_result} == 1} {
                                return ${sub_match}
                            }
                        }
                    }
                    if {[regexp "</${v_key}>" ${v_line}] == 1} {
                        incr v_index -1
                    }
                }
                return
            }

            proc get_ip_list {{current_level 0} {current_system ""} {previous_system ""} {current_instance ""}} {

                upvar v_ip_array v_ip_array

                if {${current_system} == ""} {
                    set current_system [get_module_property FILE]
                }

                load_system ${current_system}

                if {${current_level} == 0} {
                    array set v_ip_array {}
                    set v_ip_array(subsystems) {}
                    set v_ip_array(instances)  {}
                }

                set v_subsystem_index 0

                set v_result [regexp {.*[\/\\](.*)\.qsys} ${current_system} match sub_match]
                if {${v_result} != 1} {
                    return -code ${v_result} "Unable to parse subsystem path"
                }

                if {[info exists v_ip_array(subsystems)] == 0} {
                    set v_ip_array(subsystems) [list ${sub_match}]
                } else {
                    set v_subsystem_index [llength $v_ip_array(subsystems)]
                    lappend v_ip_array(subsystems) ${sub_match}
                }

                foreach v_instance [get_instances] {
                    set v_instance_group [get_instance_property ${v_instance} GROUP]

                    if {(${v_instance_group} == "System") || (${v_instance_group} == "Systems")} {
                        set v_instance_file [get_instance_property ${v_instance} FILE]

                        set current_system [get_ip_list [expr ${current_level} + 1] ${v_instance_file}\
                                                        ${current_system} ${v_instance}]
                        load_system ${current_system}

                    } elseif {${v_instance_group} == "Generic Component"} {
                        set v_instance_name    [extract_xml_value [get_instance_parameter_value ${v_instance}\
                                                                   componentDefinition] {originalModuleInfo className}]
                        set v_instance_version [extract_xml_value [get_instance_parameter_value ${v_instance}\
                                                                   componentDefinition] {originalModuleInfo version}]

                        set v_instance_index [lsearch $v_ip_array(instances) ${v_instance_name}]

                        if {${v_instance_index} < 0} {
                            set v_instance_index [llength $v_ip_array(instances)]
                            lappend v_ip_array(instances) ${v_instance_name}

                            set v_ip_array(${v_instance_index},subsystems) [list ${v_subsystem_index}]
                            set v_ip_array(${v_instance_index},version)    [list ${v_instance_version}]
                            set v_ip_array(${v_instance_index},name)       [list ${v_instance}]

                        } else {
                            lappend v_ip_array(${v_instance_index},subsystems) ${v_subsystem_index}
                            lappend v_ip_array(${v_instance_index},version)    ${v_instance_version}
                            lappend v_ip_array(${v_instance_index},name)       ${v_instance}

                        }
                    }
                }

                if {${current_level} == 0} {
                    set v_ip_list [array get v_ip_array]
                    puts "<get_ip_list_output>${v_ip_list}</get_ip_list_output>"
                    return -code ok

                } else {
                    return ${previous_system}
                }

                return
            }

            get_ip_list
        }

        # Modify script (for exec command)
        regsub -all -- {(\s*#[^\n]*)\n} ${v_script} ""   v_script
        regsub -all -- {(\n[ \t]*)+} ${v_script}    "; " v_script

        set v_args    [list --system-file=${v_pd_project} --quartus-project=${v_project} --cmd=${v_script}]

        set v_result [catch {exec -ignorestderr -- qsys-script {*}${v_args} 2>@1} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        # Parse output text
        set v_result [regexp "<get_ip_list_output>(.*)</get_ip_list_output>" ${result_text} match sub_match]
        if {${v_result} != 1} {
            return -code error "Unable to parse output"
        }

        set v_length [llength ${sub_match}]
        if {[expr ${v_length} % 2] != 0} {
            return -code error "Unable to parse output, list does not contain an even number of elements"
        }

        array set v_ip_array {}

        # Convert list to array
        for {set v_index 0} {${v_index} < ${v_length}} {incr v_index 2} {
            set v_name  [lindex ${sub_match} ${v_index}]
            set v_value [lindex ${sub_match} [expr ${v_index} + 1]]

            set v_ip_array(${v_name}) ${v_value}
        }

        # Setup output file
        set v_output_directory [file join ${project_directory} "quartus"]

        set v_result [catch {file mkdir ${v_output_directory}} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_ip_information_file [file join ${v_output_directory} "ip_list.csv"]

        # Write to file
        set v_result [catch {open ${v_ip_information_file} w+} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        } else {
            set v_fid ${result_text}

            puts ${v_fid} "IP Name,Subsystem,Instance Name,Version"

            set v_total_instances [llength $v_ip_array(instances)]

            for {set v_instance_index 0} {${v_instance_index} < ${v_total_instances}} {incr v_instance_index} {
                set v_instance         [lindex $v_ip_array(instances) ${v_instance_index}]
                set v_total_subsystems [llength $v_ip_array(${v_instance_index},subsystems)]

                for {set v_index 0} {${v_index} < ${v_total_subsystems}} {incr v_index} {
                    set v_subsystem_index [lindex $v_ip_array(${v_instance_index},subsystems) ${v_index}]
                    set v_subsystem       [lindex $v_ip_array(subsystems) ${v_subsystem_index}]
                    set v_name            [lindex $v_ip_array(${v_instance_index},name) ${v_index}]
                    set v_version         [lindex $v_ip_array(${v_instance_index},version) ${v_index}]

                    puts ${v_fid} "${v_instance},${v_subsystem},${v_name},${v_version}"
                }
            }

            close ${v_fid}
        }

        return -code ok

    }

}
