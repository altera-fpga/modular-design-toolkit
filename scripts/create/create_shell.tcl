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

package require ::quartus::project
package require ::quartus::flow
package require ::quartus::misc
package require ::quartus::report
package require ::quartus::device

package require cmdline

package require fileutil

package require xml
package require xml::libxml2
package require dom
package require dom::tcl
package require dom::libxml2

# get directories so the script can be run from any directory
variable current_dir     [ pwd ]
variable abs_script_path [ dict get [ info frame 0 ] file ]
variable abs_script_dir  [file dirname $abs_script_path]

# load custom packages
set packages [glob -directory "$abs_script_dir/packages" -types d -- *]

foreach package $packages {
  lappend auto_path $package
}

package require xml_parse_pkg             1.0
package require quartus_verification_pkg  1.0
package require reporting_pkg             1.0
package require pd_handler_pkg            1.0
package require query_pkg                 1.0

::oo::class create logger {

  variable fid 0

  constructor {dir name} {

    if {[catch {file mkdir $dir}]} {
      post_message -type error "Unable to create directory: $dir"
    }

    if {[catch {open $name a} fid]} {
      post_message -type error "Unable to create file: $name"
    }

  }

  method writeToLog {text} {
    puts $fid $text
  }

  destructor {
    close $fid
  }

}

# copy a file/directory from one location to another (follow symlinks to root)
proc file_copy { src_path dest_path } {
  while {[file type $src_path] == "link" } {
      set src_path [file readlink $src_path]
  }
  file copy -force $src_path $dest_path
}

# convert the subsystem type to the directory under which its files belong
proc type_to_directory {type} {

  if {$type == "top"} {
    return ""
  } elseif {$type == "import"} {
    return "import"
  } elseif {$type == "user"} {
    return "user"
  } else {
    return "shell"
  }

}

# create the project directory tree in the specified path
proc create_directory_tree {v_proj_path param_array} {

  upvar $param_array p_array

  set directory_list {}

  for {set id 0} {$id < $p_array(project,id)} {incr id} {       

    set directory [type_to_directory $p_array($id,type)]
    set index [lsearch $directory_list $directory]

    if {($index < 0) && ($directory != "")} {
      lappend directory_list $directory
    }

  }

  file mkdir $v_proj_path

  foreach root {non_qpds_ip quartus rtl scripts sdc software} {
      
      file mkdir $v_proj_path/$root

      if {($root != "scripts") && ($root != "software")} {  
        foreach sub $directory_list {
          file mkdir $v_proj_path/$root/$sub 
        }
      }
  }

}

proc improved_getoptions {arglistVar optlist usage} {
    upvar 1 $arglistVar argv
    # Warning: Internal cmdline function
    set opts [::cmdline::GetOptionDefaults $optlist result]
    while {[set err [::cmdline::getopt argv $opts opt arg]]} {
        if {$err < 0} {
            return -code error -errorcode {CMDLINE ERROR} $arg
        }
        set result($opt) $arg
    }
    if {[info exists result(?)] || [info exists result(help)]} {
        return -code error -errorcode {CMDLINE USAGE} \
            [::cmdline::usage $optlist $usage]
    }
    return [array get result]
}

#====================================================================================================================================

#====================================================================================================================================

proc main {} {

  variable ::argv0 $::quartus(args)
  variable v_log 0
  variable v_log_filename "project_build.log"

  set v_shell_subsystems_root [file dirname [file normalize [info script]/../../../]]   ;# absolute path of the shell design install directory (using current script as reference)
  set v_shell_install_root $v_shell_subsystems_root
  set v_shell_designs_root [file join $v_shell_subsystems_root]
  puts "$v_shell_designs_root"
  set v_shell_subsystems_root [file join $v_shell_subsystems_root modular_design_toolkit]
  set v_shell_subsystems_root [file join $v_shell_subsystems_root subsystems]
  set v_shell_subsystems_root [file join $v_shell_subsystems_root platform_designer_subsystems]
  puts "$v_shell_subsystems_root"
  set v_shell_designs_dirs_list [glob -directory $v_shell_designs_root -type d *]
  foreach subdir $v_shell_designs_dirs_list {
    lappend v_xml_file_name_list [file tail [glob -nocomplain -directory $subdir -type f *.xml]]
  }
  set v_xml_file_name_list [lsort -dictionary $v_xml_file_name_list]

  # =====================================================================
  # Definition of arguments for the script

  # "proj_name" - Switch to specify the name of the project; this overrides the project name specified in the XML file
  # "proj_path" - Switch to specify the project path; by default, the project location is the same as the shell install location as well
  # "xml_path"  - Switch to specify the xml settings file path (required for operation)
  # "log"       - Switch to enable logging of stdout to a file

  set options {
      { "proj_name.arg"   ""      "Name of the Quartus project" }
      { "proj_path.arg"   "."     "Project path" }
      { "xml_path.arg"    "."     "Shell design XML settings file path"}
      { "log"             "0"     "Log the stdout into a file" }
      { "o"               "0"     "Overwrite the project directory if it exists"}
  }

  set usage "quartus_sh -t project_script.tcl (-proj_name=?) (-proj_path=?) (-xml_path=?) (-log) (-o) (-help)"

  try {
      array set opts_hash [improved_getoptions ::argv $options $usage]
      puts "All options valid"
  } trap {CMDLINE USAGE} {msg} {
      # This trap is executed when the -help argument is used by the user
      puts stderr "\n"
      puts stderr "-------------------------------------------------------------------------------------------"
      puts stderr "----                            Shell Design Toolkit                                   ----"
      puts stderr "-------------------------------------------------------------------------------------------"
      puts stderr "\n"
      puts stderr $msg
      puts stderr "\nNAME"
      puts stderr "     create_shell.tcl -- Script to create a shell design"
      puts stderr "\nDESCRIPTION"
      puts stderr "     create_shell.tcl script creates a design based on the system description provided in "
      puts stderr "     the XML file using different subsystems as building blocks. There are three types of "
      puts stderr "     subsystems supported by the toolkit"
      puts stderr "         1. Library subsystems"
      puts stderr "         2. User subsystems"
      puts stderr "         3. Import subsystems"
      puts stderr "\nARGUMENTS"
      puts stderr "     -proj_name    By default the project name has to be specified in the XML file. Use "
      puts stderr "                   this argument to override the project name specified in the XML file\n"
      puts stderr "     -proj_path    By default create_shell.tcl script creates the project folder in the "
      puts stderr "                   script location. Use this argument to specify a absolute project path\n"
      puts stderr "     -xml_path     Argument to specify the XML file describing the system in terms of its "
      puts stderr "                   constituent subsystems and their properties\n"
      puts stderr "                   Following is the shell design XML list from shell design toolkit install directory:"
      foreach xml $v_xml_file_name_list {
        puts stderr "                       - $xml"
      }
      puts stderr "\n"
      puts stderr "     -log          Option to enable the logging of messages both from the script"
      puts stderr "                   and platform designer. Log file location would be "
      puts stderr "                   <proj_path/quartus/platform_designer_log.txt>\n"
      puts stderr "     -o            create_shell.tcl script will error out if the specified project folder"
      puts stderr "                   exists. Use this option to overwrite the existing project folder"
      puts stderr "\nSEE ALSO"
      puts stderr "     build_shell.tcl (build_shell)\n\n"
      exit 0
  } trap {CMDLINE ERROR} {msg} {
      puts stderr "Error: $msg"
      exit 1
  }

  # =====================================================================
  # Set local argument variables based on arg

  set v_proj_name ""
  set v_proj_path "."
  set v_xml_path "."
  set v_log 0
  set v_overwrite 0
  set v_log_filename "project_build.log"

  if { $opts_hash(proj_name) != "" } {
    set v_proj_name $opts_hash(proj_name)
  }

  if { $opts_hash(proj_path) != "." } {
    set v_proj_path $opts_hash(proj_path)
  }
  set v_abs_proj_path [file normalize $v_proj_path]

  if { $opts_hash(xml_path) != "." } {
    set v_xml_path $opts_hash(xml_path)
    set abs_xml_path [file dirname [file normalize $v_xml_path]]
  } else {
    puts "xml settings file is required"
    return
  }

  if { $opts_hash(log) } { set v_log 1 }

  if { $opts_hash(o) } { set v_overwrite 1 }

  # =====================================================================
  # xml parse

  array set param_array {}

  puts "shell design root : $v_shell_subsystems_root"
  puts "shell script root : $v_shell_install_root"

  ::xml_parse_pkg::parse_xml_settings_file $v_xml_path $v_shell_subsystems_root $v_shell_designs_root param_array

  # allow project name to be overridden from the command line

  if {$v_proj_name!=""} {
    set param_array(project,name) $v_proj_name
  } else {
    set v_proj_name $param_array(project,name)
  }

  # =====================================================================
  # Error checking for arguments

  # Project name check

  if {[ regexp {[^\w-]} $v_proj_name ]} {             ;# match any character that is not alphanumeric, underscore or dash
    post_message -type error "Error: Project name $v_proj_name is ILLEGAL"
    return
  }

  # Project path check

  if {[file exists $v_proj_path/non_qpds_ip] || [file exists $v_proj_path/quartus] || [file exists $v_proj_path/rtl] || [file exists $v_proj_path/scripts] || [file exists $v_proj_path/software]} {
    if {$v_overwrite} {
      file delete -force $v_proj_path/non_qpds_ip $v_proj_path/quartus $v_proj_path/rtl $v_proj_path/scripts $v_proj_path/software
    } else {
      puts stderr "Error : Project folder already exists, either use flag -o to overwrite an existing project in the specified folder, or select another folder"
      exit 1
    }
  }

  # =====================================================================
  # Print local variables

  puts "Info : v_proj_name - $v_proj_name"
  puts "Info : v_proj_path - $v_proj_path"
  puts "Info : v_xml_path  - $v_xml_path"
  puts "Info : v_log       - $v_log"

  # add final arguments to the the parameter array

  lappend param_array(project,params)  [list SHELL_DESIGN_ROOT $v_shell_subsystems_root]
  lappend param_array(project,params)  [list PROJECT_PATH      $v_abs_proj_path    ]
  lappend param_array(project,params)  [list PROJECT_NAME      $v_proj_name        ]

  regexp {[\.0-9]+} $::quartus(version) acds_env
  
  # split to major.minor version 

  set q_version [split $acds_env "."]
  set q_major [lindex $q_version 0]
  set q_minor [lindex $q_version 1]
  lappend param_array(project,params)  [list QUARTUS_VERSION   "$q_major.$q_minor"   ]

  puts "QUARTUS VERSION $q_major.$q_minor"  

  # =====================================================================
  # Create directory Structure

  create_directory_tree $v_proj_path param_array

  # Must be in the project directory to pickup the quartus.ini file
  set curr_dir [pwd]
  cd $v_proj_path/quartus

  # ====================================================================
  # generate quartus.ini file 

  ::query_pkg::create_quartus_ini_file "$v_abs_proj_path/quartus" param_array

  # =====================================================================
  # Create blank project

  # Check that the right project is open
  if {[is_project_open]} {
      if {[string compare $quartus(project) $v_proj_name]} {
          ::reporting_package::puts_log "Project $v_proj_name is not open"
          exit 1
      }
  } else {
      # Only open if not already open
      if {[project_exists $v_proj_name]} {
          project_open -revision $v_proj_name $v_proj_name
      } else {
          project_new -revision $v_proj_name $v_proj_name
      }
  }

  # add required assignments for the default .qsf

  array set temp_array [join $param_array(project,params)]

  # check the version of quartus
  if { [catch { set supported_version_list $temp_array(VERSION) } version_info_exists ] } {
    set supported_version_list ""
  } else {
    set supported_version_list $temp_array(VERSION)
  }
  ::quartus_verification_pkg::evaluate_quartus $supported_version_list

  puts "default search paths - $temp_array(IP_SEARCH_PATH_CONCAT)"

  set_global_assignment -name FAMILY $temp_array(FAMILY)
  set_global_assignment -name DEVICE $temp_array(DEVICE)
  set_global_assignment -name IP_SEARCH_PATHS $temp_array(IP_SEARCH_PATH_CONCAT)
  export_assignments

  array unset temp_array

  # run the subsystem creation scripts with qsys-script, using the intermediate script

  set qsys_script_exe "$::env(QUARTUS_ROOTDIR)/sopc_builder/bin/qsys-script"

  #====================================================================================================================================================================================

  set tempDir $v_abs_proj_path

  set cmd [list $qsys_script_exe --script=$v_shell_install_root/modular_design_toolkit/scripts/create/create_subsystems_qsys.tcl \
                                          $v_shell_install_root [array get param_array] \
                                 --quartus-project=$v_abs_proj_path/quartus/$v_proj_name 2>@1]

  set return_value [::pd_handler_pkg::run $cmd $tempDir]

  logger create my_log [pwd] "platform_designer_log.txt"

  my_log writeToLog $::pd_handler_pkg::pd_log

  if {$return_value} {
    project_close
    qexit -error
  }

  #====================================================================================================================================================================================

  # remove any edits made to the default .qsf file during the subsystem creation

  remove_all_global_assignments -name *

  # add required assignments to the default .qsf

  array set temp_array [join $param_array(project,params)]

  set_global_assignment -name FAMILY $temp_array(FAMILY)
  set_global_assignment -name DEVICE $temp_array(DEVICE)
  set_global_assignment -name IP_SEARCH_PATHS  $temp_array(IP_SEARCH_PATH_CONCAT)
  set_global_assignment -name TOP_LEVEL_ENTITY $v_proj_name
  set_global_assignment -name SEED 1

  array unset temp_array

  set_instance_assignment -name PARTITION_COLOUR 4285529948 -to $v_proj_name -entity $v_proj_name
  set_instance_assignment -name PARTITION_COLOUR 4294939049 -to auto_fab_0 -entity $v_proj_name

  export_assignments

  #=======================================================================
  # update the .qsf files to include the generated files
  #=======================================================================
  
  # loop through all subsystems
  for {set id 0} {$id < $param_array(project,id)} {incr id} {       

    set type $param_array($id,type)
    
    # the top subsystem is treated differently (no ip files)
    if {($type == "top")} {                                        

      set name $param_array(project,name)

      set fp [open "$v_abs_proj_path/quartus/shell/${name}_supplemental.qsf" a+]

      puts $fp "\nset_global_assignment -name VERILOG_FILE ./../rtl/${name}.v"
      puts $fp "\nset_global_assignment -name QSYS_FILE ./../rtl/${name}_qsys.qsys"

      close $fp

    } else {

      set folder [type_to_directory $type]

      set name $param_array($id,name)

      # check that the subsystem has an IP directory
      if {[file exists $v_abs_proj_path/rtl/$folder/ip/$name]} {

        # get a list of all IP in the subsystem
        set ip_list [fileutil::findByPattern $v_abs_proj_path/rtl/$folder/ip/$name -glob -- *.ip]

        if {[llength $ip_list] > 0} {

          # open subsystem .qsf file (append, or create)
          set fp [open "$v_abs_proj_path/quartus/$folder/$name.qsf" a+]

          # add IP files to the .qsf file
          puts $fp "\n# set file locations\n"

          foreach ip $ip_list {
            set ip_file [file tail $ip]
            puts $fp "set_global_assignment -name IP_FILE ../rtl/$folder/ip/$name/$ip_file"
          }

          close $fp

        }

      }
    
      # add the subsystem qsys file to the .qsf file
      if {[file exists $v_abs_proj_path/rtl/$folder/$name.qsys]} {
        set fp [open "$v_abs_proj_path/quartus/$folder/$name.qsf" a+]
        puts $fp "\nset_global_assignment -name QSYS_FILE ../rtl/$folder/$name.qsys"                 
        close $fp
      }

    }

  }

  if {[file exists $abs_xml_path/design.qsf]} {
    file_copy $abs_xml_path/design.qsf $v_abs_proj_path/quartus/shell/
  }

  # search the quartus directories for .qsf files and add them to the default .qsf file

  foreach v_subdir {shell user import} {

    if {[file exists $v_abs_proj_path/quartus/$v_subdir]} {
      
      set v_qsf_files_list [fileutil::findByPattern $v_abs_proj_path/quartus/$v_subdir -glob -- *.qsf]    ;# search for any .qsf in the directory
      set v_sdc_files_list [fileutil::findByPattern $v_abs_proj_path/sdc/$v_subdir -glob -- *.sdc]        ;# search for any .sdc in the directory

      foreach v_qsf_file $v_qsf_files_list {
        set v_rel_file [fileutil::relative $v_abs_proj_path/quartus $v_qsf_file]      ;# get the relative path from the .qpf

        if {$v_rel_file!="$v_proj_name.qsf"} {                                        ;# ignore the project's default .qsf
          set_global_assignment -name SOURCE_TCL_SCRIPT_FILE $v_rel_file              ;# note : this changes the default .qsf which is undesired behaviour
        }
      }

      foreach v_sdc_file $v_sdc_files_list {
        set v_rel_file [fileutil::relative $v_abs_proj_path/quartus $v_sdc_file]      ;# get the relative path from the .qpf
        set_global_assignment -name SDC_FILE $v_rel_file
      }

    }

  }

  project_close

  # generate list of IP used.
  ::quartus_verification_pkg::ip_list_generate $v_abs_proj_path $v_proj_name

}

main