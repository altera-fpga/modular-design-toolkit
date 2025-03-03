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

package provide auto_connect_pkg  1.0
package require Tcl               8.0
package require -exact qsys       20.1
variable test_mode 0

namespace eval ::auto_connect_pkg {

  # Export functions
  namespace export do_connect_subsystems

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

  # Setup
  variable param_array
  variable system
  variable logs

}

# connect_subsytems =================================================================
# -------- Output methods for debugging --------
proc print_instance {instance} {
  set properties [get_instance_properties $instance]
  set result ""

  foreach property $properties {
    set result "$result\n $property : [get_instance_property $instance $property]"
  }
  return $result
}

proc print_instances {instances} {
  foreach instance $instances {
    puts $instance
    puts [print_instance $instance]
  }
}

proc print_interface {instance interface} {
  set properties [get_interface_properties $interface]
  set result ""

  foreach property $properties {
    set result "$result\n $property : [get_instance_interface_property $instance $interface $property]"
  }
  return $result
}

proc print_parameters {instance interface} {
  set parameters [get_instance_interface_parameters $instance $interface]
  set result ""

  foreach parameter $parameters {
    set result "$result\n $instance : $interface : $parameter : [get_instance_interface_parameter_value $instance $interface $parameter]"
  }

  return $result
}
# -------------------- end --------------------

# append to 2d list
proc 2d_append {2d y value} {
    return [lreplace $2d $y $y [linsert [lindex $2d $y] end $value]]
}

# Get full component from simple component
# Use interface CLASS_NAME to get interface class and type
# Return full component {instance interface label class type}s
proc get_full_component {component} {
    if {[llength $component] != 3} {
        send_message INFO "Invalid component or incorrect component format"
    }
    set value [get_instance_interface_property [lindex $component 0] [lindex $component 1] CLASS_NAME]
    set value_split [split $value "_"]
    lappend component [join [lrange $value_split 0 end-1] "_"]
    lappend component [lindex $value_split end]
    return $component
}

# Get list of all ports of component (instance.interface)
proc get_ports {component} {
    return [get_instance_interface_ports [lindex $component 0] [lindex $component 1]]  
}

# Get list of properties of port of component
# Return list {direction role width}
proc get_port_properties {component port} {
    set dir [get_instance_interface_port_property [lindex $component 0] [lindex $component 1] $port DIRECTION]
    set role [get_instance_interface_port_property [lindex $component 0] [lindex $component 1] $port ROLE]
    set width [get_instance_interface_port_property [lindex $component 0] [lindex $component 1] $port WIDTH]
    return [list $dir $role $width]
}

# Get list of ports with properties
proc get_ports_properties {component} {
    set ports [get_ports $component]
    set ports_properties {}
    for {set i 0} {$i < [llength $ports]} {incr i} {
        set port [lindex $ports $i]
        lappend ports_properties [get_port_properties $component $port]
    }
    return $ports_properties
}

# get component connection as <instance>.<interface
proc connection_component {component} {
  return "[lindex $component 0].[lindex $component 1]"
}

# Main method connects all auto_connect components
proc ::auto_connect_pkg::do_connect_subsystems {system components} {
  puts "do_connect_subsystems($system, $components)"
  load_system $system

  # create look up table for IO/valid direction connections
  set input_keys {slave sink sender agent}
  set output_keys {master source receiver host}
  set valid_directions {{Bidir Bidir} {Input Output} {Output Input}}
  # create arrays for bin sorting
  set inputs {{} {} {} {}}
  set outputs {{} {} {} {}}
  set conduits {}


  # loop through auto_connect_list and sort components into bins by class and type
  for {set i 0} {$i < [llength $components]} {incr i} {
    set component [get_full_component [lindex $components $i]]
    set comp_type [lindex $component end]

    puts "component - $component"

    # sort by class and type
    if {$comp_type == "end"} {
        lappend conduits $component
    } elseif {[set idx [lsearch $input_keys $comp_type]] >= 0} {
        set inputs [2d_append $inputs $idx $component]
    } elseif {[set idx [lsearch $output_keys $comp_type]] >= 0} {
        set outputs [2d_append $outputs $idx $component]
    } else {
        puts "ERROR - UNSUPPORTED INTERFACE TYPE"
    }
  }

  # iterate through all output types, iterate through output array of type
  # compare to all corresponding inputs, attempt connection if matching
  for {set i 0} {$i < [llength $outputs]} {incr i} {
    set outputs_set [lindex $outputs $i]
    set inputs_set [lindex $inputs $i]
    for {set j 0} {$j < [llength $outputs_set]} {incr j} {
      set output [lindex $outputs_set $j]
      for {set k 0} {$k < [llength $inputs_set]} {incr k} {
        set input [lindex $inputs_set $k]

        # if matching labels
        if {[lindex $output 2] == [lindex $input 2]} {
          
          set input_type  [lindex $input 3]
          set output_type [lindex $output 3]

          set type_keys   [list avalon altera_axi4]

          # check the type matches (or check for special case AXI/AVMM)
          if {$output_type == $input_type} {
            add_connection [connection_component $output] [connection_component $input]
          } elseif {([lsearch $type_keys $output_type] >= 0) && ([lsearch $type_keys $input_type] >= 0)} {
            add_connection [connection_component $output] [connection_component $input]
          }

        }
      }
    }
  }

  # iterate all conduits against eachother, attempt connection if matching label and ports (ordered)
  
  puts "list of conduits detected" 
  puts $conduits
  
  for {set i 0} {$i < [llength $conduits]-1} {incr i} {
    for {set j [expr $i+1]} {$j < [llength $conduits]} {incr j} {
      
      set a [lindex $conduits $i]
      set b [lindex $conduits $j]

      set a_label [lindex $a 2]
      set b_label [lindex $b 2]

      # skip non matching labels
      if {$a_label != $b_label} {
        continue
      }
      
      # perform deeper conduit matching based on interface port properties (direction role width)

      set a_ports_props [get_ports_properties $a]
      set b_ports_props [get_ports_properties $b]

      # the number of ports must be the same for both interfaces
      if {[llength $a_ports_props] != [llength $b_ports_props]} {
        continue
      }

      # sort the ports properties lists by role
      set a_ports_props [lsort -index 1 $a_ports_props]
      set b_ports_props [lsort -index 1 $b_ports_props]

      set matching true
      for {set k 0} {($k < [llength $a_ports_props]) && $matching} {incr k} {

        set a_temp_props [lindex $a_ports_props $k] 
        set a_dir   [lindex $a_temp_props 0] 
        set a_role  [lindex $a_temp_props 1] 
        set a_width [lindex $a_temp_props 2] 

        set b_temp_props [lindex $b_ports_props $k] 
        set b_dir   [lindex $b_temp_props 0] 
        set b_role  [lindex $b_temp_props 1] 
        set b_width [lindex $b_temp_props 2] 

        set directions [list $a_dir $b_dir]

        # roles must match
        if {$a_role != $b_role} {
          puts "found error $a_role != $b_role"
          set matching false

        # widths must match 
        } elseif {$a_width != $b_width} {
          puts "found error $a_width != $b_width"
          set matching false

        # directions must be valid (i.e. opposite, or match in the case of bidirectional) 
        } elseif {[lsearch $valid_directions $directions] < 0} {
          puts "found error $directions not valid"
          set matching false
        }

      }

      if {$matching} {
        puts "$a -> $b -- attempt"
        add_connection [connection_component $a] [connection_component $b]
      }
    }
  }
  
  # save all connections to system
  if {$::test_mode == 0} {
    save_system $system
  } else {
    set post "_temp.qsys"
    set $system [string replace $system end-5 end]
    save_system "$system$post"
  }
}