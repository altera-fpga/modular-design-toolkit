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

# define the procedures used by the create_subsystems_qsys.tcl script

set_shell_parameter CPU_SUBSYSTEM_TYPE  {}

# simple, full, (watchdog not supported)
set_shell_parameter TIMER_TYPE          {simple}
set_shell_parameter TIMER_PERIOD        {1}
# USEC, MSEC, SEC, CLOCKS
set_shell_parameter TIMER_UNITS         {MSEC}

# common shell parameters for all soft cpu cores

set_shell_parameter BSP_TYPE            "hal"
set_shell_parameter BSP_SETTINGS_FILE   {}
set_shell_parameter APPLICATION_DIR     {}
set_shell_parameter CUSTOM_CMAKEFILE    0
set_shell_parameter CUSTOM_MAKEFILE     0

set_shell_parameter IRQ_PRIORITY        ""

proc subsystem_init {} {

  # derive parameters

  set v_timer_type [get_shell_parameter TIMER_TYPE]

  if {${v_timer_type} == "simple"} {
    set_shell_parameter DRV_TIMER_PRESET "Simple periodic interrupt"
  } elseif {${v_timer_type} == "full"} {
    set_shell_parameter DRV_TIMER_PRESET "Full-featured"
  } else {
    post_message -type error "CPU subsystem timer type ${v_timer_type} not supported"
    exit -1
  }

  # source variant script

  set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]
  set v_cpu_ss_type       [get_shell_parameter CPU_SUBSYSTEM_TYPE]

  if {${v_cpu_ss_type} == "dniosii"} {
    source ${v_shell_design_root}/cpu_subsystem/variants/dniosii/dniosii_create.tcl
  } elseif {${v_cpu_ss_type} == "niosii"} {
    source ${v_shell_design_root}/cpu_subsystem/variants/niosii/niosii_create.tcl
  } elseif {${v_cpu_ss_type} == "niosv"} {
    source ${v_shell_design_root}/cpu_subsystem/variants/niosv/niosv_create.tcl
  } elseif {${v_cpu_ss_type} == "dniosvg"} {
    source ${v_shell_design_root}/cpu_subsystem/variants/dniosvg/dniosvg_create.tcl
  } else {
    return -code error "CPU subsystem type ${v_cpu_ss_type} not supported"
  }

}
