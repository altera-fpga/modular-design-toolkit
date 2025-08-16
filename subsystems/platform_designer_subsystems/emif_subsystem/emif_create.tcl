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

# Valid option NONE / auto
set_shell_parameter AVMM_HOST  {}
# Valid option fpga / hps
set_shell_parameter PORT       {}
set_shell_parameter DDR_PRESET {}

# define the procedures used by the create_subsystems_qsys.tcl script

set v_board_name          [get_shell_parameter DEVKIT]
set v_shell_design_root   [get_shell_parameter SHELL_DESIGN_ROOT]

if {${v_board_name} == "A10_1150_DEVKIT"} {
    source ${v_shell_design_root}/emif_subsystem/variants/arria10/emif_a10_create.tcl
} elseif {${v_board_name} == "A10_660_DEVKIT"} {
    source ${v_shell_design_root}/emif_subsystem/variants/arria10/emif_a10_create.tcl
} elseif {${v_board_name} == "AGX_FM87_DEVKIT"} {
    source ${v_shell_design_root}/emif_subsystem/variants/agilex_i_series/emif_agx_create.tcl
} elseif {${v_board_name} == "AGX_7F_XCVR-SoC_DEVKIT"} {
    source ${v_shell_design_root}/emif_subsystem/variants/agilex_i_series/emif_agx_create.tcl
} elseif {${v_board_name} == "AGX_5E_Si_Devkit"} {
    source ${v_shell_design_root}/emif_subsystem/variants/agilex_5E_Si_Devkit/emif_agx_create.tcl
} elseif {${v_board_name} == "AGX_5E_Modular_Devkit"} {
    source ${v_shell_design_root}/emif_subsystem/variants/AGX_5E_Modular_Devkit/emif_agx_create.tcl
} elseif {${v_board_name} == "AGX_5E_ARROW_Eagle_Devkit"} {
    source ${v_shell_design_root}/emif_subsystem/variants/AGX_5E_ARROW_Eagle_Devkit/emif_agx_create.tcl
} elseif {${v_board_name} == "AGX_5E_MACNICA_Sulfur_Devkit"} {
    source ${v_shell_design_root}/emif_subsystem/variants/AGX_5E_MACNICA_Sulfur_Devkit/emif_agx_create.tcl
} else {
    send_message ERROR "devkit ${v_board_name} not supported"
}
