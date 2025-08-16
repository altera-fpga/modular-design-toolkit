###################################################################################
# Copyright (C) 2025 Altera Corporation
#
# This software and the related documents are Altera copyrighted materials, and
# your use of them is governed by the express license under which they were
# provided to you ("License"). Unless the License provides otherwise, you may
# not use, modify, copy, publish, distribute, disclose or transmit this software
# or the related documents without Altera's prior written permission.
#
# This software and the related documents are provided as is, with no express
# or implied warranties, other than those that are expressly stated in the License.
###################################################################################

package provide auto_connect_pkg 1.0

package require Tcl              8.0
package require qsys

# Helper to connect generic interfaces

namespace eval auto_connect_pkg {

    namespace export do_connect_subsystems

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    proc ::auto_connect_pkg::append_2d_list {list index value} {

        set v_sub_list [lindex ${list} ${index}]
        set v_sub_list [linsert ${v_sub_list} end ${value}]
        set v_list     [lreplace ${list} ${index} ${index} ${v_sub_list}]

        return ${v_list}

    }

    # Get CLASS_NAME property of a component, and append to the component
    proc ::auto_connect_pkg::get_full_component {component} {

        if {[llength ${component}] != 3} {
            send_message INFO "Invalid component or incorrect component format"
        }

        set v_instance  [lindex ${component} 0]
        set v_interface [lindex ${component} 1]

        set v_value_string [get_instance_interface_property ${v_instance} ${v_interface} CLASS_NAME]
        set v_value_list   [split ${v_value_string} "_"]

        lappend component [join [lrange ${v_value_list} 0 end-1] "_"]
        lappend component [lindex ${v_value_list} end]
        return ${component}

    }

    # Get list of all ports of component
    proc ::auto_connect_pkg::get_ports {component} {

        set v_instance  [lindex ${component} 0]
        set v_interface [lindex ${component} 1]
        set v_ports     [get_instance_interface_ports ${v_instance} ${v_interface}]

        return ${v_ports}

    }

    # Get list of properties of port of component; return {direction role v_width}
    proc ::auto_connect_pkg::get_port_properties {component port} {

        set v_instance  [lindex ${component} 0]
        set v_interface [lindex ${component} 1]

        set v_direction [get_instance_interface_port_property ${v_instance} ${v_interface} ${port} DIRECTION]
        set v_role      [get_instance_interface_port_property ${v_instance} ${v_interface} ${port} ROLE]
        set v_width     [get_instance_interface_port_property ${v_instance} ${v_interface} ${port} WIDTH]

        set v_properties [list ${v_direction} ${v_role} ${v_width}]

        return ${v_properties}

    }

    # Get list of ports with properties
    proc ::auto_connect_pkg::get_ports_properties {component} {

        set v_ports_properties {}
        set v_ports            [::auto_connect_pkg::get_ports ${component}]

        foreach v_port ${v_ports} {
            lappend v_ports_properties [::auto_connect_pkg::get_port_properties ${component} ${v_port}]
        }

        return ${v_ports_properties}

    }

    # Get component connection as <instance>.<interface>
    proc ::auto_connect_pkg::connection_component {component} {

        set v_instance  [lindex ${component} 0]
        set v_interface [lindex ${component} 1]

        return "${v_instance}.${v_interface}"

    }

    # Connect all auto_connect components
    proc ::auto_connect_pkg::run_connections {system components} {

        load_system ${system}

        # create look up table for valid connections
        set v_input_keys        {slave sink sender agent}
        set v_output_keys       {master source receiver host}
        set v_valid_connections {{Bidir Bidir} {Input Output} {Output Input}}

        # create arrays for bin sorting
        set v_inputs   {{} {} {} {}}
        set v_outputs  {{} {} {} {}}
        set v_conduits {}

        # loop through auto_connect_list and sort components into bins by class and type
        foreach v_component ${components} {

            set v_component [::auto_connect_pkg::get_full_component ${v_component}]
            set v_type      [lindex ${v_component} end]

            # sort by class and type
            if {${v_type} == "end"} {
                lappend v_conduits ${v_component}
            } elseif {[set v_index [lsearch ${v_input_keys} ${v_type}]] >= 0} {
                set v_inputs [::auto_connect_pkg::append_2d_list ${v_inputs} ${v_index} ${v_component}]
            } elseif {[set v_index [lsearch ${v_output_keys} ${v_type}]] >= 0} {
                set v_outputs [::auto_connect_pkg::append_2d_list ${v_outputs} ${v_index} ${v_component}]
            } else {
                puts "ERROR - UNSUPPORTED INTERFACE TYPE"
            }

        }

        # iterate through all output types, iterate through output array of type
        # compare to all corresponding inputs, attempt connection if matching
        for {set v_index 0} {${v_index} < [llength ${v_outputs}]} {incr v_index} {

            set v_outputs_set [lindex ${v_outputs} ${v_index}]
            set v_inputs_set  [lindex ${v_inputs} ${v_index}]

            foreach v_output ${v_outputs_set} {
                foreach v_input ${v_inputs_set} {

                    # if matching labels
                    if {[lindex ${v_output} 2] == [lindex ${v_input} 2]} {

                        set v_input_type  [lindex ${v_input} 3]
                        set v_output_type [lindex ${v_output} 3]
                        set v_type_keys   [list avalon altera_axi4]

                        # check the type matches (or check for special case AXI/AVMM)
                        if {${v_output_type} == ${v_input_type}} {
                            add_connection [::auto_connect_pkg::connection_component ${v_output}]\
                                           [::auto_connect_pkg::connection_component ${v_input}]
                        } elseif {([lsearch ${v_type_keys} ${v_output_type}] >= 0) &&\
                                  ([lsearch ${v_type_keys} ${v_input_type}] >= 0)} {
                            add_connection [::auto_connect_pkg::connection_component ${v_output}]\
                                           [::auto_connect_pkg::connection_component ${v_input}]
                        }

                    }
                }
            }
        }

        # iterate all conduits against each other, attempt connection if matching label and ports (ordered)
        for {set v_index_a 0} {${v_index_a} < [llength ${v_conduits}]-1} {incr v_index_a} {
            for {set v_index_b [expr ${v_index_a}+1]} {${v_index_b} < [llength ${v_conduits}]} {incr v_index_b} {

                set v_conduit_a [lindex ${v_conduits} ${v_index_a}]
                set v_conduit_b [lindex ${v_conduits} ${v_index_b}]

                set v_label_a [lindex ${v_conduit_a} 2]
                set v_label_b [lindex ${v_conduit_b} 2]

                # skip non v_matching labels
                if {${v_label_a} != ${v_label_b}} {
                    continue
                }

                # perform deeper conduit v_matching based on interface port properties (direction role width)

                set v_properties_a [::auto_connect_pkg::get_ports_properties ${v_conduit_a}]
                set v_properties_b [::auto_connect_pkg::get_ports_properties ${v_conduit_b}]

                # the number of ports must be the same for both interfaces
                if {[llength ${v_properties_a}] != [llength ${v_properties_b}]} {
                    continue
                }

                # sort the ports properties lists by role
                set v_properties_a [lsort -index 1 ${v_properties_a}]
                set v_properties_b [lsort -index 1 ${v_properties_b}]

                set v_matching true

                for {set v_properties_index 0} {${v_properties_index} < [llength ${v_properties_a}]}\
                    {incr v_properties_index} {

                    set v_port_properties_a [lindex ${v_properties_a} ${v_properties_index}]
                    set v_port_direction_a  [lindex ${v_port_properties_a} 0]
                    set v_port_role_a       [lindex ${v_port_properties_a} 1]
                    set v_port_width_a      [lindex ${v_port_properties_a} 2]

                    set v_port_properties_b [lindex ${v_properties_b} ${v_properties_index}]
                    set v_port_direction_b  [lindex ${v_port_properties_b} 0]
                    set v_port_role_b       [lindex ${v_port_properties_b} 1]
                    set v_port_width_b      [lindex ${v_port_properties_b} 2]

                    set v_directions        [list ${v_port_direction_a} ${v_port_direction_b}]

                    # roles must match
                    if {${v_port_role_a} != ${v_port_role_b}} {
                        set v_matching false
                        break
                    # widths must match
                    } elseif {${v_port_width_a} != ${v_port_width_b}} {
                        set v_matching false
                        break
                    # v_directions must be valid (i.e. opposite, or match in the case of bidirectional)
                    } elseif {[lsearch ${v_valid_connections} ${v_directions}] < 0} {
                        set v_matching false
                        break
                    }

                }

                if {${v_matching}} {
                    add_connection [::auto_connect_pkg::connection_component ${v_conduit_a}]\
                                   [::auto_connect_pkg::connection_component ${v_conduit_b}]
                }
            }
        }

        save_system

    }

}
