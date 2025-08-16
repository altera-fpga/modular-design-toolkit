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

package provide utils_pkg 1.0

package require Tcl       8.0

set script_dir    [file dirname [info script]]
lappend auto_path [file join ${script_dir} ".."]

# Miscellaneous helper functions

namespace eval utils_pkg {

    namespace export file_copy

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # Recursive file copy

    proc ::utils_pkg::file_copy {source destination {level 0}} {

        # Note : qsys-script only supports the -nocomplain flag for glob so will only work
        #        in the current directory, hence the procedure traverses the input directory
        #        structure via the cd command.

        set v_saved_directory [pwd]

        set v_type [file type ${source}]

        if {(${v_type} != "directory") && (${v_type} != "file")} {
            return -code error "file_copy - source folder / file is a symlink (${source})"
        }

        if {(${level} == 0)} {
            if {[file exists ${source}] == 0} {
                return -code error "file_copy - source folder / file does not exist (${source})"
            }

            # Check for copy type: file -> file, file -> dir, dir -> dir
            if {[file isdirectory ${source}] == 1} {
                if {[::utils_pkg::string_isfile ${destination}] == 1} {
                    return -code error "file_copy - cannot copy a directory to a file (${source} -> ${destination})"
                } else {
                    # Replicate Linux 'cp' behavior
                    # <path>/<dir>/. copies only the contents of <dir>, not <dir> itself
                    # <path>/<dir>/  copies <dir> and its contents

                    if {[string match */. ${source}] == 0} {
                        set v_tail      [file tail ${source}]
                        set destination [file join ${destination} ${v_tail}]
                    } else {
                        set source [string trimright ${source} "."]
                    }
                }
            } else {
                if {[::utils_pkg::string_isfile ${destination}] == 0} {

                    if {[file exists ${destination}] == 0} {
                        file mkdir ${destination}
                    }

                    # file -> dir : need to append filename to destination
                    set v_tail [file tail ${source}]
                    set destination [file join ${destination} ${v_tail}]
                }
            }
        }

        if {[file isdirectory ${source}] == 1} {

            if {[file exists ${destination}] == 0} {
                file mkdir ${destination}
            }

            cd ${source}

            set v_objects [glob -nocomplain *]

            foreach v_object ${v_objects} {
                set v_source_object      [file join ${source} ${v_object}]
                set v_destination_object [file join ${destination} ${v_object}]
                set v_level              [expr ${level} + 1]

                ::utils_pkg::file_copy ${v_source_object} ${v_destination_object} ${v_level}
            }

        } else {

            if {[file exists ${destination}] == 0} {
                file copy -force ${source} ${destination}
            }

        }

        cd ${v_saved_directory}

        return -code ok

    }

    # Check string is a file (isfile / isdirectory does not work on non-existent objects)

    proc ::utils_pkg::string_isfile {input} {

        if {[info exists ::tcl_platform(host_platform)] == 1} {
            set v_platform ${::tcl_platform(host_platform)}
        } elseif {[info exists ::tcl_platform(os)] == 1} {
            set v_platform ${::tcl_platform(os)}
        } else {
            return -code error "file_copy : unknown file separator"
        }

        if {[string match -nocase "*unix*" ${v_platform}] == 1} {
            set v_separator "/"
        } elseif {[string match -nocase "*linux*" ${v_platform}] == 1} {
            set v_separator "/"
        } elseif {[string match -nocase "*windows*" ${v_platform}] == 1} {
            set v_separator "\\"
        } else {
            return -code error "file_copy : unknown file separator"
        }

        if {[string match "*${v_separator}" ${input}]} {
            return -code ok 0
        } else {
            set v_input_tail      [file tail ${input}]
            set v_input_split     [split ${v_input_tail} "."]
            set v_input_split_len [llength ${v_input_split}]

            if {${v_input_split_len} == 1} {
                return -code ok 0
            } else {
                set v_input_end     [lindex ${v_input_split} end-1]
                set v_input_end_len [llength ${v_input_end}]

                if {${v_input_end_len} > 0} {
                    return -code ok 1
                } else {
                    return -code error "filename error - file cannot end with a '.'"
                }
            }
        }

        return -code error "function error"

    }

    # Recursive mkdir (equivalent to 'mkdir -p <source>')

    proc ::utils_pkg::recursive_mkdir {source} {

        set v_source_split [file split ${source}]

        foreach v_subdirectory ${v_source_split} {
            set v_directory [file join ${v_directory} ${v_subdirectory}]

            if {[file exists ${v_directory}] == 0} {
                file mkdir ${v_directory}
            }
        }

        return -code ok

    }

}
