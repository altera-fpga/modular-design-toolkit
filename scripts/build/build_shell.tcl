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

package require Thread
package require fileutil
package require cmdline

package require ::quartus::project
package require ::quartus::flow
package require ::quartus::misc
package require ::quartus::report
package require ::quartus::device

# Helper for Quartus and CPU/HPS software compilation, and miscellaneous pre/post processing

namespace eval build_shell {

    variable ::argv0 $::quartus(args)
    variable v_log_filename "shell.build.rpt"
    variable v_proj_name ""

    # get paths so the script is directory agnostic
    variable v_abs_script_path [dict get [ info frame 0 ] file ]
    variable v_abs_script_dir  [file dirname ${v_abs_script_path}]
    variable v_proj_base_dir   [file normalize ${v_abs_script_dir}/../]

    # load custom packages
    set v_packages [glob -directory "${v_abs_script_dir}/packages" -types d -- *]

    foreach package ${v_packages} {
        lappend auto_path ${package}
    }

    package require archive_pkg         1.0
    package require logging_pkg         1.0
    package require software_build_pkg  1.0
    package require timer_pkg           1.0

    # parse command line arguments into an array

    proc ::build_shell::improved_getoptions {arglistVar optlist usage} {

        upvar 1 ${arglistVar} argv

        set v_opts [::cmdline::GetOptionDefaults ${optlist} v_result]

        while {[set v_err [::cmdline::getopt argv ${v_opts} v_opt v_arg]]} {
            if {${v_err} < 0} {
                return -code error -errorcode {CMDLINE ERROR} ${v_arg}
            }
            set v_result(${v_opt}) ${v_arg}
        }

        if {[info exists v_result(?)] || [info exists v_result(help)]} {
            return -code error -errorcode {CMDLINE USAGE} \
                [::cmdline::usage ${optlist} ${usage}]
        }

        return [array get v_result]

    }

    proc ::build_shell::main {} {

        variable v_abs_script_dir
        variable v_log_filename
        variable v_proj_name
        variable v_proj_base_dir

        # build flags
        set v_project_clean 0
        set v_pd_generate   0
        set v_sw_compile    0
        set v_hw_compile    0

        # extra flags
        set v_update_capability 0
        set v_update_sof        0
        set v_hps_post          0
        set v_hps_post_agx      0
        set v_hps_post_agx5e    0

        # misc flags
        set v_archive_project 0
        set v_silent_mode     0

        set v_options {
            { "proj_name.arg"         ""    "Name of the project"}
            { "clean_project"         "0"   "Remove all generated files from the project (Platform Designer and\
                                             Quartus)"}
            { "update_ocs"            "0"   "Update the automatic capability structure"}
            { "qsys_gen"              "1"   "Generate the Platform Designer systems"}
            { "sw_compile"            "1"   "Compile the Nios2/NiosV software"}
            { "hw_compile"            "1"   "Generates the sub-systems and systems & compiles SOF"}
            { "full_compile"          "1"   "Generates the sub-systems and systems, compiles SW & SOF"}
            { "hps_post"              "0"   "Warning: experimental feature - Split the output SOF into core and\
                                             peripheral files"}
            { "hps_post_agx"          "0"   "Warning: experimental feature - Convert the output SOF into core.rbf and\
                                             .jic based on default hps_debug.ihex and u-boot-spl-dtb.hex respectively"}
            { "hps_post_agx5e"        "0"   "Warning: experimental feature - Convert the output SOF into core.rbf and\
                                             .jic based on default u-boot-spl-dtb.hex"}
            { "update_sof"            "0"   "Compile the Nios2/NiosV software, and update the SOF file"}
            { "archive"               "0"   "Create an archive (.qar) of the project, following any compile options"}
            { "archive_fileset.arg"   ""    "Text file containing a list of paths to files to include in the archive,\
                                             this is in addition to the default fileset"}
            { "silent_mode"           "0"   "Disable the console output timer display"}
        }

        set v_usage "quartus_sh -t build_shell.tcl (-proj_name=?) (-qsys_gen) (-sw_compile) (-hw_compile) (-full_compile)"

        try {
            array set v_opts_hash [build_shell::improved_getoptions ::argv ${v_options} ${v_usage}]
            puts "All options valid"
        } trap {CMDLINE USAGE} {msg} {
        # This trap is executed when the -help argument is used by the user
            puts stderr "\n"
            puts stderr "-------------------------------------------------------------------------------------------"
            puts stderr "----                            Shell Design Toolkit                                   ----"
            puts stderr "-------------------------------------------------------------------------------------------"
            puts stderr "\n"
            puts stderr ${msg}
            puts stderr "\nNAME"
            puts stderr "     build_shell.tcl -- script to build a shell design"
            puts stderr "\nDESCRIPTION"
            puts stderr "     build_shell.tcl script builds a design based on the Quartus project created by the shell"
            puts stderr "     design toolkit"
            puts stderr "\nARGUMENTS"
            puts stderr "     -proj_name        (optional) Quartus project name. Required if multiple projects\
                                                are present\n"
            puts stderr "     -update_ocs       (Optional) update the automatic capability structure\n"
            puts stderr "     -qsys_gen         (Optional) generate the Platform Designer systems\n"
            puts stderr "     -sw_compile       (Optional) compile software for all cpu subsystems. Executes\
                                                -qsys_gen beforehand\n"
            puts stderr "     -hw_compile       (Optional) compile hardware. Executes -qsys_gen followed by\
                                                Quartus compile\n"
            puts stderr "     -full_compile     (Optional) compile hardware and software. Executes -sw_compile\
                                                followed by -hw_compile\n"
            puts stderr "     -hps_post         (Optional) Warning: experimental feature - HPS post-processing.\
                                                Split the SOF into core and peripheral files\n"
            puts stderr "     -hps_post_agx     (Optional) Warning: experimental feature - HPS post-processing.\
                                                Split the SOF into core.rbf and .jic from provided"
            puts stderr "                       hps_debug.ihex and u-boot-spl-dtb.hex files\n"
            puts stderr "     -hps_post_agx5e   (Optional) Warning: experimental feature - HPS post-processing.\
                                                Split the SOF into core.rbf and .jic from provided"
            puts stderr "                       u-boot-spl-dtb.hex\n"
            puts stderr "     -update_sof       (Optional) update the SOF without a hardware compile. Executes\
                                                -sw_compile beforehand\n"
            puts stderr "     -archive          (Optional) create a Quartus archive (.qar) using the default\
                                                Quartus fileset\n"
            puts stderr "     -archive_fileset  (Optional) file containing additional fileset to include in Quartus\
                                                archive."
            puts stderr "                       Enables -archive argument\n"
            puts stderr "     -silent_mode      (Optional) disable command line output from script execution timer \n"
            puts stderr "\nSEE ALSO"
            puts stderr "     create_shell.tcl (create_shell)\n\n"
            exit 0
        } trap {CMDLINE ERROR} {msg} {
            post_message -type error ${msg}
            return
        }

        # set flags based on command line arguments
        if {$v_opts_hash(clean_project)} {
            set v_project_clean 1
        }
        if {$v_opts_hash(update_ocs)} {
            set v_update_capability 1
        }
        if {$v_opts_hash(qsys_gen)} {
            set v_pd_generate   1
        }
        if {$v_opts_hash(sw_compile)} {
            set v_sw_compile 1
        }
        if {$v_opts_hash(hw_compile)} {
            set v_pd_generate   1
            set v_hw_compile    1
        }
        if {$v_opts_hash(full_compile)} {
            set v_pd_generate   1
            set v_sw_compile    1
            set v_hw_compile    1
        }
        if {$v_opts_hash(update_sof)} {
            set v_sw_compile 1
            set v_update_sof 1
        }
        if {$v_opts_hash(hps_post)} {
            set v_hps_post   1
        }
        if {$v_opts_hash(hps_post_agx)} {
            set v_hps_post_agx 1
        }
        if {$v_opts_hash(hps_post_agx5e)} {
            set v_hps_post_agx5e 1
        }
        if {$v_opts_hash(silent_mode)} {
            set v_silent_mode 1
        }
        if {$v_opts_hash(archive) || $v_opts_hash(archive_fileset) != ""} {
            set v_archive_project 1
            set v_archive_fileset ""

            # check that the file in the switch exists
            if {$v_opts_hash(archive_fileset) != ""} {

                # use the absolute path of the archive_fileset file
                set v_archive_fileset [file normalize $v_opts_hash(archive_fileset)]

                if {[file exists ${v_archive_fileset}] == 0} {
                    post_message -type error "The file in argument archive_fileset does not exist\
                                              (${v_archive_fileset})"
                    return -code error -errorinfo "The file in argument archive_fileset does not exist\
                                                   (${v_archive_fileset})"
                }
            }
        }

        # if there is no flag set default to a standard build (full_compile)
        if {(${v_project_clean} == 0) && (${v_pd_generate} == 0) && (${v_sw_compile} == 0) &&
            (${v_hw_compile} == 0) && (${v_update_capability} == 0) && (${v_update_sof} == 0) &&
            (${v_hps_post} == 0) && (${v_hps_post_agx} == 0) && (${v_hps_post_agx5e} == 0) &&
            (${v_archive_project} == 0)} {

            set v_pd_generate   1
            set v_sw_compile    1
            set v_hw_compile    1
        }

        # derive project name
        if {$v_opts_hash(proj_name) != ""} {
            ::logging_pkg::gen_log "Info : User specified project name - $v_opts_hash(proj_name)"
            set v_proj_name $v_opts_hash(proj_name)
        }

        if {${v_proj_name}==""} {
            set v_project_list [glob -directory [file join ${v_proj_base_dir} "quartus"] -tail *.qpf]
            set v_num_projects [llength ${v_project_list}]

            if {${v_num_projects}==1} {
                set v_proj_name [string range [lindex ${v_project_list} 0] 0 end-4]
            } elseif {${v_num_projects}==0} {
                post_message -type error "No projects found"
                ::logging_pkg::gen_log "Error : No projects found"
                return
            } elseif {${v_num_projects} > 1} {
                post_message -info "Multiple projects detected, please specify via command line"
                ::logging_pkg::gen_log "Error : Multiple projects detected, please specify via command line"
                return
            }
        }

        # Setup logging
        set v_path [list [file join ${v_proj_base_dir} "quartus" "output_files"] ${v_log_filename}]
        set v_base_log_file [file join {*}${v_path}]

        ::logging_pkg::set_proj_settings ${v_proj_base_dir} ${v_proj_name}
        ::logging_pkg::set_log_file ${v_base_log_file}

        # Open project
        cd [file join ${v_proj_base_dir} "quartus"]

        ::logging_pkg::gen_log "########################################"
        ::logging_pkg::gen_log "# INFO : Create or open ${v_proj_name}.qpf"
        ::logging_pkg::gen_log "########################################"

        # Check that the correct project is open
        if {[is_project_open]} {
            if {[string compare $quartus(project) ${v_proj_name}]} {
                post_message -type error "Another project is currently open, please close and rerun the script"
                ::logging_pkg::gen_log "Another project is currently open, please close and rerun the script"
                return
            }
        } else {
            if {[project_exists ${v_proj_name}]} {
                project_open -revision ${v_proj_name} ${v_proj_name}
            } else {
                post_message -type error "The project (${v_proj_name}) does not exist"
                ::logging_pkg::gen_log "The project (${v_proj_name}) does not exist"
                return
            }
        }

        ::timerOO_pkg::timer create progress_timer ${v_silent_mode}

        # Print local variables
        ::logging_pkg::gen_log "Info : Project Name - ${v_proj_name}"
        ::logging_pkg::gen_log "Info : Script USAGE:"
        ::logging_pkg::gen_log "Info : ${v_usage}"

        set v_result 0

        if {(${v_project_clean} == 1) && (${v_result} == 0)} {
            set v_result [catch {::build_shell::clean_project} result_text result_options]
        }

        if {(${v_update_capability} == 1) && (${v_result} == 0)} {
            set v_result [catch {::build_shell::update_capability_structure} result_text result_options]
        }

        if { (${v_pd_generate} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::qsys_generate} result_text result_options]
        }

        if { (${v_sw_compile} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::sw_compile} result_text result_options]
        }

        cd [file join ${v_proj_base_dir} "quartus"]

        if { (${v_hw_compile} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::hw_compile} result_text result_options]
        }

        if { (${v_update_sof} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::update_sof} result_text result_options]
        }

        if { (${v_hps_post} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::hps_post_process} result_text result_options]
        }

        if { (${v_hps_post_agx} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::hps_post_agx_process} result_text result_options]
        }

        if { (${v_hps_post_agx5e} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::hps_post_agx5e_process} result_text result_options]
        }

        if { (${v_archive_project} == 1) && (${v_result} == 0) } {
            set v_result [catch {::build_shell::archive_project ${v_archive_fileset}} result_text result_options]
        }

        # Cleanup tasks
        progress_timer destroy
        project_close

        if {${v_result}!=0} {
            post_message -type error ${result_text}
            return -code error -errorinfo "${result_text}"
        }

        return

    }

    # Search through the Platform Designer systems, find all ocs compatible ip
    # and update automatic RAM in the ocs subsystem

    proc ::build_shell::update_capability_structure {} {

        variable v_proj_base_dir
        variable v_proj_name

        ::logging_pkg::init_log "Capability Structure" "cap"

        # Setup paths
        set v_pd_project [file join ${v_proj_base_dir} "rtl" "${v_proj_name}_qsys.qsys"]
        set v_q_project  [file join ${v_proj_base_dir} "quartus" ${v_proj_name}]

        set v_proj_ip_search_paths  [get_global_assignment -name IP_SEARCH_PATHS]
        set v_pd_ip_search_paths    [string map {; ,} ${v_proj_ip_search_paths}]
        append v_pd_ip_search_paths "\$"

        # Create arguments (to run the update capability structure script)

        set v_auto_path [file join ${v_proj_base_dir} "scripts" "packages" "capability_structure_pkg"]

        set v_pd_cmd [list "lappend auto_path \"${v_auto_path}\";"\
                           {package require capability_structure_pkg 1.0;}\
                           {::capability_structure_pkg::update_capability_structure;}]
        set v_pd_cmd [join ${v_pd_cmd} " "]

        set v_args [list --system-file=${v_pd_project} --cmd=${v_pd_cmd} --search_path=${v_pd_ip_search_paths}\
                         --quartus-project=${v_q_project}]

        cd [file join ${v_proj_base_dir} "scripts"]

        set v_result [catch {::build_shell::run_quartus_executable "Capability Structure Update"\
                             qsys-script ${v_args}} result_text result_options]
        ::logging_pkg::gen_log ${result_text}

        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Remove generated files from project

    proc ::build_shell::clean_project {} {

        variable v_proj_base_dir
        variable v_proj_name

        cd [file join ${v_proj_base_dir} "quartus"]

        # Execute pre flow script
        set v_result [catch {::build_shell::run_global_assignment_script PRE_FLOW_SCRIPT_FILE clean_project}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute clean (PD & Quartus)
        set v_args   [list --clean ${v_proj_name}]
        set v_result [catch {::build_shell::run_quartus_executable "Clean Project" quartus_sh ${v_args}}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute post flow script
        set v_result [catch {::build_shell::run_global_assignment_script POST_FLOW_SCRIPT_FILE clean_project}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Platform Designer generation

    proc ::build_shell::qsys_generate {} {

        variable v_proj_base_dir
        variable v_proj_name

        cd [file join ${v_proj_base_dir} "quartus"]

        ::logging_pkg::init_log "Generation" "gen"

        # Execute pre flow scripts
        set v_result [catch {::build_shell::run_global_assignment_script PRE_FLOW_SCRIPT_FILE compile}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute Platform Designer generation
        set args [list ${v_proj_name} --generate_project_ip_files --clear_ip_generation_dirs]
        set v_result [catch {::build_shell::run_quartus_executable "Generation" quartus_ipgenerate ${args} 1}\
                             result_text result_options]
        ::logging_pkg::gen_log ${result_text}

        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute post flow script
        set v_result [catch {::build_shell::run_global_assignment_script POST_FLOW_SCRIPT_FILE compile}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Software compile

    proc ::build_shell::sw_compile {} {

        variable v_proj_base_dir

        ::logging_pkg::init_log "Software Build" "sw_build"

        progress_timer start "Running Software Compile Stage"

        # Execute software build
        set v_result   [catch {::software_build_pkg::build_software ${v_proj_base_dir}} result_text result_options]
        set v_duration [progress_timer stop]

        ::logging_pkg::gen_log ${result_text}

        if {${v_result}!=0} {
            puts "\rSoftware Compile Stage - Failed (${v_duration})"
            return -code ${v_result}
        } else {
            puts "\rSoftware Compile Stage - Passed (${v_duration})"
        }

        return

    }

    # Quartus compile (Analysis and Synthesis, Fitter, Timing Analysis, Assembler)

    proc ::build_shell::hw_compile {} {

        variable v_proj_base_dir
        variable v_proj_name

        set v_device  [get_global_assignment -name device]
        set v_tile    [get_part_info -sip_tile ${v_device}]

        # Certain device families require the generation of support logic
        if {${v_tile}=="F-Tile"} {
            # Execute support-logic generation
            set v_result [catch {::build_shell::run_quartus_executable "Support-Logic Generation" quartus_tlg\
                                 ${v_proj_name} 1} result_text result_options]
            if {${v_result}!=0} {
                return -code ${v_result} ${result_text}
            }
        }

        # Execute analysis & synthesis
        set v_result [catch {::build_shell::run_quartus_executable "Analysis & Synthesis" quartus_syn\
                             ${v_proj_name} 1} result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute fitter
        set v_result [catch {::build_shell::run_quartus_executable "Quartus Fitter" quartus_fit ${v_proj_name} 1}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute STA
        set v_result [catch {::build_shell::run_quartus_executable "Quartus STA" quartus_sta ${v_proj_name} 1}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute Assembler
        set v_result [catch {::build_shell::run_quartus_executable "Quartus Assembler" quartus_asm ${v_proj_name} 1}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Execute post flow script
        set v_result [catch {::build_shell::run_global_assignment_script POST_FLOW_SCRIPT_FILE compile}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Update all Nios RAM in the project, and run the assembler to create a new sof.
    # Allows software to be tested without a full hardware compile.

    proc ::build_shell::update_sof {} {

        variable v_proj_base_dir
        variable v_proj_name

        ::logging_pkg::init_log "Update SOF " "update_sof"

        # Update memory contents
        set v_args [list --update_mif ${v_proj_name}]
        set v_result [catch {::build_shell::run_quartus_executable "Update Memory Contents" quartus_cdb ${v_args} 1}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Create SOF
        set v_result [catch {::build_shell::run_quartus_executable "Quartus Assembler" quartus_asm ${v_proj_name} 1}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Generate RBF and ITB files and append to a precompiled HPS U-Boot header file

    proc ::build_shell::hps_post_process {} {

        variable v_proj_base_dir
        variable v_proj_name

        # Generate RBF
        set v_sof_path [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.sof"]
        set v_rbf_path [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.rbf"]

        set v_args [list -c --hps -o bitstream_compression=on ${v_sof_path} ${v_rbf_path}]

        set v_result [catch {::build_shell::run_quartus_executable "Create RBF" quartus_cpf ${v_args} 1}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        # Find pre-compiled HPS U-Boot header
        set v_itb_search_path [file join ${v_proj_base_dir} "scripts" "ext"]
        set v_header_list     [glob -directory ${v_itb_search_path} *.itb.header]
        set v_num_headers     [llength ${v_header_list}]

        if {${v_num_headers} == 0} {
            return -code error "no .itb.header file found in ${v_itb_search_path}"
        } elseif {${v_num_headers} > 1} {
            return -code error "multiple .itb.header files found in ${v_itb_search_path}"
        }

        set v_header_path [lindex ${v_header_list} 0]

        # Copy the ITB header file and append the RBF file in binary format
        set v_itb_path [file join ${v_proj_base_dir} "quartus" "output_files" "fit_spl_fpga.itb"]
        set v_rbf_path [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.periph.rbf"]

        file copy -force ${v_header_path} ${v_itb_path}

        set v_itb_file [open ${v_itb_path} a]
        fconfigure ${v_itb_file} -translation binary

        set v_rbf_file [open ${v_rbf_path} ]
        fconfigure ${v_rbf_file} -translation binary

        fcopy ${v_rbf_file} ${v_itb_file}

        close ${v_rbf_file}
        close ${v_itb_file}

        return

    }

    # Generate RBF and JIC files using prebuilt SOF, (hps_debug).ihex and (u-boot-spl-dtb).hex files
    # .ihex - HPS debug first stage bootloader
    # .hex  - U-Boot secondary program loader

    proc ::build_shell::hps_post_agx_process {} {

        variable v_proj_base_dir
        variable v_proj_name

        # Find ihex file
        set v_ihex_search_path [file join ${v_proj_base_dir} "scripts" "ext"]
        set v_ihex_list        [glob -directory ${v_ihex_search_path} *.ihex]
        set v_num_ihex         [llength ${v_ihex_list}]

        if {${v_num_ihex} == 0} {
            return -code error "no .ihex file found in ${v_ihex_search_path}"
        } elseif {${v_num_ihex} > 1} {
            return -code error "multiple .ihex files found in ${v_ihex_search_path}"
        }

        set v_ihex_path [lindex ${v_ihex_list} 0]

        # Generate RBF
        set v_sof_path [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.sof"]
        set v_jic_path [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.jic"]

        set v_args_rbf [list -c ${v_sof_path} ${v_jic_path} -o hps_path=${v_ihex_path} -o device=MT25QU02G\
                             -o flash_loader=AGFB014R24B2E2V -o mode=ASX4 -o hps=1]

        set v_result [catch {::build_shell::run_quartus_executable "Create RBF" quartus_pfg ${v_args_rbf} 1}\
                             result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }
        file delete -force -- [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.hps.jic"]

        # Find HPS U-Boot SPL
        set v_hex_search_path [file join ${v_proj_base_dir} "scripts" "ext"]
        set v_hex_list        [glob -directory ${v_hex_search_path} *.hex]
        set v_num_hex         [llength ${v_hex_list}]

        if {${v_num_hex} == 0} {
            return -code error "no .hex file found in ${v_hex_search_path}"
        } elseif {${v_num_hex} > 1} {
            return -code error "multiple .hex files found in ${v_hex_search_path}"
        }

        set v_hex_path [lindex ${v_hex_list} 0]

        # Generate JIC
        set v_args_jic [list -c ${v_sof_path} ${v_jic_path} -o hps_path=${v_hex_path} -o device=MT25QU02G\
                             -o flash_loader=AGFB014R24B2E2V -o mode=ASX4 -o hps=1]

        set v_result [catch {::build_shell::run_quartus_executable "Create JIC (for QSPI programming)" quartus_pfg\
                             ${v_args_jic} 1} result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Generate RBF and JIC using prebuilt SOF and (u-boot-spl-dtb).hex file
    # .hex  - U-Boot secondary program loader

    proc ::build_shell::hps_post_agx5e_process {} {

        variable v_proj_base_dir
        variable v_proj_name

        # Find HPS U-Boot SPL
        set v_hex_search_path [file join ${v_proj_base_dir} "scripts" "ext"]
        set v_hex_list        [glob -directory ${v_hex_search_path} *.hex]
        set v_num_hex         [llength ${v_hex_list}]

        if {${v_num_hex} == 0} {
            return -code error "no .hex file found in ${v_hex_search_path}"
        } elseif {${v_num_hex} > 1} {
            return -code error "multiple .hex files found in ${v_hex_search_path}"
        }

        set v_hex_path [lindex ${v_hex_list} 0]

        # Generate RBF and JIC
        set v_sof_path [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.sof"]
        set v_jic_path [file join ${v_proj_base_dir} "quartus" "output_files" "${v_proj_name}.hps_first.jic"]

        set v_args [list -c ${v_sof_path} ${v_jic_path} -o hps_path=${v_hex_path} -o device=MT25QU02G\
                         -o flash_loader=A5ED065BB32AE6SR0 -o mode=ASX4 -o hps=1]

        set v_result [catch {::build_shell::run_quartus_executable "Create RBF and JIC (for QSPI programming)"\
                             quartus_pfg ${v_args} 1} result_text result_options]
        if {${v_result}!=0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Create a Quartus archive file (.qar)

    proc ::build_shell::archive_project {archive_fileset} {

        variable v_proj_base_dir
        variable v_proj_name

        ::logging_pkg::init_log "QAR Create" "qar_create"

        progress_timer start "Running Qar Create Stage"
        set v_result [catch {::archive_pkg::create_archive ${v_proj_base_dir} ${v_proj_name} ${archive_fileset}}\
                             result_text result_options]
        set v_duration [progress_timer stop]

        ::logging_pkg::gen_log ${result_text}

        if {${v_result}!=0} {
            puts "\rQar Create Stage - Failed (${v_duration})"
            return -code ${v_result} ${result_text}
        } else {
            puts "\rQar Create Stage - Passed (${v_duration})"
        }

        return

    }

    # Run Quartus global assignment scripts. The following assignments are supported:
    # - PRE_FLOW_SCRIPT_FILE
    # - POST_FLOW_SCRIPT_FILE
    # - POST_MODULE_SCRIPT_FILE

    proc ::build_shell::run_global_assignment_script {assignment_name module} {

        variable v_proj_base_dir
        variable v_proj_name

        if {(${assignment_name}!="PRE_FLOW_SCRIPT_FILE")    &&
            (${assignment_name}!="POST_MODULE_SCRIPT_FILE") &&
            (${assignment_name}!="POST_FLOW_SCRIPT_FILE")   } {
                return -code error "Invalid assignment name ${assignment_name}"
        }

        set v_assignment_value [get_global_assignment -name ${assignment_name}]

        if {${v_assignment_value}!=""} {

            # format the assignment name for debug purposes
            set v_short_name  [string tolower [string range ${assignment_name} 0 end-5]]
            set v_title_name  [string totitle [string map {"_" " "} ${v_short_name}]]

            # split the assignment value
            set v_split_value [split ${v_assignment_value} ":"]
            set v_executable  [lindex ${v_split_value} 0]
            set v_script      [lindex ${v_split_value} 1]

            # change the log file
            set v_curr_logfile  [::logging_pkg::get_log_file]
            ::logging_pkg::set_log_file [file join ${v_proj_base_dir} "quartus" "output_files"\
                                                   "${v_proj_name}.${v_short_name}.${module}.rpt"]

            # Execute script
            set v_args [list -t ${v_script} ${module} ${v_proj_name}]
            set v_result [catch {::build_shell::run_quartus_executable ${v_title_name} ${v_executable} ${v_args} 0}\
                                 result_text result_options]
            ::logging_pkg::gen_log ${result_text}

            # revert to previous log file
            ::logging_pkg::set_log_file ${v_curr_logfile}

            if {${v_result}!=0} {
                return -code ${v_result} ${result_text}
            }

        }

        return

    }

    # Run a Quartus executable and post module script (if enabled)

    proc ::build_shell::run_quartus_executable {title exe args {post 0}} {

        variable v_proj_base_dir
        variable v_proj_name

        set v_cmd [list {*}${exe} {*}${args}]

        progress_timer start "Running ${title}"
        set v_result   [catch {exec -ignorestderr -- {*}${v_cmd} 2>@1} result_text result_options ]
        set v_duration [progress_timer stop]

        if {${v_result}!=0} {
            puts "\r${title} - Failed (${v_duration})"
            return -code ${v_result} ${result_text}
        } else {
            puts "\r${title} Stage - Passed (${v_duration})"
        }

        # Post module script execution
        if {${post}} {
            set v_post_result [catch {::build_shell::run_global_assignment_script POST_MODULE_SCRIPT_FILE ${exe}}\
                                      post_result_text post_result_options]
            if {${v_post_result}!=0} {
                return -code ${v_post_result} "POST_MODULE_SCRIPT_FILE evaluation failed"
            }
        }

        return -code ${v_result} ${result_text}

    }

}

set v_result [catch {::build_shell::main} result_text result_options]
if {$v_result != 0} {
    post_message -type error "${result_text}"
    qexit -error
} else {
    qexit -success
}
