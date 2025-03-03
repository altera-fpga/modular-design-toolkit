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

package provide utils_pkg  1.0
package require Tcl             8.0

set script_dir [file dirname [info script]]
lappend auto_path "$script_dir/../"

namespace eval ::utils_pkg {

  # Export functions
  namespace export file_copy

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

}

# note : qsys-script only supports the -nocomplain flag for glob so will only work
#        in the current dirrectory, hence the procedure traverses the input directory
#        structure via the cd command. 

proc ::utils_pkg::file_copy {src dst {level 0}} {

  #puts "Debug : file_copy $src -> $dst"

  set saved_pwd [pwd]

  # always check that the folder/file is not a symbolic link
  set file_type [file type $src]

  if {($file_type != "directory") && ($file_type != "file")} {
    return -code error "file_copy - source folder / file is a symlink ($src)"
  }

  # perform the following checks on first call
  if {($level == 0)} {

    if {![file exists $src]} {
      return -code error "file_copy - source folder / file does not exist ($src)"
    }

    # check for copy : file -> file, file -> dir, dir -> dir
    if {[file isdirectory $src]} {

      if {[string_isfile $dst]} {
        return -code error "file_copy - cannot copy a directory to a file ($src -> $dst)"
      } else {
    
        # replicate linux cp command  
        # <path>/<dir>/. copies only the contents of <dir>, not <dir> itself
        # <path>/<dir>/  copies <dir> and its contents

        if {![string match */. $src]} {
          set tmp [file tail $src]
          set dst [file join $dst $tmp]
        } else {
          # remove trailing '.' (for neatness)
          set src [string trimright $src "."]
        }

      }

    } else {

      if {![string_isfile $dst]} {

        if {![file exists $dst]} {
          file mkdir $dst
        }

        # file -> dir : need to append filename to desination
        set tmp [file tail $src]
        set dst [file join $dst $tmp]

      }

    }

  }

  #-----------------------------------

  # if src is a directory
  if {[file isdirectory $src]} {

    if {![file exists $dst]} {
      file mkdir $dst
    }

    # get all objects in the directory (sub-directories & files)
    
    cd $src

    set objects [glob -nocomplain *]

    foreach object $objects {
    
      # convert to full paths
      set src_object [file join $src $object]
      set dst_object [file join $dst $object]
    
      # call file_copy (recursively)
      set level [expr $level + 1]
      file_copy $src_object $dst_object $level

    }

  } else {

    puts "Debug : copying file : $src -> $dst"
    file copy -force $src $dst

  }

  cd $saved_pwd

  return

}

# Check that the string is a file, used to check the destination of a folder/file copy.
# The standard isfile / isdirectory does not work on non-existent objects

proc ::utils_pkg::string_isfile {input} {

  # get the file system path separator

  if {[info exists ::tcl_platform(host_platform)]} {
    set platform $::tcl_platform(host_platform)
  } elseif {[info exists ::tcl_platform(os)]} {
    set platform $::tcl_platform(os)
  } else {
    return -code error "file_copy : unknown file separator"
  }

  if {[string match -nocase "*unix*" $platform]} {
    set sep "/"
  } elseif {[string match -nocase "*linux*" $platform]} {
    set sep "/"
  } elseif {[string match -nocase "*windows*" $platform]} {
    set sep "\\"
  } else {
    return -code error "file_copy : unknown file separator"
  }

  if {[string match "*${sep}" $input]} {

    # string ends in a separator so it is a directory
    return -code ok 0

  } else {

    # the string could be a file
    set input_tail      [file tail $input]

    set input_split     [split $input_tail "."]
    set input_split_len [llength $input_split]

    if {$input_split_len == 1} {
      # there is no "." so is a directory
      return -code ok 0
    } else {
    
      set input_end     [lindex $input_split end-1]
      set input_end_len [llength $input_end]

      if {$input_end_len > 0} {
        # the file format is correct
        return -code ok 1
      } else {
        # there is an error in the filename
        return -code error "filename error - file cannot end with a '.'"
      }

    }

  }

  # there is an error in the function
  return -code error "function error"

}

# 
#

proc ::utils_pkg::recursive_mkdir {src} {

  set src_split [file split $src]
  set dir ""

  foreach part $src_split {
    set dir [file join $dir $part]
    #puts "Debug : recursive directory : $dir"
    if {![file exists $dir]} {
      puts "Debug : recursive directory : $dir"
      file mkdir $dir
      #set atts [file attributes $v_proj_path/$root/$sub -permissions]
      #puts "Debug : $atts"
    }
  }

}

#======================================================================================
#

#

proc ::utils_pkg::debug_message {global_debug_level subsystem_name debug_level message } {

  # debug levels
  #
  # 3 - all
  # 2 - external + internal procedure calls  
  # 1 - external procedure calls
  # 0 - off

  if {$global_debug_level >= $debug_level} {
    puts "$subsystem_name : $message"
  }

}