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

# create script specific parameters and default values

set_shell_parameter USER_LED_TO_AVMM_EN     {0}
set_shell_parameter USER_PB_TO_AVMM_EN      {0}
set_shell_parameter USER_DIP_SW_TO_AVMM_EN  {0}

set_shell_parameter AVMM_HOST {{auto X}}

# define the procedures used by the create_subsystems_qsys.tcl script

set v_board_name        [get_shell_parameter DEVKIT]
set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]

if {${v_board_name} == "A10_1150_DEVKIT"} {
    source ${v_shell_design_root}/board_subsystem/boards/A10_1150_Devkit/board_create.tcl
} elseif {${v_board_name} == "A10_660_DEVKIT"} {
    source ${v_shell_design_root}/board_subsystem/boards/A10_660_Devkit/board_create.tcl
} elseif {${v_board_name} == "AGX_FM87_DEVKIT"} {
    source ${v_shell_design_root}/board_subsystem/boards/AGX_FM87_Devkit/board_create.tcl
} elseif {${v_board_name} == "AGX_7F_XCVR-SoC_DEVKIT"} {
    source ${v_shell_design_root}/board_subsystem/boards/AGX_7F_XCVR-SoC_Devkit/board_create.tcl
} elseif {${v_board_name} == "AGX_5E_Modular_Devkit"} {
    source ${v_shell_design_root}/board_subsystem/boards/AGX_5E_Modular_Devkit/board_create.tcl
} elseif {${v_board_name} == "AGX_5E_Si_Devkit"} {
    source ${v_shell_design_root}/board_subsystem/boards/AGX_5E_Si_Devkit/board_create.tcl
} elseif {${v_board_name} == "AGX_5E_ARROW_Eagle_Devkit"} {
    source ${v_shell_design_root}/board_subsystem/boards/AGX_5E_ARROW_Eagle_Devkit/board_create.tcl
} elseif {${v_board_name} == "AGX_5E_MACNICA_Sulfur_Devkit"} {
    source ${v_shell_design_root}/board_subsystem/boards/AGX_5E_MACNICA_Sulfur_Devkit/board_create.tcl
} else {
    send_message ERROR "devkit ${v_board_name} not supported"
}

