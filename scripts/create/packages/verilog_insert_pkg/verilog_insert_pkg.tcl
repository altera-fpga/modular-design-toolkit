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

package provide verilog_insert_pkg 1.0

package require Tcl                8.0

# Helper to insert Verilog code into a file

# Structures:
#     There is never the need to include ';' or ',' as they are automatically added

#     io_component: {interface, width, component_name}
#         The io_component structure can be used for io and wire insertion
#         width must be in the form of "[x:y]" where x is the start width and y is the end
#         example use: {"input" "[63:0]" "hdmi_inp"} would produce "input wire [63:0] hdmi_inp"

#     assign_statement: {varname, expression}
#         there is no need to include '=' as this is inserted automatically
#         example use: {"hdmi_inp" "x*y+2"} would produce "assign hdmi_inp = x*y+2;"

#     export: {component_name expression}
#         example use: {"hdmi_inp" "SOMETHING"} would produce ".hdmi_inp (SOMETHING)"

namespace eval verilog_insert_pkg {

    namespace export verilog_insert

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    variable v_label
    variable v_lines

    variable v_comment_sections {}

    # IO as a structure
    set io_component {interface width component_name}
    interp alias {} io_component@ {} lsearch ${io_component}

    # Assignments as a structure
    set assign_statement {varname expression}
    interp alias {} assign_statement@ {} lsearch ${assign_statement}

    # Exports as a structure
    set export {component_name expression}
    interp alias {} export@ {} lsearch ${export}

    set comment_header "// Code auto-generated from script:"

    set search_conditions {{" localparam "} {" input " " output " " inout "} {" wire " " reg "} {" assign "}}
    set ignore_conditions {{} {} {"input" "output" "inout"} {}}

    # Insert Verilog code into file

    proc ::verilog_insert_pkg::verilog_insert {file label exports_name verilog_insert_array} {

        variable v_label ${label}
        variable v_lines ""

        upvar ${verilog_insert_array} v_verilog_insert_array

        set v_result [catch {open ${file} "r"} v_fid]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_fid}
        }

        set v_data [read ${v_fid}]
        close ${v_fid}

        set v_lines [split ${v_data} "\n"]

        set v_result [catch {::verilog_insert_pkg::io_insert $v_verilog_insert_array(ports)} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {::verilog_insert_pkg::wire_insert $v_verilog_insert_array(declarations)} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {::verilog_insert_pkg::assign_insert $v_verilog_insert_array(assignments)} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {::verilog_insert_pkg::export_insert ${exports_name}\
                                                                 $v_verilog_insert_array(exports)} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {::verilog_insert_pkg::code_insert $v_verilog_insert_array(generic)} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {open ${file} "w"} v_fid]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_fid}
        }

        foreach v_line ${v_lines} {
            puts ${v_fid} ${v_line}
        }
        close ${v_fid}

        return -code ok

    }

    # Create list of comment block locations

    proc ::verilog_insert_pkg::find_comment_sections {} {

        variable v_lines
        variable v_comment_sections

        set v_start 0
        set v_end   0

        while {${v_start} < [llength ${v_lines}]} {
            if {[string first "/*" [lindex ${v_lines} ${v_start}]] > -1} {
                set v_end [::verilog_insert_pkg::iterate_file ${v_start} -1 1 {"*/"} {}]
                lappend v_comment_sections [list ${v_start} ${v_end}]
                set v_start ${v_end}
            }
            incr v_start
        }

        return -code ok

    }

    # Count pattern matches in string

    proc ::verilog_insert_pkg::total_matches {string patterns} {

        set v_matches 0

        foreach v_pattern ${patterns} {
            if {[string first ${v_pattern} ${string}] > -1} {
                incr v_matches
            }
        }

        return ${v_matches}

    }

    # Check if line is within a commented block

    proc ::verilog_insert_pkg::in_bounds {index} {

        variable v_comment_sections

        foreach v_bound ${v_comment_sections} {
            set v_lower_bound [lindex ${v_bound} 0]
            set v_upper_bound [lindex ${v_bound} 1]

            if {( ${v_lower_bound} <= ${index} ) && ( ${index} <= ${v_upper_bound} )} {
                return 1
            }
        }

        return 0

    }

    # Check if line is commented

    proc ::verilog_insert_pkg::is_comment {line index} {

        set v_result [regexp {(\s*\/\/.*)} ${line} v_match]

        if {${v_result} == 1} {
            if {${v_match} == ${line}} {
                return 1
            }
        }

        set v_in_bounds [::verilog_insert_pkg::in_bounds ${index}]

        return ${v_in_bounds}

    }

    # Insert comma after code but before comment

    proc ::verilog_insert_pkg::insert_comma {line} {

        set v_index [string first "//" ${line}]

        if {${v_index} == -1} {
            set v_index [string first "/*" ${line}]
        }

        if {${v_index} == -1} {
            set v_output "${line},"
        } else {
            incr v_index -1
            set v_index [::verilog_insert_pkg::prev_char_index ${line} ${v_index}]
            set v_start_string [string range ${line} 0 ${v_index}]
            incr v_index
            set v_end_string [string range ${line} ${v_index} end]
            set v_output "${v_start_string},${v_end_string}"
        }

        return ${v_output}

    }

    # Get the index of the last code character

    proc ::verilog_insert_pkg::prev_char_index {line start} {

        if {${start} < 0} {
            return 0
        }

        if {${start} > [string length ${line}]} {
            set start [expr [string length ${line}] - 1]
        }

        set v_char [string index ${line} ${start}]

        while {([string is space ${v_char}] == 1) && (${start} > 0)} {
            incr start -1
            set v_char [string index ${line} ${start}]
        }

        return ${start}

    }

    # Check iteration direction is valid

    proc ::verilog_insert_pkg::movement_bounds {start end direction} {

        if {((( ${start} < ${end} ) && ( ${direction} == 1  )) ||\
             (( ${start} > ${end} ) && ( ${direction} == -1 ))) } {

            return 1
        }

        return 0

    }

    # Iterate through lines until all search conditions are matched (also includes negative constraint)

    proc ::verilog_insert_pkg::iterate_file {start end direction search_conditions not_conditions} {

        variable v_lines

        if {${start} == -1} {
            if {${direction} == 1} {
                set start 0
            }
            if {${direction} == -1} {
                set start [llength ${v_lines}]
            }
        }

        if {${end} == -1} {
            if {${direction} == 1} {
                set end [llength ${v_lines}]
            }
            if {${direction} == -1} {
                set end 0
            }
        }

        if {[::verilog_insert_pkg::movement_bounds ${start} ${end} ${direction}] == 0} {
            return -1
        }

        set v_line [lindex ${v_lines} ${start}]

        while {(([::verilog_insert_pkg::total_matches ${v_line} ${search_conditions}] == 0) ||\
                ([::verilog_insert_pkg::total_matches ${v_line} ${not_conditions}] > 0) ||\
                ([::verilog_insert_pkg::is_comment ${v_line} ${start}] == 1)) && ( ${start} != ${end} )} {
            incr start ${direction}
            set v_line [lindex ${v_lines} ${start}]
        }

        if {${start} == ${end}} {
            return -1
        }

        return ${start}

    }

    # Find code section end

    proc ::verilog_insert_pkg::starting_point {target} {

        # Search through lines (in reverse) for last line of the target section
        # If not found, search for end of preceding section, until top level module port list found

        while {${target} >= 0} {
            set v_search_conditions [lindex ${::verilog_insert_pkg::search_conditions} ${target}]
            set v_ignore_conditions [lindex ${::verilog_insert_pkg::ignore_conditions} ${target}]

            set v_index [::verilog_insert_pkg::iterate_file -1 -1 -1 ${v_search_conditions} ${v_ignore_conditions}]

            if {${v_index} != -1} {
                return ${v_index}
            }
            incr target -1
        }

        set v_index [::verilog_insert_pkg::iterate_file -1 -1 1 {");"} {}]

        return ${v_index}

    }

    # Iterate through lines in reverse until line is not whitespace (also includes negative constraint)

    proc ::verilog_insert_pkg::backtrack {start not_conditions} {

        variable v_lines

        while {(([string is space [lindex ${v_lines} ${start}]]) ||\
                ([::verilog_insert_pkg::total_matches [lindex ${v_lines} ${start}] ${not_conditions}] > 0) ||\
                ([::verilog_insert_pkg::is_comment [lindex ${v_lines} ${start}] ${start}] == 1)) && (${start} > 0)} {
            incr start -1
        }

        return ${start}

    }

    # Create io_component string

    proc ::verilog_insert_pkg::component_string {component} {

        set v_interface      [lindex ${component} [io_component@ interface]]
        set v_width          [lindex ${component} [io_component@ width]]
        set v_component_name [lindex ${component} [io_component@ component_name]]

        return "   ${v_interface}  wire  ${v_width}  ${v_component_name};"

    }

    # Insert component names into module definition

    proc ::verilog_insert_pkg::insert_component_name {subsystem_name io_components} {

        variable v_lines

        # Move to end of module definition
        set  v_end_bracket_index [::verilog_insert_pkg::iterate_file -1 -1 1 {");"} {}]
        incr v_end_bracket_index -1

        # Move to last code line within module definition
        set v_index [::verilog_insert_pkg::backtrack ${v_end_bracket_index} {"//"}]

        # Append comma to line
        set v_segment [lindex ${v_lines} ${v_index}]
        if {[string first "(" ${v_segment}] == -1} {
            set v_segment [::verilog_insert_pkg::insert_comma ${v_segment}]
            set v_lines   [lreplace ${v_lines} ${v_index} ${v_index} ${v_segment}]
        }

        incr v_end_bracket_index

        set  v_length [llength ${io_components}]
        incr v_length -1

        # Insert comment banner
        set  v_lines [linsert ${v_lines} ${v_end_bracket_index}\
                      "\n      ${::verilog_insert_pkg::comment_header} ${subsystem_name}"]
        incr v_end_bracket_index

        # Insert all components (except last)
        for {set v_component_index 0} {${v_component_index} < ${v_length}} {incr v_component_index} {
            set v_code_line "      [lindex [lindex ${io_components} ${v_component_index}]\
                            [io_component@ component_name]],"
            set v_lines [linsert ${v_lines} ${v_end_bracket_index} ${v_code_line}]
            incr v_end_bracket_index
        }

        # Insert last component (without comma)
        set v_code_line "      [lindex [lindex ${io_components} end] [io_component@ component_name]]"
        set v_lines [linsert ${v_lines} ${v_end_bracket_index} ${v_code_line}]

        return ${v_lines}

    }

    # Insert wire io code

    proc ::verilog_insert_pkg::insert_component_io {subsystem_name io_components} {

        variable v_lines

        # Find start of wire io section
        set  v_index [::verilog_insert_pkg::starting_point 1]
        incr v_index

        # Insert top comment banner
        set  v_lines [linsert ${v_lines} ${v_index} "\n   ${::verilog_insert_pkg::comment_header} ${subsystem_name}"]
        incr v_index

        # Insert wire io
        foreach v_component ${io_components} {
            set  v_lines [linsert ${v_lines} ${v_index} [::verilog_insert_pkg::component_string ${v_component}]]
            incr v_index
        }

        return ${v_lines}

    }

    # Insert module definition components and wire io

    proc ::verilog_insert_pkg::io_insert {io_components} {

        variable v_label
        variable v_lines

        if {[llength ${io_components}] == 0} {
            return -code ok
        }

        ::verilog_insert_pkg::find_comment_sections

        set v_lines [::verilog_insert_pkg::insert_component_name ${v_label} ${io_components}]
        set v_lines [::verilog_insert_pkg::insert_component_io ${v_label} ${io_components}]

        return -code ok

    }

    # Insert wires

    proc ::verilog_insert_pkg::wire_insert {wire_components} {

        variable v_label
        variable v_lines

        if {[llength ${wire_components}] == 0} {
            return -code ok
        }

        ::verilog_insert_pkg::find_comment_sections

        # Move to wire section
        set  v_index [::verilog_insert_pkg::starting_point 2]
        incr v_index

        # Insert comment banner
        set  v_lines [linsert ${v_lines} ${v_index} "\n   ${::verilog_insert_pkg::comment_header} ${v_label}"]
        incr v_index

        # Insert all wires
        foreach v_component ${wire_components} {
            set v_interface      [lindex ${v_component} [io_component@ interface]]
            set v_width          [lindex ${v_component} [io_component@ width]]
            set v_component_name [lindex ${v_component} [io_component@ component_name]]

            set  v_lines [linsert ${v_lines} ${v_index} "   ${v_interface}  ${v_width}  ${v_component_name};"]
            incr v_index
        }

        return

    }

    # Insert assignments

    proc ::verilog_insert_pkg::assign_insert {assign_statements} {

        variable v_label
        variable v_lines

        if {[llength ${assign_statements}] == 0} {
            return -code ok
        }

        ::verilog_insert_pkg::find_comment_sections

        # Move to assign section
        set  v_index [::verilog_insert_pkg::starting_point 3]
        incr v_index

        # Insert comment banner
        set  v_lines [linsert ${v_lines} ${v_index} "\n   ${::verilog_insert_pkg::comment_header} ${v_label}"]
        incr v_index

        # Insert assignment statements
        foreach v_component ${assign_statements} {
            set v_varname    [lindex ${v_component} [assign_statement@ varname]]
            set v_expression [lindex ${v_component} [assign_statement@ expression]]

            set  v_lines [linsert ${v_lines} ${v_index} "   assign ${v_varname} = ${v_expression};"]
            incr v_index
        }

        return

    }

    # Insert exports

    proc ::verilog_insert_pkg::export_insert {export_section exports} {

        variable v_label
        variable v_lines

        if {[llength ${exports}] == 0} {
            return -code ok
        }

        ::verilog_insert_pkg::find_comment_sections

        set v_search {}
        lappend v_search ${export_section}

        # Move to bottom of exports
        set v_index      [::verilog_insert_pkg::iterate_file -1 -1 1 ${v_search} {}]
        set v_module_end [::verilog_insert_pkg::iterate_file ${v_index} -1 1 {");"} {""}]

        set  v_index ${v_module_end}
        incr v_index -1

        # Move to last exported item
        set v_index [::verilog_insert_pkg::backtrack ${v_index} {}]

        # Add comma to the last exported item
        set v_segment [lindex ${v_lines} ${v_index}]

        if {[string first ")" ${v_segment}] > -1} {
            set v_segment [::verilog_insert_pkg::insert_comma ${v_segment}]
            set v_lines   [lreplace ${v_lines} ${v_index} ${v_index} ${v_segment}]
        }

        set  v_length [llength ${exports}]
        incr v_length -1

        # Insert comment banner
        set  v_lines [linsert ${v_lines} ${v_module_end} "\n      ${::verilog_insert_pkg::comment_header} ${v_label}"]
        incr v_module_end

        # Insert export statements
        for {set v_exports_index 0} {${v_exports_index} < ${v_length}} {incr v_exports_index} {
            set v_component      [lindex ${exports} ${v_exports_index}]
            set v_component_name [lindex ${v_component} [export@ component_name]]
            set v_expression     [lindex ${v_component} [export@ expression]]

            set  v_lines [linsert ${v_lines} ${v_module_end} "       .${v_component_name}  (${v_expression}),"]
            incr v_module_end
        }

        set v_component      [lindex ${exports} end]
        set v_component_name [lindex ${v_component} [export@ component_name]]
        set v_expression     [lindex ${v_component} [export@ expression]]

        set v_lines [linsert ${v_lines} ${v_module_end} "       .${v_component_name}  (${v_expression})"]

        return -code ok

    }

    # Insert generic code at end of file

    proc ::verilog_insert_pkg::code_insert {code_lines} {

        variable v_label
        variable v_lines

        if {[llength ${code_lines}] == 0} {
            return -code ok
        }

        foreach v_block ${code_lines} {

            ::verilog_insert_pkg::find_comment_sections

            set v_end_index [::verilog_insert_pkg::iterate_file -1 -1 -1 {"endmodule"} {""}]

            set  v_lines [linsert ${v_lines} ${v_end_index} "\t${::verilog_insert_pkg::comment_header} ${v_label}"]
            incr v_end_index

            foreach v_code_line ${v_block} {
                set  v_lines [linsert ${v_lines} ${v_end_index} "\t${v_code_line}"]
                incr v_end_index
            }

            set v_lines [linsert ${v_lines} ${v_end_index} "\t${::verilog_insert_pkg::comment_header} ${v_label}\n"]

        }

        return -code ok

    }

}
