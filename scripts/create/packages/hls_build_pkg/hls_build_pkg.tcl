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

package provide hls_build_pkg     1.0

package require Tcl               8.0
package require pd_handler_pkg    1.0

# Helper to run HLS build flows (DSP Builder Advanced / OneAPI)

namespace eval hls_build_pkg {

    namespace export dsp_builder_build

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    ###################################################################################

    # Generate RTL from a DSP Builder Advanced model

    proc ::hls_build_pkg::dsp_builder_build {model_path model_name family speed_grade rtl_path} {

        set v_mscript_path $::hls_build_pkg::pkg_dir

        set v_mscript_exists    [file exists [file join ${v_mscript_path} "dsp_builder_build_model.m"]]
        set v_model_path_exists [file exists [file join ${model_path} "${model_name}.slx"]]

        if {${v_mscript_exists} != 1} {
            return -code error "Unable to locate script dsp_builder_build_model.m in ${v_mscript_path}"
        } elseif {${v_model_path_exists} != 1} {
            return -code error "Unable to locate ${model_name}.slx in ${model_path}"
        }

        # The rtl_path must be relative to model_path to ensure generated IP uses relative paths
        if {[file pathtype ${rtl_path}] == "absolute"} {
            return -code error "Output directory ${rtl_path} must be relative to the model directory ${model_path}"
        }

        set v_absolute_rtl_path        [file join ${model_path} ${rtl_path}]
        set v_absolute_rtl_path_exists [file exists ${v_absolute_rtl_path}]

        if {${v_absolute_rtl_path_exists} != 1} {
            set v_result [catch {file mkdir ${v_absolute_rtl_path}} v_result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${v_result_text}
            }
        }

        # Skip RTL generation if .ipx file exists (indicates generation has previously occurred)
        set v_ipx_file        [file join ${v_absolute_rtl_path} ${model_name}.ipx]
        set v_ipx_file_exists [file exists ${v_ipx_file}]

        if {${v_ipx_file_exists} == 1} {
            ::pd_handler_pkg::sendMessage "    RTL previously generated for DSP Builder Advanced model: ${model_name}"
            return -code ok
        }

        ::pd_handler_pkg::sendMessage "    Generating RTL for DSP Builder Advanced model: ${model_name}"
        ::pd_handler_pkg::sendMessage "    Please be patient, this can take up to 10 minutes"

        set v_log_file [file join ${v_absolute_rtl_path} "${model_name}_dsp_builder.log"]

        # Define file paths and script files
        set v_mfile_path  [file join ${v_absolute_rtl_path} "${model_name}_dsp_script.m"]
        set v_shfile_path [file join ${v_absolute_rtl_path} "${model_name}_run_dsp_builder.sh"]

        # Write MATLAB script (.m)
        set v_fp [open ${v_mfile_path} "w"]
        puts ${v_fp} "load_sl_glibc_patch;"
        puts ${v_fp} "sl_refresh_customizations;"
        puts ${v_fp} "diary('${v_log_file}');"
        puts ${v_fp} "addpath('${v_mscript_path}');"
        puts ${v_fp} "dsp_builder_build_model('${model_path}', '${model_name}', '${family}', '${speed_grade}', '${rtl_path}');"
        puts ${v_fp} "exit;"
        close ${v_fp}

        # Write shell script
        set v_fp [open ${v_shfile_path} "w"]
        puts ${v_fp} "#!/bin/bash"
        puts ${v_fp} "dsp_builder.sh -nosplash -nodisplay -r \"run('$v_mfile_path');\""
        close ${v_fp}

        # Make script executable (avoid file attributes!)
        exec chmod +x ${v_shfile_path}

        # Run DSP Builder shell script
        ::pd_handler_pkg::sendMessage "    Running: ${v_shfile_path}"

        set v_result [catch {
            set output [exec ${v_shfile_path}]
        } v_result_text]

        if {${v_result} != 0} {
            return -code ${v_result} "DSP Builder Advanced generation of model ${model_name} failed: ${v_result_text}"
        }

        set v_result [catch {::hls_build_pkg::create_ipx_file ${model_name} ${v_absolute_rtl_path}} v_result_text]
        if {${v_result}!=0} {
            return -code ${v_result} ${v_result_text}
        }

        return -code ok

    }

    # Create an IPX file for the generated DSP Builder Advanced model

    proc ::hls_build_pkg::create_ipx_file {model_name v_absolute_rtl_path} {

        set v_ipx_file [file join ${v_absolute_rtl_path} "${model_name}.ipx"]

        # The glob -directory flag is not supported in qsys-script, cd into the directory
        set v_current_path [pwd]
        cd [file join ${v_absolute_rtl_path} ${model_name}]

        set v_hw_tcl_files {}
        set v_hw_tcl_files [glob -nocomplain -- "*_hw.tcl"]

        cd ${v_current_path}

        set v_hw_tcl_file_count [llength ${v_hw_tcl_files}]

        if {${v_hw_tcl_file_count} == 0} {
            return -code error "Unable to find _hw.tcl file for generated DSP Builder Advanced model ${model_name}"
        } elseif {${v_hw_tcl_file_count} >= 2} {
            return -code error "Unable to disambiguate multiple _hw.tcl files for generated DSP Builder Advanced\
                                model ${model_name}"
        }

        set v_result [catch {open ${v_ipx_file} w} v_fid]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_fid}
        }

        puts ${v_fid} "<?xml version=\"1.0\"?>"
        puts ${v_fid} "<library>"
        puts ${v_fid} "<index file=\"${model_name}/${v_hw_tcl_files}\" />"
        puts ${v_fid} "</library>"

        close ${v_fid}

        return -code ok

    }

    ###################################################################################

    # Generate RTL from a OneAPI kernel
    # Note: In some cases the user is required to provide pre_commands to setup the environment
    #       e.g. "export LD_PRELOAD=\"/usr/lib/x86_64-linux-gnu/libstdc++.so.6
    #             /usr/lib/x86_64-linux-gnu/libcurl.so.4.7.0\"; "

    proc ::hls_build_pkg::build_kernel {kernel_path kernel_name device pre_commands make_target} {

        set v_current_path [pwd]

        cd ${kernel_path}

        set v_result [catch {file delete -force build} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_result [catch {file mkdir build} v_result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_result_text}
        }

        cd build

        set v_oneapi_version     [hls_build_pkg::get_oneapi_version]

        set v_pre_command_string ""

        foreach v_pre_command ${pre_commands} {
            append v_pre_command_string ${v_pre_command}
        }

        set v_command ${v_pre_command_string}
        append v_command "cmake .. -DFPGA_DEVICE=${device}"

        set v_result [catch {exec sh -c "${v_command}"} v_result_text]
        if {${v_result} !=0} {
            return -code ${v_result} ${v_result_text}
        }

        set v_command ${v_pre_command_string}
        append v_command "make ${make_target}"

        set v_result [catch {exec sh -c "${v_command}"} v_result_text]
        if {${v_result} !=0} {
            return -code ${v_result} ${v_result_text}
        }

        # OneAPI version below 2023.1 requires a python script to adjust the _hw.tcl file
        if {${v_oneapi_version} < 2023.1} {
            cd "${kernel_name}.${make_target}.prj"
            set v_result [catch {exec python "${kernel_name}_${make_target}_di_hw_tcl_adjustment_script.py"}\
                                v_result_text]
            if {${v_result} !=0} {
                return -code ${v_result} ${v_result_text}
            }
        }

        cd ${v_current_path}

        return -code ok

    }

    # Get the system Linux distribution

    proc ::hls_build_pkg::get_linux_distribution {} {

        # Use lsb_release command to get the linux info in the following format
        # LSB Version:    n/a
        # Distributor ID: SUSE
        # Description:    SUSE Linux Enterprise Server 12 SP5
        # Release:        12.5
        # Codename:       n/a

        set v_result [catch {exec lsb_release -a} v_lsb_release]
        if {${v_result} != 0} {
            return -code ${v_result} ${v_lsb_release}
        }

        set v_linux_info [split ${v_lsb_release} "\n"]

        # Iterate over each line of the linux-info dump
        foreach v_line ${v_linux_info} {
            set v_fields [split ${v_line} ":"]
            set v_label  [string trim [lindex ${v_fields} 0]]
            set v_value  [string trim [lindex ${v_fields} 1]]

            set v_linux_info_array(${v_label}) ${v_value}
        }

        if {[info exists v_linux_info_array("Distributor ID")] == 1} {
            return $v_linux_info_array("Distributor ID")
        } else {
            return -code error "Unable to retrieve system distributor ID"
        }

    }

    # Get the OneAPI version

    proc ::hls_build_pkg::get_oneapi_version {} {

        # Use <which aoc> command to get the installation path of OneAPI
        set v_result [catch {exec which aoc} v_which_aoc]
        if {${v_result} != 0} {
            return -code ${v_result} "Command <which aoc> failed; Check oneAPI installation (${v_which_aoc})"
        }

        set v_result [regexp {.*aclsycltest[\/\\]([^\/\\]*)[\/\\].*} ${v_which_aoc} v_match v_aoc_version]
        if {${v_result} != 1} {
            return -code error "Unable to retrieve OneAPI version"
        } else {
            return ${v_aoc_version}
        }

    }

}
