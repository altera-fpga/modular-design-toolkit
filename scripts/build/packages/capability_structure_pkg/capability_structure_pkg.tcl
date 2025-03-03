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

package provide capability_structure_pkg      1.0
package require Tcl                           8.0

package require -exact qsys 18.0

# Helper to detect OCS enabled IP and create entries in the OCS ROM(s)

namespace eval capability_structure_pkg {

    namespace export update_capability_structure

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # Get the value of a parameter from a list (i.e. param=value)

    proc ::capability_structure_pkg::extract_value {parameter generic_list} {

        foreach item ${generic_list} {
            if {[regexp ${parameter} ${item}] == 1} {
                regexp "${parameter}=*(\[A-Za-z0-9\]*)" ${item} match sub
                return ${sub}
            }
        }

        return ""

    }

    # Get the value of a list of keys from an xml formatted string

    proc ::capability_structure_pkg::extract_value_xml {xml_string keys_list} {

        set v_index       0
        set v_keys_length [llength ${keys_list}]

        foreach line [split ${xml_string} "\n"] {
            set v_key [lindex ${keys_list} ${v_index}]

            if {[regexp "<${v_key}>" ${line}] == 1} {
                incr v_index

                if {${v_index} == ${v_keys_length}} {
                    regexp "<${v_key}>(.*)</${v_key}>" ${line} match sub
                    return ${sub}
                }
            }

            if {[regexp "</${v_key}>" ${line}] == 1} {
                incr v_index -1
            }
        }

        return ""

    }

    # Protect against requesting addresses from connection that have none

    proc ::capability_structure_pkg::custom_get_address {connection} {

        set v_parameters [get_connection_parameters ${connection}]

        if {[regexp "baseAddress" ${v_parameters}] == 1} {
            return [get_connection_parameter_value ${connection} "baseAddress"]
        }

        return ""

    }

    # Update the IP capability ROM from the Platform Designer system
    #
    # Phase 1:
    #
    #   1) Build a connection tree of the entire design:
    #       - create variable "v_all_nets". This is an Tcl Array(key) pair identifying
    #         two ends of a net, (source/destination)
    #   2) Find all "omni***"" ip cores that have a CPU addressable interface
    #   3) Locate mm-bridges and create a fake connection through them
    #   4) At each node, extract ANY address information
    #
    # Phase 2:
    #
    #    1) Iterate over each cpu-addressable "omni***" ip core
    #    2) All C_OMNI_ parameters are cloned into the offset_capability
    #    3) Traverse netlist from CPU interface back to root-node:
    #       - During the traverse, extract each "relative-address"
    #       - Add these together to form the "absolute-address"
    #       - Once Root-Node found (end of list) we have the TRUE base-address
    #       - Apply base address to offset capability
    #
    # Phase 3:
    #
    #    Sync systems and Save

    proc ::capability_structure_pkg::update_capability_structure { {current_level 0} {current_system ""} {previous_system ""} {current_instance ""} } {

        upvar v_all_nets        v_all_nets
        upvar v_all_cores       v_all_cores
        upvar v_all_base        v_all_base
        upvar v_all_generics    v_all_generics
        upvar v_all_offset      v_all_offset
        upvar v_all_startpoints v_all_startpoints
        upvar v_hierarchy       v_hierarchy

        # Phase 1

        if {${current_system} == ""} {
            set current_system [get_module_property FILE]
        }

        load_system ${current_system}

        # Add netlist connections for IP core exported interfaces
        if {${current_level} != 0} {
            foreach interface [get_interfaces] {

                set v_source    "${current_instance}.${interface}"
                set v_export    [get_interface_property ${interface} EXPORT_OF]
                set v_sink      "${current_instance}.${v_export}"
                set v_direction [lindex [split ${v_export} "."] 1]

                # direction cannot be directly queried, infer from export name
                if {${v_direction} == "s0"} {
                    lappend v_all_nets(${v_sink}) ${v_source}
                } else {
                    lappend v_all_nets(${v_source}) ${v_sink}
                }

            }
        }

        # Add netlist connections for IP core to IP core interfaces
        foreach connection [get_connections]  {

            set v_connection       [split ${connection} "/"]
            set v_source_interface [lindex ${v_connection} 0]
            set v_sink_interface   [lindex ${v_connection} 1]

            set v_source "${current_instance}.${v_source_interface}"
            set v_sink   "${current_instance}.${v_sink_interface}"

            lappend v_all_nets(${v_sink}) ${v_source}

            # Add base address of the connection (if present)
            set v_working_base [::capability_structure_pkg::custom_get_address ${connection}]

            if {${v_working_base} != ""} {
                set v_all_base(${v_sink}) ${v_working_base}
            }

        }

        foreach instance [get_instances] {

            set v_instance_group [get_instance_property ${instance} GROUP]

            # check the instance type
            if {(${v_instance_group} == "System") || (${v_instance_group} == "Systems")} {

                set v_hierarchy(${instance}) [get_module_property NAME]
                set v_instance_file          [get_instance_property ${instance} FILE]

                # recurse into the subsystem
                set current_system [::capability_structure_pkg::update_capability_structure [expr ${current_level} + 1]\
                                    ${v_instance_file} ${current_system} ${instance}]
                load_system ${current_system}

            } elseif {${v_instance_group} == "Generic Component"} {

                load_component ${instance}

                set v_ip_core_generics {}

                foreach parameter [get_component_parameters] {
                    set v_parameter_value      [get_component_parameter_value ${parameter}]
                    lappend v_ip_core_generics "${parameter}=${v_parameter_value}"
                }

                set v_instance_parameter_value [get_instance_parameter_value ${instance} componentDefinition]
                set v_keys                     {originalModuleInfo className}

                set v_ip_core_name [::capability_structure_pkg::extract_value_xml\
                                    ${v_instance_parameter_value} ${v_keys}]

                # Check the IP core type
                if {${v_ip_core_name} == "intel_offset_capability"} {

                    # Add offset capability
                    set v_all_offset(${instance}) ${current_system}

                } elseif {(${v_ip_core_name} == "altera_avalon_mm_bridge") || (${v_ip_core_name} == "altera_axi_bridge")} {

                    # Create a dummy connection through the bridge
                    set v_source "${current_instance}.${instance}.m0"
                    set v_sink   "${current_instance}.${instance}.s0"

                    lappend v_all_nets(${v_source}) ${v_sink}

                    foreach connection [get_connections "${instance}.m0"]  {

                        set v_working_base [::capability_structure_pkg::custom_get_address ${connection}]

                        if {${v_working_base} != ""} {
                            set v_all_base(${v_sink}) 0
                        }

                    }

                } else {

                    set v_component_parameters [get_component_parameters]
                    set v_capability_enabled   [regexp "C_OMNI_CAP_ENABLED" ${v_component_parameters}]

                    if {${v_capability_enabled}} {

                        set v_hierarchy_name "${current_instance}.${instance}"

                        # Find AXI/Avalon Agents
                        foreach connection [get_connections ${instance}]  {

                            set v_connection_type [get_connection_property ${connection} TYPE]

                            if {${v_connection_type} == "avalon"} {

                                set v_connection       [split ${connection} "/"]
                                set v_source_interface [lindex ${v_connection} 0]
                                set v_sink_interface   [lindex ${v_connection} 1]

                                set v_source "${current_instance}.${v_source_interface}"
                                set v_sink   "${current_instance}.${v_sink_interface}"

                                set v_working_base [get_connection_parameter_value ${connection} baseAddress]

                                set v_all_base(${v_hierarchy_name})        ${v_working_base}
                                set v_all_generics(${v_hierarchy_name})    ${v_ip_core_generics}
                                set v_all_startpoints(${v_hierarchy_name}) ${v_sink}
                                lappend v_all_cores ${v_hierarchy_name}

                            }
                        }
                    }
                }
            }
        }

        # Phase 2

        if {${current_level} == 0} {

            foreach key [array names v_all_offset] {

                load_system    $v_all_offset(${key})
                load_component ${key}

                set v_offset_core_generics {}

                foreach parameter [get_component_parameters] {
                    set v_component_parameter      [get_component_parameter_value ${parameter}]
                    lappend v_offset_core_generics "${parameter}=${v_component_parameter}"
                }

                set v_automatic_component [::capability_structure_pkg::extract_value C_AUTO ${v_offset_core_generics}]

                if {${v_automatic_component} == 1} {

                    set v_capability_index 0

                    foreach core ${v_all_cores} {

                        set v_capability_found      0
                        set v_capability_properties [list C_OMNI_CAP_TYPE C_OMNI_CAP_VERSION C_OMNI_CAP_SIZE\
                                                          C_OMNI_CAP_ID_ASSOCIATED C_OMNI_CAP_ID_COMPONENT\
                                                          C_OMNI_CAP_IRQ  C_OMNI_CAP_IRQ_ENABLE C_OMNI_CAP_IRQ_STATUS\
                                                          C_OMNI_CAP_IRQ_ENABLE_EN C_OMNI_CAP_IRQ_STATUS_EN]

                        # search for capability properties to add to the ROM
                        foreach generic $v_all_generics(${core}) {
                            foreach extract ${v_capability_properties} {
                                if {[regexp "${extract}=" "${generic}="]} {
                                    set v_capability_found 1
                                    regsub C_OMNI_CAP "${extract}" "C_CAP${v_capability_index}" extract
                                    set v_parameter_value [lindex [split ${generic} "="] 1]
                                    set_component_parameter_value ${extract} ${v_parameter_value}
                                }
                            }
                        }

                        if {${v_capability_found}} {

                            # find absolute base address of the core by traversing the v_hierarchy
                            if {$v_all_base(${core}) != ""} {
                                if {[info exists v_all_startpoints(${core})]} {

                                    set v_current_node      $v_all_startpoints(${core})
                                    set v_true_base_address 0x0

                                    while {[info exists v_all_nets(${v_current_node})]} {

                                        set v_current_base_address 0x0
                                        if {[info exists v_all_base(${v_current_node})]} {
                                            set v_current_base_address $v_all_base(${v_current_node})
                                        }

                                        set v_true_base_address [format 0x%x [expr ${v_true_base_address}\
                                                                              + ${v_current_base_address}]]
                                        set v_current_node      $v_all_nets(${v_current_node})

                                        # Use v_hierarchy mapping to allow a level jump if the node name is pre-pended with parent name
                                        if {![info exists v_all_nets(${v_current_node})]} {
                                            regsub {\..*} "${v_current_node}" "" v_parent_name
                                            if {[info exists v_hierarchy(${v_parent_name})]} {
                                                set v_current_node "$v_hierarchy(${v_parent_name}).${v_current_node}"
                                            }
                                        }
                                    }
                                }

                                set_component_parameter_value "C_CAP${v_capability_index}_BASE" ${v_true_base_address}
                            }

                            incr v_capability_index

                        }
                    }

                    # Phase 3

                    set_component_parameter_value "C_NUM_CAPS" ${v_capability_index}
                    sync_sysinfo_parameters
                    save_component
                    save_system

                }
            }

        } else {
            return ${previous_system}
        }

        return

    }

}
