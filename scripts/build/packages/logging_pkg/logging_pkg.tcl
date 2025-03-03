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

package provide logging_pkg 1.0

package require ::quartus::project
package require ::quartus::flow
package require ::quartus::misc
package require ::quartus::report
package require ::quartus::device
package require cmdline

# Helper to create (Quartus style) reports for build steps that do not automatically
# create them.

namespace eval logging_pkg {

    namespace export set_logging set_proj_settings init_log gen_log

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    variable v_log_file    ""
    variable v_log_enabled 1

    variable v_project_directory
    variable v_project_name

    proc ::logging_pkg::set_logging {enable} {

        variable v_log_enabled
        set v_log_enabled $enable

        return

    }

    proc ::logging_pkg::set_proj_settings {project_directory project_name} {

        variable v_project_directory
        variable v_project_name

        set v_project_directory ${project_directory}
        set v_project_name      ${project_name}

        return

    }

    proc ::logging_pkg::init_log {title extension} {

        variable v_project_directory
        variable v_project_name

        ::logging_pkg::set_log_file [file join ${v_project_directory} "quartus" "output_files" "${v_project_name}.${extension}.rpt"]

        set v_current_time [clock seconds]
        set v_current_date [clock format ${v_current_time} -format {%a %b %d %H:%M:%S %Y}]

        ::logging_pkg::gen_log "${title} Report"
        ::logging_pkg::gen_log ${v_current_date}
        ::logging_pkg::gen_log $::quartus(version)
        ::logging_pkg::gen_log "\n"
        ::logging_pkg::gen_log "+-------------------------------+"
        ::logging_pkg::gen_log "; ${title} Messages ;"
        ::logging_pkg::gen_log "+-------------------------------+"

        return

    }

    proc ::logging_pkg::set_log_file {file} {

        variable v_log_file
        variable v_log_enabled

        set v_log_file ${file}

        if {${v_log_enabled}} {

            set v_directory [file dirname ${v_log_file}]

            if {[file exists ${v_directory}] == 0} {
                file mkdir ${v_directory}
            }

            set v_fid [open ${v_log_file} w+]
            close ${v_fid}

        }

        return

    }

    proc ::logging_pkg::get_log_file {} {

        variable v_log_file
        return ${v_log_file}

    }

    proc ::logging_pkg::gen_log {message} {

        variable v_log_file
        variable v_log_enabled

        if {${v_log_enabled}} {

            set v_fid [open ${v_log_file} a+]
            puts  ${v_fid} ${message}
            close ${v_fid}

        }

        return

    }

}
