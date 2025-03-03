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

package provide hls_build_pkg     1.0
package require Tcl               8.0
package require pd_handler_pkg    1.0

namespace eval ::hls_build_pkg {

  # Export functions
  namespace export dsp_builder_build

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

}

proc ::hls_build_pkg::dsp_builder_build {model_dir model_name family rtl_dir} {

  set m_file_path $::hls_build_pkg::pkg_dir

  # error check inputs
  set m_file_exists     [file exists [file join $m_file_path "dsp_builder_build_model.m"]]
  set model_dir_exists  [file exists [file join $model_dir "$model_name.slx"]]
  
  if (!$m_file_exists) {
    return -code error -errorinfo "Unable to locate dsp_builder_build_model.m in $m_file_path"
  } elseif {!$model_dir_exists} {
    return -code error -errorinfo "Unable to locate $model_name.slx in $model_dir"
  }

  # need to ensure that the rtl_dir is defined relative to the 
  # model_dir to ensure the resulting IP uses relative paths
  if {[file pathtype $rtl_dir] == "absolute"} {
    return -code error -errorinfo "Output directory $rtl_dir must be relative to the model directory $model_dir"
  }

  set abs_rtl_dir     [file join $model_dir $rtl_dir]
  set rtl_dir_exists  [file exists $abs_rtl_dir]
  
  if {!$rtl_dir_exists} {
    file mkdir $abs_rtl_dir
  }

  # skip RTL generation if the output directory already exists (indicates generation has previously occured)
  set ip_dir    [file join $abs_rtl_dir $model_name]
  set ip_exists [file exists $ip_dir]

  if {$ip_exists==1} {
    ::pd_handler_pkg::sendMessage "  RTL previously generated for DSP Builder model: $model_name"
    return -code ok
  }

  # display message to the user
  ::pd_handler_pkg::sendMessage "  Generating RTL for DSP Builder model: $model_name"
  ::pd_handler_pkg::sendMessage "  Please be patient, this can take up to 10 minutes"

  set    args "diary '$abs_rtl_dir/${model_name}_dsp_builder.log'; "
  append args "addpath('$m_file_path'); "
  append args "dsp_builder_build_model('$model_dir', '$model_name', '$family', '$rtl_dir'); "
  append args "exit;"

  set result [catch {exec dsp_builder.sh -nosplash -nodisplay -r "$args"} result_text]

  if {$result!=0} {
    # return -code error -errorinfo $result_text
    ::pd_handler_pkg::sendMessage "  Matlab::dsp-builder finished running! This is the result value = $result"
    ::pd_handler_pkg::sendMessage "  This is the result_text:"
    ::pd_handler_pkg::sendMessage "  $result_text"
  }

  set result [catch {::hls_build_pkg::create_ipx_file $model_name $abs_rtl_dir} result_text] 

  # if {$result!=0} {
  #   return -code error -errorinfo $result_text
  # } else {
  #   return -code ok
  # }
  if {$result!=0} {
    # return -code error -errorinfo $result_text
    ::pd_handler_pkg::sendMessage "  Matlab::create_ipx_file finished running! This is the result value = $result"
    ::pd_handler_pkg::sendMessage "  This is the result_text:"
    ::pd_handler_pkg::sendMessage "  $result_text"
  }
  return -code ok
  
}

proc ::hls_build_pkg::create_ipx_file {model_name abs_rtl_dir} {

  set ipx_file [file join $abs_rtl_dir ${model_name}.ipx]

  # qsys-script tcl version does not support glob -directory flag so
  # need to cd into the directory first
  set curr_dir [pwd]
  cd [file join $abs_rtl_dir $model_name]

  set hw_files [list]
  set hw_files [glob -nocomplain -- "*_hw.tcl"]
  
  cd $curr_dir

  set num_hw_files [llength $hw_files]

  if {$num_hw_files==0} {
    return -code error -errorinfo "Unable to find _hw.tcl file for generated DSP Builder IP ($model_name)"
  } elseif {$num_hw_files>1} {
    return -code error -errorinfo "Unable to disambiguate multiple _hw.tcl files for generated DSP Builder IP ($model_name)"
  }

  set fid [open ${ipx_file} w] 

  puts $fid "<?xml version=\"1.0\"?>"
  puts $fid "<library>"
  puts $fid "<index file=\"${model_name}/${hw_files}\" />"
  puts $fid "</library>"

  close $fid

  return -code ok

}

proc ::hls_build_pkg::get_linux_distrbid {} {

  # Use lsb_release command to get the linux info in the following format
  # LSB Version:       n/a
  # Distributor ID: SUSE
  # Description:    SUSE Linux Enterprise Server 12 SP5
  # Release:        12.5
  # Codename:       n/a
  set lsb_release_result  [exec lsb_release -a]

  # Split the string into list of each line
  set linux_info          [split $lsb_release_result "\n"]

  # Iterate over each line of the linux-info dump
  foreach line $linux_info {
    set fields [split $line ":"]
    set linux_info_aarray([lindex $fields 0]) [lindex $fields 1]
  }
  # return [array get $linux_info_aarray]
  return [string trim $linux_info_aarray(Distributor ID)]

}

proc ::hls_build_pkg::get_linux_release {} {

  # Use lsb_release command to get the linux release number
  set lsb_release_result  [exec lsb_release -a]
  # Split the string into list of each line
  set linux_info          [split $lsb_release_result "\n"]
  # Iterate over each line of the linux-info dump
  foreach line $linux_info {
    set fields [split $line ":"]
    set linux_info_aarray([lindex $fields 0]) [lindex $fields 1]
  }
  return [string trim $linux_info_aarray(Release)]
}


proc ::hls_build_pkg::get_oneapi_version {} {

  # Initialize
  set oneapi_version ""

  # Use <which aoc> command to get the installation path of oneapi 
  # Example of output "/p/psg/swip/releases_hld/aclsycltest/2023.1/20230213.3487/linux64/bin/aoc"
  if {[catch {exec which aoc} whic_aoc_result] == 0} {

    # Split the string based on the delimiter /
    set split_aoc_list [split $whic_aoc_result /]
    set match 0

    # Search for the match "aclsycltest" & select the next item to extract the version
    foreach item $split_aoc_list {
      if {$match == "0"} {
        if {$item == "aclsycltest"} {
          set match 1
        }
      } else { 
        set oneapi_version $item
        break
      }
    }
    return $oneapi_version
  } else {
    return -code error -errorinfo "<which aoc> failed; Check oneAPI installation"
  }

}

proc ::hls_build_pkg::build_kernel {kernel_dir kernel_name device en_ld_preload use_custom_ld_preload custom_ld_preload make_target} {

  set init_dir [pwd]
  cd $kernel_dir
  file delete -force build
  file mkdir build
  cd build

  set linux_distrbid        [hls_build_pkg::get_linux_distrbid]
  set linux_release         [hls_build_pkg::get_linux_release]
  set oneapi_version        [hls_build_pkg::get_oneapi_version]

  if {$en_ld_preload == "1"} {
    ::pd_handler_pkg::sendMessage "ENABLE_LD_PRELOAD set to $en_ld_preload"
    if {$use_custom_ld_preload == "1"} {
      ::pd_handler_pkg::sendMessage "USE_CUSTOM_LD_PRELOAD set to $use_custom_ld_preload"
      set ld_preload_paths $custom_ld_preload
    } elseif {$use_custom_ld_preload == "0"} {
      if {$linux_distrbid == "Ubuntu"} {
        ::pd_handler_pkg::sendMessage "Linux distribution is Ubuntu"
        set ld_preload_paths "export LD_PRELOAD=\"/usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libcurl.so.4\"; "
      } elseif {$linux_distrbid == "SUSE"} {
        ::pd_handler_pkg::sendMessage "Linux distribution is SUSE"
        set ld_preload_paths ""
      } else {
        ::pd_handler_pkg::sendMessage "Untested linux distribution id ($linux_distrbid): Resetting ld_preload_path"
        set ld_preload_paths ""
      }
    } else {
      set ld_preload_paths ""
    }
  } else {
    set ld_preload_paths ""
  }

  ::pd_handler_pkg::sendMessage "set ld_preload_paths to <$ld_preload_paths>"

  # # Internal Ubuntu setting
  # # set ld_preload_paths "export LD_PRELOAD=\"/usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libcurl.so.4.7.0\"; "

  set cmd $ld_preload_paths
  append cmd "cmake .. -DFPGA_DEVICE=$device"
  set result_failed [catch {exec sh -c "$cmd"} result_text]
  if {$result_failed!=0} {
    ::pd_handler_pkg::sendMessage " <cmake ..>  return value $result_failed"
    ::pd_handler_pkg::sendMessage " <cmake ..>  log:"
    ::pd_handler_pkg::sendMessage "$result_text"
  }
  set cmd $ld_preload_paths
  append cmd "make $make_target"
  set result_failed [catch {exec sh -c "$cmd"} result_text]
  if {$result_failed!=0} {
    ::pd_handler_pkg::sendMessage "<make $make_target>  return value $result_failed"
    ::pd_handler_pkg::sendMessage "<make $make_target>  log:"
    ::pd_handler_pkg::sendMessage "$result_text"
  }
  if {$oneapi_version < 2023.1} {
    ::pd_handler_pkg::sendMessage "  oneapi version is less than 2023.1; so, python script to adjust the _hw.tcl file is executed"
    cd ${kernel_name}.${make_target}.prj
    exec python ${kernel_name}_${make_target}_di_hw_tcl_adjustment_script.py
  }
  cd $init_dir

}