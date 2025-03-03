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

# get directories so the script can be run from any directory
set shell_script_root [lindex $argv 0]
puts "shell script root : $shell_script_root"

# load custom packages
set curr_dir [pwd]
cd "$shell_script_root/modular_design_toolkit/scripts/create/packages"
set packages [glob -- *]

foreach package $packages {
  if {[file isdirectory $package] == 1} {
    lappend auto_path [file join [pwd] $package]
  }
}

cd $curr_dir

package require TopInsert         1.0
package require pd_handler_pkg    1.0
package require subsystems_pkg    1.0
package require auto_connect_pkg  1.0
package require irq_connect_pkg   1.0
package require avmm_connect_pkg  1.0

package require -exact qsys 20.1
package require altera_terp

# evaluate the procedure_name within each namespace in the namespace_list

proc run_namespace_procedure {namespace_list procedure_name} {

  set combined_result {}

  foreach current_namespace $namespace_list {

    set procedure_list [namespace eval $current_namespace "info procs"]         ;# get a list of procedures within the namespace

    if { [lsearch $procedure_list [lindex $procedure_name 0]] >= 0 } {          ;# only evaluate the procedure if it exists within the namespace

      ;# catch tcl errors raised by the procedure, this does not include errors within Platform Designer

      if {[set result [catch {namespace eval $current_namespace $procedure_name} resulttext]]} {
        ::pd_handler_pkg::setError "$::errorInfo"
      } else {
        set combined_result [concat $combined_result $resulttext]                     ;# group the return value of the procedure
      }

    }

  }

  return $combined_result

}

# sync sysinfo parameters for the top level system, and auto assign base addresses for
# all instances.
# This is required to determine the bus width of any memory mapped bridges, that has
# the automatic width parameter enabled. Base addresses are auto assigned afterwards
# to reflect any changes in the bus widths

proc memory_map_resolve {param_array} {

  sync_sysinfo_parameters
  auto_assign_system_base_addresses

  upvar $param_array p_array

  for {set loop 0} {$loop < 2} {incr loop} {
    for {set id 0} {$id < $p_array(project,id)} {incr id} {

      set system_name $p_array($id,name)
      set system_type $p_array($id,type)
      set path ""

      switch $system_type {
        top     {set path "./../rtl/$p_array(project,name)_qsys.qsys"}
        user    {set path "./../rtl/user/${system_name}.qsys"}
        import  {set path "./../rtl/import/${system_name}.qsys"}
        default {set path "./../rtl/shell/${system_name}.qsys"}
      }

      if {[file exists $path]} {
        load_system $path
      }

      sync_sysinfo_parameters
      auto_assign_system_base_addresses

      save_system

    }
  }

}

#==========================================================

proc main {} {

  # get arguments passed to the script from create_shell.tcl

  set shell_design_root [lindex $::argv 0]
  array set subsystem_array [lindex $::argv 1]

  # setup event handler
  set tmp_dir [lindex $::argv 2]
  set tmp_pid [lindex $::argv 3]
  ::pd_handler_pkg::init $tmp_dir $tmp_pid

  # add set of default parameters for this script

  array set script_params {}

  set script_params(QUERY_ONLY)       0
  set script_params(AUTO_CONN_EN)     1
  set script_params(AUTO_GEN_TOP_EN)  1

  # update default parameters from input parameters

  foreach p_pair $subsystem_array(project,params) {
    set name  [lindex $p_pair 0]
    set value [lindex $p_pair 1]
    set script_params($name) $value
  }

  # initialize the namespaces

  set namespace_list [::subsystems_pkg::create_namespaces subsystem_array]

  # skip the shell design generation to allow querying of the initialized subsystem namespaces

  if {$script_params(QUERY_ONLY) == 1} {
    set param_lists_shell [ run_namespace_procedure $namespace_list "get_shell_parameters_list" ]
    puts $param_lists_shell
    return
  }

  # run the shell design creation stages (in order) for all namespaces

  foreach ns $namespace_list {
    ::pd_handler_pkg::sendMessage "Initialising Subsystem: $ns"
    run_namespace_procedure $ns "pre_creation_step"
    ::pd_handler_pkg::waitForInstruction
  }

  reload_ip_catalog

  foreach ns $namespace_list {
    ::pd_handler_pkg::sendMessage "Creating Subsystem: $ns"
    run_namespace_procedure $ns "creation_step"
    ::pd_handler_pkg::waitForInstruction
  }

  reload_ip_catalog

  foreach ns $namespace_list {
    ::pd_handler_pkg::sendMessage "Running post-creation step for $ns"
    run_namespace_procedure $ns "post_creation_step"
    ::pd_handler_pkg::waitForInstruction
  }

  # run the auto connection procedure to connect interfaces at the top system level

  if { $script_params(AUTO_CONN_EN) != 0 } {
    set auto_connection_list [run_namespace_procedure $namespace_list "get_auto_connections"]
    puts "Running auto connection"
    puts $auto_connection_list
    ::auto_connect_pkg::do_connect_subsystems "./../rtl/$script_params(PROJECT_NAME)_qsys.qsys" $auto_connection_list
  }

  # run irq connection and priority

  set irq_list [run_namespace_procedure $namespace_list "get_irq_connections"]
  puts "Running irq connection"
  puts $irq_list
  ::irq_connect_pkg::run_connections "./../rtl/$script_params(PROJECT_NAME)_qsys.qsys" $irq_list

  # run avmm connection and priority

  set avmm_list [run_namespace_procedure $namespace_list "get_avmm_connections"]
  puts "Running avmm connection"
  puts $avmm_list
  ::avmm_connect_pkg::run_connections "./../rtl/$script_params(PROJECT_NAME)_qsys.qsys" $avmm_list





  foreach ns $namespace_list {
    ::pd_handler_pkg::sendMessage "Running post-connection step for $ns"
    run_namespace_procedure $ns "post_connection_step"
    ::pd_handler_pkg::waitForInstruction
  }
  # run_namespace_procedure $namespace_list "post_connection_step"

  # resolve any issues arising from memory mapped bridge bus width detection

  memory_map_resolve subsystem_array

  # modify the debug subsystem based on the source and probe requirements of the other subsystems

  for {set id 0} {$id < $subsystem_array(project,id)} {incr id} {
    if {$subsystem_array($id,type)=="debug"} {
      set debug_namespace $subsystem_array($id,name)
      set debug_source_list [run_namespace_procedure $namespace_list "get_debug_source_list"]
      set debug_probe_list  [run_namespace_procedure $namespace_list "get_debug_probe_list"]
      run_namespace_procedure $debug_namespace [list "generate_source_and_probes" $debug_source_list $debug_probe_list]
    }
  }

  # run the top hdl generation procedure that inserts code into the top level hdl file

  if { $script_params(AUTO_GEN_TOP_EN) != "0" } {

    # for the automatic code insert to be correctly labeled, the procedures must be called for each
    # namespace individually, rather than all namespaces at once

    foreach current_namespace $namespace_list {

      # get all top hdl lists for the namespace

      set top_port_list           [run_namespace_procedure $current_namespace "get_top_port_list"]
      set declaration_list        [run_namespace_procedure $current_namespace "get_declaration_list"]
      set assignment_list         [run_namespace_procedure $current_namespace "get_assignments_list"]
      set qsys_inst_exports_list  [run_namespace_procedure $current_namespace "get_qsys_inst_exports_list"]
      set code_list               [run_namespace_procedure $current_namespace "get_code_insert_list"]

      set label $current_namespace
      set file_path "./../rtl/$script_params(PROJECT_NAME).v"

      # run top insert procedures, if edit list not empty

      if {[llength $top_port_list] != 0} {
        ::TopInsert::io_insert     $label $file_path $top_port_list
      }

      if {[llength $declaration_list] != 0} {
        ::TopInsert::wire_insert   $label $file_path $declaration_list
      }

      if {[llength $assignment_list] != 0} {
        ::TopInsert::assign_insert $label $file_path $assignment_list
      }

      if {[llength $qsys_inst_exports_list] != 0} {
        ::TopInsert::export_insert $label $file_path "$script_params(PROJECT_NAME)_qsys" $qsys_inst_exports_list
      }

      if {[llength $code_list] != 0} {
        puts "is this ever executing: $code_list"
        foreach block $code_list {
        ::TopInsert::code_insert $label $file_path $block
        }
      }

    }

  }

}

main

::pd_handler_pkg::endProcess