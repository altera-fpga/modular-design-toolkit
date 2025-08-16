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

package provide irq_connect_pkg 1.0

package require Tcl             8.0

# Helper to connect interrupt interfaces

namespace eval irq_connect_pkg {

    namespace export run_connections

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    variable v_irq_array
    array set v_irq_array {}

    proc ::irq_connect_pkg::run_connections {system irq_list} {

        set v_result [catch {::irq_connect_pkg::parse_irq_list ${irq_list}} result_text]
        if {${v_result} != 0} {
            puts "${result_text}"
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {::irq_connect_pkg::connect_irqs ${system}} result_text]
        if {${v_result} != 0} {
            puts "${result_text}"
            return -code ${v_result} ${result_text}
        }

        return -code ok

    }

    # Convert a list of IRQ interfaces, priorities and labels into an array

    proc ::irq_connect_pkg::parse_irq_list {irq_list} {

        variable v_irq_array

        set v_irq_array(labels) {}

        foreach v_irq ${irq_list} {

            set v_instance  [lindex ${v_irq} 0]
            set v_interface [lindex ${v_irq} 1]
            set v_priority  [lindex ${v_irq} 2]
            set v_label     [lindex ${v_irq} 3]

            set v_label_exists [lsearch $v_irq_array(labels) ${v_label}]

            if {${v_label_exists} < 0} {
                lappend v_irq_array(labels)                   ${v_label}
                set     v_irq_array(${v_label},receiver)      ""
                set     v_irq_array(${v_label},priorities)    {}
                set     v_irq_array(${v_label},${v_priority}) {}
            }

            set v_result [catch {get_instance_interface_property ${v_instance} ${v_interface} CLASS_NAME} result_text]
            if {${v_result} != 0} {
                return -code ${v_result} "unable to retrieve class_name property from ${v_instance}.${v_interface}"
            }

            if {[string equal ${result_text} "interrupt_receiver"] == 1} {
                if {$v_irq_array(${v_label},receiver) == ""} {
                    set v_irq_array(${v_label},receiver)  ${v_instance}.${v_interface}
                } else {
                    return -code error "cannot have multiple irq receivers with the same label (${v_label}:\
                                        $v_irq_array(${v_label},receiver), ${v_instance}.${v_interface})"
                }

            } elseif {[string equal ${result_text} "interrupt_sender"] == 1} {
                set v_priority_exists [lsearch $v_irq_array(${v_label},priorities) ${v_priority}]

                if {${v_priority_exists} < 0} {
                    lappend v_irq_array(${v_label},priorities) ${v_priority}
                    lappend v_irq_array(${v_label},${v_priority}) ${v_instance}.${v_interface}
                } else {
                    return -code error "cannot have multiple irq senders with the same label and priority\
                                        (${v_priority}: $v_irq_array(${v_label},${v_priority}),\
                                        ${v_instance}.${v_interface})"
                }

            } else {
                return -code error "class_name property of ${v_instance}.${v_interface} not of interrupt type"
            }
        }

        foreach v_label $v_irq_array(labels) {
            set v_ordered_priorities [lsort -dictionary $v_irq_array(${v_label},priorities)]
            set v_irq_array(${v_label},priorities) ${v_ordered_priorities}
        }

        return -code ok

    }

    # Connect the IRQs at the platform designer top level
    # Note: assumes irq bridge in receiver subsystem that converts relative to absolute priorities

    proc ::irq_connect_pkg::connect_irqs {system} {

        variable v_irq_array

        load_system ${system}

        foreach v_label $v_irq_array(labels) {
            set v_receiver          $v_irq_array(${v_label},receiver)
            set v_relative_priority 0

            foreach v_absolute_priority $v_irq_array(${v_label},priorities) {
                set v_sender $v_irq_array(${v_label},${v_absolute_priority})
                ::irq_connect_pkg::create_connection ${v_receiver} ${v_sender} ${v_relative_priority}
                incr v_relative_priority
            }
        }

        save_system

    }

    # Check for duplicate priorities in a list

    proc ::irq_connect_pkg::check_duplicate_priorities {priorities} {

        set v_ordered_priorities [lsort -dictionary ${priorities}]
        set v_previous_priority  ""

        foreach v_priority ${v_ordered_priorities} {
            set v_dont_care [string equal -nocase ${v_priority} "x"]

            if {(${v_priority} == ${v_previous_priority}) && (${v_dont_care} != 1)} {
                return -code error "duplicate priorities found (${v_priority})"
            }

            set v_previous_priority ${v_priority}

        }

        return -code ok 0

    }

    # Connect the IRQ sender to the receiver with the given priority

    proc ::irq_connect_pkg::create_connection {receiver sender priority} {
        add_connection                  ${receiver} ${sender}
        set_connection_parameter_value  "${receiver}/${sender}" irqNumber ${priority}
    }

    # Get a sorted list of IRQ priorities. For use by subsystems with an exported irq receiver

    proc ::irq_connect_pkg::get_external_irqs {param_array instance_name internal_priorities} {

        upvar ${param_array} p_array

        set v_external_priorities {}

        for {set v_subsystem_id 0} {${v_subsystem_id} < $p_array(project,id)} {incr v_subsystem_id} {

            set v_subsystem_parameters $p_array(${v_subsystem_id},params)

            array set v_subsystem_irq_array  {}
            set v_subsystem_irq_array(names) {}

            foreach v_subsystem_parameter ${v_subsystem_parameters} {
                set v_name  [lindex ${v_subsystem_parameter} 0]
                set v_value [lindex ${v_subsystem_parameter} 1]

                set v_result [regexp {^(.*)IRQ_(HOST|PRIORITY)$} ${v_name} full_match sub_match_0 sub_match_1]

                if {${v_result} == 1} {
                    set v_irq_name ${sub_match_0}

                    if {[string equal ${sub_match_1} "HOST"] == 1} {

                        if {[string equal ${instance_name} ${v_value}] == 1} {
                            lappend v_subsystem_irq_array(names) ${v_irq_name}

                            # if a priority doesn't exist default to don't care
                            if {[info exists v_subsystem_irq_array(${v_irq_name},priority)] == 0} {
                                set v_subsystem_irq_array(${v_irq_name},priority) "X"
                            }
                        }
                    }

                    if {[string equal ${sub_match_1} "PRIORITY"] == 1} {
                        set v_subsystem_irq_array(${v_irq_name},priority) ${v_value}
                    }
                }
            }

            foreach v_irq_name $v_subsystem_irq_array(names) {
                set v_priority $v_subsystem_irq_array(${v_irq_name},priority)
                lappend v_external_priorities ${v_priority}
            }
        }

        set v_total_priorities [concat ${v_external_priorities} ${internal_priorities}]

        set v_result [catch {::irq_connect_pkg::check_duplicate_priorities ${v_total_priorities}} result_text]
        if {${v_result} != 0} {
            puts "duplicate irq priorities found ${result_text}"
            return -code ${v_result} ${result_text}
        }

        set v_sorted_priorities [lsort -dictionary ${v_external_priorities}]

        return ${v_sorted_priorities}

    }

}
