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

source mappings.tcl

set issp_path {}

#======================================================================
# generic helper functions

# convert hex string to a binary string
proc hex_to_bin {data width} {

  # check valid hex input
  if {[regexp {(0[xX])?[a-fA-F0-9]+$} $data matched] == 0} {
    puts "not a valid hex value: $data"
    return ""
  }

  # remove 0x from hex number
  if {[regexp {(0[xX])?$} $data matched] == 1} {
    set data [string range $data 2 [string length $data]]
  }

  # pad to nearest byte
  set expected_length [expr [expr [expr $width + 7] / 8] * 2]    ;# round up to nearest byte (note simplified 8/4 = 2)
  set actual_length   [string length $data]

  if {$actual_length < $expected_length} {
    set padding [expr $expected_length-$actual_length]
  } elseif {[expr $actual_length % 2] != 0} {
    set padding 1
  } else {
    set padding 0
  }

  # apply padding
  for {set i 0} {$i < $padding} {incr i} {
    set data "0$data"
  }

  # split data into bytes to convert into a binary string

  set actual_length [string length $data]
  set binary_string ""

  for {set i 0} {$i < [expr $actual_length/2]} {incr i} {

    set start [expr $i * 2]
    set end [expr $start + 1]

    set sub_str [string range $data $start $end]
    binary scan [binary format H* $sub_str] B* binary_sub_str     ;# convert the input hex to a binary string

    set binary_string  "$binary_string$binary_sub_str"

  }

  # remove padding bits from the binary string
  set binary_length [string length $binary_string]
  set binary_string [string range $binary_string [expr $binary_length-$width] $binary_length]     ;# remove padding bits from binary string

  return $binary_string

}

# convert binary string to a hex string
proc bin_to_hex {data} {

  set padding [expr [string length $data] % 8]

  if {$padding != 0} {
    for {set i 0} {$i < 8-$padding} {incr i} {
      set data "0$data"
    }
  }

  binary scan [binary format B* $data] H* output_hex

  return $output_hex

}

#
proc claim_issp {name} {

  set issp_service_paths [lsearch -all -inline [get_service_paths issp] *$name*]
  set num_issp_paths     [llength $issp_service_paths]

  if {$num_issp_paths == 0} {
    puts "INFO: no issp found of name: $name"
  } elseif {$num_issp_paths >= 2} {
    puts "INFO: multiple issp found of name: $name, disambiguation required"
    foreach item $issp_service_paths {
      puts "$item"
    }
  } else {
    puts "$issp_service_paths"
    set master_path [lindex $issp_service_paths 0 ]
    set open [is_service_open issp "$master_path"]
    if {$open == 0} {
      set claimed_path [claim_service issp "$master_path" mylib]
      set all_probe_data [issp_read_probe_data $claimed_path]
      puts "$all_probe_data"
      array set instance_info [issp_get_instance_info $claimed_path]
      set source_width $instance_info(source_width)
      set probe_width $instance_info(probe_width)
      puts "source: $source_width probe: $probe_width"
      set item [list $name $claimed_path]
      puts "$item"
      lappend ::issp_path $item
      puts "INFO: opened service ($name)"
    } else {
      puts "INFO: service already open ($name)"
    }
  }

}

proc close_issp {name} {

  set index 0
  set path ""

  foreach item $::issp_path {
    set i_name [lindex $item 0]
    set i_path [lindex $item 1]

    puts "$i_name - $i_path"

    if {$i_name == $name} {
      set path "$i_path"
      break
    }
    incr index
  }

  if {[string length "$path"] > 0} {
    close_service issp "$path"
    set ::issp_path [lreplace $::issp_path $index $index]
    puts "INFO: closed service ($name)"
  } else {
    puts "INFO: no service open ($name)"
  }

}

# search all of the open issp paths
proc get_issp_path {name} {

  foreach item $::issp_path {

    set i_name [lindex $item 0]
    set i_path [lindex $item 1]

    if {$i_name == $name} {
      return "$i_path"
    }

  }

  return ""

}

#======================================================================
# list functions

proc list_issps {} {

  if {[llength $::issp_path] == 0} {
    puts "no sources available"
  } else {
    puts "sources available:"
    foreach item $::issp_path {
      puts [lindex $item 0]
    }
  }

}

proc list_sources {} {

  if {[llength $::source_list] == 0} {
    puts "no sources available"
  } else {
    puts "sources available:"
    foreach item $::source_list {
      puts [lindex $item 0]
    }
  }

}

proc list_probes {} {

  if {[llength $::probe_list] == 0} {
    puts "no probes available"
  } else {
    puts "probes available:"
    foreach item $::probe_list {
      puts [lindex $item 0]
    }
  }

}

#======================================================================
# probe functions

proc read_all_probe_data {name} {

  set path [get_issp_path $name]

  if {[string length "$path"] > 0} {
    set data [issp_read_probe_data $path]
    puts "probe - $data"
    return $data
  } else {
    puts "name not open"
    return ""
  }

}

proc read_probe {name probe} {

  set data [read_all_probe_data $name]

  if {[string length $data] == 0} {
    return
  }

  set out [lsearch -index 1 $::probe_list $probe]

  if {$out >= 0} {

    set curr_probe [lindex $::probe_list $out]

    set issp_name [lindex $curr_probe 0]
    set name      [lindex $curr_probe 1]
    set width     [lindex $curr_probe 2]
    set offset    [lindex $curr_probe 3]

    puts "name $name, width $width, offset $offset"

    set len [string length $data]

    puts "length $len"

    set sub [string range $data 2 $len]   ;# remove 0x

    if {[expr $len % 2] != 0} {          ;# pad to
      set sub "0$sub"
    }

    puts "sub - $sub"

    binary scan [binary format H* $sub] B* binary_str

    set bin_len [string length $binary_str]
    puts "bin = $binary_str"

    set start [expr $bin_len-$width-$offset]
    set end   [expr $bin_len-$offset-1]

    puts "$start - $end"

    set bin_str [string range $binary_str $start $end]

    puts "bin sub = ${width}b'$bin_str"


    # convert back to hex

    set total_default_hex ""
    set padding [expr [string length $bin_str] % 8]

    if {$padding != 0} {
      for {set i 0} {$i < 8-$padding} {incr i} {
        set bin_str "0$bin_str"
      }
    }

    binary scan [binary format B* $bin_str] H* total_default_hex

    puts "hex 0x$total_default_hex"

  } else {
    puts "probe not found ($name)"
  }

  #set default_value_len [string length $default_value]

}

#======================================================================
# source functions

proc read_all_source_data {name} {

  set path [get_issp_path $name]

  if {[string length "$path"] > 0} {
    set data [issp_read_source_data $path]
    puts "source - $data"
    return $data
  } else {
    puts "name not open"
    return ""
  }

}

proc set_all_source_data {name data} {

  set path [get_issp_path $name]

  if {[string length "$path"] > 0} {
    issp_write_source_data $path $data
  } else {
    puts "name not open"
    return
  }

}

proc set_source {name source data} {

  set path [get_issp_path $name]

  if {$path == "" } {
    return
  }

  array set instance_info [issp_get_instance_info $path]
  set source_width $instance_info(source_width)
  set full_data [issp_read_source_data $path]
  set full_bin  [hex_to_bin $full_data $source_width]

  puts "unmodified = $full_data"

  #------------------------------------------------------

  set out [lsearch -index 1 $::source_list $source]

  if {$out >= 0} {

    set curr_source [lindex $::source_list $out]

    set issp_name [lindex $curr_source 0]
    set name_1    [lindex $curr_source 1]
    set width     [lindex $curr_source 2]
    set offset    [lindex $curr_source 3]

    puts "name $name_1, width $width, offset $offset"

    set part_bin [hex_to_bin $data $width]

    puts "$part_bin"


    # replace

    set start [expr $source_width-$width-$offset]
    set end   [expr $source_width-$offset-1]

    puts "start = $start - end = $end"

    set new_bin [string replace $full_bin $start $end $part_bin]

    puts "source replace"
    puts "$full_data"
    puts "$full_bin"
    puts "$new_bin"

    # convert back to hex and write to fpga

    set out_hex [bin_to_hex $new_bin]
    issp_write_source_data $path "0x$out_hex"

  } else {
    puts "name not found"
  }



}

proc set_source_bit {name source bit value} {

  set path [get_issp_path $name]

  if {[string length "$path"] > 0} {

    array set instance_info [issp_get_instance_info $path]
    set source_width $instance_info(source_width)
    set full_data [issp_read_source_data $path]
    set full_bin  [hex_to_bin $full_data $source_width]

    set out [lsearch -index 1 $::source_list $source]

    if {$out >= 0} {

      set curr_source [lindex $::source_list $out]

      set issp_name [lindex $curr_source 0]
      set name_1    [lindex $curr_source 1]
      set width     [lindex $curr_source 2]
      set offset    [lindex $curr_source 3]

      if {$bit >= $width} {
        puts "bit exceeds source width"
        return
      }

      set start [expr $source_width-$offset-$bit-1]
      set end   $start

      set new_bin [string replace $full_bin $start $end $value]

      puts "source replace"
      puts "$full_data"
      puts "$full_bin"
      puts "$new_bin"

      set out_hex [bin_to_hex $new_bin]
      issp_write_source_data $path "0x$out_hex"

    } else {
      puts "something else"
      return ""
    }

  } else {
    puts "name not open"
    return ""
  }

}

proc toggle_source_bit {name source bit} {

  set path [get_issp_path $name]

  if {[string length "$path"] > 0} {

    array set instance_info [issp_get_instance_info $path]
    set source_width $instance_info(source_width)
    set full_data [issp_read_source_data $path]
    set full_bin  [hex_to_bin $full_data $source_width]

    set out [lsearch -index 1 $::source_list $source]

    if {$out >= 0} {

      set curr_source [lindex $::source_list $out]

      set issp_name [lindex $curr_source 0]
      set name_1    [lindex $curr_source 1]
      set width     [lindex $curr_source 2]
      set offset    [lindex $curr_source 3]

      if {$bit >= $width} {
        puts "bit exceeds source width"
        return
      }

      set start [expr $source_width-$offset-$bit-1]
      set end   $start

      set value [string range $full_bin $start $end]

      if {$value} {
        set value "0"
      } else {
        set value "1"
      }

      set new_bin [string replace $full_bin $start $end $value]

      puts "source replace"
      puts "$full_data"
      puts "$full_bin"
      puts "$new_bin"

      set out_hex [bin_to_hex $new_bin]
      issp_write_source_data $path "0x$out_hex"

    } else {
      puts "something else"
      return ""
    }

  } else {
    puts "name not open"
    return ""
  }

}























#----------------------------------------------------------------------------------------------

proc test {} {

  claim_issp SP01

  read_all_probe_data SP01

  read_probe SP01 prb_0

  read_probe SP01 prb_1

  read_probe SP01 prb_6

  set_source SP01 src_1 0xafea

  set_source SP01 src_2 0xaa23a

  set_source SP01 src_6 0xaa68

  set_source_bit SP01 src_0 33 1
  set_source_bit SP01 src_0 34 1
  set_source_bit SP01 src_0 35 1
  set_source_bit SP01 src_0 36 1

  toggle_source_bit SP01 src_1 25
  toggle_source_bit SP01 src_1 25
  toggle_source_bit SP01 src_1 25
  toggle_source_bit SP01 src_1 25

  toggle_source_bit SP01 debug_remote_resetn 0
  after 300
  toggle_source_bit SP01 debug_remote_resetn 0

  close_issp SP01

}

test