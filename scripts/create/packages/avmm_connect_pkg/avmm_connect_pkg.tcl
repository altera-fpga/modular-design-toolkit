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

package provide avmm_connect_pkg 1.0

package require Tcl              8.0

# Helper to connect memory mapped interfaces (Avalon)

namespace eval avmm_connect_pkg {

    namespace export run_connections

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # AVMM Associative array
    #
    # v_avmm_array(labels)       - list of AVMM labels
    # v_avmm_array(hosts)        - list of hosts in format {instance interface offset}
    # v_avmm_array(label,hosts)  - list of indexes in the host list
    # v_avmm_array(agents)       - list of agents in format {instance interface offset address_span}
    # v_avmm_array(label,agents) - list of indexes in the agent list
    # v_avmm_array(connections)  - list of list of agent indexes, the (main) index corresponds to each host
    #                            - e.g. v_avmm_array(connections)[0] = a list of agent indexes that connect
    #                                   to host index 0
    #
    # Note: Offset values are either a hexadecimal number, or 'x' (don't care / auto assign)
    #
    # See procedure print_avmm_array as an example of array traversal
    #
    variable  v_avmm_array
    array set v_avmm_array {}

    set v_avmm_array(labels) {}
    set v_avmm_array(hosts)  {}
    set v_avmm_array(agents) {}

    # constants for indexes in the host/agent list
    variable v_instance_index     0
    variable v_interface_index    1
    variable v_offset_index       2
    variable v_address_span_index 3

    proc ::avmm_connect_pkg::run_connections {system avmm_list} {

        set v_result [catch {::avmm_connect_pkg::parse_avmm_list ${avmm_list}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::update_avmm_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::validate_connections} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::connect_avmm ${system}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Convert a list of {instance interface offset label} into an associative array

    proc ::avmm_connect_pkg::parse_avmm_list {avmm_list} {

        variable v_avmm_array

        foreach item ${avmm_list} {

            set v_instance  [lindex ${item} 0]
            set v_interface [lindex ${item} 1]
            set v_offset    [lindex ${item} 2]
            set v_label     [lindex ${item} 3]

            # Check for new label
            if {[lsearch $v_avmm_array(labels) ${v_label}] == -1} {

                lappend v_avmm_array(labels)        ${v_label}
                set v_avmm_array(${v_label},hosts)  {}
                set v_avmm_array(${v_label},agents) {}

            }

            set v_interface_properties [get_instance_interface_properties ${v_instance} ${v_interface}]

            if {[regexp CLASS_NAME ${v_interface_properties}] == 0} {
                return -code error "Error - unable to get class name for ${v_instance}.${v_interface}"
            }

            set v_class_name [get_instance_interface_property ${v_instance} ${v_interface} CLASS_NAME]

            if {${v_class_name} == "avalon_master"} {
                set v_direction "hosts"
            } elseif {${v_class_name} == "avalon_slave"} {
                set v_direction "agents"
            } else {
                return -code error "Error - direction value is invalid - ${v_instance}.${v_interface} = ${v_direction}"
            }

            set v_result [catch {::avmm_connect_pkg::normalize_base_address ${v_offset}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            set v_entry [list ${v_instance} ${v_interface} ${v_result_text}]
            set v_index [lsearch -exact $v_avmm_array(${v_direction}) ${v_entry}]

            if {${v_index} == -1} {
                set v_index [llength $v_avmm_array(${v_direction})]
                lappend v_avmm_array(${v_direction}) ${v_entry}
            }

            lappend v_avmm_array(${v_label},${v_direction}) ${v_index}

        }

        return -code ok

    }

    # Fill additional information in the avmm array

    proc ::avmm_connect_pkg::update_avmm_array {} {

        set v_result [catch {::avmm_connect_pkg::update_system_bridges} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::get_host_base_addresses} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::get_agent_address_spans} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::sort_agents_by_offsets} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::avmm_connect_pkg::generate_connections_list} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Check avmm connection rules:
    # - The base address of an agent component must be a multiple of the address span of the component
    # - The address spans of agent components must not overlap

    proc ::avmm_connect_pkg::validate_connections {} {

        variable v_avmm_array

        variable v_instance_index
        variable v_interface_index
        variable v_offset_index
        variable v_address_span_index

        for {set v_host_index 0} {${v_host_index} < [llength $v_avmm_array(hosts)]} {incr v_host_index} {

            set v_host          [lindex $v_avmm_array(hosts) ${v_host_index}]
            set v_agent_indexes [lindex $v_avmm_array(connections) ${v_host_index}]

            set v_host_instance  [lindex ${v_host} ${v_instance_index}]
            set v_host_interface [lindex ${v_host} ${v_interface_index}]
            set v_host_offset    [lindex ${v_host} ${v_offset_index}]

            set v_min_base_address   ${v_host_offset}
            set v_previous_interface "${v_host_instance}.${v_host_interface}"

            foreach v_agent_index ${v_agent_indexes} {

                set v_agent [lindex $v_avmm_array(agents) ${v_agent_index}]

                set v_agent_instance     [lindex ${v_agent} ${v_instance_index}]
                set v_agent_interface    [lindex ${v_agent} ${v_interface_index}]
                set v_agent_offset       [lindex ${v_agent} ${v_offset_index}]
                set v_agent_address_span [lindex ${v_agent} ${v_address_span_index}]

                set v_undefined [string equal -nocase ${v_agent_offset} "x"]

                if {${v_undefined} == 0} {

                    set v_address_span_mod [expr { fmod( ${v_agent_offset}, ${v_agent_address_span} ) }]

                    if {${v_address_span_mod} != 0.0} {
                        return -code error "Offset must be a multiple of the address span:\
                                            ${v_agent_instance}.${v_agent_interface}, requested\
                                            ${v_agent_offset} (span ${v_agent_address_span})"
                    }

                    if {${v_min_base_address} > ${v_agent_offset}} {
                        return -code error "Address space overlaps between ${v_previous_interface}\
                                            and ${v_agent_instance}.${v_agent_interface}, requested\
                                            ${v_agent_offset}, available ${v_min_base_address}"
                    }

                    set v_int_offset [expr ${v_agent_offset} + ${v_agent_address_span}]
                    set v_hex_offset [format 0x%x ${v_int_offset}]

                    set v_result [catch {::avmm_connect_pkg::normalize_base_address ${v_hex_offset}} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }

                    set v_min_base_address   ${v_result_text}
                    set v_previous_interface "${v_agent_instance}.${v_agent_interface}"

                }

            }

        }

        return -code ok

    }

    # Connect all AVMM interfaces

    proc ::avmm_connect_pkg::connect_avmm {system} {

        variable v_avmm_array

        load_system ${system}

        for {set v_host_index 0} {${v_host_index} < [llength $v_avmm_array(connections)]} {incr v_host_index} {
            set v_host          [lindex $v_avmm_array(hosts) ${v_host_index}]
            set v_agent_indexes [lindex $v_avmm_array(connections) ${v_host_index}]

            foreach v_agent_index ${v_agent_indexes} {
                set v_agent [lindex $v_avmm_array(agents) ${v_agent_index}]

                set v_result [catch {::avmm_connect_pkg::add_avmm_connection ${v_host} ${v_agent}} v_result_text]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_result_text}
                }
            }
        }

        save_system
        return -code ok

    }

    # Update system bridge widths

    proc ::avmm_connect_pkg::update_system_bridges {} {

        variable v_avmm_array
        variable v_instance_index

        set v_instance_list  {}
        set v_instance_files {}

        foreach v_host $v_avmm_array(hosts) {
            set v_instance [lindex ${v_host} ${v_instance_index}]
            if {[lsearch -exact ${v_instance_list} ${v_instance}] == -1} {
                lappend v_instance_list  ${v_instance}
                lappend v_instance_files [get_instance_property ${v_instance} FILE]
            }
        }

        foreach v_agent $v_avmm_array(agents) {
            set v_instance [lindex ${v_agent} ${v_instance_index}]
            if {[lsearch -exact ${v_instance_list} ${v_instance}] == -1} {
                lappend v_instance_list  ${v_instance}
                lappend v_instance_files [get_instance_property ${v_instance} FILE]
            }
        }

        set v_current_system [get_module_property FILE]

        foreach v_instance_file ${v_instance_files} {
            load_system ${v_instance_file}
            sync_sysinfo_parameters
            save_system
        }

        load_system ${v_current_system}

        return -code ok

    }

    # Get the base addresses of all hosts

    proc ::avmm_connect_pkg::get_host_base_addresses {} {

        variable v_avmm_array
        variable v_instance_index
        variable v_interface_index

        set v_current_system [get_module_property FILE]
        set v_host_list      {}

        foreach v_host $v_avmm_array(hosts) {
            set v_instance  [lindex ${v_host} ${v_instance_index}]
            set v_interface [lindex ${v_host} ${v_interface_index}]

            set v_result [catch {::avmm_connect_pkg::trace_avmm_interface\
                                   0 ${v_current_system} ${v_instance} ${v_interface}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            lappend v_host_list [list ${v_instance} ${v_interface} ${v_result_text}]

        }

        set v_avmm_array(hosts) ${v_host_list}
        load_system             ${v_current_system}

        return -code ok

    }

    # Get address spans of all agents

    proc ::avmm_connect_pkg::get_agent_address_spans {} {

        variable v_avmm_array

        variable v_instance_index
        variable v_interface_index

        set v_current_system [get_module_property FILE]
        set v_agent_list     {}

        foreach v_agent $v_avmm_array(agents) {
            set v_instance  [lindex ${v_agent} ${v_instance_index}]
            set v_interface [lindex ${v_agent} ${v_interface_index}]

            set v_properties   [get_instance_interface_properties ${v_instance} ${v_interface}]
            set v_span_present [regexp "addressSpan" ${v_properties}]

            if {${v_span_present} == 1} {
                set v_address_span [get_instance_interface_property ${v_instance} ${v_interface} "addressSpan"]
            } else {
                return -code error "Unable to find addressSpan property of ${v_instance}.${v_interface}"
            }

            lappend v_agent      ${v_address_span}
            lappend v_agent_list ${v_agent}

        }

        set v_avmm_array(agents) ${v_agent_list}
        load_system              ${v_current_system}

        return -code ok

    }

    # Sort agents by ascending base address offset

    proc ::avmm_connect_pkg::sort_agents_by_offsets {} {

        variable v_avmm_array

        # sort by ascending base address order
        set v_result [catch {::avmm_connect_pkg::manual_sort $v_avmm_array(agents) 2} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_sorted_agents ${v_result_text}

        # find the mapping between the unsorted and sorted agents lists
        set v_agent_mapping {}

        foreach v_agent $v_avmm_array(agents) {
            set v_index [lsearch -exact ${v_sorted_agents} ${v_agent}]

            if {${v_index} >= 0} {
                lappend v_agent_mapping ${v_index}
            } else {
                return -code error "unable to find agent (${v_agent}) in list (${v_sorted_agents})"
            }
        }

        # update agent indexes to the sorted list index
        set v_avmm_array(agents) ${v_sorted_agents}

        foreach v_label $v_avmm_array(labels) {
            set v_updated_agents {}

            foreach v_old_agent_index $v_avmm_array(${v_label},agents) {
                set v_new_agent_index    [lindex ${v_agent_mapping} ${v_old_agent_index}]
                lappend v_updated_agents ${v_new_agent_index}
            }


            set v_avmm_array(${v_label},agents) [lsort -integer ${v_updated_agents}]
        }

        return -code ok

    }

    # Generate list of connections between host and agent interfaces

    proc ::avmm_connect_pkg::generate_connections_list {} {

        variable v_avmm_array

        set v_connections {}

        for {set v_host_index 0} {${v_host_index} < [llength $v_avmm_array(hosts)]} {incr v_host_index} {
            lappend v_connections {}
        }

        set v_agents {}

        foreach v_label $v_avmm_array(labels) {

            foreach v_host_index $v_avmm_array(${v_label},hosts) {
                set v_agents [lindex ${v_connections} ${v_host_index}]

                foreach v_agent_index $v_avmm_array(${v_label},agents) {
                    if {[lsearch ${v_agents} ${v_agent_index}] < 0} {
                        lappend v_agents ${v_agent_index}
                    }
                }

                set v_agents      [lsort -integer ${v_agents}]
                set v_connections [lreplace ${v_connections} ${v_host_index} ${v_host_index} ${v_agents}]
            }
        }

        set v_avmm_array(connections) ${v_connections}

        return -code ok

    }

    # Pad base address to 32-bits and 0x prefix

    proc ::avmm_connect_pkg::normalize_base_address {base_address} {

        if {[string equal -nocase ${base_address} "x"]} {
            return ${base_address}
        }

        set v_base_address [string trim ${base_address}]
        set v_base_address [string tolower ${v_base_address}]
        set v_base_address [string map {"0x" ""} ${v_base_address}]

        set v_length [string length ${v_base_address}]

        if {${v_length} <= 8} {
            set v_padding [string repeat 0 [expr 8 - ${v_length}]]
            set v_base_address ${v_padding}${v_base_address}
        } else {
            set v_bits [expr ${v_length} * 4]
            return -code error "Maximum width of base address exceeded (expected 32 bits, received ${v_bits} bits)"
        }

        return -code ok "0x${v_base_address}"

    }

    # Trace the avmm interface to the source(s) returning the total base address offset

    proc ::avmm_connect_pkg::trace_avmm_interface {{current_level 0} {current_system ""}\
                                                   {current_instance ""} {current_interface ""}} {

        if {${current_system} != ""} {
            load_system ${current_system}

            # The first invocation does not have an export
            if {${current_level} != 0} {
                set v_exported_interface [get_interface_property ${current_interface} EXPORT_OF]

                if {${v_exported_interface} != ""} {
                    set v_split_exported_interface [split ${v_exported_interface} "."]
                    set current_instance           [lindex ${v_split_exported_interface} 0]
                    set current_interface          [lindex ${v_split_exported_interface} 1]
                } else {
                    return -code error "Failed to find the interface exported to\
                                        ${current_instance}.${current_interface}"
                }
            }
        }

        set v_instance_group    [get_instance_property ${current_instance} GROUP]
        set v_is_system         [expr [string equal -nocase ${v_instance_group} "systems"] ||\
                                      [string equal -nocase ${v_instance_group} "system"]]
        set v_is_component      [string equal -nocase ${v_instance_group} "Generic Component"]
        set v_is_cpu            [string equal -nocase ${v_instance_group} "Processors and Peripherals/Hard Processor Systems"]

        if {${v_is_system} == 1} {
            set v_instance_file [get_instance_property ${current_instance} FILE]
            set v_next_level    [expr ${current_level} + 1]

            # get the upstream base address
            set v_result [catch {::avmm_connect_pkg::trace_avmm_interface\
                                    ${v_next_level} ${v_instance_file} ${current_instance}\
                                    ${current_interface}} v_result_text]
            return -code ${v_result} ${v_result_text}

        } elseif {${v_is_component} == 1} {
            set v_instance_definition [get_instance_parameter_value ${current_instance} componentDefinition]

            set v_result [catch {::avmm_connect_pkg::extract_value_xml\
                                    ${v_instance_definition} {originalModuleInfo className}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            set v_instance_type ${v_result_text}

            if {${v_instance_type} == "altera_avalon_mm_bridge"} {
                set v_instance_connections [get_connections ${current_instance}.s0]
                set v_base_address_list     {}

                foreach v_connection ${v_instance_connections}  {

                    set v_result [catch {::avmm_connect_pkg::get_base_address ${v_connection}} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }

                    set v_base_address ${v_result_text}
                    set v_next_level   [expr ${current_level} + 1]

                    # follow host upstream
                    set v_result [regexp "(\w+)\.(\w+)\/(\w+)\.(\w+)" ${v_connection} v_match\
                        v_host_instance v_host_interface v_agent_instance v_agent_interface]
                    if {${v_result} != 1} {
                        return -code ${v_result} ${v_result_text}
                    }

                    # get upstream base address (within current system)
                    set v_result [catch {::avmm_connect_pkg::trace_avmm_interface\
                                            ${v_next_level} "" ${v_host_instance}\
                                            ${v_host_interface}} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }

                    set v_base_address [format 0x%x [expr ${v_base_address} + ${v_result_text}]]

                    set v_result [catch {::avmm_connect_pkg::normalize_base_address ${v_base_address}} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }

                    lappend v_base_address_list ${v_result_text}

                }

                set v_base_addresses [llength ${v_base_address_list}]

                if {${v_base_addresses} <= 0} {
                    return -code error "No connections to ${current_instance}.s0"
                }

                set v_ref_base_address [lindex ${v_base_address_list} 0]

                foreach v_base_address ${v_base_address_list} {
                    if {${v_ref_base_address} != ${v_base_address}} {
                        return -code error "${current_instance}.s0 connected to multiple hosts with\
                                            differing base addresses (${v_base_address_list}). Unable\
                                            to resolve ambiguity in base address"
                    }
                }

                return -code ok "${v_ref_base_address}"

            } elseif {${v_instance_type} == ""} {
                return -code error "Unable to get current_instance type (${current_instance})"
            } else {
                return -code ok "0x00000000"
            }

        } elseif {${v_is_cpu} == 1} {
            print_message "Reached source of AVMM chain (${current_instance}.${current_interface})"
            return -code ok "0x00000000"
        } else {
            return -code error "current_instance (${current_instance}) of unknown current_instance group (${v_instance_group})"
        }

    }

    # Sort the input list of lists based on the sub-list input_index

    proc ::avmm_connect_pkg::manual_sort {input_list input_index} {

        set v_sorted_list [list [lindex ${input_list} 0]]

        for {set v_index 1} {${v_index} < [llength ${input_list}]} {incr v_index} {
            set v_sub_list           [lindex ${input_list} ${v_index}]
            set v_sort_value         [lindex ${v_sub_list} ${input_index}]
            set v_sorted_list_length [llength ${v_sorted_list}]
            set v_inserted           0

            if {[string equal -nocase "x" ${v_sort_value}] == 0} {

                for {set v_sorted_list_index 0} {${v_sorted_list_index} < ${v_sorted_list_length}}\
                    {incr v_sorted_list_index} {
                    set v_ref_sub_list [lindex ${v_sorted_list} ${v_sorted_list_index}]
                    set v_ref_value    [lindex ${v_ref_sub_list} ${input_index}]

                    if {${v_sort_value} < ${v_ref_value}} {
                        set v_sorted_list [linsert ${v_sorted_list} ${v_sorted_list_index} ${v_sub_list}]
                        set v_inserted 1
                        break
                    }
                }
            }

            if {${v_inserted} == 0} {
                lappend v_sorted_list ${v_sub_list}
            }

        }

        return -code ok "${v_sorted_list}"

    }

    # Connect AVMM host/agent pair (with base address if present)

    proc ::avmm_connect_pkg::add_avmm_connection {host agent} {

        variable v_instance_index
        variable v_interface_index
        variable v_offset_index

        set v_host_instance      [lindex ${host} ${v_instance_index}]
        set v_host_interface     [lindex ${host} ${v_interface_index}]
        set v_host_base_address  [lindex ${host} ${v_offset_index}]

        set v_agent_instance     [lindex ${agent} ${v_instance_index}]
        set v_agent_interface    [lindex ${agent} ${v_interface_index}]
        set v_agent_base_address [lindex ${agent} ${v_offset_index}]

        set v_host  "${v_host_instance}.${v_host_interface}"
        set v_agent "${v_agent_instance}.${v_agent_interface}"

        add_connection ${v_host} ${v_agent}

        if {[string equal -nocase ${v_agent_base_address} "x"] == 0} {
            set v_base_address [format 0x%x [expr ${v_agent_base_address} - ${v_host_base_address}]]

            set v_result [catch {::avmm_connect_pkg::normalize_base_address ${v_base_address}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            set_connection_parameter_value "${v_host}/${v_agent}" baseAddress ${v_result_text}
            lock_avalon_base_address ${v_agent}
        }

        return -code ok

    }

    # Extract key value from an xml (multi-line) string

    proc ::avmm_connect_pkg::extract_value_xml {xml keys} {

        set v_key_length [llength ${keys}]
        set v_lines      [split ${xml} "\n"]
        set v_depth      0

        foreach v_line ${v_lines} {
            set v_key [lindex ${keys} ${v_depth}]

            if {[regexp "<${v_key}>" ${v_line}]} {
                incr v_depth

                if {${v_depth} == ${v_key_length}} {
                    regexp "<${v_key}>(.*)</${v_key}>" ${v_line} v_match v_submatch
                    return -code ok "${v_submatch}"
                }
            }

            if {[regexp "</${v_key}>" ${v_line}]} {
                incr v_depth -1
            }
        }

        return -code ok

    }

    # Procedure to get the base address of an existing connection

    proc ::avmm_connect_pkg::get_base_address {connection} {

        set v_connection_parameters [get_connection_parameters ${connection}]

        if {[regexp "baseAddress" ${v_connection_parameters}]} {
            set v_base_address [get_connection_parameter_value ${connection} "baseAddress"]
            set v_result       [catch {::avmm_connect_pkg::normalize_base_address ${v_base_address}} v_result_text]
            return -code ${v_result} ${v_result_text}

        } else {
            return -code error "Unable to get base address for connection ${connection}"

        }

        return -code ok

    }

    # Print the AVMM array

    proc ::avmm_connect_pkg::print_avmm_array {} {

        variable v_avmm_array

        puts "AVMM connect pkg: ============================================"
        puts "AVMM connect pkg: ---------------- AVMM Array ----------------"
        puts "AVMM connect pkg: ============================================"

        foreach v_label $v_avmm_array(labels) {
            puts "AVMM connect pkg: AVMM label - ${v_label}"
            puts "AVMM connect pkg: Hosts ($v_avmm_array(${v_label},hosts)):"

            foreach v_host_index $v_avmm_array(${v_label},hosts) {
                set v_host [lindex $v_avmm_array(hosts) ${v_host_index}]
                puts "AVMM connect pkg: -- ${v_host}"
            }

            puts "AVMM connect pkg: Agents ($v_avmm_array(${v_label},agents)):"

            foreach v_agent_index $v_avmm_array(${v_label},agents) {
                set v_agent [lindex $v_avmm_array(agents) ${v_agent_index}]
                puts "AVMM connect pkg: -- ${v_agent}"
            }

            puts "AVMM connect pkg: ============================================"

        }

        if {[info exists v_avmm_array(connections)]} {

            puts "AVMM connect pkg: --------------- Connections ----------------"
            puts "AVMM connect pkg: ============================================"

            for {set v_host_index 0} {${v_host_index} < [llength $v_avmm_array(connections)]} {incr v_host_index} {
                set v_host          [lindex $v_avmm_array(hosts) ${v_host_index}]
                set v_agent_indexes [lindex $v_avmm_array(connections) ${v_host_index}]

                if {[llength ${v_agent_indexes}] > 0} {
                    puts "AVMM connect pkg: Host (${v_host_index}):"
                    puts "AVMM connect pkg: -- ${v_host}"
                    puts "AVMM connect pkg: Agents (${v_agent_indexes}):"

                    foreach v_agent_index ${v_agent_indexes} {
                        set v_agent [lindex $v_avmm_array(agents) ${v_agent_index}]
                        puts "AVMM connect pkg: -- ${v_agent}"

                    }

                    puts "AVMM connect pkg: ============================================"

                }
            }

        }

        puts "AVMM connect pkg: ============================================"
        puts "AVMM connect pkg: ============================================"

        return -code ok

    }

}
