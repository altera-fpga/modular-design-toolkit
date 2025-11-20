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

# parameter to allow subsystem to be dummy/blank (enables the board subsystem to enable DDR4 without EMIF)
set_shell_parameter DUMMY           {0}

# if non-zero, enables an async clock input to EMIF for the user
set_shell_parameter ASYNC_CLK       {0}

set_shell_parameter AVMM_EN         {0}

set_shell_parameter BANK_2B_ECC_EN  {0}


# resolve interdependencies
proc derive_parameters {param_array} {
    set v_port      [get_shell_parameter PORT]
    set v_async_clk [get_shell_parameter ASYNC_CLK]

    upvar ${param_array} p_array

    # convert the port name to a consistent internal scheme
    # note that valid port names as follows are valid for this board:
    # BANK_2B, FPGA_2B; BANK_3A, HPS; BANK_3B, FPGA_3B
    if {${v_port} == "HPS"} {
        set v_port  BANK_3A
    } elseif {${v_port} == "FPGA_2B"} {
        set v_port  BANK_2B
    } elseif {${v_port} == "FPGA_3B"} {
        set v_port  BANK_3B
    }
    set_shell_parameter DRV_PORT    ${v_port}

    # Find subsystem with matching DDR memory interface port and save the preset
    # note : it is assumed that the DDR preset file is copied by the
    #        board subsystem or DRR DIMM addon before the creation stage
    set v_emif_subsystems {}

    for {set id 0} {$id < $p_array(project,id)} {incr id} {
        # Get DDR presets from board subsystem (DDR is soldered)
        if {$p_array($id,type) == "board"} {
            set params $p_array($id,params)

            foreach v_pair ${params} {
                set v_name  [lindex ${v_pair} 0]
                set v_value [lindex ${v_pair} 1]
                set v_temp_array(${v_name}) ${v_value}
            }

            if {[info exists v_temp_array(DDR4_PRESET_${v_port}_FILE)]} {
                set_shell_parameter DDR_PRESET_FILE $v_temp_array(DDR4_PRESET_${v_port}_FILE)
            } else {
                send_message ERROR "EMIF_subsystem: cannot find DDR preset file"
            }

            if {[info exists v_temp_array(DDR4_PRESET_${v_port})]} {
                set_shell_parameter DDR_PRESET $v_temp_array(DDR4_PRESET_${v_port})
            } else {
                send_message ERROR "EMIF_subsystem: cannot find DDR preset"
            }
        }

        # Get instantiated EMIF subsystems to generate unique instance ids
        if {$p_array($id,type) == "emif"} {
            set params $p_array($id,params)

            foreach v_pair ${params} {
                set v_name  [lindex ${v_pair} 0]
                set v_value [lindex ${v_pair} 1]
                set v_temp_array(${v_name}) ${v_value}
            }

            if {[info exists v_temp_array(INSTANCE_NAME)]} {
                lappend v_emif_subsystems $v_temp_array(INSTANCE_NAME)
            }
        }
    }

    set_shell_parameter DRV_EMIF_SUBSYSTEMS ${v_emif_subsystems}

    if {${v_async_clk} != 0} {
        set_shell_parameter DRV_ASYNC_CLK_EN {1}
    } else {
        set_shell_parameter DRV_ASYNC_CLK_EN {0}
    }
}

# define the procedures used by the create_subsystems_qsys.tcl script

proc creation_step {} {
    set v_dummy [get_shell_parameter DUMMY]

    if {${v_dummy} == 0} {
        create_emif_subsystem
    }
}

proc post_creation_step {} {
    set v_dummy [get_shell_parameter DUMMY]

    if {${v_dummy} == 0} {
        edit_top_level_qsys
        add_auto_connections
        edit_top_v_file
    }
}

# create the emif subsystem
proc create_emif_subsystem {} {
    set v_project_path    [get_shell_parameter PROJECT_PATH]
    set v_instance_name   [get_shell_parameter INSTANCE_NAME]
    set v_port            [get_shell_parameter DRV_PORT]
    set v_async_clk_en    [get_shell_parameter DRV_ASYNC_CLK_EN]
    set v_avmm_en         [get_shell_parameter AVMM_EN]
    set v_bank_2b_ecc_en  [get_shell_parameter BANK_2B_ECC_EN]

    create_system ${v_instance_name}
    save_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys


    ############################
    #### Add Instances      ####
    ############################

    add_instance cal_clk_bridge   altera_clock_bridge
    add_instance cal_rst_bridge   altera_reset_bridge
    add_instance ddr4_emif        emif_io96b_ddr4comp
    add_instance ddr4_cal         emif_ph2_axil_driver
    if {${v_avmm_en}} {
        add_instance ddr4_clk_bridge  altera_clock_bridge
        add_instance ddr4_rst_bridge  altera_reset_bridge
        add_instance ddr4_mm_bridge   altera_avalon_mm_bridge
    }


    ############################
    #### Set Parameters     ####
    ############################

    set_instance_parameter_value    cal_clk_bridge    NUM_CLOCK_OUTPUTS   {1}

    set_instance_parameter_value    cal_rst_bridge    NUM_RESET_OUTPUTS   {1}

    if {${v_avmm_en}} {
        set_instance_parameter_value    ddr4_clk_bridge   NUM_CLOCK_OUTPUTS         {1}

        set_instance_parameter_value    ddr4_rst_bridge   NUM_RESET_OUTPUTS         {1}

        set_instance_parameter_value    ddr4_mm_bridge    SYNC_RESET                {0}
        set_instance_parameter_value    ddr4_mm_bridge    DATA_WIDTH                {256}
        set_instance_parameter_value    ddr4_mm_bridge    SYMBOL_WIDTH              {8}
        set_instance_parameter_value    ddr4_mm_bridge    ADDRESS_WIDTH             {0}
        set_instance_parameter_value    ddr4_mm_bridge    USE_AUTO_ADDRESS_WIDTH    {1}
        set_instance_parameter_value    ddr4_mm_bridge    ADDRESS_UNITS             {SYMBOLS}
        set_instance_parameter_value    ddr4_mm_bridge    MAX_BURST_SIZE            {64}
        set_instance_parameter_value    ddr4_mm_bridge    LINEWRAPBURSTS            {0}
        set_instance_parameter_value    ddr4_mm_bridge    MAX_PENDING_RESPONSES     {64}
        set_instance_parameter_value    ddr4_mm_bridge    MAX_PENDING_WRITES        {0}
        set_instance_parameter_value    ddr4_mm_bridge    PIPELINE_COMMAND          {1}
        set_instance_parameter_value    ddr4_mm_bridge    PIPELINE_RESPONSE         {1}
        set_instance_parameter_value    ddr4_mm_bridge    USE_RESPONSE              {0}
        set_instance_parameter_value    ddr4_mm_bridge    USE_WRITERESPONSE         {0}
    }

    set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_MARGIN                         {0}
    set_instance_parameter_value    ddr4_emif     ANALOG_PARAM_DERIVATION_PARAM_NAME            {}
    set_instance_parameter_value    ddr4_emif     CTRL_AUTO_PRECHARGE_EN                        {0}
    set_instance_parameter_value    ddr4_emif     CTRL_DM_EN                                    {1}
    set_instance_parameter_value    ddr4_emif     CTRL_PERFORMANCE_PROFILE                      {default}
    set_instance_parameter_value    ddr4_emif     CTRL_RD_DBI_EN                                {0}
    set_instance_parameter_value    ddr4_emif     CTRL_SCRAMBLER_EN                             {0}
    set_instance_parameter_value    ddr4_emif     CTRL_WR_DBI_EN                                {0}
    set_instance_parameter_value    ddr4_emif     DEBUG_TOOLS_EN                                {0}
    set_instance_parameter_value    ddr4_emif     DIAG_EXTRA_PARAMETERS                         {}
    set_instance_parameter_value    ddr4_emif     DIAG_HMC_ADDR_SWAP_EN                         {0}
    set_instance_parameter_value    ddr4_emif     EMIF_INST_NAME                                {}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_GEN_CDC                             {0}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_GEN_SIM                             {1}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_GEN_SYNTH                           {1}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_HDL_FORMAT                          {VERILOG}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_NOC_PLL_REFCLK_FREQ_MHZ             {100}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_PMON_CH0_EN                         {0}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_PMON_INTERNAL_JAMB_EN               {1}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_TG_CSR_ACCESS_MODE                  {JTAG}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_TG_PROGRAM                          {MEDIUM}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_USER_PLL_OUTPUT_FREQ_MHZ            {200.0}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_USER_PLL_OUTPUT_FREQ_MHZ_AUTOSET_EN {1}
    set_instance_parameter_value    ddr4_emif     EX_DESIGN_USER_PLL_REFCLK_FREQ_MHZ            {100.0}
    set_instance_parameter_value    ddr4_emif     HPS_EMIF_RZQ_SHARING                          {0}
    set_instance_parameter_value    ddr4_emif     INSTANCE_ID                                   {0}
    set_instance_parameter_value    ddr4_emif     IS_HPS                                        {0}
    set_instance_parameter_value    ddr4_emif     JEDEC_OVERRIDE_TABLE_PARAM_NAME {MEM_CL_CYC MEM_CWL_CYC MEM_TRFC_NS MEM_TRFC_DLR_NS MEM_TRRD_DLR_NS MEM_TFAW_DLR_NS MEM_TCCD_DLR_NS}
    set_instance_parameter_value    ddr4_emif     MEM_AC_MIRRORING_EN                           {0}
    set_instance_parameter_value    ddr4_emif     MEM_AC_PARITY_EN                              {0}
    set_instance_parameter_value    ddr4_emif     MEM_AC_PARITY_LATENCY_MODE                    {0.0}
    set_instance_parameter_value    ddr4_emif     MEM_AL_CYC                                    {0.0}
    set_instance_parameter_value    ddr4_emif     MEM_CHANNEL_CS_WIDTH                          {1}
    set_instance_parameter_value    ddr4_emif     MEM_CHANNEL_DATA_DQ_WIDTH                     {32}
    set_instance_parameter_value    ddr4_emif     MEM_CLAMSHELL_EN                              {0}
    set_instance_parameter_value    ddr4_emif     MEM_CL_CYC                                    {12.0}
    set_instance_parameter_value    ddr4_emif     MEM_CWL_CYC                                   {11.0}
    set_instance_parameter_value    ddr4_emif     MEM_DIE_DENSITY_GBITS                         {16}
    set_instance_parameter_value    ddr4_emif     MEM_DIE_DQ_WIDTH                              {8}
    set_instance_parameter_value    ddr4_emif     MEM_DQ_VREF                                   {35}
    set_instance_parameter_value    ddr4_emif     MEM_FINE_GRANULARITY_REFRESH_MODE             {1.0}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_DQ_X_IDLE                             {off}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_DQ_X_NON_TGT_RD                       {off}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_DQ_X_NON_TGT_WR                       {off}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_DQ_X_RON                              {7}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_DQ_X_TGT_WR                           {4}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_NOM                                   {off}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_PARK                                  {4}
    set_instance_parameter_value    ddr4_emif     MEM_ODT_WR                                    {off}
    set_instance_parameter_value    ddr4_emif     MEM_OPERATING_FREQ_MHZ                        {800}
    set_instance_parameter_value    ddr4_emif     MEM_OPERATING_FREQ_MHZ_AUTOSET_EN             {1}
    set_instance_parameter_value    ddr4_emif     MEM_PAGE_SIZE                                 {1024.0}
    set_instance_parameter_value    ddr4_emif     MEM_RANKS_SHARE_CK_EN                         {0}
    set_instance_parameter_value    ddr4_emif     MEM_RD_PREAMBLE_MODE                          {1.0}
    set_instance_parameter_value    ddr4_emif     MEM_SPEEDBIN                                  {3200AA}
    set_instance_parameter_value    ddr4_emif     MEM_TCCD_DLR_NS                               {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TCCD_L_NS                                 {6.25}
    set_instance_parameter_value    ddr4_emif     MEM_TCCD_S_NS                                 {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TCKESR_CYC                                {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TCKE_NS                                   {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TCKSRE_NS                                 {10.0}
    set_instance_parameter_value    ddr4_emif     MEM_TCKSRX_NS                                 {10.0}
    set_instance_parameter_value    ddr4_emif     MEM_TCK_CL_CWL_MAX_NS                         {1.5}
    set_instance_parameter_value    ddr4_emif     MEM_TCK_CL_CWL_MIN_NS                         {1.25}
    set_instance_parameter_value    ddr4_emif     MEM_TCPDED_NS                                 {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TDQSCK_MAX_MIN_NS                         {0.16}
    set_instance_parameter_value    ddr4_emif     MEM_TDQSCK_NS                                 {0.0}
    set_instance_parameter_value    ddr4_emif     MEM_TDQSS_CYC                                 {0.0}
    set_instance_parameter_value    ddr4_emif     MEM_TDSH_NS                                   {0.225}
    set_instance_parameter_value    ddr4_emif     MEM_TDSS_NS                                   {0.225}
    set_instance_parameter_value    ddr4_emif     MEM_TFAW_DLR_NS                               {20.0}
    set_instance_parameter_value    ddr4_emif     MEM_TFAW_NS                                   {25.0}
    set_instance_parameter_value    ddr4_emif     MEM_TIH_NS                                    {65000.0}
    set_instance_parameter_value    ddr4_emif     MEM_TIS_NS                                    {40000.0}
    set_instance_parameter_value    ddr4_emif     MEM_TMOD_NS                                   {30.0}
    set_instance_parameter_value    ddr4_emif     MEM_TMPRR_NS                                  {1.25}
    set_instance_parameter_value    ddr4_emif     MEM_TMRD_NS                                   {10.0}
    set_instance_parameter_value    ddr4_emif     MEM_TQSH_NS                                   {0.5}
    set_instance_parameter_value    ddr4_emif     MEM_TRAS_MAX_NS                               {70200.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRAS_MIN_NS                               {32.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRAS_NS                                   {32.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRCD_NS                                   {13.75}
    set_instance_parameter_value    ddr4_emif     MEM_TRC_NS                                    {45.75}
    set_instance_parameter_value    ddr4_emif     MEM_TREFI_NS                                  {7800.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRFC_DLR_NS                               {190.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRFC_NS                                   {350.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRP_NS                                    {13.75}
    set_instance_parameter_value    ddr4_emif     MEM_TRRD_DLR_NS                               {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRRD_L_NS                                 {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRRD_S_NS                                 {5.0}
    set_instance_parameter_value    ddr4_emif     MEM_TRTP_NS                                   {7.5}
    set_instance_parameter_value    ddr4_emif     MEM_TWLH_NS                                   {0.1625}
    set_instance_parameter_value    ddr4_emif     MEM_TWLS_NS                                   {0.1625}
    set_instance_parameter_value    ddr4_emif     MEM_TWR_CRC_DM_NS                             {6.25}
    set_instance_parameter_value    ddr4_emif     MEM_TWR_NS                                    {15.0}
    set_instance_parameter_value    ddr4_emif     MEM_TWTR_L_CRC_DM_NS                          {6.25}
    set_instance_parameter_value    ddr4_emif     MEM_TWTR_L_NS                                 {7.5}
    set_instance_parameter_value    ddr4_emif     MEM_TWTR_S_CRC_DM_NS                          {6.25}
    set_instance_parameter_value    ddr4_emif     MEM_TWTR_S_NS                                 {2.5}
    set_instance_parameter_value    ddr4_emif     MEM_TXP_NS                                    {6.0}
    set_instance_parameter_value    ddr4_emif     MEM_TXS_DLL_NS                                {1280.0}
    set_instance_parameter_value    ddr4_emif     MEM_TXS_NS                                    {360.0}
    set_instance_parameter_value    ddr4_emif     MEM_TZQCS_NS                                  {160.0}
    set_instance_parameter_value    ddr4_emif     MEM_TZQINIT_CYC                               {1024.0}
    set_instance_parameter_value    ddr4_emif     MEM_TZQOPER_CYC                               {512.0}
    set_instance_parameter_value    ddr4_emif     MEM_VREF_DQ_X_RANGE                           {2}
    set_instance_parameter_value    ddr4_emif     MEM_VREF_DQ_X_VALUE                           {67.75}
    set_instance_parameter_value    ddr4_emif     MEM_WR_CRC_EN                                 {0.0}
    set_instance_parameter_value    ddr4_emif     MEM_WR_PREAMBLE_MODE                          {1.0}
    set_instance_parameter_value    ddr4_emif     PHY_AC_PLACEMENT                              {BOT}
    set_instance_parameter_value    ddr4_emif     PHY_ALERT_N_PLACEMENT                         {AC2}
    set_instance_parameter_value    ddr4_emif     PHY_FORCE_MIN_4_AC_LANES_EN                   {0}
    set_instance_parameter_value    ddr4_emif     PHY_MAINBAND_ACCESS_MODE                      {SYNC}
    set_instance_parameter_value    ddr4_emif     PHY_MAINBAND_ACCESS_MODE_AUTOSET_EN           {0}
    set_instance_parameter_value    ddr4_emif     PHY_REFCLK_ADVANCED_SELECT_EN                 {0}
    set_instance_parameter_value    ddr4_emif     PHY_REFCLK_FREQ_MHZ                           {150.0}
    set_instance_parameter_value    ddr4_emif     PHY_REFCLK_FREQ_MHZ_AUTOSET_EN                {0}
    set_instance_parameter_value    ddr4_emif     PHY_SIDEBAND_ACCESS_MODE                      {FABRIC}
    set_instance_parameter_value    ddr4_emif     PHY_SIDEBAND_ACCESS_MODE_AUTOSET_EN           {1}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_AC_OUTPUT_IO_STD_TYPE              {SSTL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_CK_OUTPUT_IO_STD_TYPE              {DF_SSTL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_CS_OUTPUT_IO_STD_TYPE              {SSTL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_DQS_IO_STD_TYPE                    {DF_POD}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_DQ_IO_STD_TYPE                     {POD}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_DQ_SLEW_RATE                       {FASTEST}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_DQ_VREF                            {68.3}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_GPIO_IO_STD_TYPE                   {LVCMOS}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_REFCLK_IO_STD_TYPE                 {TRUE_DIFF}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_R_S_AC_OUTPUT_OHM                  {SERIES_34_OHM_CAL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_R_S_CK_OUTPUT_OHM                  {SERIES_34_OHM_CAL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_R_S_CS_OUTPUT_OHM                  {SERIES_34_OHM_CAL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_R_S_DQ_OUTPUT_OHM                  {SERIES_34_OHM_CAL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_R_T_DQ_INPUT_OHM                   {RT_50_OHM_CAL}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_R_T_GPIO_INPUT_OHM                 {RT_OFF}
    set_instance_parameter_value    ddr4_emif     PHY_TERM_X_R_T_REFCLK_INPUT_OHM               {RT_DIFF}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_R2R_DIFFCS_CYC                     {0}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_R2R_SAMECS_CYC                     {0}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_R2W_DIFFCS_CYC                     {0}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_R2W_SAMECS_CYC                     {0}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_W2R_DIFFCS_CYC                     {0}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_W2R_SAMECS_CYC                     {0}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_W2W_DIFFCS_CYC                     {0}
    set_instance_parameter_value    ddr4_emif     TURNAROUND_W2W_SAMECS_CYC                     {0}

    if {${v_port} == "BANK_2B"} {
        if {${v_bank_2b_ecc_en} == 1} {
            set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_REQ {1}
            set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_WEQ {1}
            set_instance_parameter_value    ddr4_emif     CTRL_ECC_AUTOCORRECT_EN {1}
            set_instance_parameter_value    ddr4_emif     MEM_CHANNEL_ECC_DQ_WIDTH {8}
            set v_extra_params  "BYTE_SWIZZLE_CH0=1,X,X,X,0,2,3,ECC; \
                                                              PIN_SWIZZLE_CH0_DQS3=31,29,27,25,26,30,24,28; \
                                                              PIN_SWIZZLE_CH0_DQS2=19,23,21,17,16,18,20,22; \
                                                              PIN_SWIZZLE_CH0_DQS1=9,15,13,11,14,12,8,10; \
                                                              PIN_SWIZZLE_CH0_DQS0=7,5,1,3,4,2,0,6; \
                                                              PIN_SWIZZLE_CH0_ECC=6,4,0,2,5,7,3,1;"
        } else {
            set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_REQ {0}
            set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_WEQ {0}
            set_instance_parameter_value    ddr4_emif     CTRL_ECC_AUTOCORRECT_EN {0}
            set_instance_parameter_value    ddr4_emif     MEM_CHANNEL_ECC_DQ_WIDTH {0}
            set v_extra_params  "BYTE_SWIZZLE_CH0=1,X,X,X,0,2,3,X;  PIN_SWIZZLE_CH0_DQS0=7,5,1,3,4,2,0,6; \
                                                              PIN_SWIZZLE_CH0_DQS1=9,15,13,11,14,12,8,10; \
                                                              PIN_SWIZZLE_CH0_DQS2=19,23,21,17,16,18,20,22; \
                                                              PIN_SWIZZLE_CH0_DQS3=31,29,27,25,26,30,24,28; "
        }
    } elseif {${v_port} == "BANK_3A"} {
        set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_REQ {1}
        set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_WEQ {1}
        set_instance_parameter_value    ddr4_emif     CTRL_ECC_AUTOCORRECT_EN {1}
        set_instance_parameter_value    ddr4_emif     MEM_CHANNEL_ECC_DQ_WIDTH {8}
        set v_extra_params "BYTE_SWIZZLE_CH0=0,X,X,X,1,2,3,ECC;   PIN_SWIZZLE_CH0_DQS0=2,0,6,4,7,5,3,1; \
                                                                PIN_SWIZZLE_CH0_DQS1=14,11,12,8,10,9,13,15; \
                                                                PIN_SWIZZLE_CH0_DQS2=16,20,22,18,23,21,19,17; \
                                                                PIN_SWIZZLE_CH0_DQS3=26,30,28,24,25,27,29,31; \
                                                                PIN_SWIZZLE_CH0_ECC=4,6,2,0,1,7,5,3;"
    } elseif {${v_port} == "BANK_3B"} {
        set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_REQ {1}
        set_instance_parameter_value    ddr4_emif     ADV_CAL_ENABLE_WEQ {1}
        set_instance_parameter_value    ddr4_emif     CTRL_ECC_AUTOCORRECT_EN {1}
        set_instance_parameter_value    ddr4_emif     MEM_CHANNEL_ECC_DQ_WIDTH {8}
        set v_extra_params  "BYTE_SWIZZLE_CH0=0,X,X,X,1,2,3,ECC;  PIN_SWIZZLE_CH0_DQS0=2,0,6,4,7,3,5,1; \
                                                                PIN_SWIZZLE_CH0_DQS1=12,14,13,10,8,11,15,9; \
                                                                PIN_SWIZZLE_CH0_DQS2=16,17,18,19,20,21,22,23; \
                                                                PIN_SWIZZLE_CH0_DQS3=24,25,26,27,28,29,30,31; \
                                                                PIN_SWIZZLE_CH0_ECC=0,2,6,4,1,3,7,5;"
    }

    set_instance_parameter_value  ddr4_emif   PHY_SWIZZLE_MAP             ${v_extra_params}

    set_instance_parameter_value  ddr4_cal    AXIL_DRIVER_ADDRESS_WIDTH   {32}

    save_system

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys


    ############################
    #### Create Connections ####
    ############################

    set v_emif_s0_port_name   "s0_axi4lite"
    set v_emif_s0_clk_name    "s0_axi4lite_clock"
    set v_emif_s0_rst_name    "s0_axi4lite_reset_n"
    set v_emif_init_name      "core_init_n"
    set v_emif_clk_in_name    "s0_axi4_clock_in"
    set v_emif_ref_clk_name   "ref_clk"
    set v_emif_clk_out_name   "s0_axi4_clock_out"
    set v_emif_rst_out_name   "s0_axi4_ctrl_ready"

    add_connection  cal_clk_bridge.out_clk    cal_rst_bridge.clk
    add_connection  cal_clk_bridge.out_clk    ddr4_emif.${v_emif_s0_clk_name}
    add_connection  cal_clk_bridge.out_clk    ddr4_cal.axil_driver_clk

    add_connection  cal_rst_bridge.out_reset  ddr4_emif.${v_emif_init_name}
    add_connection  cal_rst_bridge.out_reset  ddr4_emif.${v_emif_s0_rst_name}
    add_connection  cal_rst_bridge.out_reset  ddr4_cal.axil_driver_rst_n

    add_connection  ddr4_cal.axil_driver_axi4_lite    ddr4_emif.${v_emif_s0_port_name}


    ##########################
    ##### Create Exports #####
    ##########################

    add_interface             i_cal_clk       clock       sink
    set_interface_property    i_cal_clk       export_of   cal_clk_bridge.in_clk

    add_interface             i_cal_rst       reset       sink
    set_interface_property    i_cal_rst       export_of   cal_rst_bridge.in_reset


    ####################
    ##### Optional #####
    ####################

    if {${v_avmm_en}} {
        add_connection  ddr4_cal.cal_done_rst_n   ddr4_rst_bridge.in_reset
        add_connection  ddr4_cal.cal_done_rst_n   ddr4_mm_bridge.reset

        add_connection  ddr4_mm_bridge.m0         ddr4_emif.s0_axi4

        if {${v_async_clk_en}} {
            add_connection  ddr4_clk_bridge.out_clk   ddr4_emif.${v_emif_clk_in_name}
            add_connection  ddr4_clk_bridge.out_clk   ddr4_rst_bridge.clk
            add_connection  ddr4_clk_bridge.out_clk   ddr4_mm_bridge.clk

            add_interface           i_clk_ddr4_emif_emif_usr  clock       sink
            set_interface_property  i_clk_ddr4_emif_emif_usr  export_of   ddr4_clk_bridge.in_clk
        } else {
            add_connection    ddr4_emif.${v_emif_clk_out_name}     ddr4_clk_bridge.in_clk
            add_connection    ddr4_emif.${v_emif_clk_out_name}     ddr4_rst_bridge.clk
            add_connection    ddr4_emif.${v_emif_clk_out_name}     ddr4_mm_bridge.clk

            add_interface           o_clk_ddr4_emif_emif_usr  clock       source
            set_interface_property  o_clk_ddr4_emif_emif_usr  export_of   ddr4_clk_bridge.out_clk
        }

        add_interface           o_reset_ddr4_emif_emif_usr  reset       source
        set_interface_property  o_reset_ddr4_emif_emif_usr  export_of   ddr4_rst_bridge.out_reset

        add_interface           i_ddr4_emif_ctrl_amm_0      avmm        host
        set_interface_property  i_ddr4_emif_ctrl_amm_0      export_of   ddr4_mm_bridge.s0

    } else {
        # clock can be input/output dependant on parameters
        if {${v_async_clk_en}} {
            add_interface           i_clk_ddr4_emif_emif_usr    clock       sink
            set_interface_property  i_clk_ddr4_emif_emif_usr    export_of   ddr4_emif.${v_emif_clk_in_name}
        } else {
            add_interface           o_clk_ddr4_emif_emif_usr    clock       source
            set_interface_property  o_clk_ddr4_emif_emif_usr    export_of   ddr4_emif.${v_emif_clk_out_name}
        }

        # reset is driven by the calibration done signal, not the EMIF driver reset
        add_interface           o_reset_ddr4_emif_emif_usr  reset       source
        set_interface_property  o_reset_ddr4_emif_emif_usr  export_of   ddr4_cal.cal_done_rst_n

        add_interface           i_ddr4_emif_ctrl_amm_0      axi4        subordinate
        set_interface_property  i_ddr4_emif_ctrl_amm_0      export_of   ddr4_emif.s0_axi4
    }

    add_interface           dummy_export            reset       source
    set_interface_property  dummy_export            export_of   ddr4_emif.${v_emif_rst_out_name}

    add_interface           c_ddr4_emif_ck0         conduit     end
    set_interface_property  c_ddr4_emif_ck0         export_of   ddr4_emif.mem_ck_0

    add_interface           c_ddr4_emif_resetn      conduit     end
    set_interface_property  c_ddr4_emif_resetn      export_of   ddr4_emif.mem_reset_n

    # to pins
    add_interface           i_clk_ddr4_emif_pll_ref     clock       sink
    set_interface_property  i_clk_ddr4_emif_pll_ref     export_of   ddr4_emif.${v_emif_ref_clk_name}

    add_interface           c_ddr4_emif_oct             conduit     end
    set_interface_property  c_ddr4_emif_oct             export_of   ddr4_emif.oct_0

    add_interface           c_ddr4_emif_mem             conduit     end
    set_interface_property  c_ddr4_emif_mem             export_of   ddr4_emif.mem_0

    set_domain_assignment   ddr4_mm_bridge.m0 qsys_mm.maxAdditionalLatency 4

    set_postadaptation_assignment \
      mm_interconnect_1|cmd_demux.src0/cmd_mux.sink0 qsys_mm.postTransform.pipelineCount 0
    set_postadaptation_assignment \
      mm_interconnect_1|cmd_demux.src1/cmd_mux_001.sink0 qsys_mm.postTransform.pipelineCount 0
    set_postadaptation_assignment \
      mm_interconnect_1|cmd_mux qsys_mm.postTransform.pipelineCount 1
    set_postadaptation_assignment \
      mm_interconnect_1|cmd_mux_001 qsys_mm.postTransform.pipelineCount 1
    set_postadaptation_assignment \
      mm_interconnect_1|ddr4_mm_bridge_m0_agent.cp/router.sink qsys_mm.postTransform.pipelineCount 1
    set_postadaptation_assignment \
      mm_interconnect_1|ddr4_mm_bridge_m0_limiter.cmd_src/cmd_demux.sink qsys_mm.postTransform.pipelineCount 1
    set_postadaptation_assignment \
      mm_interconnect_1|ddr4_mm_bridge_m0_limiter.rsp_src/ddr4_mm_bridge_m0_agent.rp\
                                                  qsys_mm.postTransform.pipelineCount 1
    set_postadaptation_assignment \
      mm_interconnect_1|router.src/ddr4_mm_bridge_m0_limiter.cmd_sink qsys_mm.postTransform.pipelineCount 0
    set_postadaptation_assignment \
      mm_interconnect_1|router_001.src/rsp_demux.sink qsys_mm.postTransform.pipelineCount 0
    set_postadaptation_assignment \
      mm_interconnect_1|router_002.src/rsp_demux_001.sink qsys_mm.postTransform.pipelineCount 0
    set_postadaptation_assignment \
      mm_interconnect_1|rsp_demux.src0/rsp_mux.sink0 qsys_mm.postTransform.pipelineCount 1
    set_postadaptation_assignment \
      mm_interconnect_1|rsp_demux_001.src0/rsp_mux.sink1 qsys_mm.postTransform.pipelineCount 1
    set_postadaptation_assignment \
      mm_interconnect_1|rsp_mux.src/ddr4_mm_bridge_m0_limiter.rsp_sink qsys_mm.postTransform.pipelineCount 0

    sync_sysinfo_parameters
    save_system
}

# insert the emif subsystem into the top level qsys system, and add interfaces
# to the boundary of the top level qsys system
proc edit_top_level_qsys {} {
    set v_project_name    [get_shell_parameter PROJECT_NAME]
    set v_project_path    [get_shell_parameter PROJECT_PATH]
    set v_instance_name   [get_shell_parameter INSTANCE_NAME]

    load_system ${v_project_path}/rtl/${v_project_name}_qsys.qsys

    add_instance  ${v_instance_name}  ${v_instance_name}

    # add interfaces to the boundary of the subsystem
    add_interface           "${v_instance_name}_i_clk_ddr4_emif_pll_ref"  clock       sink
    set_interface_property  "${v_instance_name}_i_clk_ddr4_emif_pll_ref" export_of \
                                                                    ${v_instance_name}.i_clk_ddr4_emif_pll_ref

    add_interface           "${v_instance_name}_c_ddr4_emif_oct"  conduit     end
    set_interface_property  "${v_instance_name}_c_ddr4_emif_oct"  export_of   ${v_instance_name}.c_ddr4_emif_oct

    add_interface           "${v_instance_name}_c_ddr4_emif_mem"  conduit     end
    set_interface_property  "${v_instance_name}_c_ddr4_emif_mem"  export_of   ${v_instance_name}.c_ddr4_emif_mem

    add_interface           "${v_instance_name}_c_ddr4_emif_ck0"  conduit     end
    set_interface_property  "${v_instance_name}_c_ddr4_emif_ck0"  export_of   ${v_instance_name}.c_ddr4_emif_ck0

    add_interface           "${v_instance_name}_c_ddr4_emif_resetn" conduit   end
    set_interface_property  "${v_instance_name}_c_ddr4_emif_resetn" export_of ${v_instance_name}.c_ddr4_emif_resetn

    sync_sysinfo_parameters
    save_system
}

# enable a subset of subsystem interfaces to be available for auto-connection
# to other subsystems at the top qsys level
proc add_auto_connections {} {
    set v_instance_name   [get_shell_parameter INSTANCE_NAME]
    set v_async_clk_en    [get_shell_parameter DRV_ASYNC_CLK_EN]
    set v_async_clk       [get_shell_parameter ASYNC_CLK]

    add_auto_connection   ${v_instance_name}    i_cal_clk   100000000
    add_auto_connection   ${v_instance_name}    i_cal_rst   100000000

    if {${v_async_clk_en}} {
        add_auto_connection   ${v_instance_name}    i_clk_ddr4_emif_emif_usr   [expr ${v_async_clk} * 1000000]
    } else {
        add_auto_connection   ${v_instance_name}    o_clk_ddr4_emif_emif_usr   ${v_instance_name}_user_clk
    }

    add_auto_connection   ${v_instance_name}    o_reset_ddr4_emif_emif_usr    ${v_instance_name}_user_rst
    add_auto_connection   ${v_instance_name}    i_ddr4_emif_ctrl_amm_0        ${v_instance_name}_user_data
}

# insert lines of code into the top level hdl file
proc edit_top_v_file {} {
    set v_instance_name   [get_shell_parameter INSTANCE_NAME]
    set v_port            [get_shell_parameter DRV_PORT]
    set v_port            [string tolower ${v_port}]

    add_qsys_inst_exports_list    "${v_instance_name}_i_clk_ddr4_emif_pll_ref_clk"    "${v_port}_mem_pll_ref_clk"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_oct_oct_rzqin"      "${v_port}_mem_oct_rzqin"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_a"          "${v_port}_mem_a"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_act_n"      "${v_port}_mem_act_n"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_ba"         "${v_port}_mem_ba"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_bg"         "${v_port}_mem_bg"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_cke"        "${v_port}_mem_cke"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_cs_n"       "${v_port}_mem_cs_n"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_odt"        "${v_port}_mem_odt"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_par"        "${v_port}_mem_par"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_alert_n"    "${v_port}_mem_alert_n"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_dq"         "${v_port}_mem_dq"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_dqs_t"      "${v_port}_mem_dqs"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_dqs_c"      "${v_port}_mem_dqs_n"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_mem_mem_dbi_n"      "${v_port}_mem_dbi_n"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_ck0_mem_ck_t"       "${v_port}_mem_ck"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_ck0_mem_ck_c"       "${v_port}_mem_ck_n"
    add_qsys_inst_exports_list    "${v_instance_name}_c_ddr4_emif_resetn_mem_reset_n" "${v_port}_mem_reset_n"
}
