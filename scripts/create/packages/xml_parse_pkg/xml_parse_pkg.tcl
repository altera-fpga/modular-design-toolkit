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

package provide xml_parse_pkg 1.0

package require Tcl           8.0

package require xml
package require xml::libxml2
package require dom
package require dom::tcl
package require dom::libxml2

set v_script_directory [file dirname [info script]]
lappend auto_path [file join ${v_script_directory} ".."]

# Helper for XML design file parsing

namespace eval xml_parse_pkg {

    namespace export parse_xml_design_file

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    variable v_parameter_array

    # Namespace constants
    set v_xml_path         ""
    set v_toolkit_root     ""
    set v_subsystems_root  ""
    set v_document_element ""

    # Minimum parameters required for Quartus Project creation
    set v_required_parameters [list DEVICE DEVKIT FAMILY]

    # List of nodes with children
    set v_parent_nodes [list PROJECT SUBSYSTEM ADDON_CARD]

    # Special parameter nodes (requiring extra parsing)
    set v_memory_mapped_nodes [list "AVMM_HOST*"]
    set v_interrupt_nodes     [list "IRQ_RX*"]
    set v_path_nodes          [list "*_DIR" "*_FILE"]

    # Search paths relative to generated project file (.qpf)
    set v_default_ip_search_paths [list [file join "." ".." "non_qpds_ip" "**" "*"]\
                                        [file join "." ".." "rtl" "shell" "**" "*"]\
                                        [file join "." ".." "rtl" "user"  "**" "*"]\
                                        "\$"]

    # Search paths (relative to v_toolkit_root, glob syntax)
    set v_design_search_paths     [list [file join "."]]
    set v_subsystem_search_paths  [list [file join "." "subsystems" "platform_designer_subsystems" "*_subsystem" "*_create.tcl"]]
    set v_addon_card_search_paths [list [file join "." "subsystems" "platform_designer_subsystems" "board_subsystem" "addon_cards" "*" "*_create.tcl"]]

    ###################################################################################

    # Parse the xml design file and create an associative array of parameters

    proc ::xml_parse_pkg::parse_xml_design_file {xml_argument toolkit_root output_parameter_array} {

        upvar ${output_parameter_array} v_output_parameter_array

        variable v_parameter_array

        set v_result [catch {::xml_parse_pkg::initialize_variables ${xml_argument} ${toolkit_root}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::parse_project} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::parse_subsystems} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::post_process_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        array set v_output_parameter_array [array get v_parameter_array]

        return -code ok

    }

    # Initialize variables (XML path, toolkit root, document element (base node))

    proc ::xml_parse_pkg::initialize_variables {xml_argument toolkit_root} {

        set v_result [catch {::xml_parse_pkg::set_xml_path ${xml_argument}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::set_toolkit_root ${toolkit_root}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::set_xml_document_element} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Parse project attributes and parameters

    proc ::xml_parse_pkg::parse_project {} {

        variable v_parameter_array

        set v_result [catch {::xml_parse_pkg::initialize_parameter_array} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::parse_project_attributes\
                             ${::xml_parse_pkg::v_document_element}} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::get_node_parameters ${::xml_parse_pkg::v_document_element}} v_parameters]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_parameters}
        }

        set v_parameter_array(project,params) [list {*}$v_parameter_array(project,params) {*}${v_parameters}]

        set v_result [catch {::xml_parse_pkg::process_project_parameters} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Parse subsystem attributes and parameters

    proc ::xml_parse_pkg::parse_subsystems {} {

        variable v_parameter_array

        set v_result [catch {::xml_parse_pkg::get_subsystem_nodes\
                             ${::xml_parse_pkg::v_document_element}} v_subsystem_nodes]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_subsystem_nodes}
        }

        foreach v_subsystem ${v_subsystem_nodes} {

            set v_id $v_parameter_array(project,id)

            set v_result [catch {::xml_parse_pkg::parse_subsystem_attributes ${v_subsystem}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            set v_result [catch {::xml_parse_pkg::get_node_parameters ${v_subsystem}} v_parameters]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_parameters}
            }

            set v_parameter_array(${v_id},params) ${v_parameters}

            # parse special subsystems
            switch -exact $v_parameter_array(${v_id},type) {
                board   {
                    set v_result [catch {::xml_parse_pkg::parse_board_subsystem ${v_subsystem}} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }
                }
                user    {
                    set v_result [catch {::xml_parse_pkg::parse_user_subsystem ${v_subsystem}} v_result_text]
                    if {${v_result} != 0} {
                        return -code ${v_result} ${v_result_text}
                    }
                }
                default {}
            }

            incr v_parameter_array(project,id)

        }

        return -code ok

    }

    # Post process parameters (check parameters, assign subsystem names/scripts)

    proc ::xml_parse_pkg::post_process_parameter_array {} {

        set v_result [catch {::xml_parse_pkg::check_required_parameters} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::set_subsystem_names} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::set_subsystem_scripts} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Parse the xml argument and set the namespace constant v_xml_path
    # - If the argument is a design file without directory (e.g. design.xml)
    #   it is assumed to be a toolkit provided design. The absolute file path is
    #   obtained by searching toolkit design locations for the design file.
    # - Otherwise the design file is normalized to an absolute file path.

    proc ::xml_parse_pkg::set_xml_path {xml_argument} {

        set v_extension [file extension ${xml_argument}]

        if {[string equal -nocase ".xml" ${v_extension}] != 1} {
            return -code error "Design file must have .xml extension"
        }

        set v_directory [file dirname ${xml_argument}]

        if {[string equal "." ${v_directory}] == 1} {

            set v_found_xml_files {}

            foreach v_relative_search_path ${::xml_parse_pkg::v_design_search_paths} {
                set v_absolute_search_path [file join ${::xml_parse_pkg::v_toolkit_root} ${v_relative_search_path}]
                set v_temporary_xml_files  [fileutil::findByPattern ${v_absolute_search_path} -glob -- ${xml_argument}]
                set v_found_xml_files      [list {*}${v_found_xml_files} {*}${v_temporary_xml_files}]
            }

            if {[llength ${v_found_xml_files}] == 0} {
                return -code error "Unable to find design file (${xml_argument}) in default search paths"
            } elseif {[llength ${v_found_xml_files}] > 1} {
                return -code error "Multiple design files found for ${xml_argument}\
                                    provide full path to file.\n(${v_found_xml_files})"
            } else {
                set v_normalized_xml_path [lindex ${v_found_xml_files} 0]
                set v_normalized_xml_path [file normalize ${v_normalized_xml_path}]
            }

        } else {

            set v_normalized_xml_path [file normalize ${xml_argument}]

            if {[file exists ${v_normalized_xml_path}] != 1} {
                return -code error "Unable to find design file (${v_normalized_xml_path})"
            }
        }

        set ::xml_parse_pkg::v_xml_path ${v_normalized_xml_path}

        return -code ok

    }

    # Set the namespace constant v_toolkit_root and v_subsystems_root

    proc ::xml_parse_pkg::set_toolkit_root {toolkit_root} {

        if {[file exists ${toolkit_root}] != 1} {
            return -code error ""
        } elseif {[file isdirectory ${toolkit_root}] != 1} {
            return -code error ""
        }

        set ::xml_parse_pkg::v_toolkit_root ${toolkit_root}
        set ::xml_parse_pkg::v_subsystems_root [file join ${toolkit_root} subsystems platform_designer_subsystems]

        return -code ok

    }

    # Set the namespace constant v_document_element

    proc ::xml_parse_pkg::set_xml_document_element {} {

        if {[file exists ${::xml_parse_pkg::v_xml_path}] != 1} {
            return -code error "XML file does not exist (${::xml_parse_pkg::v_xml_path})"
        }

        set v_result [catch {open ${::xml_parse_pkg::v_xml_path} r} v_file]
        if {${v_result} != 0} {
            return -code error "Unable to open XML file (${::xml_parse_pkg::v_xml_path}): ${v_file}"
        }

        set v_xml_data [read ${v_file}]
        close ${v_file}

        set v_dom_data                          [::dom::parse ${v_xml_data}]
        set ::xml_parse_pkg::v_document_element [::dom::document cget ${v_dom_data} -documentElement]

        set v_name [::dom::node cget ${::xml_parse_pkg::v_document_element} -nodeName]

        if {[string equal "PROJECT" ${v_name}] != 1} {
            return -code error "Incorrect document element name, expected PROJECT, received ${v_name}"
        }

        return -code ok

    }

    # Initialize parameter array to default values

    proc ::xml_parse_pkg::initialize_parameter_array {} {

        variable v_parameter_array

        set v_parameter_array(project,name)     "top"
        set v_parameter_array(project,params)   {}
        set v_parameter_array(project,id)       0
        set v_parameter_array(project,xml_path) ${::xml_parse_pkg::v_xml_path}

        lappend v_parameter_array(project,params) [list DEFAULT_IP_SEARCH_PATH\
                                                        ${::xml_parse_pkg::v_default_ip_search_paths}]
        lappend v_parameter_array(project,params) [list TOOLKIT_ROOT ${::xml_parse_pkg::v_toolkit_root}]
        lappend v_parameter_array(project,params) [list SHELL_DESIGN_ROOT ${::xml_parse_pkg::v_subsystems_root}]

        # Top subsystem is an internal (hidden) subsystem required for general project management
        set v_id $v_parameter_array(project,id)
        set v_parameter_array(${v_id},name) $v_parameter_array(project,name)
        set v_parameter_array($v_parameter_array(project,name),id) ${v_id}
        set v_parameter_array(${v_id},class)  "SUBSYSTEM"
        set v_parameter_array(${v_id},type)   "top"
        set v_parameter_array(${v_id},params) {}

        incr v_parameter_array(project,id)

        return -code ok

    }

    # Check required parameters are declared in parameter array

    proc ::xml_parse_pkg::check_required_parameters {} {

        variable v_parameter_array

        array set v_array [join $v_parameter_array(project,params)]

        foreach v_parameter ${::xml_parse_pkg::v_required_parameters} {
            if {[info exist v_array(${v_parameter})] == 0} {
                return -code error "Project parameter ${v_parameter} is not defined in the XML file"
            }
        }

        array unset v_array

        return -code ok

    }

    # Set names of subsystems without (xml defined) names

    proc ::xml_parse_pkg::set_subsystem_names {} {

        variable v_parameter_array

        array set v_temporary_array {}

        # Create a temporary array of subsystems with unassigned names
        for {set v_id 0} {${v_id} < $v_parameter_array(project,id)} {incr v_id} {

            if {[info exists v_parameter_array(${v_id},name)] != 1} {

                set v_class       $v_parameter_array(${v_id},class)
                set v_class_lower [string tolower ${v_class}]
                set v_type        $v_parameter_array(${v_id},type)

                set v_name        "${v_type}_${v_class_lower}"

                if {[info exists v_temporary_array(${v_name})] != 1} {
                    set v_temporary_array(${v_name}) [list ${v_id}]
                } else {
                    lappend v_temporary_array(${v_name}) ${v_id}
                }
            }
        }

        # Generate names
        foreach {v_base_name v_ids} [array get v_temporary_array] {

            set v_base_index 0

            foreach v_id ${v_ids} {

                if {[llength ${v_ids}] == 1} {
                    set v_name ${v_base_name}

                    if {[info exists v_parameter_array(${v_name},id)] == 0} {
                        set v_parameter_array(${v_id},name) ${v_name}
                        continue
                    }
                }

                for {set v_index ${v_base_index}} {${v_index} < [expr ${v_base_index} + 1000]} {incr ${v_index}} {
                    set v_name "${v_base_name}_${v_index}"

                    if {[info exists v_parameter_array(${v_name},id)] == 0} {
                        set v_parameter_array(${v_id},name) ${v_name}
                        set v_base_index [expr ${v_index} + 1]
                        break
                    }
                }

                if {[string equal "" $v_parameter_array(${v_id},name)] == 1} {
                    set v_class [string tolower $v_parameter_array(${v_id},class)]
                    set v_type  $v_parameter_array(${v_id},type)
                    return -code error "Unable to assign unique name for ${v_class} - ${v_type}"
                }
            }
        }

        # Propagate names to parameter array
        for {set v_id 0} {${v_id} < $v_parameter_array(project,id)} {incr v_id} {
            set v_name $v_parameter_array(${v_id},name)
            set v_parameter_array(${v_name},id) ${v_id}
            lappend v_parameter_array(${v_id},params) [list "INSTANCE_NAME" $v_parameter_array(${v_id},name)]
        }

        array unset v_temporary_array

        return -code ok

    }

    # Set subsystem creation scripts
    # User subsystem scripts are assigned in the parse_user_subsystem procedure
    # from the XML file; all others (toolkit provided subsystems) are assigned here.

    proc ::xml_parse_pkg::set_subsystem_scripts {} {

        variable v_parameter_array

        array set v_available_subsystems  {}
        array set v_available_addon_cards {}

        set v_result [catch {::xml_parse_pkg::get_available_subsystems v_available_subsystems} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {::xml_parse_pkg::get_available_addon_cards v_available_addon_cards} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        for {set v_id 0} {${v_id} < $v_parameter_array(project,id)} {incr v_id} {

            if {[info exists v_parameter_array(${v_id},script)] == 1} {
                continue
            }

            set v_class $v_parameter_array(${v_id},class)
            set v_type  $v_parameter_array(${v_id},type)

            if {[string equal "SUBSYSTEM" ${v_class}] == 1} {
                if {[info exists v_available_subsystems(${v_type})] == 1} {
                    set v_parameter_array(${v_id},script) $v_available_subsystems(${v_type})
                } else {
                    return -code error "The ${v_class} ($v_parameter_array(${v_id},name)) of type (${v_type})\
                                        does not match any available ${v_class}"
                }
            } elseif {[string equal "ADDON_CARD" ${v_class}] == 1} {
                if {[info exists v_available_addon_cards(${v_type})] == 1} {
                    set v_parameter_array(${v_id},script) $v_available_addon_cards(${v_type})
                } else {
                    return -code error "The ${v_class} ($v_parameter_array(${v_id},name)) of type (${v_type})\
                                        does not match any available ${v_class}"
                }
            } else {
                return -code error "Unknown ${v_class} (($v_parameter_array(${v_id},name)))"
            }
        }

        return -code ok

    }

    # Get list of all subsystems

    proc ::xml_parse_pkg::get_available_subsystems {subsystem_array} {

        upvar ${subsystem_array} v_subsystem_array

        foreach v_search_path ${::xml_parse_pkg::v_subsystem_search_paths} {
            set v_subsystems [glob -nocomplain -directory ${::xml_parse_pkg::v_toolkit_root} -type f ${v_search_path}]

            foreach v_subsystem ${v_subsystems} {
                set v_subsystem_file [file tail ${v_subsystem}]
                set v_result [regexp {(.*)_create\.tcl$} ${v_subsystem_file} v_match v_subsystem_name]
                if {${v_result} != 1} {
                    return -code error "Unable to retrieve subsystem name from path (${v_subsystem})"
                }

                if {[info exists v_subsystem_array(${v_subsystem_name})] != 0} {
                    return -code error "Duplicate subsystem names (${v_subsystem})"
                }

                set v_subsystem_array(${v_subsystem_name}) ${v_subsystem}

            }
        }

        return -code ok

    }

    # Get list of all addon cards

    proc ::xml_parse_pkg::get_available_addon_cards {addon_card_array} {

        upvar ${addon_card_array} v_addon_card_array

        foreach v_search_path ${::xml_parse_pkg::v_addon_card_search_paths} {
            set v_addon_cards [glob -nocomplain -directory ${::xml_parse_pkg::v_toolkit_root} -type f ${v_search_path}]

            foreach v_addon_card ${v_addon_cards} {
                set v_addon_card_file [file tail ${v_addon_card}]
                set v_result [regexp {(.*)_create\.tcl$} ${v_addon_card_file} v_match v_addon_card_name]
                if {${v_result} != 1} {
                    return -code error "Unable to retrieve addon card name from path (${v_addon_card})"
                }

                if {[info exists v_addon_card_array(${v_addon_card_name})] != 0} {
                    return -code error "Duplicate addon card names (${v_addon_card})"
                }

                set v_addon_card_array(${v_addon_card_name}) ${v_addon_card}

            }
        }

        return -code ok

    }

    ###################################################################################
    # Node processing

    # Find children of the XML node that match the element type

    proc ::xml_parse_pkg::find_children_of_element_type {xml_node element_type} {

        set v_matches {}

        foreach v_child [::dom::node children ${xml_node}] {

            if {[::dom::node cget ${v_child} -nodeType] != "element"} {
                continue
            }

            set v_child_name [::dom::node cget ${v_child} -nodeName]

            if {[string equal ${v_child_name} ${element_type}] == 1} {
                lappend v_matches ${v_child}
            }
        }

        return ${v_matches}

    }

    # Find children of the XML node that are subsystems

    proc ::xml_parse_pkg::get_subsystem_nodes {xml_node} {

        set v_subsystem_nodes [::xml_parse_pkg::find_children_of_element_type ${xml_node} "SUBSYSTEM"]
        return ${v_subsystem_nodes}

    }

    # Find children of the XML node that are addon cards

    proc ::xml_parse_pkg::get_addon_card_nodes {xml_node} {

        set v_addon_cards [::xml_parse_pkg::find_children_of_element_type ${xml_node} "ADDON_CARD"]
        return ${v_addon_cards}

    }

    ###################################################################################
    # Parameter processing

    # Get parameters from node

    proc ::xml_parse_pkg::get_node_parameters {xml_node} {

        array set v_local_parameter_array {}

        foreach v_child [::dom::node children ${xml_node}] {

            if {[::dom::node cget ${v_child} -nodeType] != "element"} {
                continue
            }

            set v_result [catch {::xml_parse_pkg::get_node_parameter_pair ${v_child}} v_parameter_pair]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_parameter_pair}
            }

            set v_result [catch {::xml_parse_pkg::add_parameter_pair_to_array \
                ${v_parameter_pair} v_local_parameter_array} v_result_text]

            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

        }

        set v_parameters_list {}

        foreach {v_parameter_name v_parameter_value} [array get v_local_parameter_array] {
            lappend v_parameters_list [list ${v_parameter_name} ${v_parameter_value}]
        }

        return ${v_parameters_list}

    }

    # Get parameter name and value from node

    proc ::xml_parse_pkg::get_node_parameter_pair {xml_node} {

        set v_node_name  [::dom::node cget ${xml_node} -nodeName]
        set v_node_value ""

        if {[lsearch -exact ${::xml_parse_pkg::v_parent_nodes} ${v_node_name}] >= 0} {
            return -code ok {}
        }

        # Parse memory mapped node
        foreach v_memory_mapped_node ${::xml_parse_pkg::v_memory_mapped_nodes} {
            if {[string match ${v_memory_mapped_node} ${v_node_name}] == 1} {
                set v_result [catch {::xml_parse_pkg::get_memory_mapped_parameter ${xml_node}} v_node_value]

                if {${v_result} != 0} {
                    return -code error ${v_node_value}
                }

                set v_node_value [list ${v_node_value}]

                return -code ok  [list ${v_node_name} ${v_node_value}]
            }
        }

        # Parse interrupt node
        foreach v_interrupt_node ${::xml_parse_pkg::v_interrupt_nodes} {
            if {[string match ${v_interrupt_node} ${v_node_name}] == 1} {
                set v_result [catch {::xml_parse_pkg::get_interrupt_parameter ${xml_node}} v_node_value]
                if {${v_result} != 0} {
                    return -code error ${v_node_value}
                }

                set v_node_value [list ${v_node_value}]

                return -code ok  [list ${v_node_name} ${v_node_value}]
            }
        }

        # Parse standard node (concatenate multiline values)
        foreach v_child [::dom::node children ${xml_node}] {
            set v_node_type [::dom::node cget ${v_child} -nodeType]

            if {[string equal -nocase ${v_node_type} "textNode"] != 1} {
                return -code error "XML Parser - unexpected non-text node in node (${v_node_name})"
            }

            set v_value [::dom::node cget ${v_child} -nodeValue]
            set v_node_value ${v_node_value}${v_value}
        }

        # Convert path node to an absolute path
        foreach v_path_node ${::xml_parse_pkg::v_path_nodes} {
            if {([string match ${v_path_node} ${v_node_name}] == 1)} {
                set v_result [catch {::xml_parse_pkg::convert_to_absolute_path ${v_node_value}} v_node_value]

                if {${v_result} != 0} {
                    return -code ${v_result} ${v_node_value}
                } else {
                    return -code ok [list ${v_node_name} ${v_node_value}]
                }
            }
        }

        return -code ok [list ${v_node_name} ${v_node_value}]

    }

    # Add a parameter pair to the parameter array

    proc ::xml_parse_pkg::add_parameter_pair_to_array {parameter parameter_array} {

        upvar ${parameter_array} v_parameter_array

        set v_parameter_length [llength ${parameter}]

        if {${v_parameter_length} == 2} {
            set v_parameter_name  [lindex ${parameter} 0]
            set v_parameter_value [lindex ${parameter} 1]

            if {[info exists v_parameter_array(${v_parameter_name})] == 1} {
                lappend v_parameter_array(${v_parameter_name}) {*}${v_parameter_value}
            } else {
                set v_parameter_array(${v_parameter_name}) ${v_parameter_value}
            }

        } elseif {${v_parameter_length} == 0} {
            return -code ok
        } else {
            return -code error "Incorrect number of entries in parameter pair list: expected 2 got ${v_parameter_length}"
        }

        return -code ok

    }

    ###################################################################################
    # Attribute parsers

    # Parse attributes of PROJECT node

    proc ::xml_parse_pkg::parse_project_attributes {xml_node} {

        variable v_parameter_array

        set v_class [::dom::node cget ${xml_node} -nodeName]

        if {[string equal "PROJECT" ${v_class}] != 1} {
            return -code error "Expected PROJECT node, received ${v_class}"
        }

        set v_attributes [::dom::node cget ${xml_node} -attributes]

        if {[info exists ${v_attributes}(name)] == 1} {
            set v_parameter_array(project,name) [set ${v_attributes}(name)]
        }

        return -code ok

    }

    # Parse attributes of SUBSYSTEM node

    proc ::xml_parse_pkg::parse_subsystem_attributes {xml_node} {

        variable v_parameter_array

        set v_class [::dom::node cget ${xml_node} -nodeName]

        if {[string equal "SUBSYSTEM" ${v_class}] != 1} {
            return -code error "Expected SUBSYSTEM node, received ${v_class}"
        }

        set v_id $v_parameter_array(project,id)
        set v_parameter_array(${v_id},class) ${v_class}

        set v_attributes [::dom::node cget ${xml_node} -attributes]

        if {[info exists ${v_attributes}(type)] == 1} {
            set v_parameter_array(${v_id},type) [set ${v_attributes}(type)]
        } else {
            return -code error "SUBSYSTEM node requires a 'type' attribute"
        }

        if {[info exists ${v_attributes}(name)]} {

            set v_name [set ${v_attributes}(name)]

            if {[info exists v_parameter_array(${v_name},id)] == 1} {
                return -code error "SUBSYSTEM name: ${v_name}, in use by multiple subsystems"
            }

            set v_parameter_array(${v_id},name) ${v_name}
            set v_parameter_array(${v_name},id) ${v_id}

        }

        return -code ok

    }

    # Parse attributes of ADDON_CARD node

    proc ::xml_parse_pkg::parse_addon_card_attributes {xml_node} {

        variable v_parameter_array

        set v_class [::dom::node cget ${xml_node} -nodeName]

        if {[string equal "ADDON_CARD" ${v_class}] != 1} {
            return -code error "Expected ADDON_CARD node, received ${v_class}"
        }

        set v_id $v_parameter_array(project,id)
        set v_parameter_array(${v_id},class) ${v_class}

        set v_attributes [::dom::node cget ${xml_node} -attributes]

        if {[info exists ${v_attributes}(type)] == 1} {
            set v_parameter_array(${v_id},type) [set ${v_attributes}(type)]
        } else {
            return -code error "ADDON_CARD node requires a 'type' attribute"
        }

        return -code ok

    }

    ###################################################################################
    # Parameter parsers

    # Parse project parameters

    # The optional parameter IP_SEARCH_PATH specifies absolute paths to directories containing IP.
    # This is provided as an alternative to copying IP into the project folder upon creation.
    # When moving the project directory access to these paths must be maintained.
    # Example use case: Testing pre-release ip when the IP already exists in the Quartus/Platform Designer
    #                   IP catalog (the highest version number is used)

    proc ::xml_parse_pkg::process_project_parameters {} {

        variable v_parameter_array

        array set v_project_parameter_array [join $v_parameter_array(project,params)]

        set v_grouped_ip_search_paths $v_project_parameter_array(DEFAULT_IP_SEARCH_PATH)

        if {[info exists v_project_parameter_array(IP_SEARCH_PATH)] == 1} {

            set v_ip_search_paths $v_project_parameter_array(IP_SEARCH_PATH)

            foreach v_ip_search_path ${v_ip_search_paths} {

                # Remove wildcards from search paths (e.g. **/*)
                set v_result [regexp "\s*(.*?)(?:\*\*)?[\/\\](?:\*)\s*$" ${v_ip_search_path} v_match v_submatch]

                if {${v_result} != 1} {
                    return -code error "Unable to parse IP_SEARCH_PATH: ${v_ip_search_path}"

                } elseif {[string equal -nocase "absolute" [file pathtype ${v_submatch}]] != 1} {
                    return -code error "IP Search Path: ${v_ip_search_path}, must be an absolute path"

                } elseif {[file exists ${v_submatch}] != 1} {
                    return -code error "IP Search Path: ${v_ip_search_path}, does not exist"

                }

                lappend v_grouped_ip_search_paths [string ${v_ip_search_path} trim]

            }
        }

        set v_concatenated_ip_search_paths [join ${v_grouped_ip_search_paths} ";"]

        set v_parameters [list [list "IP_SEARCH_PATH_CONCAT" ${v_concatenated_ip_search_paths}]]
        set v_parameter_array(project,params) [list {*}$v_parameter_array(project,params) {*}${v_parameters}]

        set v_device $v_project_parameter_array(DEVICE)
        set v_speed_grade [get_part_info -speed_grade ${v_device}]

        set v_parameters [list [list "SPEED_GRADE" ${v_speed_grade}]]
        set v_parameter_array(project,params) [list {*}$v_parameter_array(project,params) {*}${v_parameters}]

        return -code ok

    }

    # Parse board subsystem parameters

    proc ::xml_parse_pkg::parse_board_subsystem {xml_node} {

        variable v_parameter_array

        set v_addon_cards [::xml_parse_pkg::get_addon_card_nodes ${xml_node}]

        foreach v_addon_card ${v_addon_cards} {
            incr v_parameter_array(project,id)
            set v_id $v_parameter_array(project,id)

            set v_result [catch {::xml_parse_pkg::parse_addon_card_attributes ${v_addon_card}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }

            set v_result [catch {::xml_parse_pkg::get_node_parameters ${v_addon_card}} v_parameters]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_parameters}
            }

            set v_parameter_array(${v_id},params) ${v_parameters}
        }

        return -code ok

    }

    # Parse user subsystem parameters

    proc ::xml_parse_pkg::parse_user_subsystem {xml_node} {

        variable v_parameter_array

        set v_id $v_parameter_array(project,id)

        set v_attributes [::dom::node cget ${xml_node} -attributes]

        if {[info exists ${v_attributes}(script)]} {
            set v_script [set ${v_attributes}(script)]
            set v_result [catch {::xml_parse_pkg::convert_to_absolute_path ${v_script}} v_absolute_script_path]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_absolute_script_path}
            }

            set v_parameter_array(${v_id},script) ${v_absolute_script_path}

        } else {
            return -code error "User subsystem $v_parameter_array(${v_id},name) requires a script attribute"
        }

        return -code ok

    }

    # Get memory-mapped parameter

    proc ::xml_parse_pkg::get_memory_mapped_parameter {xml_node} {

        set v_host_name    ""
        set v_base_address "X"

        foreach v_child [::dom::node children ${xml_node}] {

            if {[string equal -nocase "element" [::dom::node cget ${v_child} -nodeType]] != 1} {
                continue
            }

            set v_result [catch {::xml_parse_pkg::get_node_parameter_pair ${v_child}} v_parameter_pair]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_parameter_pair}
            } elseif {[llength ${v_parameter_pair}] != 2} {
                continue
            }

            switch -nocase [lindex ${v_parameter_pair} 0] {
                "NAME"   {set v_host_name    [lindex ${v_parameter_pair} 1]}
                "OFFSET" {set v_base_address [lindex ${v_parameter_pair} 1]}
                default  {continue}
            }

        }

        if {[string equal ${v_host_name} ""] == 1} {
            return -code error "Memory mapped parameter requires a host name"
        }

        return [list ${v_host_name} ${v_base_address}]

    }

    # Get interrupt parameter

    proc ::xml_parse_pkg::get_interrupt_parameter {xml_node} {

        set v_host_name          ""
        set v_interrupt_priority "X"

        foreach child [::dom::node children ${xml_node}] {

            if {[string equal -nocase "element" [::dom::node cget ${v_child} -nodeType]] != 1} {
                continue
            }

            set v_result [catch {::xml_parse_pkg::get_node_parameter_pair ${v_child}} v_parameter_pair]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_parameter_pair}
            } elseif {[llength ${v_parameter_pair}] != 2} {
                continue
            }

            switch -nocase [lindex ${v_parameter_pair} 0] {
                "NAME"     {set v_host_name          [lindex ${v_parameter_pair} 1]}
                "PRIORITY" {set v_interrupt_priority [lindex ${v_parameter_pair} 1]}
                default    {continue}
            }

        }

        if {[string equal ${v_host_name} ""] == 1} {
            return -code error "Interrupt parameter requires a host name"
        }

        return [list ${v_host_name} ${v_interrupt_priority}]

    }

    ###################################################################################
    # Misc

    # Convert relative path (to XML) to absolute path

    proc ::xml_parse_pkg::convert_to_absolute_path {path} {

        set v_path_type [file pathtype ${path}]

        if {[string equal -nocase ${v_path_type} "relative"] == 1} {
            set v_xml_directory [file dirname ${::xml_parse_pkg::v_xml_path}]
            set v_absolute_path [file join ${v_xml_directory} ${path}]
            set v_absolute_path [file normalize ${v_absolute_path}]

            set v_tail [file tail ${path}]

            # Special case to preserve a trailing "."
            if {[string equal ${v_tail} "."] == 1} {
                set v_absolute_path [file join ${v_absolute_path} "."]
            }

        } else {
            set v_absolute_path ${path}
        }

        if {[file exists ${v_absolute_path}] == 0} {
            return -code error "XML Parse - path (${v_absolute_path}) does not exist"
        }

        return ${v_absolute_path}

    }

    # Get a list of xml designs in the default search paths

    proc ::xml_parse_pkg::get_default_xml_designs {toolkit_root script_path} {

        set v_found_xml_files {}

        array set v_valid_xml_files_array {}
        set       v_valid_xml_files_list  {}

        foreach v_relative_search_path ${::xml_parse_pkg::v_design_search_paths} {
            set v_absolute_search_path [file normalize [file join ${toolkit_root} ${v_relative_search_path}]]
            set v_temporary_xml_files  [fileutil::findByPattern ${v_absolute_search_path} -glob -- "*.xml"]
            set v_found_xml_files      [list {*}${v_found_xml_files} {*}${v_temporary_xml_files}]
        }

        # Perform basic parsing of .xml files to ensure they are in the toolkit format
        foreach v_found_xml_file ${v_found_xml_files} {

            set v_result [catch {open ${v_found_xml_file} r} v_file_id]
            if {${v_result} != 0} {
                return -code error "Unable to open XML file (${v_found_xml_file}): ${v_file_id}"
            }

            set v_xml_data [read ${v_file_id}]
            close ${v_file_id}

            set v_dom_data                   [::dom::parse ${v_xml_data}]
            set v_temporary_document_element [::dom::document cget ${v_dom_data} -documentElement]

            set v_name [::dom::node cget ${v_temporary_document_element} -nodeName]

            if {[string equal "PROJECT" ${v_name}] == 1} {

                set v_filename      [file tail ${v_found_xml_file}]
                set v_path          [file dirname ${v_found_xml_file}]

                # Search path is relative to toolkit root, rebase to script path
                set v_relative_path [::fileutil::relative ${script_path} ${v_path}]

                if {[info exists v_valid_xml_files_array(${v_filename})] == 1} {
                    lappend v_valid_xml_files_array(${v_filename}) ${v_relative_path}
                } else {
                    set v_valid_xml_files_array(${v_filename}) [list ${v_relative_path}]
                }

            }

        }

        set v_valid_xml_files_list [array get v_valid_xml_files_array]
        set v_valid_xml_files_list [lsort -stride 2 -dictionary ${v_valid_xml_files_list}]

        return ${v_valid_xml_files_list}

    }

    # Print the parameter array to the terminal

    proc ::xml_parse_pkg::print_parameter_array {} {

        variable v_parameter_array

        puts "\n============================================="

        if {[info exists v_parameter_array(project,name)]} {
            puts "Project name: $v_parameter_array(project,name)"
        }

        if {[info exists v_parameter_array(project,params)]} {
            foreach v_parameter_pair $v_parameter_array(project,params) {
                set v_name  [lindex ${v_parameter_pair} 0]
                set v_value [lindex ${v_parameter_pair} 1]
                puts "\tParameter: ${v_name} : ${v_value}"
            }
        }

        puts "---------------------------------------------"

        for {set v_id 0} {${v_id} < $v_parameter_array(project,id)} {incr v_id} {

            if {[info exists v_parameter_array(${v_id},class)]} {
                set v_class $v_parameter_array(${v_id},class)
            } else {
                set v_class "UNKNOWN"
            }

            if {[info exists v_parameter_array(${v_id},name)]} {
                puts "${v_class} name: $v_parameter_array(${v_id},name)"
            }

            if {[info exists v_parameter_array(${v_id},type)]} {
                puts "${v_class} type: $v_parameter_array(${v_id},type)"
            }

            if {[info exists v_parameter_array(${v_id},script)]} {
                puts "${v_class} script: $v_parameter_array(${v_id},script)"
            }

            if {[info exists v_parameter_array(${v_id},params)]} {
                foreach v_parameter_pair $v_parameter_array(${v_id},params) {
                    set v_name  [lindex ${v_parameter_pair} 0]
                    set v_value [lindex ${v_parameter_pair} 1]
                    puts "\tParameter: ${v_name} - ${v_value}"
                }
            }

            if {${v_id} < [expr $v_parameter_array(project,id)-1]} {
                puts "---------------------------------------------"
            }

        }

        puts "=============================================\n"

        return -code ok

    }

}
