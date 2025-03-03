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

This script can insert IO, wire, assignment and export code into a Verilog file


Structures:
    **There is never the need to include ';' or ',' as they are automatically added**

    io_component: {interface, width, component_name}
        The io_component structure can be used for io and wire insertion
        width must be in the form of "[x:y]" where x is the start width and y is the end
        example use: {"input" "[63:0]" "hdmi_inp"} would produce "input wire [63:0] hdmi_inp"

    assign_statement: {varname, expression}
        there is no need to include '=' as this is inserted automatically
        example use: {"hdmi_inp" "x*y+2"} would produce "assign hdmi_inp = x*y+2;"

    export: {component_name expression}
        example use: {"hdmi_inp" "SOMETHING"} would produce ".hdmi_inp (SOMETHING)"


Methods:
    ::TopInsert::io_insert (subsystem_name top_path io_components)
    ::TopInsert::wire_insert (subsystem_name top_path io_components)
    ::TopInsert::assign_insert (subsystem_name top_path assign_statements)
    ::TopInsert::export_insert (subsystem_name top_path export_subsystem_name exports)


How to use the package:
    The package can be included in your own script by adding:
        lappend auto_path "<path to top_code_insert_pkg>"
        package require TopInsert 1.0