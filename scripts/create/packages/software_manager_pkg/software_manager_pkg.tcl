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

package provide software_manager_pkg 1.0

package require Tcl                  8.0

# Helper to setup software for CPU / HPS (generate makefile, copy source files, etc)

# This package requires an array of the following format
#
# array(project_name)      -
# array(project_directory) -
# array(instance_name)     -
# array(cpu_type)          - NIOSII / NIOSV / HPS
# array(application_dir)   - list of paths
# array(bsp_type)          - hal / ucosii / freertos
# array(bsp_settings_file) -
# array(custom_cmakefile)  - 0 / 1
# array(custom_makefile)   - 0 / 1

# Nios V only
# array(memory_base)
# array(memory_size)

# Notes on using a custom bsp settings file, or a custom Makefile
#
# The bsp settings file will be moved to (or created in) the software
# directory. The makefile will automatically update the settings.bsp file
# to point to the correct .sopcinfo or .qsys file, and the location of the
# bsp directory.
#
# The application makefile is expected to be located at the top level in the
# application folder and will be executed in place.
#
# - The default recipe must create an elf file and all required .hex files
# - All paths should be relative
#
# The file app_variables.mk file in the software directory should be included
# in the custom makefile and the following variables used
#
# - SUBSYSTEM_NAME
# - PROJECT_ROOT_DIR
# - QUARTUS_PROJECT_DIR
#
# - BSP_ROOT_DIR : path of the BSP generation directory
# - BIN_DIR      : path of the application build directory
#
# - ELF_NAME     : name of the application .elf file
# - ELF          : path of the application .elf file
#
# - OBJ_ROOT_DIR : path to object files
# - MEM_INIT_DIR : path of the memory initialization file

namespace eval software_manager_pkg {

    namespace export initialize_software

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    variable software_array

    # Setup the software for a specific subsystem instance

    proc ::software_manager_pkg::initialize_software {software_array} {

        upvar ${software_array} v_array

        variable  v_software_array
        array set v_software_array [array get v_array]

        # Skip software initialization if no application directory provided
        set v_instance_name         $v_software_array(instance_name)
        set v_application_directory $v_software_array(application_dir)

        if {[llength ${v_application_directory}] == 0} {
            return -code ok "No application directory provided for (${v_instance_name}), skipping software manager"
        }

        set v_result [catch {::software_manager_pkg::validate_array} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {::software_manager_pkg::transfer_files} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_result [catch {::software_manager_pkg::generate_makefile} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        return -code ok

    }

    # Validate software parameters (user defined parameters only)

    proc ::software_manager_pkg::validate_array {} {

        variable v_software_array

        set v_cpu_type              $v_software_array(cpu_type)

        set v_bsp_type              $v_software_array(bsp_type)
        set v_bsp_settings_file     $v_software_array(bsp_settings_file)
        set v_application_directory $v_software_array(application_dir)
        set v_custom_cmakefile      $v_software_array(custom_cmakefile)
        set v_custom_makefile       $v_software_array(custom_makefile)

        # Check application directories
        foreach v_directory ${v_application_directory} {
            if {[file exists ${v_directory}] != 1} {
                return -code error "Application directory (${v_directory}) does not exist"
            }
        }

        # Check CPU type
        set v_supported_cpus [list "NIOSII" "NIOSV" "HPS"]
        set v_found          0

        foreach v_cpu ${v_supported_cpus} {
            if {[string equal -nocase ${v_cpu} ${v_cpu_type}] == 1} {
                set v_found 1
                break
            }
        }

        if {${v_found} == 0} {
            return -code error "CPU type must be one of the following values ${v_supported_cpus} (given ${v_cpu_type})"
        }

        # check BSP type (NIOS only)
        if {[string equal -nocase ${v_cpu_type} "HPS"] != 1} {
            set v_supported_bsps [list "hal" "ucosii"]
            set v_found          0

            if {[string equal -nocase ${v_cpu_type} "NIOSII"] == 1} {
                lappend v_supported_bsps "freertos"
            }

            foreach v_bsp ${v_supported_bsps} {
                if {[string equal -nocase ${v_bsp} ${v_bsp_type}] == 1} {
                    set v_found 1
                    break
                }
            }

            if {${v_found} == 0} {
                return -code error "BSP type must be one of the following values ${v_supported_bsps}\
                                    (given ${v_bsp_type})"
            }

        }

        # Check bsp settings
        if {[llength ${v_bsp_settings_file}] == 1} {
            if {[file exists ${v_bsp_settings_file}] != 1} {
                return -code error "BSP settings file (${v_bsp_settings_file}) does not exist"
            } elseif {[file isfile ${v_bsp_settings_file}] != 1} {
                return -code error "BSP settings file (${v_bsp_settings_file}) is not a file"
            }
        } elseif {[llength ${v_bsp_settings_file}] > 1} {
            return -code error "Only one BSP settings file can be declared"
        }

        # Check custom cmakefile
        if {[lsearch -exact [list "0" "1"] ${v_custom_cmakefile}] == -1} {
            return -code error "Custom cmakefile value must be either 0 or 1 (given ${v_custom_cmakefile})"
        }

        # Check custom makefile
        if {[lsearch -exact [list "0" "1"] ${v_custom_makefile}] == -1} {
            return -code error "Custom makefile value must be either 0 or 1 (given ${v_custom_makefile})"
        }

        # HPS requires either a custom cmakefile or a makefile
        if {[string equal -nocase ${v_cpu_type} "HPS"] == 1} {
            if {((${v_custom_cmakefile} == 0) && (${v_custom_makefile} == 0)) ||\
                ((${v_custom_cmakefile} == 1) && (${v_custom_makefile} == 1))} {
                    return -code error "HPS subsystem requires either a custom cmakefile or custom makefile"
            }
        }

        # Check custom makefile is in expected location (<instance_name>/app/)
        if {${v_custom_makefile} == 1} {
            set v_valid_makefiles [list Makefile makefile GNUmakefile]]
            set v_found_makefile  0

            foreach v_path ${v_application_directory} {

                if {[file isfile ${v_path}] == 1} {
                    set v_filename [file tail ${v_path}]

                    if {[lsearch -exact ${v_valid_makefiles} ${v_filename}] >= 0} {
                        set v_found_makefile 1
                        break
                    }

                } elseif {[file isdirectory ${v_path}] == 1} {
                    set v_path_tail [file tail ${v_path}]

                    # path ending with . indicates the folder contents will be copied directly into the app folder
                    if {${v_path_tail} == "."} {
                        foreach v_name ${v_valid_makefiles} {
                            set v_makefile_name [file join ${v_path} ${v_name}]

                            if {[file exists ${v_makefile_name}] == 1} {
                                set v_found_makefile 1
                                break
                            }
                        }
                    }
                }
            }

            if {${v_found_makefile} != 1} {
                return -code error "No custom makefile found in application directories"
            }
        }

        # Check custom cmakefile is in expected location (<instance_name>/app/)
        if {${v_custom_cmakefile} == 1} {
            set v_valid_cmakefiles [list CMakeLists.txt]
            set v_found_cmakefile  0

            foreach v_path ${v_application_directory} {

                if {[file isfile ${v_path}] == 1} {
                    set v_filename [file tail ${v_path}]

                    if {[lsearch -exact ${v_valid_cmakefiles} ${v_filename}] >= 0} {
                        set v_found_cmakefile 1
                        break
                    }

                } elseif {[file isdirectory ${v_path}] == 1} {
                    set v_path_tail [file tail ${v_path}]

                    # path ending with . indicates the folder contents will be copied directly into the app folder
                    if {${v_path_tail} == "."} {
                        foreach v_name ${v_valid_cmakefiles} {
                            set v_cmakefile_name [file join ${v_path} ${v_name}]

                            if {[file exists ${v_cmakefile_name}] == 1} {
                                set v_found_cmakefile 1
                                break
                            }
                        }
                    }
                }
            }

            if {${v_found_cmakefile} != 1} {
                return -code error "No custom cmakefile found in application directories"
            }
        }

        return -code ok

    }

    # Transfer software files to the default locations

    proc ::software_manager_pkg::transfer_files {} {

        variable v_software_array

        set v_project_name          $v_software_array(project_name)
        set v_project_path          $v_software_array(project_directory)
        set v_instance_name         $v_software_array(instance_name)
        set v_cpu_type              $v_software_array(cpu_type)

        set v_bsp_settings_file     $v_software_array(bsp_settings_file)
        set v_bsp_settings_filename [file tail ${v_bsp_settings_file}]
        set v_application_directory $v_software_array(application_dir)
        set v_custom_makefile       $v_software_array(custom_makefile)

        set v_instance_software_directory    [file join ${v_project_path} "software" ${v_instance_name}]
        set v_instance_application_directory [file join ${v_instance_software_directory} "app"]

        file mkdir ${v_instance_application_directory}

        foreach v_path ${v_application_directory} {
            file_copy ${v_path} ${v_instance_application_directory}
        }

        if {[llength ${v_bsp_settings_file}] == 1} {
            file copy -force ${v_bsp_settings_file} ${v_instance_software_directory}
            set v_new_bsp_settings_file [file join ${v_instance_software_directory} ${v_bsp_settings_filename}]

            # Update paths in the bsp settings file
            set v_result [catch {::software_manager_pkg::update_bsp_settings ${v_new_bsp_settings_file}\
                                                                             ${v_project_name}} result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${result_text}
            }
        }

        # Copy toolkit defines file
        if {${v_custom_makefile} == 1} {
            set v_app_defines_makefile [file join $::software_manager_pkg::pkg_dir "app_defines.mk.terp"]
            file copy -force ${v_app_defines_makefile} ${v_instance_software_directory}
        }

        # Create QSF entries for memory initialization files
        if {[string equal -nocase ${v_cpu_type} "HPS"] != 1} {
            set v_result [catch {::software_manager_pkg::create_qsf_file} result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${result_text}
            }
        }

        # Copy toolkit makefile to the software directory
        if {[string equal -nocase ${v_cpu_type} "NIOSII"] == 1} {
            set v_software_makefile [file join $::software_manager_pkg::pkg_dir "makefile.terp"]
        } elseif {[string equal -nocase ${v_cpu_type} "NIOSV"] == 1} {
            set v_software_makefile [file join $::software_manager_pkg::pkg_dir "makefile_niosv.terp"]
        } elseif {[string equal -nocase ${v_cpu_type} "HPS"] == 1} {
            set v_software_makefile [file join $::software_manager_pkg::pkg_dir "makefile_hps.terp"]
        }

        file copy -force ${v_software_makefile} [file join ${v_instance_software_directory} "makefile.terp"]

        return -code ok

    }

    # Create makefile to automate BSP generation and software compilation (used by build_shell.tcl)

    proc ::software_manager_pkg::generate_makefile {} {

        variable v_software_array

        set v_project_path    $v_software_array(project_directory)
        set v_instance_name   $v_software_array(instance_name)
        set v_custom_makefile $v_software_array(custom_makefile)
        set v_cpu_type        $v_software_array(cpu_type)

        # convert the array into a list for terp evaluation
        set v_parameter_list {}
        lappend v_parameter_list  $v_software_array(project_name)
        lappend v_parameter_list  ${v_instance_name}
        lappend v_parameter_list  ${v_cpu_type}
        lappend v_parameter_list  $v_software_array(bsp_type)
        lappend v_parameter_list  [file tail $v_software_array(bsp_settings_file)]
        lappend v_parameter_list  $v_software_array(custom_cmakefile)
        lappend v_parameter_list  ${v_custom_makefile}

        if {[string equal -nocase ${v_cpu_type} "NIOSV"] == 1} {
            set v_memory_base $v_software_array(memory_base)
            set v_memory_size $v_software_array(memory_size)

            set v_memory_end [expr ${v_memory_base} + ${v_memory_size} - 1]
            set v_memory_end [format 0x%08X ${v_memory_end}]

            lappend v_parameter_list ${v_memory_base}
            lappend v_parameter_list ${v_memory_end}
        }

        set v_software_dir [file join ${v_project_path} software ${v_instance_name}]
        set v_makefile     [file join ${v_software_dir} "makefile.terp"]

        set v_result [catch {::software_manager_pkg::evaluate_terp_file ${v_makefile}\
                                                                        ${v_parameter_list} 0 1} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        if {(${v_custom_makefile} == 1) && ([string equal -nocase ${v_cpu_type} "HPS"] != 1)} {
            set v_defines_makefile [file join ${v_software_dir} "app_defines.mk.terp"]

            set v_result [catch {::software_manager_pkg::evaluate_terp_file ${v_defines_makefile}\
                                                                            ${v_instance_name} 0 1} result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${result_text}
            }
        }

        return -code ok

    }

    # Update Platform Designer and Quartus file paths in BSP settings file

    proc ::software_manager_pkg::update_bsp_settings {file project_name} {

        set v_relative_qsys_file    [file join ".." ".." ".." ".." "rtl" "${project_name}_qsys.qsys"]
        set v_relative_project_file [file join ".." ".." ".." ".." "quartus" "${project_name}.qpf"]

        set v_qsys_file_substitution    "<QsysFile>${v_relative_qsys_file}</QsysFile>"
        set v_project_file_substitution "<QuartusProjectFile>${v_relative_project_file}</QuartusProjectFile>"

        if {[file exists ${file}] != 1} {
            return -code error "BSP settings file does not exist (${file})"
        }

        set v_result [catch {open ${file} r+} v_fid]
        if {${v_result} != 0} {
            return -code ${v_result} "Could not open BSP settings file (${v_fid})"
        }

        set v_data  [read ${v_fid}]
        set v_lines [split ${v_data} "\n"]

        seek ${v_fid} 0

        foreach v_line ${v_lines} {
            regsub "\<QsysFile\>(.*)\</QsysFile\>" ${v_line} ${v_qsys_file_substitution} v_line
            regsub "\<QuartusProjectFile\>(.*)\</QuartusProjectFile\>" ${v_line} ${v_project_file_substitution} v_line
            puts ${v_fid} ${v_line}
        }

        close ${v_fid}

        return -code ok

    }

    # Create QSF entries for memory initialization files

    proc ::software_manager_pkg::create_qsf_file {} {

        variable v_software_array

        set v_project_path  $v_software_array(project_directory)
        set v_instance_name $v_software_array(instance_name)
        set v_qsf_file_name "${v_instance_name}_software.qsf"
        set v_qsf_file_path [file join ${v_project_path} quartus shell ${v_qsf_file_name}]

        set v_result [catch {open ${v_qsf_file_path} "w"} v_fid]
        if {${v_result} != 0} {
            return -code ${v_result} "Unable to create or open file ${v_qsf_file_path} (${v_fid})"
        }

        set v_memory_path [file join ".." "software" "${v_instance_name}" "build" "bin" "mem_init"]

        puts  ${v_fid} "set_global_assignment -name SEARCH_PATH ${v_memory_path}"
        close ${v_fid}

        return -code ok

    }

    # Generate file from TERP file and parameter list

    proc ::software_manager_pkg::evaluate_terp_file {terp_file parameters execute delete} {

        if {[file exists ${terp_file}] != 1} {
            return -code error "TERP file does not exist (${terp_file})"
        }

        set v_result [catch {open ${terp_file} "r"} v_fid]
        if {${v_result} != 0} {
            return -code ${v_result} "Unable to open TERP file (${terp_file}) (${v_fid})"
        }

        set v_terp_data [read ${v_fid}]
        close ${v_fid}

        # Convert parameter list to TERP style parameter array
        for {set v_index 0} {${v_index} < [llength ${parameters}]} {incr v_index} {
            set v_terp_parameters(param${v_index}) [lindex ${parameters} ${v_index}]
        }

        set v_result [catch {altera_terp ${v_terp_data} v_terp_parameters} v_output_data]
        if {${v_result} != 0} {
            return -code ${v_result} "Unable to evaluate TERP file (${v_output_data})"
        }

        set v_output_file [file rootname ${terp_file}]

        set v_result [catch {open ${v_output_file} "w+"} v_fid]
        if {${v_result} != 0} {
            return -code ${v_result} "Unable to open output file (${v_output_file}) (${v_fid})"
        }

        puts  ${v_fid} ${v_output_data}
        close ${v_fid}

        if {${execute} == 1} {
            source ${v_output_file}
        }

        if {${delete} == 1} {
            file delete -force -- ${terp_file}
        }

        return -code ok

    }

    # Print the software array (for debug)

    proc ::software_manager_pkg::print_array {} {

        variable v_software_array

        set v_project_name  $v_software_array(project_name)
        set v_project_path  $v_software_array(project_directory)
        set v_instance_name $v_software_array(instance_name)
        set v_cpu_type      $v_software_array(cpu_type)

        if {[string exact -nocase ${v_cpu_type} "NIOSV"] == 1} {
            set v_memory_base $v_software_array(memory_base)
            set v_memory_size $v_software_array(memory_size)
        }

        set v_bsp_type          $v_software_array(bsp_type)
        set v_bsp_settings_file $v_software_array(bsp_settings_file)
        set v_app_dir           $v_software_array(application_dir)
        set v_custom_cmakefile  $v_software_array(custom_cmakefile)
        set v_custom_makefile   $v_software_array(custom_makefile)

        puts "=========================================="
        puts "============= Software Array ============="
        puts "=========================================="
        puts ""
        puts "project name:  ${v_project_name}"
        puts "project path:  ${v_project_path}"
        puts "instance name: ${v_instance_name}"
        puts "cpu type:      ${v_cpu_type}"
        puts ""

        if {[string exact -nocase ${v_cpu_type} "NIOSV"] == 1} {
            puts "memory base:      ${v_memory_base}"
            puts "memory size:      ${v_memory_size}"
            puts ""
        }

        puts "bsp type:         ${v_bsp_type}"
        puts "bsp file:         ${v_bsp_settings_file}"
        puts "application dir:  ${v_app_dir}"
        puts "custom cmakefile: ${v_custom_cmakefile}"
        puts "custom makefile:  ${v_custom_makefile}"
        puts ""
        puts "=========================================="

        return -code ok

    }

}
