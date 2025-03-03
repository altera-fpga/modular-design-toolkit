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

package provide irq_connect_pkg 1.0
package require Tcl             8.0

namespace eval irq_connect_pkg {

  namespace export run_connections

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

  variable enable_debug_messages 1

  # array of irq connection requests from the project .xml file (see parse_irq_list)
  variable irq_array 
  array set irq_array {}

  proc ::irq_connect_pkg::run_connections {top_qsys_file irq_list} {
      
    parse_irq_list $irq_list
    connect_irqs

  }

  # convert a list of IRQ interfaces, priorities and labels into an array to simplify
  # the connection process. Also performs error checking
  proc parse_irq_list {irq_list} {

    variable irq_array

    set irq_array(labels) {}

    foreach irq $irq_list {

      set instance      [lindex $irq 0]
      set interface     [lindex $irq 1]
      set priority      [lindex $irq 2]
      set label         [lindex $irq 3]

      print_message "parsing irq list entry - instance: $instance, interface: $interface, priority: $priority, label: $label"
      
      # check if the label entry exists
      if {[lsearch $irq_array(labels) $label] == -1} {

        print_message "adding label ($label) to the irq array"

        # add new label to the array, and initialize array elements
        lappend irq_array(labels) $label
        set irq_array($label,receiver) ""
        set irq_array($label,priorities) {}
        set irq_array($label,$priority)  {}      

      }

      # check that the instance and interface exists
      if {[catch {get_instance_interface_property $instance $interface CLASS_NAME} result_text]} {
        
        print_message "irq list entry is invalid - intance: ${instance} or interface ${instance}.${interface} doesn't exist"
        print_message $result_text
        return

      } else {

        if {$result_text == "interrupt_receiver"} {

          if {$irq_array($label,receiver) == ""} {
            print_message "adding receiver ($instance) for $label"
            set irq_array($label,file)  [get_instance_property $instance FILE]
            set irq_array($label,receiver) ${instance}.${interface}
            set irq_array($label,interface) ${interface}
          } else {
            print_message "there is already a receiver for label $label"
            return
          }

        } elseif {$result_text == "interrupt_sender"} {

          if {[lsearch $irq_array($label,priorities) $priority] >= 0} {
            print_message "duplicate priority found for $instance $interface"
            return
          } else {
            print_message "adding sender ($instance) for $label"
            lappend irq_array($label,priorities) $priority
            lappend irq_array($label,$priority) ${instance}.${interface}
          }

        }

      }

    }

    # sort the priorities in ascending order
    foreach label $irq_array(labels) {
      set ordered_priority [lsort -dictionary $irq_array(${label},priorities)]
      set irq_array(${label},priorities) $ordered_priority
    }

    return

  }

  # Connect the IRQs at the platform designer top level based on the array built from parse_irq_list
  # It is assumed that the connections are made via an IRQ bridge in the subsystem and so the 
  # priority order is kept, but the absolute values are not. This allows the subsystem containing the IRQ
  # bridge to resize it as appropriate.
  proc connect_irqs {} {

    variable irq_array

    print_message "connecting irqs for the irq labels ($irq_array(labels))"

    set system [get_module_property FILE]

    # load top level of the project
    load_system $system

    foreach label $irq_array(labels) {

      set receiver $irq_array($label,receiver)
      set external_priority 0

      print_message "connecting irqs for the irq receiver ($receiver) with priorities ($irq_array($label,priorities))"

      foreach priority $irq_array($label,priorities) {
        set sender $irq_array($label,$priority)
        create_connection ${receiver} ${sender} ${external_priority}
        incr external_priority
      }

    }

    save_system 

  }

  # return 1 if there are duplicate priority values, return 0 otherwise
  proc check_duplicate_priorities {priorities} {

    set ordered_priorities [lsort -dictionary $priorities]

    set previous_priority ""

    foreach priority $ordered_priorities {

      if {($priority == $previous_priority) && ($priority != "X")} {
        print_message "detected duplicate priority"
        return 1
      }

      set previous_priority $priority

    }

    return 0

  }

  # Connect the IRQ sender to the receiver with the provided priority
  proc create_connection {receiver sender priority} {

    print_message "connecting sender: ${sender} to receiver: ${receiver} with $priority"

    add_connection                  ${receiver} ${sender}
    set_connection_parameter_value  ${receiver}/${sender} irqNumber $priority

  }

  #=================================================================
  # Other procedures
  
  # Produces a sorted list of external IRQ priorities. For use by subsystems 
  # with an exported irq receiver that uses an IRQ bridge.
  proc get_external_irqs {param_array instance_name internal_priorities} {

    upvar $param_array p_array

    set v_instance_name $instance_name

    set external_priorities {}

    print_message "getting external irqs for subsystem $v_instance_name"

    # search for subsystem parameters that contain the key words
    # - <name>_IRQ_HOST     - the subsystem name containing the IRQ receiver to connect to
    # - <name>_IRQ_PRIORITY - the priority of the IRQ

    for {set id 0} {$id < $p_array(project,id)} {incr id} {
        
      set params $p_array($id,params) 
      
      array set irqs {}
      set irqs(names) {}

      foreach param $params {

        set name [lindex $param 0]
        set value [lindex $param 1]

        print_message "checking parameter ($param) in subsystem ($p_array($id,name)) for IRQ property"
        
        set result [regexp {^(.*)IRQ_HOST$} $name full_match sub_match]

        # the IRQ host parameter value must apply to the current instance
        if {($result) && ($value == $v_instance_name)} {

          print_message "found matching IRQ ($sub_match) in subsystem ($p_array($id,name))"
          
          set irq_name "${id}_${sub_match}"
          lappend irqs(names) $irq_name
          
          # if a priority doesn't exist for the IRQ default to don't care
          if {[info exists irqs(${irq_name},priority)] == 0} {
            set irqs(${irq_name},priority) "X"
          }

        }

        set result [regexp {^(.*)IRQ_PRIORITY$} $name full_match sub_match]

        # we cannot know if this irq priority applies to the current instance
        # so save it for future reference
        if {$result} {
          set irq_name "${id}_${sub_match}"
          print_message "found an IRQ priority ($sub_match = $value) in subsystem ($p_array($id,name)) speculatively saving"
          set irqs(${irq_name},priority) $value
        }

      }

      # add the locally found irq priorites to the global list.
      # Note: only those irq priorities with the correct host are added
      foreach irq_name $irqs(names) {

        set priority $irqs($irq_name,priority)
        set index [lsearch $external_priorities $priority]

        # check for duplicate priorites
        if {($index == -1) || ($priority == "X")} {
          print_message "adding an IRQ priority ($priority) in subsystem ($p_array($id,name)) to the list"
          lappend external_priorities $priority
        } else {
          print_message "multiple irqs with priority ($priority), in subsystem ($p_array($id,name)), priorities must be unique per host"
          return
        }

      }

    }

    # check no conflict between the subsystem's internal IRQ priorities and the external priorities
    foreach priority $internal_priorities {
      set index [lsearch $external_priorities $priority]
      if {($index >= 0) && ($priority != "X")} {
        print_message "multiple irqs with priority ($priority), in subsystem "
        return
      } 
    }

    set external_priorities [lsort -dictionary $external_priorities]

    print_message "found external priorities $external_priorities"

    return $external_priorities

  }

  #=================================================================
  # Misc procedures

  proc print_message {msg} {

    variable enable_debug_messages

    if {$enable_debug_messages} {
      puts "IRQ connect pkg: $msg"
    }

  }

}