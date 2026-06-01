########################################################################################################################
# Copyright (C) Altera Corporation
#
# This software and the related documents are Altera copyrighted materials, and
# your use of them is governed by the express license under which they were
# provided to you ("License"). Unless the License provides otherwise, you may
# not use, modify, copy, publish, distribute, disclose or transmit this software
# or the related documents without Altera's prior written permission.
#
# This software and the related documents are provided as is, with no express
# or implied warranties, other than those that are expressly stated in the License.
########################################################################################################################

# create script specific parameters and default values

# if non-zero, enables an async clock input to EMIF for the user
set_shell_parameter AVMM_EN     {0}

# define the procedures used by the create_subsystems_qsys.tcl script

proc creation_step {} {
    create_emif_subsystem
}

proc post_creation_step {} {
    edit_top_level_qsys
    add_auto_connections
    edit_top_v_file
}

# create the emif subsystem
proc create_emif_subsystem {} {
    set v_project_path    [get_shell_parameter PROJECT_PATH]
    set v_inst_name       [get_shell_parameter INSTANCE_NAME]

    create_system ${v_inst_name}
    save_system   ${v_project_path}/rtl/shell/${v_inst_name}.qsys
    load_system   ${v_project_path}/rtl/shell/${v_inst_name}.qsys

    #### Add Instances      ####
    add_instance emif_cpu_clk_bridge            altera_clock_bridge
    add_instance emif_cpu_rst_bridge            altera_reset_bridge
    add_instance emif_axi_clk_out_bridge        altera_clock_bridge
    add_instance emif_axi_ctrl_ready_out_bridge altera_reset_bridge
    add_instance emif_rst_bridge                altera_reset_bridge
    add_instance emif_mm_bridge                 altera_avalon_mm_bridge
    add_instance pio_emif_cal                   altera_avalon_pio
    add_instance ddr4_emif                      emif_io96b_lpddr4
    add_instance ddr4_cal                       emif_ph2_axil_driver

    #### Set Parameters     ####
    # emif_cpu_clk_bridge
    set_instance_parameter_value  emif_cpu_clk_bridge  EXPLICIT_CLOCK_RATE              {100000000.0}
    set_instance_parameter_value  emif_cpu_clk_bridge  NUM_CLOCK_OUTPUTS                {1}

    # emif_cpu_rst_bridge
    set_instance_parameter_value  emif_cpu_rst_bridge  ACTIVE_LOW_RESET                 {0}
    set_instance_parameter_value  emif_cpu_rst_bridge  NUM_RESET_OUTPUTS                {1}
    set_instance_parameter_value  emif_cpu_rst_bridge  SYNCHRONOUS_EDGES                {deassert}
    set_instance_parameter_value  emif_cpu_rst_bridge  SYNC_RESET                       {0}
    set_instance_parameter_value  emif_cpu_rst_bridge  USE_RESET_REQUEST                {0}

    # emif_axi_clk_out_bridge
    set_instance_parameter_value  emif_axi_clk_out_bridge NUM_CLOCK_OUTPUTS             {1}

    # emif_axi_ctrl_ready_out_bridge
    set_instance_parameter_value  emif_axi_ctrl_ready_out_bridge  ACTIVE_LOW_RESET      {0}
    set_instance_parameter_value  emif_axi_ctrl_ready_out_bridge  NUM_RESET_OUTPUTS     {1}
    set_instance_parameter_value  emif_axi_ctrl_ready_out_bridge  SYNCHRONOUS_EDGES     {none}
    set_instance_parameter_value  emif_axi_ctrl_ready_out_bridge  SYNC_RESET            {0}
    set_instance_parameter_value  emif_axi_ctrl_ready_out_bridge  USE_RESET_REQUEST     {0}

    # emif_rst_bridge
    set_instance_parameter_value  emif_rst_bridge  ACTIVE_LOW_RESET                     {1}
    set_instance_parameter_value  emif_rst_bridge  NUM_RESET_OUTPUTS                    {1}
    set_instance_parameter_value  emif_rst_bridge  SYNCHRONOUS_EDGES                    {none}
    set_instance_parameter_value  emif_rst_bridge  SYNC_RESET                           {0}
    set_instance_parameter_value  emif_rst_bridge  USE_RESET_REQUEST                    {0}

    # emif_mm_bridge
    set_instance_parameter_value  emif_mm_bridge   ADDRESS_UNITS                        {SYMBOLS}
    set_instance_parameter_value  emif_mm_bridge   ADDRESS_WIDTH                        {0}
    set_instance_parameter_value  emif_mm_bridge   DATA_WIDTH                           {32}
    set_instance_parameter_value  emif_mm_bridge   LINEWRAPBURSTS                       {0}
    set_instance_parameter_value  emif_mm_bridge   M0_WAITREQUEST_ALLOWANCE             {0}
    set_instance_parameter_value  emif_mm_bridge   MAX_BURST_SIZE                       {1}
    set_instance_parameter_value  emif_mm_bridge   MAX_PENDING_RESPONSES                {4}
    set_instance_parameter_value  emif_mm_bridge   MAX_PENDING_WRITES                   {0}
    set_instance_parameter_value  emif_mm_bridge   PIPELINE_COMMAND                     {1}
    set_instance_parameter_value  emif_mm_bridge   PIPELINE_RESPONSE                    {1}
    set_instance_parameter_value  emif_mm_bridge   S0_WAITREQUEST_ALLOWANCE             {0}
    set_instance_parameter_value  emif_mm_bridge   SYMBOL_WIDTH                         {8}
    set_instance_parameter_value  emif_mm_bridge   SYNC_RESET                           {0}
    set_instance_parameter_value  emif_mm_bridge   USE_AUTO_ADDRESS_WIDTH               {1}
    set_instance_parameter_value  emif_mm_bridge   USE_RESPONSE                         {0}
    set_instance_parameter_value  emif_mm_bridge   USE_WRITERESPONSE                    {0}

    # pio_emif_cal
    set_instance_parameter_value  pio_emif_cal     bitClearingEdgeCapReg                {0}
    set_instance_parameter_value  pio_emif_cal     bitModifyingOutReg                   {0}
    set_instance_parameter_value  pio_emif_cal     captureEdge                          {0}
    set_instance_parameter_value  pio_emif_cal     direction                            {Input}
    set_instance_parameter_value  pio_emif_cal     edgeType                             {RISING}
    set_instance_parameter_value  pio_emif_cal     generateIRQ                          {0}
    set_instance_parameter_value  pio_emif_cal     irqType                              {LEVEL}
    set_instance_parameter_value  pio_emif_cal     resetValue                           {0.0}
    set_instance_parameter_value  pio_emif_cal     simDoTestBenchWiring                 {0}
    set_instance_parameter_value  pio_emif_cal     simDrivenValue                       {0.0}
    set_instance_parameter_value  pio_emif_cal     width                                {8}

    # ddr4_emif
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_R_T_DQ_INPUT_OHM          {RT_50_OHM_CAL}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_DQS_IO_STD_TYPE           {DF_LVSTL}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_R_S_CK_OUTPUT_OHM         {SERIES_40_OHM_CAL}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_REFCLK_IO_STD_TYPE        {TRUE_DIFF}
    set_instance_parameter_value  ddr4_emif        PHY_REFCLK_FREQ_MHZ_AUTOSET_EN       {false}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_GPIO_IO_STD_TYPE          {LVCMOS}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_DQ_VREF                   {17.5}
    set_instance_parameter_value  ddr4_emif        CTRL_PERFORMANCE_PROFILE             {RAND}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_DQ_SLEW_RATE              {FASTEST}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_DQ_IO_STD_TYPE            {LVSTL}
    set_instance_parameter_value  ddr4_emif        CTRL_ECC_AUTOCORRECT_EN              {false}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_CK_OUTPUT_IO_STD_TYPE     {DF_LVSTL}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_R_S_CS_OUTPUT_OHM         {SERIES_40_OHM_CAL}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_R_T_REFCLK_INPUT_OHM      {RT_DIFF}
    set_instance_parameter_value  ddr4_emif        PHY_REFCLK_FREQ_MHZ                  {166.6667}
    set_instance_parameter_value  ddr4_emif        MEM_ODT_DQ_X_TGT_WR                  {5}
    set_instance_parameter_value  ddr4_emif        PHY_REFCLK_ADVANCED_SELECT_EN        {true}
    set_instance_parameter_value  ddr4_emif        MEM_VREF_DQ_X_VALUE                  {18.0}
    set_instance_parameter_value  ddr4_emif        MEM_PER_BANK_REF_EN                  {1}
    set_instance_parameter_value  ddr4_emif        PHY_MAINBAND_ACCESS_MODE_AUTOSET_EN  {false}
    set_instance_parameter_value  ddr4_emif        PHY_MAINBAND_ACCESS_MODE             {SYNC}
    set_instance_parameter_value  ddr4_emif        MEM_TXSR_NS                          {287.5}
    set_instance_parameter_value  ddr4_emif        PHY_SIDEBAND_ACCESS_MODE             {FABRIC}
    set_instance_parameter_value  ddr4_emif        MEM_VREF_DQ_X_RANGE                  {1}
    set_instance_parameter_value  ddr4_emif        MEM_WLS                              {1.0}
    set_instance_parameter_value  ddr4_emif        MEM_TCKCKEL_NS                       {5.0}
    set_instance_parameter_value  ddr4_emif        MEM_VREF_CA_X_CA_RANGE               {2}
    set_instance_parameter_value  ddr4_emif        MEM_DIE_DENSITY_GBITS                {8}
    set_instance_parameter_value  ddr4_emif        MEM_TSR_NS                           {15.0}
    set_instance_parameter_value  ddr4_emif        MEM_TWTR_NS                          {10.0}
    set_instance_parameter_value  ddr4_emif        MEM_TZQLAT_NS                        {30.0}
    set_instance_parameter_value  ddr4_emif        MEM_TZQCAL_NS                        {1000.0}
    set_instance_parameter_value  ddr4_emif        MEM_TRC_NS                           {63.0}
    set_instance_parameter_value  ddr4_emif        MEM_TCCD_NS                          {7.5}
    set_instance_parameter_value  ddr4_emif        MEM_TESCKE_NS                        {2.8125}
    set_instance_parameter_value  ddr4_emif        MEM_TRPPB_NS                         {18.0}
    set_instance_parameter_value  ddr4_emif        MEM_TCKELCMD_NS                      {5.0}
    set_instance_parameter_value  ddr4_emif        MEM_TDQSCK_MIN_NS                    {1.5}
    set_instance_parameter_value  ddr4_emif        MEM_TRFCAB_NS                        {280.0}
    set_instance_parameter_value  ddr4_emif        EX_DESIGN_USER_PLL_OUTPUT_FREQ_MHZ   {200.0}
    set_instance_parameter_value  ddr4_emif        MEM_CA_VREF                          {13}
    set_instance_parameter_value  ddr4_emif        MEM_TRCD_NS                          {18.0}
    set_instance_parameter_value  ddr4_emif        MEM_ODT_CA_X_CS_ENABLE               {true}
    set_instance_parameter_value  ddr4_emif        MEM_TFAW_NS                          {40.0}
    set_instance_parameter_value  ddr4_emif        MEM_TCSCKEH_NS                       {1.75}
    set_instance_parameter_value  ddr4_emif        MEM_ODT_CA_X_CA_COMM                 {3}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_CS_OUTPUT_IO_STD_TYPE     {LVSTL}
    set_instance_parameter_value  ddr4_emif        ADV_CAL_ENABLE_REQ                   {true}
    set_instance_parameter_value  ddr4_emif        MEM_ODT_CA_X_CA_ENABLE               {true}
    set_instance_parameter_value  ddr4_emif        MEM_CWL_CYC                          {18}
    set_instance_parameter_value  ddr4_emif        MEM_TREFW_NS                         {3.2E7}
    set_instance_parameter_value  ddr4_emif        MEM_ODT_DQ_X_IDLE                    {off}
    set_instance_parameter_value  ddr4_emif        ADV_CAL_ENABLE_WEQ                   {true}
    set_instance_parameter_value  ddr4_emif        MEM_CL_CYC                           {20}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_R_T_GPIO_INPUT_OHM        {RT_OFF}
    set_instance_parameter_value  ddr4_emif        MEM_OPERATING_FREQ_MHZ               {1066.667}
    set_instance_parameter_value  ddr4_emif        MEM_TMRR_NS                          {8.0}
    set_instance_parameter_value  ddr4_emif        MEM_TCKELCK_NS                       {5.0}
    set_instance_parameter_value  ddr4_emif        MEM_TRAS_NS                          {42.0}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_R_S_DQ_OUTPUT_OHM         {SERIES_40_OHM_CAL}
    set_instance_parameter_value  ddr4_emif        MEM_OPERATING_FREQ_MHZ_AUTOSET_EN    {false}
    set_instance_parameter_value  ddr4_emif        CTRL_AUTO_PRECHARGE_EN               {true}
    set_instance_parameter_value  ddr4_emif        MEM_TREFI_NS                         {3906.0}
    set_instance_parameter_value  ddr4_emif        MEM_TRRD_NS                          {10.0}
    set_instance_parameter_value  ddr4_emif        MEM_TCKCKEH_NS                       {2.8125}
    set_instance_parameter_value  ddr4_emif        MEM_TRPAB_NS                         {21.0}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_R_S_AC_OUTPUT_OHM         {SERIES_40_OHM_CAL}
    set_instance_parameter_value  ddr4_emif        MEM_VREF_CA_X_CA_VALUE               {27.2}
    set_instance_parameter_value  ddr4_emif        MEM_CHANNEL_DATA_DQ_WIDTH            {32}
    set_instance_parameter_value  ddr4_emif        MEM_ODT_DQ_X_RON                     {6}
    set_instance_parameter_value  ddr4_emif        MEM_TCSCKE_NS                        {1.75}
    set_instance_parameter_value  ddr4_emif        PHY_TERM_X_AC_OUTPUT_IO_STD_TYPE     {LVSTL}
    set_instance_parameter_value  ddr4_emif        JEDEC_OVERRIDE_TABLE_PARAM_NAME      {{MEM_TREFI_NS} {MEM_TMRR_NS}}
    set_instance_parameter_value  ddr4_emif        MEM_TRTP_NS                          {7.5}
    set_instance_parameter_value  ddr4_emif        MEM_TCKEHCMD_NS                      {7.5}
    set_instance_parameter_value  ddr4_emif        MEM_NUM_CHANNELS                     {1}
    set_instance_parameter_value  ddr4_emif        MEM_MINNUMREFSREQ                    {8192.0}
    set_instance_parameter_value  ddr4_emif        MEM_TDQSCK_MAX_NS                    {3.5}
    set_instance_parameter_value  ddr4_emif        MEM_ODT_CA_X_CK_ENABLE               {true}
    set_instance_parameter_value  ddr4_emif        MEM_DQ_VREF                          {20}
    set_instance_parameter_value  ddr4_emif        MEM_TCMDCKE_NS                       {2.8125}
    set_instance_parameter_value  ddr4_emif        MEM_TMRD_NS                          {14.0}
    set_instance_parameter_value  ddr4_emif        MEM_TMRWCKEL_NS                      {14.0}
    set_instance_parameter_value  ddr4_emif        MEM_TMRW_NS                          {10.0}
    set_instance_parameter_value  ddr4_emif        MEM_TPPD_CYC                         {4.0}
    set_instance_parameter_value  ddr4_emif        MEM_TWR_NS                           {18.0}
    set_instance_parameter_value  ddr4_emif        MEM_TRFCPB_NS                        {140.0}
    set_instance_parameter_value  ddr4_emif        MEM_TCKE_NS                          {7.5}
    set_instance_parameter_value  ddr4_emif        MEM_TXP_NS                           {7.5}
    set_instance_parameter_value  ddr4_emif        MEM_TZQCKE_NS                        {2.8125}

    set v_extra_params "BYTE_SWIZZLE_CH0=1,0,X,X,X,X,2,3; PIN_SWIZZLE_CH0_DQS0=0,1,3,2,6,7,4,5; \
                                                          PIN_SWIZZLE_CH0_DQS1=15,14,13,12,9,11,8,10; \
                                                          PIN_SWIZZLE_CH0_DQS2=19,20,21,18,17,16,23,22; \
                                                          PIN_SWIZZLE_CH0_DQS3=25,30,24,31,27,26,28,29;"

    set_instance_parameter_value  ddr4_emif        PHY_SWIZZLE_MAP                      ${v_extra_params}

    # ddr4_cal
    set_instance_parameter_value  ddr4_cal         AXIL_DRIVER_ADDRESS_WIDTH            {32}

    save_system
    load_system   ${v_project_path}/rtl/shell/${v_inst_name}.qsys

    #### Create Connections ####
    # emif_cpu_clk_bridge
    add_connection  emif_cpu_clk_bridge.out_clk                 emif_cpu_rst_bridge.clk
    add_connection  emif_cpu_clk_bridge.out_clk                 emif_mm_bridge.clk
    add_connection  emif_cpu_clk_bridge.out_clk                 pio_emif_cal.clk
    add_connection  emif_cpu_clk_bridge.out_clk                 ddr4_emif.s0_axi4lite_clock
    add_connection  emif_cpu_clk_bridge.out_clk                 ddr4_cal.axil_driver_clk

    # emif_cpu_rst_bridge
    add_connection  emif_cpu_rst_bridge.out_reset               emif_mm_bridge.reset
    add_connection  emif_cpu_rst_bridge.out_reset               pio_emif_cal.reset

    # emif_axi_clk_out_bridge
    add_connection  ddr4_emif.s0_axi4_clock_out                 emif_axi_clk_out_bridge.in_clk

    # emif_axi_ctrl_ready_out_bridge
    add_connection  ddr4_emif.s0_axi4_ctrl_ready                emif_axi_ctrl_ready_out_bridge.in_reset

    # emif_rst_bridge
    add_connection  emif_rst_bridge.out_reset                   ddr4_emif.core_init_n
    add_connection  emif_rst_bridge.out_reset                   ddr4_emif.s0_axi4lite_reset_n
    add_connection  emif_rst_bridge.out_reset                   ddr4_cal.axil_driver_rst_n

    # emif_mm_bridge
    add_connection  emif_mm_bridge.m0                           pio_emif_cal.s1

    # ddr4_cal
    add_connection  ddr4_cal.axil_driver_axi4_lite              ddr4_emif.s0_axi4lite

    ##### Create Exports #####
    # emif_cpu_clk_bridge
    add_interface           cpu_clk_in                  clock       sink
    set_interface_property  cpu_clk_in                  EXPORT_OF   emif_cpu_clk_bridge.in_clk

    # emif_cpu_rst_bridge
    add_interface           cpu_rst_in                  reset       sink
    set_interface_property  cpu_rst_in                  EXPORT_OF   emif_cpu_rst_bridge.in_reset

    # emif_axi_clk_out_bridge
    set_interface_property  emif_clk_out                EXPORT_OF   emif_axi_clk_out_bridge.out_clk

    # emif_axi_ctrl_ready_out_bridge
    set_interface_property  emif_ready_out              EXPORT_OF   emif_axi_ctrl_ready_out_bridge.out_reset

    # emif_rst_bridge
    set_interface_property  emif_rst_brdg_in            EXPORT_OF   emif_rst_bridge.in_reset

    # emif_mm_bridge
    add_interface           mm_ctrl_in                  avalon      slave
    set_interface_property  mm_ctrl_in                  EXPORT_OF   emif_mm_bridge.s0

    # pio_emif_cal
    add_interface           emif_cal_pio                conduit     end
    set_interface_property  emif_cal_pio                export_of   pio_emif_cal.external_connection

    # ddr4_emif
    add_interface           c_ddr4_emif_resetn          conduit     end
    set_interface_property  c_ddr4_emif_resetn          export_of   ddr4_emif.mem_reset_n

    add_interface           c_ddr4_emif_oct             conduit     end
    set_interface_property  c_ddr4_emif_oct             export_of   ddr4_emif.oct_0

    add_interface           i_clk_ddr4_emif_pll_ref     clock       sink
    set_interface_property  i_clk_ddr4_emif_pll_ref     export_of   ddr4_emif.ref_clk

    add_interface           c_ddr4_emif_ck0             conduit     end
    set_interface_property  c_ddr4_emif_ck0             export_of   ddr4_emif.mem_ck_0

    add_interface           c_ddr4_emif_mem             conduit     end
    set_interface_property  c_ddr4_emif_mem             export_of   ddr4_emif.mem_0

    add_interface           i_emif_s0_axi4              axi4        subordinate
    set_interface_property  i_emif_s0_axi4              export_of   ddr4_emif.s0_axi4

    # ddr4_cal
    add_interface           emif_cal_done_rst_n         reset       source
    set_interface_property  emif_cal_done_rst_n         export_of   ddr4_cal.cal_done_rst_n

    ##### Sync / Validation     #####
    ##### Assign Base Addresses #####
    sync_sysinfo_parameters
    auto_assign_system_base_addresses
    save_system
}

# insert the emif subsystem into the top level Platform Designer system, and add interfaces
# to the boundary of the top level Platform Designer system
proc edit_top_level_qsys {} {
    set v_project_name    [get_shell_parameter PROJECT_NAME]
    set v_project_path    [get_shell_parameter PROJECT_PATH]
    set v_inst_name       [get_shell_parameter INSTANCE_NAME]

    load_system ${v_project_path}/rtl/${v_project_name}_qsys.qsys
    add_instance  ${v_inst_name}  ${v_inst_name}

    # add interfaces to the boundary of the subsystem
    # pio_emif_cal
    add_interface          "${v_inst_name}_emif_cal_pio"            conduit   end
    set_interface_property "${v_inst_name}_emif_cal_pio"            export_of ${v_inst_name}.emif_cal_pio

    add_interface          "${v_inst_name}_emif_cal_done_rst_n"     reset     source
    set_interface_property "${v_inst_name}_emif_cal_done_rst_n"     export_of ${v_inst_name}.emif_cal_done_rst_n

    add_interface          "${v_inst_name}_emif_rst_brdg_in"        reset     sink
    set_interface_property "${v_inst_name}_emif_rst_brdg_in"        export_of ${v_inst_name}.emif_rst_brdg_in

    add_interface          "${v_inst_name}_i_clk_ddr4_emif_pll_ref" clock     sink
    set_interface_property "${v_inst_name}_i_clk_ddr4_emif_pll_ref" export_of ${v_inst_name}.i_clk_ddr4_emif_pll_ref

    add_interface          "${v_inst_name}_c_ddr4_emif_oct"         conduit   end
    set_interface_property "${v_inst_name}_c_ddr4_emif_oct"         export_of ${v_inst_name}.c_ddr4_emif_oct

    add_interface          "${v_inst_name}_c_ddr4_emif_mem"         conduit   end
    set_interface_property "${v_inst_name}_c_ddr4_emif_mem"         export_of ${v_inst_name}.c_ddr4_emif_mem

    add_interface          "${v_inst_name}_c_ddr4_emif_ck0"         conduit   end
    set_interface_property "${v_inst_name}_c_ddr4_emif_ck0"         export_of ${v_inst_name}.c_ddr4_emif_ck0

    add_interface          "${v_inst_name}_c_ddr4_emif_resetn"      conduit   end
    set_interface_property "${v_inst_name}_c_ddr4_emif_resetn"      export_of ${v_inst_name}.c_ddr4_emif_resetn

    sync_sysinfo_parameters
    save_system
}

# enable a subset of subsystem interfaces to be available for auto-connection
# to other subsystems at the top Platform Designer level
proc add_auto_connections {} {
    set v_inst_name   [get_shell_parameter INSTANCE_NAME]
    set v_avmm_host   [get_shell_parameter AVMM_HOST]

    add_auto_connection   ${v_inst_name} cpu_clk_in         {100000000}
    add_auto_connection   ${v_inst_name} cpu_rst_in         {100000000}
    add_auto_connection   ${v_inst_name} emif_clk_out       from_emif_clk_out
    add_auto_connection   ${v_inst_name} emif_ready_out     from_emif_ready_out
    add_avmm_connections  mm_ctrl_in     ${v_avmm_host}
    add_auto_connection   ${v_inst_name} i_emif_s0_axi4     from_i_emif_s0_axi4
}

# insert lines of code into the top level hdl file
proc edit_top_v_file {} {
    set v_inst_name         [get_shell_parameter INSTANCE_NAME]
    set v_port              [get_shell_parameter PORT]
    set v_port              [string tolower ${v_port}]
    set v_extra_assigment   "{6'd0, clock_subsystem_iopll_0_locked, cal_done_rst_n}"

    add_declaration_list wire  ""  "cal_done_rst_n"
    add_qsys_inst_exports_list "${v_inst_name}_emif_rst_brdg_in_reset_n"       "~user_device_ready_export"
    add_qsys_inst_exports_list "${v_inst_name}_emif_cal_done_rst_n_reset_n"    "cal_done_rst_n"
    add_qsys_inst_exports_list "${v_inst_name}_emif_cal_pio_export"            "${v_extra_assigment}"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_oct_oct_rzqin"      "${v_port}_mem_oct_rzqin"
    add_qsys_inst_exports_list "${v_inst_name}_i_clk_ddr4_emif_pll_ref_clk"    "${v_port}_mem_pll_ref_clk"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_mem_mem_cke"        "${v_port}_mem_cke"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_mem_mem_dq"         "${v_port}_mem_dq"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_mem_mem_dqs_t"      "${v_port}_mem_dqs"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_mem_mem_dqs_c"      "${v_port}_mem_dqs_n"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_mem_mem_cs"         "${v_port}_mem_cs"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_mem_mem_ca"         "${v_port}_mem_ca"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_mem_mem_dmi"        "${v_port}_mem_dmi"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_ck0_mem_ck_t"       "${v_port}_mem_ck"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_ck0_mem_ck_c"       "${v_port}_mem_ck_n"
    add_qsys_inst_exports_list "${v_inst_name}_c_ddr4_emif_resetn_mem_reset_n" "${v_port}_mem_reset_n"
}
