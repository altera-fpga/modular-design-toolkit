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

package provide archive_pkg 1.0

package require fileutil

# Helper to create a Quartus archive (.qar) from a Quartus project

namespace eval archive_pkg {

    namespace export create_archive

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    variable project_path ""
    variable fileset      {}

    proc ::archive_pkg::create_archive {proj_path qar_name fileset_file} {

        variable project_path
        set project_path ${proj_path}

        ::archive_pkg::init_fileset

        if {${fileset_file} != ""} {
            ::archive_pkg::parse_fileset_file ${fileset_file}
        }

        ::archive_pkg::save_fileset

        set v_result [catch {::archive_pkg::create_qar ${qar_name}} result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # search the project directory for files to archive

    proc ::archive_pkg::init_fileset {} {

        variable project_path
        variable fileset

        # list of directories and file extensions to search for
        set v_recursive_find {}
        set v_current_find   {}

        # add non_qpds_ip directories
        set v_non_qpds_ip_directories [::archive_pkg::find_directories "non_qpds_ip"]

        foreach v_directory ${v_non_qpds_ip_directories} {
            set v_sub_dir [file join "non_qpds_ip" ${v_directory}]

            # special case for dsp builder models
            if {${v_directory} == "dsp_builder_models"} {
                lappend v_recursive_find [list ${v_sub_dir} {*.slx *.m}]
            } else {
                lappend v_current_find [list ${v_sub_dir} {*.ipx *.qprs *.arch}]
                set v_ip_directories [::archive_pkg::find_directories ${v_sub_dir}]
                foreach ip ${v_ip_directories} {
                    set v_ip_dir [file join ${v_sub_dir} ${ip}]
                    lappend v_recursive_find [list ${v_ip_dir} {*}]
                }
            }
        }

        # add other Quartus directories
        lappend v_recursive_find [list "quartus" {*.qsf *.qpf *.tcl}]
        lappend v_recursive_find [list "rtl"     {*.qsys *.ip}]
        lappend v_recursive_find [list "sdc"     {*.sdc}]
        lappend v_current_find   [list "rtl"     {*.v}]

        # add software subdirectories
        set v_software_directories [::archive_pkg::find_directories "software"]

        foreach v_directory ${v_software_directories} {
            set v_root_dir [file join software ${v_directory}]
            set v_app_dir  [file join ${v_root_dir} app]
            lappend v_recursive_find [list ${v_app_dir} {*}]
            lappend v_current_find   [list ${v_root_dir} {*.bsp}]
        }

        # add generated files
        lappend v_recursive_find [list [file join "quartus" "output_files"] {*.sof}]

        foreach v_directory ${v_software_directories} {
            set v_root_dir [file join software ${v_directory}]
            lappend v_recursive_find [list [file join ${v_root_dir} "build" "bin"] {*.elf *.hex}]
        }

        # generate list of files using recursive search and add to fileset
        foreach v_item ${v_recursive_find} {
            set v_directory     [lindex ${v_item} 0]
            set v_extensions    [lindex ${v_item} 1]
            set v_abs_directory [file join ${project_path} ${v_directory}]

            set v_files [::archive_pkg::find_files_recursive ${v_abs_directory} ${v_extensions}]
            set fileset [list {*}${fileset} {*}${v_files}]
        }

        # generate list of files using non-recursive search and add to fileset
        foreach v_item ${v_current_find} {
            set v_directory     [lindex ${v_item} 0]
            set v_extensions    [lindex ${v_item} 1]
            set v_abs_directory [file join ${project_path} ${v_directory}]

            set v_files [::archive_pkg::find_files_current ${v_abs_directory} ${v_extensions}]
            set fileset [list {*}${fileset} {*}${v_files}]
        }

        return

    }

    # parse a user fileset file, add its contents to the current fileset

    proc ::archive_pkg::parse_fileset_file {fileset_file} {

        variable fileset

        set v_fileset_file_dir [file dirname ${fileset_file}]

        set v_fid  [open ${fileset_file} r]
        set v_data [read ${v_fid}]
        close ${v_fid}

        set v_lines [split ${v_data} "\n"]

        foreach line ${v_lines} {

            # clean input line, remove whitespace/comments
            set v_trimmed [string trim ${line}]
            set v_index   [string first "#" ${v_trimmed} 0]

            if {${v_index} >= 0} {
                set v_trimmed [string replace ${v_trimmed} ${v_index} end ""]
                set v_trimmed [string trim ${v_trimmed}]
            }

            if {[string length ${v_trimmed}] == 0} {
                continue
            }

            # convert relative paths to absolute paths
            if {[file pathtype ${v_trimmed}] == "relative"} {
                set v_abs_path [file join ${v_fileset_file_dir} ${v_trimmed}]
            } else {
                set v_abs_path ${v_trimmed}
            }

            set v_abs_path [file normalize ${v_abs_path}]

            if {[file exists ${v_abs_path}]} {
                lappend fileset ${v_abs_path}
            } else {
                post_message -type warning "archive_pkg: Unable to find file provided by external fileset (${v_abs_path})"
            }

        }

        return

    }

    # save fileset to a text file

    proc ::archive_pkg::save_fileset {} {

        variable project_path
        variable fileset

        set v_output_dir  [file join ${project_path} "quartus" "output_files"]
        set v_output_file [file join ${v_output_dir} "qar_fileset.txt"]

        if {[file exists ${v_output_dir}] == 0} {
            mkdir ${v_output_dir}
        }

        set v_fid [open ${v_output_file} "w"]

        foreach line ${fileset} {
            puts ${v_fid} ${line}
        }

        close ${v_fid}

        return

    }

    # create QAR of the project from the generated fileset

    proc ::archive_pkg::create_qar {qar_name} {

        variable project_path

        set v_qar_fileset_file [file join ${project_path} "quartus" "output_files" "qar_fileset.txt"]
        set v_qar_file         [file join ${project_path} "quartus" "output_files" "${qar_name}.qar"]

        set v_cmd [list quartus_sh --archive -input ${v_qar_fileset_file} -output ${v_qar_file}]

        set v_result [catch {exec -ignorestderr -- {*}${v_cmd} 2>@1} result_text result_options ]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # find sub-directories of the given path (relative to project path)

    proc ::archive_pkg::find_directories {relative_directory} {

        variable project_path

        set v_root_dir [file join ${project_path} ${relative_directory}]
        set v_output   [glob -nocomplain -directory ${v_root_dir} -tails -type d *]

        return ${v_output}

    }

    # find files with the specified extensions recursively

    proc ::archive_pkg::find_files_recursive {directory extensions} {

        set v_files {}

        # check directory exists as findbypattern doesn't have a nocomplain flag
        if {[file exists ${directory}]} {
            foreach extension ${extensions} {
                set v_results [fileutil::findByPattern ${directory} -glob -- ${extension}]
                foreach item ${v_results} {
                    if {[file isfile ${item}]} {
                        lappend v_files ${item}
                    }
                }
            }
        }

        return ${v_files}

    }

    # find files with the specified extensions non-recursively

    proc ::archive_pkg::find_files_current {directory extensions} {

        set v_output_files {}

        foreach extension ${extensions} {
            set v_files [glob -nocomplain -directory ${directory} -type f -- ${extension}]
            set v_output_files {} [list {*}${v_output_files} {*}${v_files}]
        }

        return ${v_output_files}

    }

}
