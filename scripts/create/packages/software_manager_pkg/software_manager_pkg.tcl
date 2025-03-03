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

package provide software_manager_pkg 1.0

package require Tcl                8.0

# this package takes in an array of the following format
#  
# array(project_name)
# array(project_directory)
# array(instance_name)
# array(cpu_type)
# array(application_dir)
# array(bsp_type)
# array(bsp_settings_file)
# array(custom_cmakefile)
# array(custom_makefile)

# Nios V only
# array(memory_base)
# array(memory_size)

namespace eval ::software_manager_pkg {

  namespace export  initialize_software

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

  # initialize the software for a specific subsystem instance
  proc initialize_software {software_array} {

    upvar $software_array soft_array

    set v_result [catch {validate_array soft_array} result_text] 

    if {$v_result == 0} {    
      transfer_files soft_array
      create_shell_makefile soft_array
    } else {
      puts "Error in initialize_software command"
      puts $result_text
    }

  }

  proc print_array {software_array} {

    upvar $software_array soft_array

    set v_project_name            $soft_array(project_name)      
    set v_project_path            $soft_array(project_directory)
    set v_instance_name           $soft_array(instance_name)
    set v_user_cpu_type           $soft_array(cpu_type)

    if {$v_user_cpu_type == "NIOSV"} {
      set v_memory_base             $soft_array(memory_base)
      set v_memory_size             $soft_array(memory_size)
    }

    set v_user_bsp_type           $soft_array(bsp_type)
    set v_user_bsp_settings_file  $soft_array(bsp_settings_file)
    set v_user_app_dir            $soft_array(application_dir)
    set v_user_custom_cmakefile   $soft_array(custom_cmakefile)
    set v_user_custom_makefile    $soft_array(custom_makefile)

    puts "=========================================="
    puts "============= Software Array ============="
    puts "=========================================="
    puts ""
    puts "project name:  $v_project_name"
    puts "project path:  $v_project_path"
    puts "instance name: $v_project_name"
    puts "cpu type:      $v_project_name"
    puts ""
    
    if {$v_user_cpu_type == "NIOSV"} {
      puts "memory base:      $v_memory_base"            
      puts "memory size:      $v_memory_size"  
      puts ""          
    }
    
    puts "bsp type:         $v_user_bsp_type"
    puts "bsp file:         $v_user_bsp_settings_file"
    puts "application dir:  $v_user_app_dir"
    puts "custom cmakefile: $v_user_custom_cmakefile"
    puts "custom makefile:  $v_user_custom_makefile"
    puts ""
    puts "=========================================="

  }

  # check that the software parameters are valid
  # all parameters not directly declared by the user are assumed to be correct
  proc validate_array {software_array} {

    upvar $software_array soft_array

    set v_instance_name           $soft_array(instance_name)

    set v_user_cpu_type           $soft_array(cpu_type)

    set v_user_bsp_type           $soft_array(bsp_type)
    set v_user_bsp_settings_file  $soft_array(bsp_settings_file)
    set v_user_app_dir            $soft_array(application_dir)
    set v_user_custom_cmakefile   $soft_array(custom_cmakefile)
    set v_user_custom_makefile    $soft_array(custom_makefile)

    # check application directories are provided, and exist

    if {$v_user_app_dir == ""} { 
      send_message WARNING "No application directory provided for ($v_instance_name), skipping software manager"
      return -code ok      "No application directory provided for ($v_instance_name), skipping software manager"
    } else {
      foreach path $v_user_app_dir {
        if {[file exists $path] != 1} {
          send_message ERROR "Application directory path ($path) does not exist"
          return -code error "Application directory path ($path) does not exist"
        }
      }
    }

    # check CPU type is supported
    set cpu_types [list "NIOSII" "NIOSV" "HPS"]
    if {[lsearch -exact $cpu_types $v_user_cpu_type] == -1} {
      send_message ERROR "CPU type must be one of the following values $cpu_types (given $v_user_cpu_type)"
      return -code error "CPU type must be one of the following values $cpu_types (given $v_user_cpu_type)"
    }

    # check BSP type is valid

    if {$v_user_cpu_type == "NIOSV"} {
      set bsp_types [list "hal" "ucosii"]
    } elseif {$v_user_cpu_type == "NIOSII"} {
      set bsp_types [list "hal" "ucosii" "freertos"]
    }

    if {$v_user_cpu_type != "HPS"} {
      if {[lsearch -exact $bsp_types $v_user_bsp_type] == -1} {
        send_message ERROR "BSP type must be one of the following values $bsp_types (given $v_user_bsp_type)"
        return -code error "BSP type must be one of the following values $bsp_types (given $v_user_bsp_type)"
      }
    }

    # check bsp settings file exists

    if {$v_user_bsp_settings_file != ""} {
      if {[llength $v_user_bsp_settings_file] > 1} {
        send_message ERROR "Only one bsp settings file can be declared"
        return -code error "Only one bsp settings file can be declared"
      } else {
        if {[file exists $v_user_bsp_settings_file] != 1} {
          send_message ERROR "bsp_settings file ($v_user_bsp_settings_file) does not exist"
          return -code error "bsp_settings file ($v_user_bsp_settings_file) does not exist"
        } else {
          if {[file isfile $v_user_bsp_settings_file] != 1} {
            send_message ERROR "bsp_settings file ($v_user_bsp_settings_file) is not a file"
            return -code error "bsp_settings file ($v_user_bsp_settings_file) is not a file"
          }
        }
      }
    }

    # check the application cmakefile option is binary

    if {[lsearch -exact [list "0" "1"] $v_user_custom_cmakefile] == -1} {
      send_message ERROR "custom cmakefile value must be either 0 or 1 (given $v_user_custom_cmakefile)"
      return -code error "custom cmakefile value must be either 0 or 1 (given $v_user_custom_cmakefile)"
    }

    # check the application makefile option is binary

    if {[lsearch -exact [list "0" "1"] $v_user_custom_makefile] == -1} {
      send_message ERROR "custom makefile value must be either 0 or 1 (given $v_user_custom_makefile)"
      return -code error "custom makefile value must be either 0 or 1 (given $v_user_custom_makefile)"
    }

    # if using HPS there must be a custom cmake/makefile
    if {$v_user_cpu_type == "HPS"} {
      if {(($v_user_custom_cmakefile == 0) && ($v_user_custom_makefile == 0)) || \
          (($v_user_custom_cmakefile == 1) && ($v_user_custom_makefile == 1))} {
        send_message ERROR "for HPS either custom makefile or custom cmakefile must be enabled"
        return -code error "for HPS either custom makefile or custom cmakefile must be enabled"
      }
    }

    # check the application cmakefile exists in the expected location (if not auto generated)
    # i.e. <instance_name>/app/cmakefile 

    if {$v_user_custom_cmakefile == 1} {

      set v_valid_cmakefiles [list CMakeLists.txt]
      set v_found_cmakefile 0

      foreach v_path $v_user_app_dir {

        # check if the file path points to a cmakefile
        if {[file isfile $v_path] == 1} {
          set v_filename [file tail $v_path]
          if {[lsearch -exact $v_valid_cmakefiles $v_filename] >= 0} {
            set v_found_cmakefile 1
            break
          }

        # check if the directory contains a cmakefile at the root
        } elseif {[file isdirectory $v_path] == 1} {
          set v_path_tail [file tail $v_path]

          # path ending with . indicates the folder contents will be copied directly into
          # the app folder (see documentation on the command 'cp')
          if {$v_path_tail == "."} {

            # create path for all possible cmakefile names and check if they exist
            foreach v_name $v_valid_cmakefiles {
              set v_cmakefile_name [file join $v_path $v_name]
              if {[file exists $v_cmakefile_name] == 1} {
                set v_found_cmakefile 1
                break
              }
            }
          }
        } else {
          # ignore this case
        }
      }

      if {$v_found_cmakefile == 0} {
        send_message ERROR "No cmakefile found in application directory"
        return -code error "No cmakefile found in application directory"
      }
    }


    # check the application makefile exists in the expected location (if not auto generated)
    # i.e. <instance_name>/app/makefile 

    if {$v_user_custom_makefile == 1} {

      set v_valid_makefiles [list Makefile makefile GNUmakefile]
      set v_found_makefile 0

      foreach v_path $v_user_app_dir {

        # check if the file path points to a makefile
        if {[file isfile $v_path] == 1} {
          set v_filename [file tail $v_path]
          if {[lsearch -exact $v_valid_makefiles $v_filename] >= 0} {
            set v_found_makefile 1
            break
          }

        # check if the directory contains a makefile at the root
        } elseif {[file isdirectory $v_path] == 1} {
          set v_path_tail [file tail $v_path]

          # path ending with . indicates the folder contents will be copied directly into
          # the app folder (see documentation on the command 'cp')
          if {$v_path_tail == "."} {

            # create path for all possible makefile names and check if they exist
            foreach v_name $v_valid_makefiles {
              set v_makefile_name [file join $v_path $v_name]
              if {[file exists $v_makefile_name] == 1} {
                set v_found_makefile 1
                break
              }
            }
          }
        } else {
          # ignore this case
        }
      }

      if {$v_found_makefile == 0} {
        send_message ERROR "No makefile found in application directory"
        return -code error "No makefile found in application directory"
      }
    }

    return

  }

  # from the project parameters transfer all software files into the default shell locations
  proc transfer_files {software_array} {

    upvar $software_array soft_array

    set v_project_name            $soft_array(project_name)
    set v_project_path            $soft_array(project_directory)
    set v_instance_name           $soft_array(instance_name)
    
    set v_user_cpu_type               $soft_array(cpu_type)
    set v_user_bsp_settings_file      $soft_array(bsp_settings_file)
    set v_user_bsp_settings_file_name [file tail $v_user_bsp_settings_file]
    set v_user_app_dir                $soft_array(application_dir)
    set v_user_custom_cmakefile       $soft_array(custom_cmakefile)
    set v_user_custom_makefile        $soft_array(custom_makefile)

    set v_shell_software_dir      [file join ${v_project_path} software ${v_instance_name}]
    set v_shell_app_dir           [file join ${v_shell_software_dir} app]

    set v_shell_makefile          [file join $::software_manager_pkg::pkg_dir makefile.terp]
    set v_shell_app_makefile      [file join $::software_manager_pkg::pkg_dir app_defines.mk.terp]

    # create directory for the software application
    file mkdir ${v_shell_app_dir}

    # copy the user defined application directories to the new application directory
    foreach dir $v_user_app_dir {
      file_copy $dir $v_shell_app_dir
    }

    # if using a custom bsp settings file, copy the bsp settings file to the software directory
    if {$v_user_bsp_settings_file != ""} {
      file copy -force $v_user_bsp_settings_file $v_shell_software_dir
      update_bsp_settings [file join $v_shell_software_dir $v_user_bsp_settings_file_name] $v_project_name
    }

    # if the application is using a custom application makefile copy the app_defines makefile to
    # the application directory
    if {($v_user_custom_makefile == 1)} {
      file copy -force $v_shell_app_makefile $v_shell_software_dir
    }

    # create a qsf file for the subsystem to add the memory initialization file (.qip) to the project
    if {$v_user_cpu_type != "HPS"} {
      create_qsf_file soft_array
    }

    # copy the shell makefile to the software directory for build automation of the BSP and application
    if {$v_user_cpu_type == "NIOSV"} {
      set v_shell_makefile [file join $::software_manager_pkg::pkg_dir makefile_niosv.terp]
    } elseif {$v_user_cpu_type == "HPS"} {
      set v_shell_makefile [file join $::software_manager_pkg::pkg_dir makefile_hps.terp]
    }
    
    file copy -force $v_shell_makefile [file join $v_shell_software_dir makefile.terp]

  }

  # From the project parameters create a makefile to automate the BSP generation and software compilation
  # of a specific subsystem instance. This file will be used by the build_shell.tcl script as appropriate
  proc create_shell_makefile { software_array } {

    upvar $software_array soft_array

    # convert the array into a list for terp evaluation

    set v_parameter_list {}
    lappend v_parameter_list  $soft_array(project_name)
    lappend v_parameter_list  $soft_array(instance_name)
    lappend v_parameter_list  $soft_array(cpu_type)
    lappend v_parameter_list  $soft_array(bsp_type)
    lappend v_parameter_list  [file tail $soft_array(bsp_settings_file)]
    lappend v_parameter_list  $soft_array(custom_cmakefile)    
    lappend v_parameter_list  $soft_array(custom_makefile)

    if {$soft_array(cpu_type) == "NIOSV"} {
      set memory_end [ expr $soft_array(memory_base) + $soft_array(memory_size) - 1 ]
      set memory_end [format 0x%08X $memory_end]

      lappend v_parameter_list $soft_array(memory_base)
      lappend v_parameter_list ${memory_end}
    }

    set v_project_path          $soft_array(project_directory)
    set v_instance_name         $soft_array(instance_name)
    set v_user_custom_makefile  $soft_array(custom_makefile)
    set v_user_cpu_type         $soft_array(cpu_type)

    set v_shell_software_dir  [file join ${v_project_path} software ${v_instance_name}]
    
    set v_shell_makefile      [file join ${v_shell_software_dir} makefile.terp]
    set v_shell_app_makefile  [file join ${v_shell_software_dir} app_defines.mk.terp]

    evaluate_terp_file $v_shell_makefile $v_parameter_list 0 1

    # if using a custom makefile and not HPS, include the app_defines.mk file
    if {($v_user_custom_makefile == 1)} {
      evaluate_terp_file $v_shell_app_makefile $v_parameter_list 0 1
    }

  }

  # update the bsp settings file so that it points to the correct PD and Quartus files (other parts will
  # automatically be updated on bsp generation)
  proc update_bsp_settings { file project_name } {

    set file_id [open $file r+]
    set lines   [split [read $file_id] "\n"]

    seek $file_id 0

    foreach line $lines {
      if {[string match "*<QsysFile>*" $line]} {
        puts $file_id "\t\t<QsysFile>../../../../rtl/${project_name}_qsys.qsys</QsysFile>"
      } elseif {[string match "*<QuartusProjectFile>*" $line]} {
        puts $file_id "\t\t<QuartusProjectFile>../../../../quartus/${project_name}.qpf</QuartusProjectFile>"
      } else {
        puts $file_id $line
      }
    }

    close $file_id

  }




  # Create a .qsf to add the subsystem instance memory initialization files to the project
  # by adding them to the project search path
  proc create_qsf_file { software_array } {

    upvar $software_array soft_array

    set v_project_path    $soft_array(project_directory)
    set v_instance_name   $soft_array(instance_name)
    set v_qsf_filename    ${v_instance_name}_software.qsf
    set v_qsf_filepath    [file join $v_project_path quartus shell $v_qsf_filename]
    
    set v_result [catch {set fileid [open $v_qsf_filepath "w"]} result_text] 

    if {$v_result == 0} {
      puts $fileid "set_global_assignment -name SEARCH_PATH ../software/${v_instance_name}/build/bin/mem_init"
      close $fileid
      return
    } else {
      send_message ERROR "Software Makefile: unable to create or open file $v_qsf_filepath"
      return -code $result $result_text
    }

  }

  proc get_terp_content { filepath param_value } {

    # Open and read terp file
    set terp_path     $filepath
    set terp_fd       [open $terp_path]
    set terp_contents [read $terp_fd]
    close $terp_fd

    puts "params - $param_value"

    # prepare parameter values for use
    for {set i 0} {$i < [llength $param_value]} {incr i} {
      puts "[lindex $param_value $i]" 
      set terp_params(param$i)  [lindex $param_value $i]
    }

    set output_contents [altera_terp $terp_contents terp_params]
    return $output_contents

  }

  # generate an output file from an input terp file and a set of parameters
  # the output file is created in the same location as the input file

  proc evaluate_terp_file {terp_path params run del} {

    set output_path   [file rootname $terp_path]        ;# remove the .terp extension

    # get the output file contents
    set file_contents [get_terp_content "$terp_path" \
                      $params]

    # write the contents to the output file
    set   output_file  [open $output_path w+]
    puts  $output_file $file_contents
    close $output_file

    # evaluate the output file as a tcl script
    if { $run == 1 } {
      source $output_path
    }

    # delete the original .terp file
    if { $del == 1 } {
      file delete -force -- $terp_path
    }

  }

}

