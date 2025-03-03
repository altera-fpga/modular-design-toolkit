###################################################################################
# INTEL CONFIDENTIAL
# 
# Copyright (C) 2022 Intel Corporation
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

# create script specific parameters and default values

set_shell_parameter CLOCK_CHECK_EN "0"

# define the procedures used by the create_subsystems_qsys.tcl script

proc pre_creation_step {} {
  transfer_files
}

proc creation_step {} {
  create_debug_subsystem
}

proc post_creation_step {} {
  edit_top_level_qsys
  add_auto_connections
  edit_top_v_file
}

#==========================================================

# copy files from the shell install directory to the target project directory

proc transfer_files {} {

  set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]
  set v_project_path      [get_shell_parameter PROJECT_PATH]
  set v_clock_check_en    [get_shell_parameter CLOCK_CHECK_EN]
  set v_subsys_dir        "$v_shell_design_root/debug_subsystem"

  if {$v_clock_check_en} {
    file mkdir                                                                $v_project_path/non_qpds_ip/shell/intel_dip_clk_check
    file_copy $v_subsys_dir/non_qpds_ip/intel_dip_clk_check                 $v_project_path/non_qpds_ip/shell
    file_copy   $v_subsys_dir/non_qpds_ip/intel_dip_clk_check.ipx             $v_project_path/non_qpds_ip/shell
  }

}

# convert terp files to their native format


# create the debug subsystem, add the required IP, parameterize it as appropriate,
# add internal connections, and add interfaces to the boundary of the subsystem

proc create_debug_subsystem {} {

  set v_project_path      [get_shell_parameter PROJECT_PATH]
  set v_instance_name     [get_shell_parameter INSTANCE_NAME]
  set v_clock_check_en    [get_shell_parameter CLOCK_CHECK_EN]

  create_system $v_instance_name
  save_system   $v_project_path/rtl/shell/$v_instance_name.qsys

  load_system   $v_project_path/rtl/shell/$v_instance_name.qsys

  # create instances

  add_instance sources_probes     altera_in_system_sources_probes

  if {$v_clock_check_en} {
    add_instance reset_bridge_cut     altera_reset_bridge
    add_instance reset_bridge_ref     altera_reset_bridge
    add_instance cut_clk_bridge       altera_clock_bridge
    add_instance ref_clk_bridge       altera_clock_bridge
    add_instance control_status_out   altera_jtag_avalon_master
    add_instance intel_dip_clk_check  intel_dip_clk_check
  }
  
  # set instance parameters

  # sources_probes
  set_instance_parameter_value  sources_probes  gui_use_auto_index          1
  set_instance_parameter_value  sources_probes  sld_instance_index          0
  set_instance_parameter_value  sources_probes  instance_id                 "SP01"

  set_instance_parameter_value  sources_probes  probe_width                 1

  set_instance_parameter_value  sources_probes  source_width                1
  set_instance_parameter_value  sources_probes  source_initial_value        0
  set_instance_parameter_value  sources_probes  create_source_clock         0
  set_instance_parameter_value  sources_probes  create_source_clock_enable  0

  if {$v_clock_check_en} {

    # reset bridges (active_low)
    set_instance_parameter_value  reset_bridge_cut ACTIVE_LOW_RESET 1
    set_instance_parameter_value  reset_bridge_ref ACTIVE_LOW_RESET 1

    # clk check
    set_instance_parameter_value  intel_dip_clk_check   REF_CLK_TC                  1000000
    set_instance_parameter_value  intel_dip_clk_check   LO_COUNT_THR                2999000
    set_instance_parameter_value  intel_dip_clk_check   HI_COUNT_THR                3001000
    set_instance_parameter_value  intel_dip_clk_check   DATA_WIDTH                  32

  }

  # add internal subsystem connections

  if {$v_clock_check_en} {
  
    # resets
    add_connection  reset_bridge_cut.out_reset  intel_dip_clk_check.cut_clk_resetn
    add_connection  reset_bridge_ref.out_reset  intel_dip_clk_check.ref_clk_resetn
    add_connection  reset_bridge_ref.out_reset  control_status_out.clk_reset

    # clocks
    add_connection  cut_clk_bridge.out_clk      reset_bridge_cut.clk
    add_connection  cut_clk_bridge.out_clk      intel_dip_clk_check.cut_clk
    add_connection  ref_clk_bridge.out_clk      reset_bridge_ref.clk
    add_connection  ref_clk_bridge.out_clk      control_status_out.clk
    add_connection  ref_clk_bridge.out_clk      intel_dip_clk_check.ref_clk

    # control_status
    add_connection  control_status_out.master  intel_dip_clk_check.control_status

  }

  # add interfaces to the boundary of the subsystem

  # sources_probes
  add_interface          oa_sources  conduit     end
  set_interface_property oa_sources  export_of   sources_probes.sources

  add_interface          ia_probes   conduit     end
  set_interface_property ia_probes   export_of   sources_probes.probes

  if {$v_clock_check_en} {

    # intel_dip_clk_check
    add_interface          o_flags        conduit         end
    set_interface_property o_flags        export_of       intel_dip_clk_check.flags

    # reset bridges
    add_interface          i_reset_cut    reset           sink
    set_interface_property i_reset_cut    export_of       reset_bridge_cut.in_reset

    add_interface          i_reset_ref    reset           sink
    set_interface_property i_reset_ref    export_of       reset_bridge_ref.in_reset

    # clock bridges
    add_interface           i_clk_cut  clock          sink
    set_interface_property  i_clk_cut  export_of      cut_clk_bridge.in_clk

    add_interface           i_clk_ref  clock          sink
    set_interface_property  i_clk_ref  export_of      ref_clk_bridge.in_clk

  }

  sync_sysinfo_parameters
  save_system

}

# insert the debug subsystem into the top level qsys system, and add interfaces
# to the boundary of the top level qsys system

proc edit_top_level_qsys {} {

  set v_project_name  [get_shell_parameter PROJECT_NAME]
  set v_project_path  [get_shell_parameter PROJECT_PATH]
  set v_instance_name [get_shell_parameter INSTANCE_NAME]
  set v_clock_check_en    [get_shell_parameter CLOCK_CHECK_EN]

  load_system $v_project_path/rtl/${v_project_name}_qsys.qsys

  add_instance  $v_instance_name $v_instance_name

  # add interfaces to the boundary of the subsystem

  add_interface          "${v_instance_name}_oa_sources"  conduit     end
  set_interface_property "${v_instance_name}_oa_sources"  export_of   $v_instance_name.oa_sources

  add_interface          "${v_instance_name}_ia_probes"   conduit     end
  set_interface_property "${v_instance_name}_ia_probes"   export_of   $v_instance_name.ia_probes

  if {$v_clock_check_en} {
    add_interface           "${v_instance_name}_o_flags"   conduit     end
    set_interface_property  "${v_instance_name}_o_flags"   export_of   $v_instance_name.o_flags
  }

  sync_sysinfo_parameters
  save_system

}

proc add_auto_connections {} {

  set v_clock_check_en    [get_shell_parameter CLOCK_CHECK_EN]

  if {$v_clock_check_en} {
    # add connections for the intel_dip_clk_check
    # clk to test
    add_auto_connection debug_subsystem_0 i_clk_cut         300000000
    add_auto_connection debug_subsystem_0 i_clk_ref         100000000

    # resets for test
    add_auto_connection debug_subsystem_0 i_reset_cut    300000000
    add_auto_connection debug_subsystem_0 i_reset_ref    100000000
  }

}

proc edit_top_v_file {} {

  set v_clock_check_en    [get_shell_parameter CLOCK_CHECK_EN]
  set v_instance_name     [get_shell_parameter INSTANCE_NAME]

  if {$v_clock_check_en} {
    # add connections for flags to probes
    add_qsys_inst_exports_list "${v_instance_name}_o_flags_error"          "o_flag_wire\[0\]"
    add_qsys_inst_exports_list "${v_instance_name}_o_flags_error_n"        "o_flag_wire\[1\]"
    add_qsys_inst_exports_list "${v_instance_name}_o_flags_freq_too_high"  "o_flag_wire\[2\]"
    add_qsys_inst_exports_list "${v_instance_name}_o_flags_check_running"  "o_flag_wire\[3\]"
    add_qsys_inst_exports_list "${v_instance_name}_o_flags_check_done"     "o_flag_wire\[4\]"
    add_qsys_inst_exports_list "${v_instance_name}_o_flags_int_error"      "o_flag_wire\[5\]"
    add_debug_probe            "${v_instance_name}_o_flag_wire"            6
  }

}

# map the top level hdl signals to the ISSP ip in the debug subsystem.
# generate a file to store these mappings for use with the syscon_main.tcl
# script for easier debugging

proc generate_source_and_probes {source_list probe_list} {

  set v_project_path  [get_shell_parameter PROJECT_PATH]
  set v_project_name  [get_shell_parameter PROJECT_NAME]
  set v_instance_name [get_shell_parameter INSTANCE_NAME]

  # error check source list for duplicate signal names and total width > 511

  set curr_index  0
  set duplicate   0
  set total_width 0

  foreach item $source_list {

    set curr_name [lindex $item 0]
    set sub_list  [lrange $source_list [expr $curr_index+1] end]

    foreach sub_item $sub_list {
      set sub_name [lindex $sub_item 0]
      if {$curr_name == $sub_name} {
        set duplicate 1
        continue
      }
    }

    set total_width [expr $total_width + [lindex $item 1]]

    if {$duplicate == 1} {
      send_message ERROR "debug_create.tcl: duplicate source name found ($curr_name)"
      return
    } elseif {$total_width > 511} {
      send_message ERROR "debug_create.tcl: total source width > 511 ($total_width)"
      return
    } else {
      incr curr_index
    }

  }

  # error check probe list for duplicate signal names and total width > 511

  set curr_index  0
  set duplicate   0
  set total_width 0

  foreach item $probe_list {

    set curr_name [lindex $item 0]
    set sub_list  [lrange $probe_list [expr $curr_index+1] end]

    foreach sub_item $sub_list {
      set sub_name [lindex $sub_item 0]
      if {$curr_name == $sub_name} {
        set duplicate 1
        continue
      }
    }

    set total_width [expr $total_width + [lindex $item 1]]

    if {$duplicate == 1} {
      send_message ERROR "debug_create.tcl: duplicate probe name found ($curr_name)"
      return
    } elseif {$total_width > 511} {
      send_message ERROR "debug_create.tcl: total probe width > 511 ($total_width)"
      return
    } else {
      incr curr_index
    }

  }

  # create mapping file variables

  set map_file_source_list {}
  set map_file_probe_list  {}

  # parse source list, and create mapping between top level hld and the debug subsystem.
  # the default values for each source in the list are joined together to form the ISSP
  # source default value

  set total_source_width  0
  set global_default_bin   ""

  foreach item $source_list {

    set name          [lindex $item 0]
    set width         [lindex $item 1]
    set default_hex   [lindex $item 2]

    # Note: The binary scan/format functions used to concatenate the default values operate on bytes
    #       and will automatically pad to byte boundaries. The default value is manually padded to avoid
    #       issues with automatic padding.

    set expected_length  [expr [expr [expr $width + 7] / 8] * 2]    ;# round up to nearest byte (note: simplified 8/4 = 2)
    set actual_length    [string length $default_hex]

    # calculate required padding

    if {$actual_length < $expected_length} {
      set padding [expr $expected_length-$actual_length]
    } elseif {[expr $actual_length % 2] != 0} {
      set padding 1
    } else {
      set padding 0
    }

    # apply padding to the default hex value

    set padded_hex $default_hex

    for {set i 0} {$i < $padding} {incr i} {
      set padded_hex "0$padded_hex"
    }

    set padded_hex_length [string length $padded_hex]

    # split the padded hex value into bytes and convert into a binary string

    set padded_bin ""

    for {set i 0} {$i < [expr $padded_hex_length/2]} {incr i} {

      set start [expr $i * 2]
      set end   [expr $start + 1]

      set sub_str [string range $padded_hex $start $end]
      binary scan [binary format H* $sub_str] B* binary_sub_str     ;# convert the input hex to a binary string

      set padded_bin  "$padded_bin$binary_sub_str"

    }

    set padded_bin_length [string length $padded_bin]

    # remove padding from binary string and append to total binary default

    set start               [expr $padded_bin_length-$width]
    set end                 $padded_bin_length

    set trimmed_bin         [string range $padded_bin $start $end]
    set global_default_bin  "$trimmed_bin$global_default_bin"

    # add declaration and assignment mappings to top level hdl file
    # note: special case when a single entry in the list of width 1, a non-array assignment
    #       is required to avoid "can't index into non-array type logic" error

    if {$width == 1} {

      add_declaration_list wire "" $name

      if {[llength $source_list] == 1} {
        add_assignments_list $name "sources"
      } else {
        add_assignments_list $name "sources\[$total_source_width\]"
      }

   } else {

      set start [expr $total_source_width+$width-1]
      set end   $total_source_width

      add_declaration_list wire "\[[expr $width-1]:0\]" $name
      add_assignments_list $name "sources\[$start:$end\]"

    }

    # write information to variable for use when generating map file

    set map_file_source_list [lappend map_file_source_list [list $name $width $total_source_width]]

    set total_source_width [expr $total_source_width + $width]

  }

  # pad global_default_bin to byte boundary and convert to hex

  set global_default_hex ""

  set padding [expr [string length $global_default_bin] % 8]

  if {$padding != 0} {
    for {set i 0} {$i < 8-$padding} {incr i} {
      set global_default_bin "0$global_default_bin"
    }
  }

  binary scan [binary format B* $global_default_bin] H* global_default_hex

  #####################################################################################
  # parse probe list, and create mapping between top level hld and the debug subsystem.

  set total_probe_width 0

  foreach item $probe_list {

    set name    [lindex $item 0]
    set width   [lindex $item 1]

    # add declaration and assignment mappings to top level hdl file
    # note: special case when a single entry in the list of width 1, a non-array assignment
    #       is required to avoid "can't index into non-array type logic" error

    if {$width == 1} {

      add_declaration_list wire "" $name

      if {[llength $probe_list] == 1} {
        add_assignments_list $name "probes"
      } else {
        add_assignments_list $name "probes\[$total_probe_width\]"
      }

    } else {

      set start [expr $total_probe_width+$width-1]
      set end   $total_probe_width

      add_declaration_list wire "\[[expr $width-1]:0\]" $name
      add_assignments_list "probes\[$start:$end\]" $name

    }

    # write information to mapping file

    set map_file_probe_list [lappend map_file_probe_list [list $name $width $total_probe_width]]

    set total_probe_width [expr $total_probe_width + $width]

  }

  # write the sources and probes to a mapping file for use with the syscon_main.tcl script
  # to enable easier debugging of the system

  set map_file "$v_project_path/scripts/mappings.tcl"

  create_mapping_file $map_file $map_file_source_list $map_file_probe_list

  #####################################################################################
  # parameterize the ISSP in the debug subsystem, if there are no sources or probes
  # remove the subsystem and all files from the project path

  puts "probes $total_probe_width sources $total_source_width"

  if {$total_probe_width == 0 && $total_source_width == 0} {

    # remove subsystem from the top level qsys file

    load_system     $v_project_path/rtl/${v_project_name}_qsys.qsys
    remove_instance $v_instance_name
    save_system

    # remove unnecessary files

    file delete -force -- $v_project_path/quartus/shell/$v_instance_name.qsf
    file delete -force -- $v_project_path/rtl/shell/$v_instance_name.qsys
    file delete -force -- $v_project_path/rtl/shell/ip/$v_instance_name

  } else {

    # add declarations and top level qsys system exports to the top level hdl file

    if {$total_source_width != 0} {
      if {$total_source_width == 1} {
        add_declaration_list wire "" sources
      } else {
        add_declaration_list wire "\[[expr $total_source_width-1]:0\]" sources
      }
      add_qsys_inst_exports_list "${v_instance_name}_oa_sources_source" sources
    }

    if {$total_probe_width != 0} {
      if {$total_probe_width == 1} {
        add_declaration_list wire "" probes
      } else {
        add_declaration_list wire "\[[expr $total_probe_width-1]:0\]" probes
      }
      add_qsys_inst_exports_list "${v_instance_name}_ia_probes_probe" probes
    }

    # parameterize the ISSP component in the debug subsystem with the calculated values

    load_system   $v_project_path/rtl/shell/$v_instance_name.qsys

    load_component sources_probes
    set_component_parameter_value  probe_width           $total_probe_width
    set_component_parameter_value  source_width          $total_source_width
    set_component_parameter_value  source_initial_value  $global_default_hex
    save_component

    sync_sysinfo_parameters
    save_system

  }

}

# write the source and probe lists to a tcl file for importation into the
# syscon_main.tcl script that contains system console helper functions to
# ease debugging.

proc create_mapping_file {map_file source_list probe_list} {

  set map_fp  [open $map_file w]

  set index   0
  set length  [expr [llength $source_list]-1]

  # parse source list

  foreach item $source_list {

    set name    [lindex $item 0]
    set width   [lindex $item 1]
    set offset  [lindex $item 2]

    set prefix    "\t\t\t\t\t\t\t\t "
    set separator "\\"

    if {$index==0} {
      set prefix    "set source_list \{"
    } elseif {$index==$length} {
      set separator "\}\n"
    }

    # write to file

    puts $map_fp "$prefix\{\"SP01\" $name $width $offset\}$separator"

    incr index

  }

  set index   0
  set length  [expr [llength $probe_list]-1]

  # parse probe list

  foreach item $probe_list {

    set name    [lindex $item 0]
    set width   [lindex $item 1]
    set offset  [lindex $item 2]

    set prefix    "\t\t\t\t\t\t\t\t"
    set separator "\\"

    if {$index==0} {
      set prefix    "set probe_list \{"
    } elseif {$index==$length} {
      set separator "\}\n"
    }

    # write to file

    puts $map_fp "$prefix\{\"SP01\" $name $width $offset\}$separator"

    incr index

  }

  close $map_fp

}