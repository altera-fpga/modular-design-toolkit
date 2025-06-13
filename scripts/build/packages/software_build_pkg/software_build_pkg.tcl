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

package provide software_build_pkg 1.0

package require ::quartus::project
package require fileutil

# Helper for CPU/HPS software compilation

namespace eval software_build_pkg {

    namespace export build_software

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    proc ::software_build_pkg::build_software {project_path} {

        set v_project_path ${project_path}

        set v_result_text {}
        set v_software_path     [file join ${v_project_path} "software"]
        set v_cpu_subsystems    [glob -directory ${v_software_path} -tail -type d *]

        foreach cpu_subsystem ${v_cpu_subsystems} {

            set v_make_path [file join ${v_software_path} ${cpu_subsystem}]
            set v_cmd       [list make --directory=${v_make_path}]

            append v_result_text "Running makefile for ${cpu_subsystem}: \"${v_cmd}\"\n\n"

            set v_result [catch {exec -ignorestderr -- {*}${v_cmd} 2>@1} result_text result_options]

            append v_result_text ${result_text}

            if {${v_result} == 1} {
                return -options ${result_options} ${v_result_text}
            }

        }

        return ${v_result_text}

    }

}
