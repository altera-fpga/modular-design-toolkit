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

package provide query_pkg     1.0
package require Tcl           8.0

set script_dir [file dirname [info script]]
lappend auto_path "$script_dir/../"

package require subsystems_pkg     1.0

namespace eval ::query_pkg {
  
  # export commands
  namespace export generate_quartus_ini_file

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

}

# open the file and extract the quartus ini flags;
# return a list of strings

proc ::query_pkg::get_quartus_ini_flags_from_file {ini_file source_path} {

  set local_ini_flags {}

  if {[file pathtype $ini_file] == "relative"} {
    set ini_file [file normalize [file join [file dirname $source_path] $ini_file]]
  }

  if {[file exists $ini_file]} {
    
    set file_ptr [open $ini_file r]
    set file_data [read $file_ptr]
    close $file_ptr

    set file_lines [split $file_data "\n"]
    set cleaned_lines {}

    foreach line $file_lines {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend cleaned_lines $line
      }
    }

    set local_ini_flags [list {*}$local_ini_flags {*}$cleaned_lines]
    
  } else {
    return -code error "Path $ini_file does not exist"
  }

  return $local_ini_flags

}

# collect all quartus ini flags from the project xml file and subsystems;
# return a list of strings

proc ::query_pkg::get_quartus_ini_flags {xml_array_link} {

  upvar $xml_array_link xml_array

  set global_ini_flags  {}
  set local_ini_flags   {}

  # check project level parameters (stored as a list of [name value] pairs)

  set param_list $xml_array(project,params)
  set cleaned_param_list {}

  foreach param_pair $param_list {

    set param_name  [lindex $param_pair 0]
    set param_value [lindex $param_pair 1]

    if {$param_name == "QUARTUS_INI_COMMAND"}  {
      set local_ini_flags [list {*}$local_ini_flags {*}$param_value]

    } elseif {$param_name == "QUARTUS_INI_FILE"} {
      set source_path $xml_array(project,xml_path)
        
      foreach ini_file $param_value {
        set ini_flags [::query_pkg::get_quartus_ini_flags_from_file $ini_file $source_path]
        set local_ini_flags [list {*}$local_ini_flags {*}$ini_flags]
      }

    } else {
      lappend cleaned_param_list $param_pair
    }

  }

  if {[llength $local_ini_flags] > 0} {
    lappend global_ini_flags "# project flags"
    set global_ini_flags [list {*}$global_ini_flags {*}$local_ini_flags]
    lappend global_ini_flags ""
  }

  # check subsystem level parameters (stored as an array within the namespace)

  # Update the project parameter list to remove the quartus ini parameters.
  # This stops the subsystem parameters from being overwritten by the project
  # level parameters.
  set xml_array(project,params) $cleaned_param_list

  # create a temporary version of the subsystems to query their parameters
  set namespaces_list [::subsystems_pkg::create_namespaces xml_array 0]

  foreach curr_ns $namespaces_list {

    set local_ini_flags {}

    # check for ini command parameter
    if {[info exists ${curr_ns}::param_array(QUARTUS_INI_COMMAND)]} {
      set ini_flags [set ${curr_ns}::param_array(QUARTUS_INI_COMMAND)]
      set local_ini_flags [list {*}$local_ini_flags {*}$ini_flags]
    }

    # check for ini file paramter
    if {[info exists ${curr_ns}::param_array(QUARTUS_INI_FILE)]} {
      set ini_files [set ${curr_ns}::param_array(QUARTUS_INI_FILE)]
      set source_path [set ${curr_ns}::param_array(SUBSYSTEM_SOURCE_PATH)]
      
      puts "ini files ($curr_ns): $ini_files"

      foreach ini_file $ini_files {
        set ini_flags [::query_pkg::get_quartus_ini_flags_from_file $ini_file $source_path]
        set local_ini_flags [list {*}$local_ini_flags {*}$ini_flags]
      }

    }

    if {[llength $local_ini_flags] > 0} {
      set instance_name [set ${curr_ns}::param_array(INSTANCE_NAME)]
      lappend global_ini_flags "# $instance_name flags"
      set global_ini_flags [list {*}$global_ini_flags {*}$local_ini_flags]
      lappend global_ini_flags ""
    }

    namespace delete ::$curr_ns

  }

  return $global_ini_flags

}

# create quartus.ini file at the given path using information
# from the xml_array

proc ::query_pkg::create_quartus_ini_file {path xml_array_link} {

  upvar $xml_array_link xml_array

  if {![file exists $path]} {
    return -code error "Path $path does not exist"
  } elseif {![file isdirectory $path]} {
    return -code error "Path $path is not a directory"    
  }

  set file_path [file join $path "quartus.ini"]
  set contents  [::query_pkg::get_quartus_ini_flags xml_array]

  if {[llength $contents] > 0} {
    set file_ptr [open $file_path w]
    foreach line $contents {
      puts $file_ptr $line
    }
    close $file_ptr
  }

}