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

package provide avmm_connect_pkg 1.0
package require Tcl              8.0

namespace eval avmm_connect_pkg {

  namespace export run_connections

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

  variable enable_debug_messages 1

  # constants for indexes in the host/agent element list
  variable instance_index       0
  variable interface_index      1
  variable offset_index         2
  variable address_span_index   3

  # array of avmm connection requests from the project .xml file (see parse_avmm_list)
  variable avmm_array 
  array set avmm_array {}

  proc ::avmm_connect_pkg::run_connections {top_qsys_file avmm_list} {

    set result [catch {::avmm_connect_pkg::parse_avmm_list $avmm_list} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    set result [catch {::avmm_connect_pkg::update_avmm_array} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    set result [catch {::avmm_connect_pkg::validate_connections} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    set result [catch {::avmm_connect_pkg::connect_avmm} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    return -code ok

  }

  # Associative array layout
  #
  # avmm_array(labels)        - list of AVMM labels
  # avmm_array(hosts)         - list of hosts in format {instance interface offset}
  # avmm_array(label,hosts)   - list of indexes in the host list
  # avmm_array(agents)        - list of agents in format {instance interface offset address_span}
  # avmm_array(label,agents)  - list of indexes in the agent list
  # avmm_array(connections)   - list of list of agent indexes, the (main) index of this list corresponds to each host
  #                           - e.g. avmm_array(connections)[0] = a list of agent indexes that connect to host index 0
  #                           - this is generated from the consolidate_connections procedure
  #
  # Procedure to convert a list of AVMM interfaces, base addresses and labels into an array to simplify
  # the connection process. Also performs some error checking
  #
  proc ::avmm_connect_pkg::parse_avmm_list {avmm_list} {

    variable avmm_array

    print_message "Running parse_avmm_list"

    set avmm_array(labels) {}
    set avmm_array(hosts)  {}
    set avmm_array(agents) {}

    foreach avmm $avmm_list {
      set instance      [lindex $avmm 0]
      set interface     [lindex $avmm 1]
      set offset        [lindex $avmm 2]
      set label         [lindex $avmm 3]

      print_message "parsing avmm list entry - instance: $instance, interface: $interface, offset: $offset, label: $label"
      
      # check if the label entry exists
      if {[lsearch $avmm_array(labels) $label] == -1} {
        print_message "adding label ($label) to the avmm array"

        # add new label to the array, and initialize array elements
        lappend avmm_array(labels) $label
        set avmm_array($label,hosts)   {}
        set avmm_array($label,agents)  {}    
      }

      # get interface direction host/agent
      set properties [get_instance_interface_properties $instance $interface]

      if {[regexp CLASS_NAME $properties]} {
        set class_name [get_instance_interface_property $instance $interface CLASS_NAME]
        
        if {$class_name == "avalon_master"} {
          set type "hosts"
        } elseif {$class_name == "avalon_slave"} {
          set type "agents"
        } else {
          return -code error "Error - avmm list entry is invalid - interface ${instance}.${interface} is not of type AVMM"
        }
        
        set normalised_offset [normalise_base_address $offset]
        set entry [list $instance $interface $normalised_offset]

        # add entry if it doesn't exist, otherwise get index
        set index [lsearch -exact $avmm_array(${type}) $entry]

        if {$index == -1} {
          set index [llength $avmm_array(${type})]
          lappend avmm_array(${type}) $entry
        }
          
        lappend avmm_array($label,${type})   $index

      } else {
        return -code error "Error - avmm list entry is invalid, unable to get class name for ${instance}.${interface}"
      }

    }

    return -code ok

  }

  # Procedure to get additional information for the avmm array
  #
  proc ::avmm_connect_pkg::update_avmm_array {} {

    set result [catch {::avmm_connect_pkg::update_system_bridges} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    set result [catch {::avmm_connect_pkg::get_host_base_addresses} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    set result [catch {::avmm_connect_pkg::get_agent_address_spans} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }
    
    set result [catch {::avmm_connect_pkg::sort_agents_by_offsets} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }
    
    set result [catch {::avmm_connect_pkg::consolidate_connections} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    return -code ok

  }

  # Procedure to consolidate the associative array into a list of connections between host and agent interfaces. 
  # This enables easier error checking during the connection phase.
  #
  proc ::avmm_connect_pkg::consolidate_connections {} {

    variable avmm_array
    set connections {}

    print_message "Running consolidate_connections"

    for {set host_index 0} {$host_index < [llength $avmm_array(hosts)]} {incr host_index} {
      set agents {}

      foreach label $avmm_array(labels) {
        set local_index [lsearch $avmm_array($label,hosts) $host_index]

        if {$local_index >= 0} {
          foreach agent_index $avmm_array($label,agents) {
            # remove duplicate agent entries
            if {[lsearch $agents $agent_index] < 0} {
              lappend agents $agent_index
            }
          }
        }
      }

      lappend connections [lsort -integer $agents]
      
    }

    set avmm_array(connections) $connections

    return -code ok

  }

  # Procedure to check the following avmm connection rules:
  # - The base address of an agent component must be a multiple of the address span of the component
  # - The address spans of agent components must not overlap
  #
  proc ::avmm_connect_pkg::validate_connections {} {

    variable avmm_array
    variable instance_index
    variable interface_index
    variable offset_index
    variable address_span_index

    print_message "Running validate_connections"

    for {set host_index 0} {$host_index < [llength $avmm_array(hosts)]} {incr host_index} {
      set host          [lindex $avmm_array(hosts) $host_index]
      set agent_indexes [lindex $avmm_array(connections) $host_index]

      set host_instance   [lindex $host $instance_index]
      set host_interface  [lindex $host $interface_index]
      set host_offset     [lindex $host $offset_index]

      print_message "Checking connections for host\[${host_index}\]: ${host_instance}.${host_interface}, offset: ${host_offset}"

      # initialise with the host (internal bridge) base address
      set minimum_address [lindex $host $offset_index]
      set previous_interface "${host_instance}.${host_interface}"

      foreach agent_index $agent_indexes {
        set agent         [lindex $avmm_array(agents) $agent_index]
        
        set agent_instance      [lindex $agent $instance_index]
        set agent_interface     [lindex $agent $interface_index]
        set agent_offset        [lindex $agent $offset_index]
        set agent_address_span  [lindex $agent $address_span_index]

        print_message "- lowest available base address: $minimum_address, agent\[$agent_index\]: ${agent_instance}.${agent_interface}, requested $agent_offset (span $agent_address_span)"

        if {$agent_offset != "X"} {
          if {[expr {fmod($agent_offset, $agent_address_span)}] != 0.0} {
            return -code error "Offset must be a multiple of the address span: ${agent_instance}.${agent_interface}, requested $agent_offset (span $agent_address_span)"
          } elseif {$minimum_address > $agent_offset} {
            return -code error "Address space overlaps between ${previous_interface} and ${agent_instance}.${agent_interface}, requested $agent_offset, available $minimum_address"
          }

          # update the minimum avalable base address (convert back to hex as tcl doesn't have uint 'type')
          set int_address     [expr $agent_offset + $agent_address_span]
          set hex_address     [format 0x%x $int_address]

          set result [catch {::avmm_connect_pkg::normalise_base_address $hex_address} result_text]
          if {$result != 0} {
            return -code $result $result_text
          }

          set minimum_address $result_text
          set previous_interface "${agent_instance}.${agent_interface}"
        }
      }
    }

    return -code ok

  }

  # Procedure to pad a base address value to 32-bits with 0x prefix
  #
  proc ::avmm_connect_pkg::normalise_base_address {base_address} {

    print_message "Running normalise_base_address (${base_address})"

    if {[string equal -nocase $base_address "x"]} {
      return $base_address
    }

    set base_address [string trim $base_address]
    set base_address [string tolower $base_address]

    # strip 0x if it exists
    set idx [string first "0x" $base_address]

    if {$idx >= 0} {
      set idx [expr $idx + 2]
      set base_address [string range $base_address $idx end]
    }

    # pad to 32 bit
    set len [string length $base_address]

    if {$len <= 8} {
      set pad_num [expr 8 - $len]
      set pad [string repeat 0 $pad_num]
      set base_address ${pad}${base_address}
    } else {
      set bits [expr $len * 4]
      return -code error "Maximum width of base address exceeded (expected 32 bits, received $bits bits)"
    }

    set base_address 0x${base_address}
    set base_address [string tolower $base_address]

    return -code ok "$base_address"
    
  }

  # Procedure to ensure AVMM bridges with auto widths are updated
  #
  proc ::avmm_connect_pkg::update_system_bridges {} {

    variable avmm_array
    variable instance_index

    print_message "Running update_system_bridges" 

    set instance_list   {}
    set instance_files  {}

    foreach host $avmm_array(hosts) {
      set instance [lindex $host $instance_index]
      if {[lsearch -exact $instance_list $instance] == -1} {
        lappend instance_list   $instance
        lappend instance_files  [get_instance_property $instance FILE]
      }
    }

    foreach agent $avmm_array(agents) {
      set instance [lindex $agent $instance_index]
      if {[lsearch -exact $instance_list $instance] == -1} {
        lappend instance_list   $instance
        lappend instance_files  [get_instance_property $instance FILE]
      }
    }

    set system [get_module_property FILE]

    foreach instance_file $instance_files {
      load_system $instance_file
      sync_sysinfo_parameters
      save_system
    }

    load_system $system

    return -code ok

  }

  # Procedure to follow the avmm interface to the source(s) returning the total base address offset
  # Note: This procedure makes use of recursion
  #
  proc ::avmm_connect_pkg::trace_avmm_interface {level system instance interface} {

    print_message "Running trace_avmm_interface $level"

    # if procedure is passed a system this indicates that a subsystem boundry is
    # being traversed (except the first invocation) so must trace the exported 
    # interface to an internal instance and interface in the subsystem
    if {$system != ""} {
      
      print_message "Loading system $system"
      load_system $system

      # The first invocation does not have an export to evaluate 
      if {$level != 0} {
        set exported_interface [get_interface_property $interface EXPORT_OF]

        if {$exported_interface != ""} {
          print_message "Interface $instance.$interface is exported from $exported_interface"

          # update the instance and interface
          set split_exported_interface [split $exported_interface "."]
          set instance  [lindex $split_exported_interface 0]
          set interface [lindex $split_exported_interface 1]
        } else {
          return -code error "Failed to find the interface exported to $instance.$interface"
        }
      }
    }

    # check if the instance is a component or a subsystem
    set instance_group [get_instance_property $instance GROUP]
    print_message "Instance $instance is of group $instance_group"
 
    if {($instance_group == "Systems") || ($instance_group == "System")} {
      # trace the interface into the subsystem 
      set instance_file [get_instance_property $instance FILE]
      set next_level    [expr $level+1]

      # get the upstream base address
      set result [catch {::avmm_connect_pkg::trace_avmm_interface $next_level $instance_file $instance $interface} result_text]
      return -code $result $result_text

    } elseif {($instance_group == "Generic Component")} {
      # find instance type
      set instance_definition [get_instance_parameter_value $instance componentDefinition]

      set result [catch {::avmm_connect_pkg::extract_value_xml $instance_definition { originalModuleInfo className }} result_text]
      if {$result != 0} {
        return -code $result $result_text
      }

      set instance_type $result_text

      print_message "Instance $instance is of type $instance_type"

      if {$instance_type == "altera_avalon_mm_bridge"} {
        set interface_connections [get_connections $instance.s0]

        if {$interface_connections != ""} {
          set local_base_address_list {}

          foreach connection ${interface_connections}  {

            set result [catch {::avmm_connect_pkg::get_base_address $connection} result_text]
            if {$result != 0} {
              return -code $result $result_text
            }
            
            set current_base_address $result_text

            print_message "Base address for connection ${connection} is ${current_base_address}"

            # follow the host upstream
            set split_connection  [split $connection "/"]
            set host              [lindex $split_connection 0]
            set split_host        [split $host "."]

            set host_instance     [lindex $split_host 0]
            set host_interface    [lindex $split_host 1]
            set next_level        [expr $level+1]

            # get upstream base address (from within existing system, hence blank system argument)
            set result [catch {::avmm_connect_pkg::trace_avmm_interface $next_level "" ${host_instance} ${host_interface}} result_text]
            if {$result != 0} {
              return -code $result $result_text
            }

            # use the upstream base address
            set local_base_address [format 0x%x [expr ${current_base_address} + ${result_text}]]
            
            set result [catch {::avmm_connect_pkg::normalise_base_address $local_base_address} result_text]
            if {$result != 0} {
              return -code $result $result_text
            }

            lappend local_base_address_list $result_text

          }

          # Note: If there are multiple hosts they must share the same base address
          #       to be able to specify the correct offset of the agent. Otherwise
          #       there is ambiguity in which base address to use as a reference.

          set ref_base_address [lindex $local_base_address_list 0]

          foreach local_base_address ${local_base_address_list} {
            if {${ref_base_address} != ${local_base_address}} {
              return -code error "${instance}.s0 connected to multiple hosts with differing base addresses (${local_base_address_list}). Unable to resolve ambiguity in base address"
            }
          }

          return -code ok "${ref_base_address}"

        } else {
          return -code error "No connections to ${instance}.s0"
        }

      } elseif {$instance_type == ""} {
        return -code error "Unable to get instance type (${instance})"
      } else {
        print_message "Reached source of AVMM chain (${instance}.${interface})"
        return -code ok "0"
      }

    } elseif {$instance_group == "Processors and Peripherals/Hard Processor Systems"} {
      print_message "Reached source of AVMM chain (${instance}.${interface})"
      return -code ok "0"
    } else {
      return -code error "Instance ($instance) of unknown instance group (${instance_group})"
    }

  }

  # Procedure to get the base addresses of all the hosts in the avmm_array
  #
  proc ::avmm_connect_pkg::get_host_base_addresses {} {

    variable avmm_array
    variable instance_index
    variable interface_index

    print_message "Running get_host_base_addresses"

    set top_file [get_module_property FILE]
    set new_hosts {}

    set length [llength $avmm_array(hosts)]

    for {set index 0} {$index < $length} {incr index} {

      set host      [lindex $avmm_array(hosts) $index]
      set instance  [lindex $host $instance_index]
      set interface [lindex $host $interface_index]
      
      print_message "Finding base address of host\[$index\]: ${instance}.${interface}"

      # get host base address
      set result [catch {::avmm_connect_pkg::trace_avmm_interface 0 $top_file $instance $interface} result_text]
      if {$result != 0} {
        return -code $result $result_text
      }

      # normalise base address 
      set result [catch {::avmm_connect_pkg::normalise_base_address $result_text} result_text]
      if {$result != 0} {
        return -code $result $result_text
      }

      set new_host [list $instance $interface $result_text]
      lappend new_hosts $new_host
      
    }

    # update the host list with the new information
    set avmm_array(hosts) $new_hosts

    load_system $top_file

    return -code ok

  }

  # Procedure to get the address spans of all the agents in the avmm_array
  #
  proc ::avmm_connect_pkg::get_agent_address_spans {} {

    variable avmm_array
    variable instance_index
    variable interface_index
    variable offset_index

    print_message "Running get_agent_address_spans"

    set top_file [get_module_property FILE]
    set new_agents {}

    set length [llength $avmm_array(agents)]

    for {set index 0} {$index < $length} {incr index} {

      set agent         [lindex $avmm_array(agents) $index]
      set instance      [lindex $agent $instance_index]
      set interface     [lindex $agent $interface_index]
      
      set address_span  0

      set properties [get_instance_interface_properties $instance $interface]

      if {[regexp addressSpan $properties]} {
        set address_span [get_instance_interface_property $instance $interface addressSpan]
      }

      lappend agent $address_span
      lappend new_agents $agent
      
    }

    # update the host list with the new information
    set avmm_array(agents) $new_agents

    load_system $top_file

    return -code ok

  }

  # Procedure to sort all agent items in the avmm_array in ascending offset order
  #
  # 1 - sort the agents list in ascending order based on offset value
  # 2 - find the mapping between the old agents list and sorted agents list
  # 3 - apply the mapping to the label agents list
  # 4 - sort the label agents list in ascending order based on value (index)
  #     the higher the index the greater the offset
  #
  proc ::avmm_connect_pkg::sort_agents_by_offsets {} {

    variable avmm_array

    print_message "Running sort_agents_by_offsets"

    # run a custom sort (due to how tcl interprets unsigned hex)
    # ascending base address order, list index 0 = lowest
    set result [catch {::avmm_connect_pkg::manual_sort $avmm_array(agents) 2} result_text]
    if {$result != 0} {
      return -code $result $result_text
    }

    set sorted_agents $result_text

    # find the mapping between the unsorted and sorted agents
    set sorted_agents_mapping {}

    foreach item $avmm_array(agents) {
      set index [lsearch -exact $sorted_agents $item]

      if {$index >= 0} {
        lappend sorted_agents_mapping $index
      } else {
        return -code error "unable to find agent ($item) in list ($sorted_agents)"
      }
    }

    # update all agent indexes to the equivalent sorted list index
    print_message "Updating agent indexes for ordered list"
    
    set avmm_array(agents) $sorted_agents

    foreach label $avmm_array(labels) {
      set new_agents_list {}

      foreach index $avmm_array($label,agents) {
        set new_index [lindex $sorted_agents_mapping $index]
        lappend new_agents_list $new_index
      }

      # sorting by integer here is fine as they are index values (not base addresses in hex)
      # this will put them in ascending base address order
      set avmm_array($label,agents) [lsort -integer $new_agents_list]
    }

    return -code ok

  }

  # Procedure to sort the input list based on the index given, specifically for hex numbers
  # required as everything is a string in tcl does not seem to have any uint functions
  # hence no variation of the built in lsort procedure will work with 32-bit hex values
  #
  proc ::avmm_connect_pkg::manual_sort {input_list index} {

    print_message "Running manual_sort ($input_list, $index)"

    set output_list {}
    lappend output_list [lindex $input_list 0]

    for {set i 1} {$i < [llength $input_list]} {incr i} {

      set new_item  [lindex $input_list $i]
      set new_value [lindex $new_item $index]
      set length    [llength $output_list]

      print_message "The current sorted list is: $output_list"
      print_message "Evaluating $new_item of value $new_value"

      if {[string match -nocase "x" $new_value] == 0} {
        for {set j 0} {$j < $length} {incr j} {
          set ref_entry [lindex $output_list $j]
          set ref_value [lindex $ref_entry $index]

          if {$new_value < $ref_value} {
            print_message "Inserting $new_item into output_list at index $j"
            set output_list [linsert $output_list $j $new_item]
            break
          }
        }
      }

      # if nothing has been inserted into the list append the entry to the output_list
      # this occurs when the input value is "don't care" or is greater than all current
      # entries in the output list
      if {$length == [llength $output_list]} {
        print_message "Appending $new_item onto the end of output_list"
        lappend output_list $new_item
      }

    }

    print_message "The final sorted list is: $output_list"
    return -code ok "$output_list"

  }

  # Procedure to perform all connections
  #
  proc ::avmm_connect_pkg::connect_avmm {} {

    variable avmm_array

    print_message "Running connect_avmm"

    set system [get_module_property FILE]
    
    load_system $system

    for {set host_index 0} {$host_index < [llength $avmm_array(hosts)]} {incr host_index} {

      set host          [lindex $avmm_array(hosts) $host_index]
      set agent_indexes [lindex $avmm_array(connections) $host_index]

      foreach agent_index $agent_indexes {
        set agent [lindex $avmm_array(agents) $agent_index]

        set result [catch {::avmm_connect_pkg::add_avmm_connection $host $agent} result_text]
        if {$result != 0} {
          return -code $result $result_text
        }
      }
    }

    save_system
    return -code ok 

  }

  # Procedure to connect a host/agent pair, and set the base address (if given)
  #
  proc ::avmm_connect_pkg::add_avmm_connection {host agent} {

    variable instance_index
    variable interface_index
    variable offset_index

    print_message "Running add_avmm_connection (${host}, ${agent})"

    set host_instance       [lindex $host $instance_index]
    set host_interface      [lindex $host $interface_index]
    set host_base_address   [lindex $host $offset_index]

    set agent_instance      [lindex $agent $instance_index]
    set agent_interface     [lindex $agent $interface_index]
    set agent_base_address  [lindex $agent $offset_index]

    set host  ${host_instance}.${host_interface}
    set agent ${agent_instance}.${agent_interface}

    add_connection ${host} ${agent}

    if {![string equal -nocase $agent_base_address "x"]} {
      set base_address [format 0x%x [expr $agent_base_address - $host_base_address]]
      
      set result [catch {::avmm_connect_pkg::normalise_base_address $base_address} result_text]
      if {$result != 0} {
        return -code $result $result_text
      }

      set_connection_parameter_value  ${host}/${agent} baseAddress $result_text
      lock_avalon_base_address $agent
    }

    return -code ok

  }

  # Procedure to extract a value from an xml file based on key names
  #
  proc ::avmm_connect_pkg::extract_value_xml { xml keys } {

    set i 0
    set l [llength $keys]
    
    foreach line [split $xml "\n"] {
      set key [lindex $keys $i]
      if {[regexp <$key> $line]} {
        incr i  
        if {$i == $l} {
          regexp <$key>(.*)</$key> $line a b
          return -code ok "$b"
        } 
      }
      if {[regexp </$key> $line]} {
        incr i -1  
      }
    }
    
    return -code ok

  }

  # Procedure to get the base address of an existing connection
  #
  proc ::avmm_connect_pkg::get_base_address { connection } {
    
    print_message "Running get_base_address ($connection)"

    set params [get_connection_parameters $connection]
    
    if {[regexp baseAddress $params]} {
      set base_address [get_connection_parameter_value $connection baseAddress]
      set result [catch {::avmm_connect_pkg::normalise_base_address $base_address} result_text]
      return -code $result $result_text
    } else {
      return -code error "unable to get base address for connection $connection"
    }

    return -code ok

  }

  # Procedure to print the avmm array for debug purposes
  #
  proc ::avmm_connect_pkg::print_avmm_array {} {

    variable avmm_array

    print_message "============================================"
    print_message "---------------- AVMM Array ----------------"
    print_message "============================================"

    foreach label $avmm_array(labels) {

      print_message "AVMM LABEL - $label"

      print_message "Hosts ($avmm_array($label,hosts)):"

      foreach id $avmm_array($label,hosts) {
        set host [lindex $avmm_array(hosts) $id]
        print_message "-- $host"
      }

      print_message "Agents ($avmm_array($label,agents)):"

      foreach id $avmm_array($label,agents) {
        set agent [lindex $avmm_array(agents) $id]
        print_message "-- $agent"
      }

      print_message "============================================"

    }

    if {[info exists avmm_array(connections)]} {

      print_message "--------------- Connections ----------------"
      print_message "============================================"

      for {set host_index 0} {$host_index < [llength $avmm_array(hosts)]} {incr host_index} {
        set host          [lindex $avmm_array(hosts) $host_index]
        set agent_indexes [lindex $avmm_array(connections) $host_index]

        if {[llength $agent_indexes] > 0} {
          print_message "Host ($host_index):"
          print_message "-- $host"
          print_message "Agents ($agent_indexes):"

          foreach agent_index $agent_indexes {
            set agent [lindex $avmm_array(agents) $agent_index]

            print_message "-- $agent"
          }

          print_message "============================================"
        }
      }

    }

    print_message "============================================"
    print_message "============================================"

    return -code ok

  }

  # procedure to print formatted messages
  #
  proc ::avmm_connect_pkg::print_message {msg} {

    variable enable_debug_messages

    if {$enable_debug_messages} {
      puts "AVMM connect pkg: $msg"
    }

    return -code ok

  }

}