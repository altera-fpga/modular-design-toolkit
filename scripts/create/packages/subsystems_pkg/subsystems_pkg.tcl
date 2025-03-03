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

package provide subsystems_pkg  1.0
package require Tcl             8.0

set script_dir [file dirname [info script]]
lappend auto_path "$script_dir/../"

package require hls_build_pkg         1.0
package require software_manager_pkg  1.0
package require irq_connect_pkg       1.0
package require avmm_connect_pkg      1.0
package require utils_pkg             1.0

namespace eval ::subsystems_pkg {

    # Export functions
    namespace export create_namespaces

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # Setup
    variable param_array

}

proc create_namespace_wrapper {name param_array} {

  upvar $param_array p_array

  # namespace needs to be named after instance name

  set ns_name $name

  # create a new namespace
  namespace eval $ns_name {

    array set param_array {}

    set auto_connection_list {}

    # ::TopInsert:: lists

    set top_port_list {}
    set declarations_list {}
    set assignments_list {}
    set qsys_inst_exports_list {}
    set code_list {}

    # debug subsystem lists

    set debug_source_list {}
    set debug_probe_list  {}

    # irq priority list

    set irq_priority_list {}

    # avmm connection list

    set avmm_conn_list  {}

    #==============================================
    # wrapper procedures for shell parameters

    # add a shell parameter to the list, or modify the value of an existing shell parameter

    proc set_shell_parameter {name value {add 1}} {

      set curr_ns [namespace current]

      if {[info exists ${curr_ns}::param_array($name)] || $add} {
        set ${curr_ns}::param_array($name) $value
      }

    }

    # get the value of a shell parameter from the list

    proc get_shell_parameter {name} {

      set curr_ns [namespace current]

      if {[info exists ${curr_ns}::param_array($name)]} {
        return [set ${curr_ns}::param_array($name)]
      }

      return -code error "Parameter $name does not exist in $curr_ns"

    }

    # get the full shell parameters list

    proc get_shell_parameters_list {} {

      set curr_ns [namespace current]
      return [set ${curr_ns}::param_array]

    }

    # update the shell parameter list values from an input list

    proc update_parameters {parameter_list {add 0}} {

      foreach parameter $parameter_list {
        set name  [lindex $parameter 0]
        set value [lindex $parameter 1]
        set_shell_parameter $name $value $add
      }

    }

    # returns a 1 if the shell parameter exists, otherwise 0

    proc check_shell_parameter {name} {
      set curr_ns [namespace current]
      return [info exists ${curr_ns}::param_array($name)]
    }

    #======================================================
    # wrapper procedures for the auto connection script

    # add a connection to the auto connection list

    proc add_auto_connection {instance_type interface anchor} {
      set curr_ns [namespace current]
      set connection [list $instance_type $interface $anchor]
      lappend ${curr_ns}::auto_connection_list $connection
    }

    # get the auto connection list

    proc get_auto_connections {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::auto_connection_list]
    }

    #======================================================
    # wrapper procedures for ::TopInsert:: procedures

    # add an external port to the top level hdl file (for use with ::TopInsert::io_insert)

    proc add_top_port_list {interface width component_name} {
      set curr_ns [namespace current]
      set port    [list $interface $width $component_name]
      lappend ${curr_ns}::top_port_list $port
    }

    # get the list of external ports to add to the top level hdl file (for use with ::TopInsert::io_insert)

    proc get_top_port_list {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::top_port_list]
    }

    # add a declaration to the top level hdl file (for use with ::TopInsert::wire_insert)

    proc add_declaration_list {interface width component_name} {
      set curr_ns     [namespace current]
      set declaration [list $interface $width $component_name]
      lappend ${curr_ns}::declarations_list $declaration
    }

    # get the list of declarations to add to the top level hdl file (for use with ::TopInsert::wire_insert)

    proc get_declaration_list {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::declarations_list]
    }

    # add an assignment to the top level hdl file (for use with ::TopInsert::assign_insert)

    proc add_assignments_list {target source} {
      set curr_ns     [namespace current]
      set assignment  [list $target $source]
      lappend ${curr_ns}::assignments_list $assignment
    }

    # get the list of assignments to add to the top level hdl file (for use with ::TopInsert::assign_insert)

    proc get_assignments_list {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::assignments_list]
    }

    # add an export to a qsys instantiation in the top level hdl file (for use with ::TopInsert::export_insert)

    proc add_qsys_inst_exports_list {port signal} {
      set curr_ns [namespace current]
      set export  [list $port $signal]
      lappend ${curr_ns}::qsys_inst_exports_list $export
    }

    # get the list of exports to add to a qsys instantiation in the top level hdl file (for use with ::TopInsert::export_insert)

    proc get_qsys_inst_exports_list {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::qsys_inst_exports_list]
    }

    proc add_code_insert_list {code} {
      set curr_ns [namespace current]
      lappend ${curr_ns}::code_list $code
    }

    proc get_code_insert_list {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::code_list]
    }

    #======================================================
    # procedures for debug sources and probes

    # add a debug source to the debug subsystem

    proc add_debug_source {name width default} {
      set curr_ns       [namespace current]
      set debug_source  [list $name $width $default]
      lappend ${curr_ns}::debug_source_list $debug_source
    }

    # get the debug source list to add to the debug subsystem

    proc get_debug_source_list {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::debug_source_list]
    }

    # add a debug probe to the debug subsystem

    proc add_debug_probe {name width} {
      set curr_ns     [namespace current]
      set debug_probe [list $name $width]
      lappend ${curr_ns}::debug_probe_list $debug_probe
    }

    # get the debug probe list to add to the debug subsystem

    proc get_debug_probe_list {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::debug_probe_list]
    }
    
    #==========================================================
    # IRQ priorities

    proc add_irq_connection {instance interface priority label} {
      set curr_ns      [namespace current]
      set irq_priority [list $instance $interface $priority $label]
      lappend ${curr_ns}::irq_priority_list $irq_priority
    }

    proc get_irq_connections {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::irq_priority_list]
    }

    #==========================================================
    # AVMM priorities

    # avmm_hosts is expected to either be:
    # 1. "host" if the interface is a host
    # 2. a list of host / offset pairs if the interface is an agent

    proc add_avmm_connections {interface avmm_hosts} {

      set v_instance_name [get_shell_parameter INSTANCE_NAME]
      set curr_ns         [namespace current]

      if {$avmm_hosts == "host"} {
        # the interface is a host, so add default labels 
        set avmm_conn   [list $v_instance_name $interface X auto_avmm_host]
        lappend ${curr_ns}::avmm_conn_list $avmm_conn
        set avmm_conn   [list $v_instance_name $interface X ${v_instance_name}_avmm_host]
        lappend ${curr_ns}::avmm_conn_list $avmm_conn
      } else {
        # the interface is an agent, so add from host list
        foreach conn $avmm_hosts {
          set host    [lindex $conn 0]
          set offset  [lindex $conn 1]
          set avmm_conn   [list $v_instance_name $interface $offset ${host}_avmm_host]
          lappend ${curr_ns}::avmm_conn_list $avmm_conn
        }
      }

    }

    proc get_avmm_connections {} {
      set curr_ns [namespace current]
      return [set ${curr_ns}::avmm_conn_list]
    }

    #==========================================================
    # misc procedures

    # write parameters back to the parameter array so that the proc
    # derive parameters has access to all of the subsystem parameters
    # including those that are not contained within the xml file,
    # i.e. default parameters that are only initialized when sourcing
    #      the script

    proc back_propagate_params {name param_array} {

      upvar $param_array p_array

      set id $p_array($name,id)

      set curr_ns [namespace current]

      set running_list {}

      foreach {name value} [array get ${curr_ns}::param_array] {
        lappend running_list [list $name $value]
      }
      
      set p_array($id,params) $running_list

    }

    # source the subsystem script within the namespace and initialize
    # the shell parameters from the calling script

    proc constructor {name param_array} {

      upvar $param_array p_array

      # get basic infromation about the subsystem
      set id $p_array($name,id)
      set path $p_array($id,script)
      set type $p_array($id,type)

      # get the global (project) and local (subsystem) parameters
      set global_parameters $p_array(project,params)
      set local_parameters  $p_array($id,params)
      
      # set default parameters required by all subsystems
      set_shell_parameter SHELL_DESIGN_ROOT ""
      set_shell_parameter PROJECT_NAME      ""
      set_shell_parameter PROJECT_PATH      ""
      set_shell_parameter INSTANCE_NAME     ""
      set_shell_parameter FAMILY            ""
      set_shell_parameter DEVICE            ""
      set_shell_parameter QUARTUS_VERSION   ""
      set_shell_parameter DEVKIT            ""

      set_shell_parameter IRQ_PRIORITY      ""

      # update subsystem parameters based on the global parameters
      # this will update only the default parameters instantiated
      # above. This is required first by some subsystems as the 
      # DEVKIT / FAMILY parameters are used to source additional scripts.
      update_parameters $global_parameters 0

      # source the subsystem script
      source $p_array($id,script)

      # update subsystem parameters based on the global parameters
      # this ensures local subsystem parameters that are set globally 
      # in the xml file are updated. 
      update_parameters $global_parameters 0

      # update subsystem parameters based on the local parameters
      update_parameters $local_parameters 0

      # check if the subsystem uses an initialisation proc to
      # source its create script based on parameter values
      # run the initialisation procedure and rerun the update
      # parameters to 
      set init_exists [expr {[llength [info procs subsystem_init]] > 0}]
      if {$init_exists} {
        subsystem_init 
        update_parameters $global_parameters 0
        update_parameters $local_parameters 0
      }

      back_propagate_params $name p_array

      # generate default parameters

      set v_project_path    [get_shell_parameter PROJECT_PATH]
      set v_project_name    [get_shell_parameter PROJECT_NAME]

      switch $type {
        top     {set folder ""}
        user    {set folder "user"}
        default {set folder "shell"}
      }

      set_shell_parameter SUBSYSTEM_SOURCE_PATH   [file dirname $path]

      set_shell_parameter SUBSYSTEM_NAME          "$name"
      set_shell_parameter SUBSYSTEM_IP_PATH       [file join $v_project_path non_qpds_ip $folder]
      set_shell_parameter SUBSYSTEM_RTL_PATH      [file join $v_project_path rtl $folder]
      set_shell_parameter SUBSYSTEM_QUARTUS_PATH  [file join $v_project_path quartus $folder]

      set_shell_parameter PROJECT_PD_FILE         "$v_project_path/rtl/${v_project_name}_qsys.qsys"

    }

    interp alias {} file_copy {} ::utils_pkg::file_copy

    # # copy a file/directory from one location to another (follow symlinks to root)
    # proc file_copy {src_path dest_path} {
    #   while {[file type $src_path] == "link" } {
    #       set src_path [file readlink $src_path]
    #   }
    #   file copy -force $src_path $dest_path
    # }

    # generate an output string from an input terp file and a set of parameters
    # using the altera_terp procedure

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

  # add the subsystem script contents to the namespace and initialize the shell parameters
  ${ns_name}::constructor $name p_array

  # remove the constructor procedure so it cannot be used
  namespace forget $ns_name constructor

  return $ns_name

}

# create a namespace for each .tcl script in the script_list and return the list of namespaces
# the shell parameters in the namespaces are initialised from the parameter_list argument

proc ::subsystems_pkg::create_namespaces {param_array {derive_parameters 1}} {

  upvar $param_array p_array

  set namespace_list {}

  for {set id 0} {$id < $p_array(project,id)} {incr id} {

    set current_script $p_array($id,script)

    set param_list [concat $p_array(project,params) $p_array($id,params)]       ;# concatenate the project (common) and subsystem specific parameter lists

    puts "creating namespace $p_array($id,name) with $param_list"

    set current_namespace [create_namespace_wrapper $p_array($id,name) p_array]
    lappend namespace_list $current_namespace

  }

  # note: the derive_parameters procedure might contain qsys commands so
  #       cannot be called in quartus. 

  if {$derive_parameters==1} {
    foreach current_namespace $namespace_list {
      set procedure_list [namespace eval ::$current_namespace "info procs"] 
      if { [lsearch $procedure_list "derive_parameters"] >= 0} {
        ::${current_namespace}::derive_parameters p_array  
      }
    }
  }

  return $namespace_list

}