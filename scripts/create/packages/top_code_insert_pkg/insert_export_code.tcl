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

#lines start end direction search_conditions not_conditions

variable comment_sections {}

# Namespace makes the three main functions into a package
namespace eval ::TopInsert {
    namespace export io_insert

    set version 1.0

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    # io as a structure
    set io_component {interface width component_name}
    interp alias {} io_component@ {} lsearch $io_component

    # Assignments as a structure
    set assign_statement {varname expression}
    interp alias {} assign_statement@ {} lsearch $assign_statement

    # Exports as a structure
    set export {component_name expression}
    interp alias {} export@ {} lsearch $export

    set comment_header "// Code auto-generated from script:"
    set search_conditions {{" localparam "} {" input " " output " " inout "} {" wire " " reg "} {" assign "}}
    set ignore_conditions {{} {} {"input" "output" "inout"} {}}
}

# Takes a file path and loads all its lines as a list
proc load_file {top_path} {
    set read_file [open $top_path]
    set lines {}
    while {[gets $read_file line] >= 0} {
        lappend lines $line
    }
    close $read_file
    return $lines
}

# Creates a list of pointers describing where blocks of comments are located
proc find_comment_sections {lines} {
    set start 0
    set end 0
    while {$start < [llength $lines]} {
        if {[string first "/*" [lindex $lines $start]] > -1} {
            set end [iterate_file $lines $start -1 1 {"*/"} {}]
            lappend ::comment_sections [list $start $end]
            set start $end
        }
        incr start
    }
}

# Given a list of strings, finds how many are partial/full matches to the main string
proc total_matches {line conditions} {
    set matches 0

    foreach condition $conditions {
        if {[string first $condition $line] > -1} {
            incr matches
        }
    }

    return $matches
}

# Given a list of strings, finds if all strings are partial/full matches to the main string
proc all_matches {line conditions} {
    set matches [total_matches $line $conditions]

    if {$matches == [llength $conditions]} {
        return 1
    }
    return 0
}

# Checks if a line resides within a commented block
proc in_bounds {index} {
    foreach bound $::comment_sections {
        if {[lindex $bound 0] <= $index && $index <= [lindex $bound 1]} {
            return 1
        }
    }
    return 0
}

# Returns if a line is fully commented
proc is_comment {line index} {
    regexp {(\s*\/\/.*)} $line a
    if {[info exists a] == 1} {
        if {$a == $line} {
            return 1
        }
    }
    return [in_bounds $index]
}

# Inserts a comma after the code but before a comment
proc insert_comma {line} {
    set index [string first "//" $line]
    if {$index == -1} {
        set index [string first "/*" $line]
    }

    if {$index == -1} {
        return "$line,"
    } else {
        incr index -1
        set index [prev_char_index $line $index]
        set start [string range $line 0 $index]
        incr index
        set end [string range $line $index end]
        return "$start,$end"
    }
}

# Gets the last index of the code line
proc prev_char_index {line start} {
    while {[string is space [string index $line $start]] == 1} {
        incr start -1
    }
    return $start
}

# Makes sure that the intended direction of movement through a file is valid
proc movement_bounds {start end direction} {
    if {($direction == 0) || ($start < $end && $direction != 1) || ($start > $end && $direction != -1)} {
        return 0;
    }
    return 1;
}

# Moves through a list of strings until all search conditions match an element in the list, element must also NOT match any of the not-conditions
proc iterate_file {lines start end direction search_conditions not_conditions} {
    if {$start == -1} {
        if {$direction == 1} {
            set start 0
        }
        if {$direction == -1} {
            set start [llength $lines]
        }
    }

    if {$end == -1} {
        if {$direction == 1} {
            set end [llength $lines]
        }
        if {$direction == -1} {
            set end 0
        }
    }

    if {[movement_bounds $start $end $direction] == 0} {
        return -1;
    }

    set line [lindex $lines $start]

    #Keeps looping until all search conditions are met and no not-conditions are met OR the list ends
    while {([total_matches $line $search_conditions] == 0 || [total_matches $line $not_conditions] > 0 || [is_comment $line $start] == 1) && $start != $end} {
        incr start $direction
        set line [lindex $lines $start]
    }

    if {$start == $end} {
        return -1
    }

    #returns the index of the string that matches the conditions
    return $start
}

# Check which sections of code have been filled in
proc starting_point {lines target} {

    # Target points to the current search conditions
    # Move through each search condition until a section of code has been found or return the position of the top module
    while {$target >= 0} {
        set index [iterate_file $lines -1 -1 -1 [lindex $TopInsert::search_conditions $target] [lindex $TopInsert::ignore_conditions $target]]
        if {$index != -1} {
            return $index
        }
        incr target -1
    }

    return [iterate_file $lines -1 -1 1 {");"} {}]
}

# Loads a list of strings into the file of a given path
proc end_file {output_list path} {
    set write_file [open $path w]
    foreach line $output_list {
        puts $write_file $line
    }
    close $write_file
}

# Moves back within a list of strings until a line is not fully whitespace and doesn't match any of the not-conditions
proc backtrack {lines start not_conditions} {

    # Keeps on looping until at the end of the list OR the line is not whitespace or matches a not-condition
    while {$start > 0 && ([string is space [lindex $lines $start]] || [total_matches [lindex $lines $start] $not_conditions] > 0 || [is_comment [lindex $lines $start] $start] == 1)} {
        incr start -1
    }

    #Returns the index of the string that matches the conditions
    return $start
}

# Same as backtrack but it also includes search conditions of which only one needs to be matched
proc backtrack_search {lines start search_conditions not_conditions} {

    # Keeps looping until at end of list or a condition is matched without a not-condition
    while {$start > 0 && (([string is space [lindex $lines $start]] || [total_matches [lindex $lines $start] $not_conditions] > 0) && [total_matches [lindex $lines $start] $search_conditions] == 0)} {
        incr start -1
    }

    # Returns the index of the string that matches the conditions
    return $start
}

proc component_string {component} {
    # Creates a string form of the io_component structure
    return "   [lindex $component [io_component@ interface]]  wire  [lindex $component [io_component@ width]]  [lindex $component [io_component@ component_name]];"
}

# Inserts all the component names into the module definition
proc insert_component_name {lines subsystem_name io_components} {
    #Move through the text until at the end of the module definition
    set end_bracket_index [iterate_file $lines -1 -1 1 {");"} {}]
    incr end_bracket_index -1

    # Move back until at the last line of code within the module
    set index [backtrack $lines $end_bracket_index {"//"}]

    #Change the line to have a comma at the end
    set segment [lindex $lines $index]
    if {[string first "(" $segment] == -1} {
        set segment [insert_comma $segment]
        set lines [lreplace $lines $index $index $segment]
    }

    incr end_bracket_index

    set len [llength $io_components]
    incr len -1

    # Insert the top comment banner
    set lines [linsert $lines $end_bracket_index "\n      $TopInsert::comment_header $subsystem_name"]
    incr end_bracket_index

    #Insert all the components (except for the last)
    for {set x 0} {$x < $len} {incr x} {
        set code_line "      [lindex [lindex $io_components $x] [io_component@ component_name]],"
        set lines [linsert $lines $end_bracket_index $code_line]
        incr end_bracket_index
    }

    # Insert last component (without a comma)
    set code_line "      [lindex [lindex $io_components end] [io_component@ component_name]]"
    set lines [linsert $lines $end_bracket_index $code_line]
    incr end_bracket_index

    return $lines
}

# Inserts the wire io code
proc insert_component_io {lines subsystem_name io_components} {
    # # Move along text until at the wire io section
    set index [starting_point $lines 1]
    incr index

    # Insert top comment banner
    set lines [linsert $lines $index "\n   $TopInsert::comment_header $subsystem_name"]
    incr index

    # Insert all wire io
    foreach component $io_components {
        set lines [linsert $lines $index [component_string $component]]
        incr index
    }

    return $lines
}

# Inserts the module definition components and the wire io
proc ::TopInsert::io_insert {subsystem_name top_path io_components} {
    if {[llength $io_components] == 0} { return }

    set lines [load_file $top_path]

    find_comment_sections $lines

    set lines [insert_component_name $lines $subsystem_name $io_components]
    set lines [insert_component_io $lines $subsystem_name $io_components]
    end_file $lines $top_path
}

# Inserts wires and assignments
proc ::TopInsert::wire_insert {subsystem_name top_path wire_components} {
    if {[llength $wire_components] == 0} { return }

    set lines [load_file $top_path]

    find_comment_sections $lines

    # Move to the wire section
    set index [starting_point $lines 2]
    incr index

    # Insert top comment banner
    set lines [linsert $lines $index "\n   $TopInsert::comment_header $subsystem_name"]
    incr index

    # Insert all wires
    foreach component $wire_components {
        set lines [linsert $lines $index "   [lindex $component [io_component@ interface]]  [lindex $component [io_component@ width]]  [lindex $component [io_component@ component_name]];"]
        incr index
    }

    end_file $lines $top_path
}

proc ::TopInsert::assign_insert {subsystem_name top_path assign_statements} {
    if {[llength $assign_statements] == 0} { return }

    set lines [load_file $top_path]

    find_comment_sections $lines

    # Move to assign section
    set index [starting_point $lines 3]
    incr index

    # Insert top comment banner
    set lines [linsert $lines $index "\n   $TopInsert::comment_header $subsystem_name"]
    incr index

    # Insert all assignment statements
    foreach component $assign_statements {
        set lines [linsert $lines $index "   assign [lindex $component [assign_statement@ varname]] = [lindex $component [assign_statement@ expression]];"]
        incr index
    }

    end_file $lines $top_path
}

# Inserts exports
proc ::TopInsert::export_insert {subsystem_name top_path export_section exports} {
    if {[llength $exports] == 0} { return }

    set lines [load_file $top_path]

    find_comment_sections $lines

    set search {}
    lappend search $export_section
    # Move to the top of the bottom of the exports
    set index [iterate_file $lines -1 -1 1 $search {}]
    set module_end [iterate_file $lines $index -1 1 {");"} {""}]
    set index $module_end
    incr index -1

    # Move to the last exported item
    set index [backtrack $lines $index {}]

    # Add a comma to the last exported item
    set segment [lindex $lines $index]
    if {[string first ")" $segment] > -1} {
        set segment [insert_comma $segment]
        set lines [lreplace $lines $index $index $segment]
    }

    set len [llength $exports]
    incr len -1

    # Insert top comment banner
    set lines [linsert $lines $module_end "\n      $TopInsert::comment_header $subsystem_name"]
    incr module_end

    # Insert all of the export statements
    for {set x 0} {$x < $len} {incr x} {
        set component [lindex $exports $x]
        set lines [linsert $lines $module_end "       .[lindex $component [export@ component_name]]  ([lindex $component [export@ expression]]),"]
        incr module_end
    }
    set component [lindex $exports end]
    set lines [linsert $lines $module_end "      .[lindex $component [export@ component_name]]  ([lindex $component [export@ expression]])"]
    incr module_end

    end_file $lines $top_path
}

# Provides a generic insert method to create code at the end of the verilog file
proc ::TopInsert::code_insert {subsystem_name top_path code_lines} {
    if {[llength $code_lines] == 0} { return }

    set lines [load_file $top_path]

    find_comment_sections $lines

    set end_index [iterate_file $lines -1 -1 -1 {"endmodule"} {""}]

    set lines [linsert $lines $end_index "\t$TopInsert::comment_header $subsystem_name"]
    incr end_index

    foreach code_line $code_lines {
        set lines [linsert $lines $end_index "\t$code_line"]
        incr end_index
    }
    set lines [linsert $lines $end_index "\t$TopInsert::comment_header $subsystem_name\n"]

    end_file $lines $top_path
}

package provide TopInsert $TopInsert::version
package require Tcl 8.0