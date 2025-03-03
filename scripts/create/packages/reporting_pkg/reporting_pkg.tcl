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

# REPLACES package.tcl
package provide reporting_pkg 1.0
package require Tcl           8.0
package require ::quartus::project
package require ::quartus::flow
package require ::quartus::misc
package require ::quartus::report
package require ::quartus::device
package require cmdline

namespace eval ::reporting_pkg {
  # export functions
  namespace export puts_log

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

  # setup
  variable text
  
}

# redirect console output to a log file

proc redirect_file {log filename cmd} {

  if {$log} {

    variable ::argv0 $::quartus(args)
    uplevel $cmd
    rename puts ::tcl::orig::puts

    set mode a
    set destination [open $filename $mode]

    proc puts args "uplevel \"::tcl::orig::puts $destination \$args\"; return"

    uplevel $cmd

    close $destination

    rename puts {}
    rename ::tcl::orig::puts puts

  } else {
    uplevel $cmd
  }

}

# write text to a log file

proc ::reporting_pkg::puts_log {text} {
  redirect_file $::v_log $::v_log_filename {puts $text}
}
