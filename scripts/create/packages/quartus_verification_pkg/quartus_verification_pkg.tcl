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

# Checks the version of Quartus that is being used against the supported Quartus version of the design

package provide quartus_verification_pkg    1.0
package require Tcl                         8.0

namespace eval ::quartus_verification_pkg {
    # export functions
    namespace export evaluate_quartus ip_list_generate

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # setup
    variable supported_version_list
    variable build_path
    variable v_shell_design_root
}

# VERIFY VERSION OF QUARTUS IS SUPPORTED
# =====================================================================================================

proc ::quartus_verification_pkg::evaluate_quartus {supported_version_list} {
    # Retrieve current version of ACDS and split into the main two numbers
    regexp {[\.0-9]+} $::quartus(version) acds_env
    puts "acds $acds_env in use"

    set fields [split $acds_env "."]
    foreach field $fields {
        lassign $fields env_version_yr env_version_qt
    }

    # Check against the supported versions for the design
    if {[info exists supported_version_list]} {
        set version_ut_list [split $supported_version_list ","]
    }
    # If no supported versions are defined
    if { $version_ut_list eq "" } {
        puts "WARNING: Supported version list is empty or not specified! This may result in errors"
        return
    } else {
        # Check supported versions to environment
        foreach version_ut $version_ut_list {
            # split up year and qt releases
            set values [split $version_ut "."]
            foreach field $values {
                lassign $values sup_version_yr sup_version_qt
            }
            # Check the main version number
            if {$sup_version_yr == $env_version_yr} {
                # Check the quarterly version number
                if {$sup_version_qt == $env_version_qt} {
                    puts "PASS: This design supports $acds_env"
                    return
                }
            }
        }
    }
    # Only reaches this point if no supported versions match the current version
    puts stderr "ERROR: ACDS VERSION NOT SUPPORTED!"
    return -code error
}

# GENERATE LIST OF IP USED THE PROJECT
# =====================================================================================================

proc nsort {plist} {
  set final "" ; # for empty lists
  foreach temp $plist { lappend length([string length $temp]) $temp }
  foreach temp [lsort -integer [array names length]] { lappend final [lsort $length($temp)] }
  return [join $final]
}

proc ::quartus_verification_pkg::ip_list {item_path build_path proj_name} {
    set current_file [ dict get [ info frame 0 ] file ]
    set current_dir [file dirname $current_file]
    catch {exec -ignorestderr -- qsys-script -system-file=$item_path --script=$current_dir/ip_list_internal_call.tcl --quartus-project=$build_path/quartus/$proj_name.qpf} ip_info
    return $ip_info
}

proc ::quartus_verification_pkg::ip_list_generate {build_path proj_name} {
    set print_to_file 1

    cd $build_path/quartus
    file mkdir output_files
    set ip_version_report [open output_files/ip_information.rpt w+]
    project_open $proj_name.qpf

    catch {exec quartus_ipgenerate --get_project_ip_files $proj_name.qpf} ip_list_temp
    cd ../../

    # for each item found...
    foreach item $ip_list_temp {
        # separate the qsys files from the ip files
        if { [regexp ".qsys" $item ]} {
            # send to qsys-script environment to extract ip info
            set ip_info [::quartus_verification_pkg::ip_list $item $build_path $proj_name]
            set items [split $ip_info ","]
            foreach item $items {
                lappend ip_info_temp $item
            }
        }
    }
    # sort list and remove duplicates
    set sorted_ip_info [nsort $ip_info_temp]
    set prev_line 0
    foreach line $sorted_ip_info {
        if { $prev_line != $line } {
            if { [regexp ":" $line]} {
    		    puts $ip_version_report $line
            }
    	}
    	set prev_line $line
    }

    close $ip_version_report
    project_close
}