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

package require cmdline
package require fileutil

package require ::quartus::project
package require ::quartus::flow
package require ::quartus::misc
package require ::quartus::report
package require ::quartus::device

set v_script_directory [file dirname [info script]]
lappend auto_path [file join ${v_script_directory} "packages"]

package require pd_handler_pkg           1.0
package require quartus_ini_pkg          1.0
package require quartus_verification_pkg 1.0
package require xml_parse_pkg            1.0

# Entry script for running the toolkit flow

namespace eval create_shell {

    set v_script_root     [file join [pwd] [file dirname [info script]]]
    set v_toolkit_root    [file normalize [file join ${v_script_root} ".." ".." ]]
    set v_designs_root    [file join ${v_toolkit_root} ".." ]
    set v_subsystems_root [file join ${v_toolkit_root} subsystems platform_designer_subsystems]

    set v_qsys_script_exe         [file join $::env(QUARTUS_ROOTDIR) sopc_builder bin qsys-script]
    set v_create_subsystem_script [file join ${v_toolkit_root} scripts create create_subsystems.tcl]

    # The first usage message must be -help
    set v_usage_message {}
    lappend v_usage_message {quartus_sh -t create_shell.tcl [-? | -help]}
    lappend v_usage_message {quartus_sh -t create_shell.tcl [-l | -list]}
    lappend v_usage_message {quartus_sh -t create_shell.tcl (-proj_name=?) (-proj_path=?) (-xml_path=?) (-i) (-o)}

    set v_help_message {}
    lappend v_help_message ""
    lappend v_help_message "Usage:"
    lappend v_help_message "------"
    lappend v_help_message ""
    foreach v_usage ${v_usage_message} {
        lappend v_help_message ${v_usage}
    }
    lappend v_help_message ""
    lappend v_help_message "Description:"
    lappend v_help_message "------------"
    lappend v_help_message ""
    lappend v_help_message "    Create a Quartus project from an XML file design description"
    lappend v_help_message ""
    lappend v_help_message "Options:"
    lappend v_help_message "--------"
    lappend v_help_message ""
    lappend v_help_message "    -proj_name  Project name. Overrides the project name in the XML design file."
    lappend v_help_message "    -proj_path  Project path. Output directory to generate Quartus project in.  "
    lappend v_help_message "                (Default: <toolkit_root>/output)                                "
    lappend v_help_message "    -xml_path   Path to XML design file. (e.g. ~\design.xml)                    "
    lappend v_help_message "    -o          Overwrite. Delete the contents of -proj_path if it exists,      "
    lappend v_help_message "                before project creation                                         "
    lappend v_help_message "    -i          List IP. Generate a CSV of Platform Designer IP used in the     "
    lappend v_help_message "                project; after creation. (<proj_path>/quartus/ip_list.csv)      "
    lappend v_help_message "    -l, -list   Display default XML design files."
    lappend v_help_message "    -?, -help   Display this message."
    lappend v_help_message ""

    # Command line options (defaults)
    set v_default_proj_path [file normalize [file join ${v_toolkit_root} ".." "output"]]

    set v_options {
        {"proj_name.arg" ""}
        {"proj_path.arg" ${v_default_proj_path}}
        {"xml_path.arg"  ""}
        {"i"             "0"}
        {"o"             "0"}
    }

    set v_hidden_options {"l" "list"}

    # Subdirectories created by the toolkit in the project directory
    set v_subdirectories {}
    lappend v_subdirectories "non_qpds_ip"
    lappend v_subdirectories "quartus"
    lappend v_subdirectories "rtl"
    lappend v_subdirectories "scripts"
    lappend v_subdirectories "sdc"
    lappend v_subdirectories "software"

    # Subdirectories created by the toolkit that require further subdirectories to be created.
    # This creates the separation between toolkit files and user files.
    # i.e. each directory in v_split_subdirectories will have have the directories in v_split_directories
    #      within them
    set v_split_subdirectories {}
    lappend v_split_subdirectories "non_qpds_ip"
    lappend v_split_subdirectories "quartus"
    lappend v_split_subdirectories "rtl"
    lappend v_split_subdirectories "sdc"

    set v_split_directories {"shell" "user"}

    ###################################################################################

    proc ::create_shell::main {} {

        array set v_project_settings {}
        array set v_parameter_array  {}

        set v_result [catch {::create_shell::parse_project_settings v_project_settings\
                                                                    v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            post_message -type ERROR ${v_result_text}
            qexit -error
        }

        set v_result [catch {::create_shell::create_project v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            if {[is_project_open]} {
                project_close
            }
            post_message -type ERROR ${v_result_text}
            qexit -error
        }

        set v_result [catch {::create_shell::finalize_project v_project_settings v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            if {[is_project_open]} {
                project_close
            }
            post_message -type ERROR ${v_result_text}
            qexit -error
        }

        qexit -success

    }

    # Parse settings / parameters from the command line arguments and the XML design file;
    # updating the project_settings and parameter_array associative arrays accordingly.

    proc ::create_shell::parse_project_settings {project_settings parameter_array} {

        upvar ${project_settings} v_project_settings
        upvar ${parameter_array}  v_parameter_array

        puts "Parsing project settings"

        set v_result [catch {::create_shell::parse_command_line_arguments ::argv v_project_settings} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::parse_xml_design_file $v_project_settings(xml_path) \
                               ${::create_shell::v_toolkit_root} v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::create_shell::parse_project_name v_project_settings v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::create_shell::parse_project_path v_project_settings v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::quartus_verification_pkg::check_quartus_compatibility v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Create project and subsystems

    proc ::create_shell::create_project {parameter_array} {

        upvar ${parameter_array}  v_parameter_array

        puts "Creating project"

        set v_result [catch {::create_shell::create_directory_tree v_parameter_array} v_result_text]
        if {${v_result} != 0} {
           return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::quartus_ini_pkg::create_quartus_ini_file v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::create_shell::create_quartus_project v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::create_shell::create_subsystems v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Finalize project (add assignments, create qsfs, add files to project)

    proc ::create_shell::finalize_project {project_settings parameter_array} {

        upvar ${project_settings} v_project_settings
        upvar ${parameter_array}  v_parameter_array

        puts "Finalizing project"

        set v_project_path $v_parameter_array(project,path)
        set v_project_name $v_parameter_array(project,name)

        set v_result [catch {::create_shell::add_project_assignments v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        for {set v_id 0} {${v_id} < $v_parameter_array(project,id)} {incr v_id} {
            set v_result [catch {::create_shell::create_subsystem_qsf v_parameter_array ${v_id}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }
        }

        set v_result [catch {::create_shell::add_subsystem_files v_project_settings v_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        if {[is_project_open]} {
            project_close
        }

        if {$v_project_settings(i) == 1} {
            set v_result [catch {::quartus_verification_pkg::ip_list_generate ${v_project_path} \
                                   ${v_project_name}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }
        }

        return -code ok

    }

    # Parse command line arguments; write results to project_settings array

    proc ::create_shell::parse_command_line_arguments {arguments project_settings} {

        upvar ${arguments}        v_arguments
        upvar ${project_settings} v_project_settings

        try {
            array set v_project_settings [::create_shell::parse_arguments v_arguments]

        } trap {CMDLINE HELP} {} {
            foreach v_line ${::create_shell::v_help_message} {
                puts ${v_line}
            }
            qexit -success

        } trap {CMDLINE LIST} {} {
            puts "\nSearching for available designs\n"

            set v_result [catch {::xml_parse_pkg::get_default_xml_designs ${::create_shell::v_toolkit_root} \
                                   ${::create_shell::v_script_root}} v_default_xml_designs]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_default_xml_designs}
            }

            if {[llength ${v_default_xml_designs}] == 0} {
                puts "\nNo designs found\n"
            } else {
                puts "\nAvailable designs:\n"

                foreach {v_default_xml_design v_paths} ${v_default_xml_designs} {
                    puts "  - ${v_default_xml_design}"

                    if {[llength ${v_paths}] > 1} {
                        foreach v_path ${v_paths} {
                            set v_full_path [file join ${v_path} ${v_default_xml_design}]
                            puts "      ${v_full_path}"
                        }
                    }
                }
            }

            puts ""
            qexit -success

        } trap {CMDLINE ERROR} {message} {
            return -code error ${message}
        }

        if {[string equal $v_project_settings(xml_path) ""] == 1} {
            return -code error "XML path is required"
        }

        set v_project_settings(proj_path) [file normalize $v_project_settings(proj_path)]
        set v_project_settings(xml_path)  [file normalize $v_project_settings(xml_path)]

        return -code ok

    }

    proc ::create_shell::parse_arguments {arguments} {

        upvar ${arguments} v_arguments

        set v_options [::cmdline::GetOptionDefaults ${::create_shell::v_options} v_parsed_arguments]

        # Add additional "hidden" options
        set v_options [concat ${v_options} ${::create_shell::v_hidden_options}]

        while {[set v_result [::cmdline::getopt v_arguments ${v_options} v_option v_value]]} {
            if {${v_result} < 0} {
                return -code error -errorcode {CMDLINE ERROR} ${v_value}
            }
            set v_parsed_arguments(${v_option}) ${v_value}
        }

        if {[info exists v_parsed_arguments(?)] || [info exists v_parsed_arguments(help)]} {
            return -code error -errorcode {CMDLINE HELP}
        } elseif {[info exists v_parsed_arguments(l)] || [info exists v_parsed_arguments(list)]} {
            return -code error -errorcode {CMDLINE LIST}
        }

        return [array get v_parsed_arguments]

    }

    # Check project name is valid

    proc ::create_shell::parse_project_name {project_settings parameter_array} {

        upvar ${project_settings} v_project_settings
        upvar ${parameter_array}  v_parameter_array

        # project name priority: command line -> XML design file -> default=top
        if {([string equal "" $v_project_settings(proj_name)]) == 1} {
            set v_project_settings(proj_name) $v_parameter_array(project,name)
        } else {
            set v_parameter_array(project,name) $v_project_settings(proj_name)
        }

        lappend v_parameter_array(project,params)  [list PROJECT_NAME $v_parameter_array(project,name)]

        if {([regexp {[^\w-]} $v_parameter_array(project,name)]) == 1} {
            return -code error "Error: Project name $v_parameter_array(project,name) is illegal\
                                (must contain only [a-z,A-Z,0-9,-,_])"
        }

        return -code ok

    }

    # Check project path is valid

    proc ::create_shell::parse_project_path {project_settings parameter_array} {

        upvar ${project_settings} v_project_settings
        upvar ${parameter_array}  v_parameter_array

        foreach v_subdirectory ${::create_shell::v_subdirectories} {

            set v_directory [file join $v_project_settings(proj_path) ${v_subdirectory}]

            if {[file exists ${v_directory}] == 1} {
                if {$v_project_settings(o) == 1} {
                    file delete -force -- ${v_directory}
                } else {
                    return -code error "Project directory already exists. Use flag -o to delete/overwrite\
                                        an existing project directory, or select another directory"
                }
            }

        }

        set v_parameter_array(project,path) $v_project_settings(proj_path)
        lappend v_parameter_array(project,params)  [list PROJECT_PATH $v_project_settings(proj_path)]

        return -code ok

    }

    # Create the project directory tree

    proc ::create_shell::create_directory_tree {parameter_array} {

        upvar ${parameter_array} v_parameter_array

        set v_project_path $v_parameter_array(project,path)

        set v_result [catch {file mkdir ${v_project_path}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_directories {}

        foreach v_directory ${::create_shell::v_subdirectories} {
            set v_index [lsearch ${::create_shell::v_split_subdirectories} ${v_directory}]

            if {${v_index} >= 0} {
                foreach v_split_directory ${::create_shell::v_split_directories} {
                    lappend v_directories [file join ${v_project_path} ${v_directory} ${v_split_directory}]
                }
            } else {
                lappend v_directories [file join ${v_project_path} ${v_directory}]
            }
        }

        foreach v_directory ${v_directories} {
            set v_result [catch {file mkdir ${v_directory}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }
        }

        return -code ok

    }

    # Create the Quartus project, add assignments

    proc ::create_shell::create_quartus_project {parameter_array} {

        upvar ${parameter_array} v_parameter_array

        array set v_temporary_array [join $v_parameter_array(project,params)]
        set v_project_path $v_parameter_array(project,path)
        set v_project_name $v_parameter_array(project,name)

        # Project must be created whilst in the Quartus directory to pickup quartus.ini (if any)
        set v_current_directory [pwd]
        set v_quartus_directory [file join ${v_project_path} "quartus"]

        cd ${v_quartus_directory}

        if {[is_project_open] == 1} {
            set v_result [catch {project_close} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }
        } elseif {[project_exists ${v_project_name}] == 1} {
            return -code error "Project (${v_project_name}) already exists"
        }

        set v_result [catch {project_new -family $v_temporary_array(FAMILY) -part $v_temporary_array(DEVICE) \
                                         -revision ${v_project_name} ${v_project_name}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {set_global_assignment -name IP_SEARCH_PATHS \
                               $v_temporary_array(IP_SEARCH_PATH_CONCAT)} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {export_assignments} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        cd ${v_current_directory}

        return -code ok

    }

    # Create Platform Designer subsystems

    proc ::create_shell::create_subsystems {parameter_array} {

        upvar ${parameter_array} v_parameter_array

        set v_quartus_project [file join $v_parameter_array(project,path) quartus $v_parameter_array(project,name)]

        set v_command [list ${::create_shell::v_qsys_script_exe} --script=${::create_shell::v_create_subsystem_script} \
                            ${::create_shell::v_toolkit_root} [array get v_parameter_array] \
                            --quartus-project=${v_quartus_project} 2>@1]

        set v_exit_code [::pd_handler_pkg::run ${v_command} $v_parameter_array(project,path)]

        set v_log_file [file join $v_parameter_array(project,path) quartus "platform_designer_log.txt"]

        set v_result [catch {open ${v_log_file} w} v_fid]
        if {${v_result} != 0} {
            return -code error "Unable to open file (${v_log_file}):\n${v_fid}"
        }

        puts  ${v_fid} ${::pd_handler_pkg::pd_log}
        close ${v_fid}

        if {${v_exit_code} == 1} {
            return -code error "Creation of Platform Designer system failed: see log file ${v_log_file} for details"
        }

        return -code ok

    }

    # Add assignments to the project

    proc ::create_shell::add_project_assignments {parameter_array} {

        upvar ${parameter_array}  v_parameter_array

        # Remove any edits made to the default .qsf file during subsystem creation
        remove_all_global_assignments -name *

        set v_project_name $v_parameter_array(project,name)

        array set v_temporary_array [join $v_parameter_array(project,params)]

        set v_result [catch {set_global_assignment -name FAMILY $v_temporary_array(FAMILY)} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {set_global_assignment -name DEVICE $v_temporary_array(DEVICE)} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {set_global_assignment -name IP_SEARCH_PATHS \
                               $v_temporary_array(IP_SEARCH_PATH_CONCAT)} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {set_global_assignment -name TOP_LEVEL_ENTITY ${v_project_name}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {set_global_assignment -name SEED 1} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        array unset v_temporary_array

        set v_result [catch {set_instance_assignment -name PARTITION_COLOUR 4285529948 \
                               -to ${v_project_name} -entity ${v_project_name}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {set_instance_assignment -name PARTITION_COLOUR 4294939049 \
                               -to auto_fab_0 -entity ${v_project_name}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        export_assignments

        return -code ok

    }

    # Create subsystem QSF (assign IP and Qsys files)

    proc ::create_shell::create_subsystem_qsf {parameter_array id} {

        upvar ${parameter_array} v_parameter_array

        set v_project_path $v_parameter_array(project,path)
        set v_project_name $v_parameter_array(project,name)

        set v_type $v_parameter_array(${id},type)

        set v_qsf_file      ""
        set v_file_contents {}

        if {[string equal "top" ${v_type}] == 1} {

            set v_qsf_file     [file join ${v_project_path} quartus shell "${v_project_name}_supplemental.qsf"]

            set v_verilog_file [file join . .. rtl "${v_project_name}.v"]
            set v_qsys_file    [file join . .. rtl "${v_project_name}_qsys.qsys"]

            lappend v_file_contents "set_global_assignment -name VERILOG_FILE ${v_verilog_file}"
            lappend v_file_contents "set_global_assignment -name QSYS_FILE    ${v_qsys_file}"

        } else {

            set v_folder "shell"

            if {[string equal "user" ${v_type}] == 1} {
                set v_folder "user"
            }

            set v_subsystem_name $v_parameter_array(${id},name)

            set v_quartus_directory [file join ${v_project_path} quartus]
            set v_qsf_file          [file join ${v_quartus_directory} ${v_folder} "${v_subsystem_name}.qsf"]

            set v_ip_directory   [file join ${v_project_path} rtl ${v_folder} ip ${v_subsystem_name}]
            set v_qsys_directory [file join ${v_project_path} rtl ${v_folder}]

            if {[file exists ${v_ip_directory}] == 1} {

                set v_subsystem_ip [fileutil::findByPattern ${v_ip_directory} -glob -- *.ip]

                foreach v_ip_file ${v_subsystem_ip} {
                    set v_relative_file [fileutil::relative ${v_quartus_directory} ${v_ip_file}]
                    lappend v_file_contents "set_global_assignment -name IP_FILE ${v_relative_file}"
                }

            }

            if {[file exists ${v_qsys_directory}] == 1} {

                set v_subsystem_qsys [fileutil::findByPattern ${v_qsys_directory} -glob -- "${v_subsystem_name}.qsys"]

                foreach v_qsys_file ${v_subsystem_qsys} {
                    set v_relative_file [fileutil::relative ${v_quartus_directory} ${v_qsys_file}]
                    lappend v_file_contents "set_global_assignment -name QSYS_FILE ${v_relative_file}"
                }

            }
        }

        if {[llength ${v_file_contents}] > 0} {

            set v_result [catch {open ${v_qsf_file} a+} v_fid]
            if {${v_result} != 0} {
                return -code ${v_result} "Unable to create/open file (${v_qsf_file}):\n${v_fid}"
            }

            foreach v_line ${v_file_contents} {
                puts ${v_fid} ${v_line}
            }

            close ${v_fid}
        }

        return -code ok

    }

    # Add subsystem QSF and SDC files to the project QSF

    proc ::create_shell::add_subsystem_files {project_settings parameter_array} {

        upvar ${project_settings} v_project_settings
        upvar ${parameter_array}  v_parameter_array

        # add required assignments to the default .qsf
        set v_project_path $v_parameter_array(project,path)
        set v_project_name $v_parameter_array(project,name)
        set v_xml_path     $v_project_settings(xml_path)
        set v_design_dir_path [file dirname $v_xml_path]
        set v_design_qsf    [file join ${v_design_dir_path} design.qsf]
        set v_qsf_directory [file join ${v_project_path} quartus shell]

        if {[file exists ${v_design_qsf}] == 1} {
            file copy -force ${v_design_qsf} ${v_qsf_directory}
        }

        set v_design_sdc    [file join ${v_design_dir_path} design.sdc]
        set v_sdc_directory [file join ${v_project_path} sdc shell]

        if {[file exists ${v_design_sdc}] == 1} {
            file copy -force ${v_design_sdc} ${v_sdc_directory}
        }

        set v_qsf_files_list {}
        set v_sdc_files_list {}

        foreach v_subdir ${::create_shell::v_split_directories} {

            set v_qsf_directory [file join ${v_project_path} quartus ${v_subdir}]
            set v_sdc_directory [file join ${v_project_path} sdc ${v_subdir}]

            if {[file exists ${v_qsf_directory}] == 1} {
                set v_temporary_list [fileutil::findByPattern ${v_qsf_directory} -glob -- *.qsf]
                set v_qsf_files_list [concat ${v_qsf_files_list} ${v_temporary_list}]
            }

            if {[file exists ${v_sdc_directory}] == 1} {
                set v_temporary_list [fileutil::findByPattern ${v_sdc_directory} -glob -- *.sdc]
                set v_sdc_files_list [concat ${v_sdc_files_list} ${v_temporary_list}]
            }

        }

        set v_quartus_directory [file join ${v_project_path} quartus]

        foreach v_qsf_file ${v_qsf_files_list} {
            set v_relative_file [fileutil::relative ${v_quartus_directory} ${v_qsf_file}]

            if {[string equal "${v_project_name}.qsf" ${v_relative_file}] != 1} {
                set v_result [catch {set_global_assignment -name SOURCE_TCL_SCRIPT_FILE \
                                       ${v_relative_file}} v_result_text]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_result_text}
                }
            }
        }

        foreach v_sdc_file ${v_sdc_files_list} {
            set v_relative_file [fileutil::relative ${v_quartus_directory} ${v_sdc_file}]
            set v_result [catch {set_global_assignment -name SDC_FILE ${v_relative_file}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }
        }

        return -code ok

    }

}

::create_shell::main
