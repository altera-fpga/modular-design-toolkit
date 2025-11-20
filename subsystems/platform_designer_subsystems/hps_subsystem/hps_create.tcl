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

# create script specific parameters and default values

# shell parameters required for software manager
set_shell_parameter APPLICATION_DIR             {}
set_shell_parameter CUSTOM_CMAKEFILE            0
set_shell_parameter CUSTOM_MAKEFILE             0

# shell parameters required to connect the FPGA RAM to the HPS
set_shell_parameter FPGA_EMIF_ENABLED           {0}
# valid option: 0x4000
set_shell_parameter FPGA_EMIF_CTRL_BASE_ADDRESS {0x0000}
# valid option: 31
set_shell_parameter FPGA_EMIF_HOST_ADDR_WIDTH   {0}
# valid option: 27
set_shell_parameter FPGA_EMIF_AGENT_ADDR_WIDTH  {0}

# NONE / auto
set_shell_parameter AVMM_HOST                   {}

# LIGHT / FULL / BOTH
set_shell_parameter H2F_EXPORT                  {LIGHT}
# 0 / 1
set_shell_parameter H2F_IS_AXI                  {0}
# 0 / 1
set_shell_parameter H2F_LW_IS_AXI               {0}

# 0 : 31
set_shell_parameter NUM_GPO                     {0}
# 0 : 31
set_shell_parameter NUM_GPI                     {0}


# define the procedures used by the create_subsystems_qsys.tcl script

set v_board_name        [get_shell_parameter DEVKIT]
set v_device_name       [get_shell_parameter DEVICE]
set v_family_name       [get_shell_parameter FAMILY]
set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]

if {${v_board_name} == "A10_660_DEVKIT"} {
  source ${v_shell_design_root}/hps_subsystem/variants/arria10/hps_create.tcl
} elseif {(${v_board_name} == "AGX_FM87_DEVKIT") || (${v_board_name} == "AGX_7F_XCVR-SoC_DEVKIT")} {
  source ${v_shell_design_root}/hps_subsystem/variants/agilex_i_series/hps_create.tcl
} elseif {(${v_board_name} == "AGX_5E_Si_Devkit") || (${v_board_name} == "AGX_5E_Modular_Devkit")} {
  source ${v_shell_design_root}/hps_subsystem/variants/agilex_5e_si/hps_create.tcl
} elseif {${v_board_name} == "AGX_5E_ARROW_Eagle_Devkit"} {
  source ${v_shell_design_root}/hps_subsystem/variants/agilex_5e_arrow_eagle/hps_create.tcl
} elseif {${v_board_name} == "AGX_5E_MACNICA_Sulfur_Devkit"} {
  source ${v_shell_design_root}/hps_subsystem/variants/agilex_5e_macnica_sulfur/hps_create.tcl
} elseif {${v_board_name} == "AGX_5E_TERASIC_DE25_Devkit"} {
  source ${v_shell_design_root}/hps_subsystem/variants/agilex_5e_terasic_de25/hps_create.tcl
} elseif {${v_board_name} == "AGX_3C_Devkit"} {
  source ${v_shell_design_root}/hps_subsystem/variants/agilex_3c_si/hps_create.tcl
} else {
  return -code error "devkit ${v_board_name} not supported (HPS Subsystem)"
}
