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

package provide capability_structure_pkg      1.0
package require Tcl                           8.0

package require qsys

# Helper to detect OCS enabled IP and create entries in the OCS ROM(s)

namespace eval capability_structure_pkg {

    namespace export update_capability_structure

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # Update the capability IP parameters. This makes use of the following array
    #
    # Array entries for automatic capability IP
    #  system_array(id,capability)                      - number of capability IP (used for <index>)
    #  system_array(<index>,capability_agent_interface) - capability memory mapped agent interface
    #  system_array(<index>,capability_host_interfaces) - capability memory mapped host interface(s)
    #  system_array(<index>,capability_system)          - capability instance (sub)system file
    #  system_array(<index>,capability_instance)        - capability instance name
    #
    # Array entries for capability enabled IP
    #  system_array(id,ip)                      - number of capability enabled IP (used for <index>)
    #  system_array(<index>,ip_agent_interface) - IP memory mapped agent interface
    #  system_array(<index>,ip_host_interfaces) - IP memory mapped host interface(s)
    #  system_array(<index>,ip_capability_info) - IP capability information (to be stored in capability IP)
    #
    # Array entries for memory mapped interfaces
    #  system_array(<agent_interface>,net_host_interfaces) - memory mapped host interface(s) of <agent_interface>
    #  system_array(<agent_interface>,net_base_addresses)  - memory mapped base address(es) of <agent_interface>

    proc ::capability_structure_pkg::update_capability_structure {} {

        array set v_system_array {}

        set v_system_array(id,ip)         0
        set v_system_array(id,capability) 0

        set v_result [catch {::capability_structure_pkg::analyze_system v_system_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::capability_structure_pkg::find_all_host_interfaces v_system_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::capability_structure_pkg::update_capability_ip v_system_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Recurse through the Platform Designer system (and subsystems)
    # Save IP information, and create a network of memory mapped connections

    proc ::capability_structure_pkg::analyze_system {system_array {current_system ""} {previous_system ""}\
                                                     {current_instance ""}} {

        upvar ${system_array} v_system_array

        if {[string equal "" ${current_system}] == 1} {
            set current_system [get_module_property FILE]
        }

        load_system ${current_system}

        # Get exported interfaces from the current system. Ignore if the current system is the top level system
        # as exported connections from it extend outside the scope of Platform Designer. Add any memory mapped
        # exported interfaces to the array as a transparent connection (i.e. base address of 0).
        if {[string equal "" ${current_system}] != 1} {

            foreach v_interface [get_interfaces] {

                set v_external_interface "${current_instance}${v_interface}"
                set v_export_of          [get_interface_property ${v_interface} EXPORT_OF]
                set v_exported_interface "${current_instance}${v_export_of}"

                set v_export_of_split    [split ${v_export_of} "."]

                if {[llength ${v_export_of_split}] < 2} {
                    return -code error "Invalid EXPORT_OF result for interface\
                                        ${v_external_interface} (${v_export_of})"
                }

                # Get the class name of the exported interface (to infer direction),
                # and ignore any non memory mapped interfaces.
                set v_export_of_instance   [lindex ${v_export_of_split} end-1]
                set v_export_of_interface  [lindex ${v_export_of_split} end]
                set v_export_of_class_name [get_instance_interface_property ${v_export_of_instance}\
                                              ${v_export_of_interface} CLASS_NAME]

                set v_result [regexp {avalon_(.*)} ${v_export_of_class_name} v_match v_direction]

                # Add the interface to the array as a transparent connection (i.e. base address is 0)
                if {${v_result} == 1} {
                    if {[string equal "slave" ${v_direction}] == 1} {
                        set v_host_interface  ${v_external_interface}
                        set v_agent_interface ${v_exported_interface}
                    } elseif {[string equal "master" ${v_direction}] == 1} {
                        set v_host_interface  ${v_exported_interface}
                        set v_agent_interface ${v_external_interface}
                    } else {
                        return -code error "Unknown CLASS_NAME (${v_export_of_class_name})\
                                            for interface ${v_exported_interface}"
                    }

                    set v_result [catch {::capability_structure_pkg::add_connection v_system_array ${v_host_interface}\
                                           ${v_agent_interface} 0} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }

                }

            }

        }

        # Get all internal connections and add any memory mapped connections to the array.
        foreach v_connection [get_connections] {

            set v_connection_type [get_connection_property ${v_connection} TYPE]

            if {[string equal "avalon" ${v_connection_type}] == 1} {

                set v_result [regexp {(.*)\/(.*)} ${v_connection} v_match v_host v_agent]
                if {${v_result} != 1} {
                    return -code error "Unable to split connection into host and agent (${v_connection})"
                }

                set v_result [catch {::capability_structure_pkg::get_connection_base_address ${v_connection}}\
                                       v_base_address]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_base_address}
                }

                set v_host_interface  "${current_instance}${v_host}"
                set v_agent_interface "${current_instance}${v_agent}"

                set v_result [catch {::capability_structure_pkg::add_connection v_system_array ${v_host_interface}\
                                       ${v_agent_interface} ${v_base_address}} v_result_text]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_result_text}
                }

            }
        }

        foreach v_instance [get_instances] {

            set v_instance_group    [get_instance_property ${v_instance} GROUP]
            set v_system            [regexp {^Systems?$} ${v_instance_group}]
            set v_generic_component [string equal "Generic Component" ${v_instance_group}]

            # The instance is a system, recurse into it
            if {${v_system} == 1} {
                set v_instance_file [get_instance_property ${v_instance} FILE]

                set v_result [catch {::capability_structure_pkg::analyze_system v_system_array ${v_instance_file}\
                    ${current_system} "${current_instance}${v_instance}."} current_system]
                if {${v_result} != 0} {
                    return -code ${v_result} ${current_system}
                }

                load_system ${current_system}

            # The instance is a generic component, further investigation required
            } elseif {${v_generic_component} == 1} {

                load_component ${v_instance}

                set v_instance_parameter_value [get_instance_parameter_value ${v_instance} componentDefinition]

                set v_result [catch {::capability_structure_pkg::extract_value_xml ${v_instance_parameter_value}\
                    {originalModuleInfo className}} v_instance_class_name]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_instance_class_name}
                }

                set v_offset_capability [string equal "intel_offset_capability" ${v_instance_class_name}]
                set v_mm_bridge         [string equal "altera_avalon_mm_bridge" ${v_instance_class_name}]
                set v_axi_bridge        [string equal "altera_axi_bridge" ${v_instance_class_name}]

                # The instance is an offset capability IP.
                # If automatic mode is enabled, add to the array as a capability IP.
                if {${v_offset_capability} == 1} {

                    set v_automatic_component [get_component_parameter_value C_AUTO]

                    if {${v_automatic_component} == 1} {

                        set v_index $v_system_array(id,capability)

                        set v_system_array(${v_index},capability_agent_interface)\
                                "${current_instance}${v_instance}.av_mm_control_agent"

                        set v_system_array(${v_index},capability_system)   ${current_system}
                        set v_system_array(${v_index},capability_instance) ${v_instance}

                        incr v_system_array(id,capability)

                    }

                # The instance is a bridge.
                # Add it to the array as a transparent connection (i.e. base address is 0).
                } elseif {(${v_mm_bridge} == 1) || (${v_axi_bridge} == 1)} {

                    set v_host_interface  "${current_instance}${v_instance}.s0"
                    set v_agent_interface "${current_instance}${v_instance}.m0"

                    set v_result [catch {::capability_structure_pkg::add_connection v_system_array ${v_host_interface}\
                                           ${v_agent_interface} 0} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }

                # The instance is not of previous type.
                # If capability mode is enabled, add all memory mapped
                # interfaces and capability information to the array.
                } else {

                    set v_component_parameters [get_component_parameters]
                    set v_capability_enabled   [regexp {C_OMNI_CAP_ENABLED} ${v_component_parameters}]

                    if {${v_capability_enabled} == 1} {

                        set v_result [catch {::capability_structure_pkg::get_ip_capability_information}\
                                               v_capability_information]
                        if {${v_result} != 0} {
                            return -code ${v_result} ${v_capability_information}
                        }

                        set v_instance_interfaces [get_instance_interfaces ${v_instance}]

                        foreach v_interface ${v_instance_interfaces} {

                            set v_interface_class_name [get_instance_interface_property ${v_instance}\
                                                        ${v_interface} CLASS_NAME]
                            set v_agent_interface      [string equal "avalon_slave" ${v_interface_class_name}]

                            if {${v_agent_interface} == 1} {

                                set v_index $v_system_array(id,ip)

                                set v_system_array(${v_index},ip_agent_interface)\
                                    "${current_instance}${v_instance}.${v_interface}"
                                set v_system_array(${v_index},ip_capability_info) ${v_capability_information}

                                incr v_system_array(id,ip)

                            }

                        }

                    }

                }

            }

        }

        return ${previous_system}

    }

    # Find the host interfaces of all capability enabled IP in the Platform Designer system

    proc ::capability_structure_pkg::find_all_host_interfaces {system_array} {

        upvar ${system_array} v_system_array

        # Find capability IP host interface(s)
        for {set v_index 0} {${v_index} < $v_system_array(id,capability)} {incr v_index} {

            set v_agent_interface $v_system_array(${v_index},capability_agent_interface)
            set v_host_interfaces {}

            set v_result [catch {::capability_structure_pkg::find_host_interfaces v_system_array ${v_agent_interface}\
                                   v_host_interfaces} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            set v_system_array(${v_index},capability_host_interfaces) ${v_host_interfaces}

        }

        # Find capability enabled IP host interface(s)
        for {set v_index 0} {${v_index} < $v_system_array(id,ip)} {incr v_index} {

            set v_agent_interface $v_system_array(${v_index},ip_agent_interface)
            set v_host_interfaces {}

            set v_result [catch {::capability_structure_pkg::find_host_interfaces v_system_array ${v_agent_interface}\
                                   v_host_interfaces} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            set v_system_array(${v_index},ip_host_interfaces) ${v_host_interfaces}

        }

        return -code ok

    }

    # Update the capability IP parameters with the capability information of connected IP

    proc ::capability_structure_pkg::update_capability_ip {system_array} {

        upvar ${system_array} v_system_array

        for {set v_cap_index 0} {${v_cap_index} < $v_system_array(id,capability)} {incr v_cap_index} {

            set v_index 0

            set v_system   $v_system_array(${v_cap_index},capability_system)
            set v_instance $v_system_array(${v_cap_index},capability_instance)

            load_system    ${v_system}
            load_component ${v_instance}

            set v_capability_host_interfaces [join $v_system_array(${v_cap_index},capability_host_interfaces)]

            foreach {v_cap_host_interface v_cap_base_address} ${v_capability_host_interfaces} {

                for {set v_ip_index 0} {${v_ip_index} < $v_system_array(id,ip)} {incr v_ip_index} {

                    set v_ip_host_interfaces [join $v_system_array(${v_ip_index},ip_host_interfaces)]

                    foreach {v_ip_host_interface v_ip_base_address} ${v_ip_host_interfaces} {

                        if {[string equal ${v_cap_host_interface} ${v_ip_host_interface}] == 1} {

                            set v_caps $v_system_array(${v_ip_index},ip_capability_info)

                            foreach {v_name v_value} [join ${v_caps}] {
                                regsub C_OMNI_CAP ${v_name} "C_CAP${v_index}" v_name
                                set_component_parameter_value ${v_name} ${v_value}
                            }

                            regsub C_OMNI_CAP C_OMNI_CAP_BASE "C_CAP${v_index}" v_name
                            set_component_parameter_value ${v_name} ${v_ip_base_address}

                            incr v_index

                        }
                    }
                }
            }

            set_component_parameter_value "C_NUM_CAPS" ${v_index}
            sync_sysinfo_parameters
            save_component
            save_system

        }

        return -code ok

    }

    # Get the value of a list of keys from an xml formatted string

    proc ::capability_structure_pkg::extract_value_xml {xml_string keys_list} {

        set v_index       0
        set v_keys_length [llength ${keys_list}]

        foreach v_line [split ${xml_string} "\n"] {
            set v_key  [lindex ${keys_list} ${v_index}]

            if {[regexp "<${v_key}>" ${v_line}] == 1} {
                incr v_index

                if {${v_index} == ${v_keys_length}} {
                    regexp "<${v_key}>(.*)</${v_key}>" ${v_line} match submatch
                    return ${submatch}
                }
            }

            if {[regexp "</${v_key}>" ${v_line}] == 1} {
                incr v_index -1
            }
        }

        return ""

    }

    # Add a memory mapped connection to the system array

    proc ::capability_structure_pkg::add_connection {system_array host_interface agent_interface base_address} {

        upvar ${system_array} v_system_array

        if {[info exists v_system_array(${agent_interface},net_host_interfaces) ] == 1} {
            lappend v_system_array(${agent_interface},net_host_interfaces) ${host_interface}
            lappend v_system_array(${agent_interface},net_base_addresses)  ${base_address}
        } else {
            set v_system_array(${agent_interface},net_host_interfaces) [list ${host_interface}]
            set v_system_array(${agent_interface},net_base_addresses)  [list ${base_address}]
        }

        return -code ok

    }

    # Get the base address of a connection

    proc ::capability_structure_pkg::get_connection_base_address {connection} {

        set v_parameters [get_connection_parameters ${connection}]

        if {[regexp "baseAddress" ${v_parameters}] == 1} {
            return [get_connection_parameter_value ${connection} "baseAddress"]
        }

        return -code error "Unable to get the base address of the connection (${connection})"

    }

    # Get capability parameters of the current component

    proc ::capability_structure_pkg::get_ip_capability_information {} {

        set v_capability_parameters [list C_OMNI_CAP_TYPE C_OMNI_CAP_VERSION C_OMNI_CAP_SIZE C_OMNI_CAP_ID_ASSOCIATED\
            C_OMNI_CAP_ID_COMPONENT C_OMNI_CAP_IRQ C_OMNI_CAP_IRQ_ENABLE\
            C_OMNI_CAP_IRQ_STATUS C_OMNI_CAP_IRQ_ENABLE_EN C_OMNI_CAP_IRQ_STATUS_EN]

        set v_capability_list {}

        foreach v_parameter [get_component_parameters] {

            set v_index [lsearch ${v_capability_parameters} ${v_parameter}]

            if {${v_index} >= 0} {
                set v_value [get_component_parameter_value ${v_parameter}]
                lappend v_capability_list [list ${v_parameter} ${v_value}]
            }

        }

        return ${v_capability_list}

    }

    # Find the memory mapped host(s) of an agent

    proc ::capability_structure_pkg::find_host_interfaces {system_array agent_interface\
                                                           host_interfaces {base_address 0}} {

        upvar ${system_array}    v_system_array
        upvar ${host_interfaces} v_host_interfaces

        if {[info exists v_system_array(${agent_interface},net_host_interfaces) ] == 1} {

            set v_interfaces     $v_system_array(${agent_interface},net_host_interfaces)
            set v_base_addresses $v_system_array(${agent_interface},net_base_addresses)

            for {set v_index 0} {${v_index} < [llength ${v_interfaces}]} {incr v_index} {

                set v_offset     [lindex ${v_base_addresses} ${v_index}]
                set base_address [format 0x%x [expr ${base_address} + ${v_offset}]]

                set agent_interface [lindex ${v_interfaces} ${v_index}]

                set v_result [catch {::capability_structure_pkg::find_host_interfaces v_system_array\
                                       ${agent_interface} v_host_interfaces ${base_address}} v_result_text]
                if {${v_result} != 0} {
                    return -code ${v_result} ${v_result_text}
                }
            }

        } else {
            lappend v_host_interfaces [list ${agent_interface} ${base_address}]
        }

        return -code ok

    }

}
