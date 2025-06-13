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

set_shell_parameter UART_IRQ_PRIORITY       "0"
set_shell_parameter TIMER0_IRQ_PRIORITY     "1"
set_shell_parameter TIMER1_IRQ_PRIORITY     "2"
set_shell_parameter CPU2RAM_AXI_BRIDGE      "0"

set_shell_parameter PERIPHERAL_REGA_BASE    {0}
set_shell_parameter PERIPHERAL_REGA_SIZE    {536870912}
set_shell_parameter PERIPHERAL_REGB_BASE    {603979776}
set_shell_parameter PERIPHERAL_REGB_SIZE    {33554432}
set_shell_parameter SYSID                   {0x006047fe}

set_shell_parameter NIOS_DCACHE_SIZE_BYTES  {16384}
set_shell_parameter NIOS_ICACHE_SIZE_BYTES  {16384}

set_shell_parameter MEMORY_SIZE             "0x00080000"

proc derive_parameters {param_array} {

  upvar ${param_array} p_array

  # =====================================================================
  # resolve interdependencies

  set v_instance_name       [get_shell_parameter INSTANCE_NAME]
  set v_timer0_irq_priority [get_shell_parameter TIMER0_IRQ_PRIORITY]
  set v_timer1_irq_priority [get_shell_parameter TIMER1_IRQ_PRIORITY]
  set v_uart_irq_priority   [get_shell_parameter UART_IRQ_PRIORITY]

  set v_internal_priorities [list ${v_timer0_irq_priority} ${v_timer1_irq_priority} ${v_uart_irq_priority}]

  if {[::irq_connect_pkg::check_duplicate_priorities ${v_internal_priorities}]} {
    puts "found duplicate internal priorities"
    return
  }

  # get an ordered list of priorities from external irqs to this receiver
  set v_external_priorities [::irq_connect_pkg::get_external_irqs p_array ${v_instance_name} ${v_internal_priorities}]

  set_shell_parameter DRV_IRQ_BRIDGE_WIDTH      [llength ${v_external_priorities}]
  set_shell_parameter DRV_IRQ_BRIDGE_PRIORITIES ${v_external_priorities}

}

# define the procedures used by the create_subsystems_qsys.tcl script

proc pre_creation_step {} {
}

proc creation_step {} {
  create_dniosvg_subsystem
  initialize_software
}

proc post_creation_step {} {
  edit_top_level_qsys
  add_auto_connections
}

proc post_connection_step {} {
  modify_avmm_domains
}

#==========================================================
# initialize the subsystem instance software via the software_manager package

proc initialize_software {} {

  set v_project_name                [get_shell_parameter PROJECT_NAME]
  set v_project_path                [get_shell_parameter PROJECT_PATH]
  set v_instance_name               [get_shell_parameter INSTANCE_NAME]
  set v_cpu2ram_bridge              [get_shell_parameter CPU2RAM_AXI_BRIDGE]

  set v_user_bsp_type               [get_shell_parameter BSP_TYPE]
  set v_user_bsp_settings_file      [get_shell_parameter BSP_SETTINGS_FILE]
  set v_user_app_dir                [get_shell_parameter APPLICATION_DIR]
  set v_user_custom_cmakefile       [get_shell_parameter CUSTOM_CMAKEFILE]
  set v_user_custom_makefile        [get_shell_parameter CUSTOM_MAKEFILE]

  #==============================================================================
  # for Nios V software building the memory base address and size must be known
  # collect this information from the created system rather than parameterisation
  # as Platform Designer can resize memory

  load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

  if {${v_cpu2ram_bridge} == "1"} {
      set v_memory_base [get_connection_parameter_value cpu.data_manager/cpu_axi_bridge.s0 baseAddress]
  } else {
      set v_memory_base [get_connection_parameter_value cpu.data_manager/cpu_ram.axi_s1 baseAddress]
  }
  set v_memory_size [get_instance_assignment cpu_ram embeddedsw.CMacro.SIZE_VALUE]
  save_system

  array set v_software_array {}

  set v_software_array(project_name)      ${v_project_name}
  set v_software_array(project_directory) ${v_project_path}
  set v_software_array(instance_name)     ${v_instance_name}
  set v_software_array(cpu_type)          NIOSV

  set v_software_array(memory_base)       ${v_memory_base}
  set v_software_array(memory_size)       ${v_memory_size}

  set v_software_array(bsp_type)          ${v_user_bsp_type}
  set v_software_array(bsp_settings_file) ${v_user_bsp_settings_file}
  set v_software_array(application_dir)   ${v_user_app_dir}
  set v_software_array(custom_cmakefile)  ${v_user_custom_cmakefile}
  set v_software_array(custom_makefile)   ${v_user_custom_makefile}

  ::software_manager_pkg::initialize_software v_software_array

}

# convert terp files to their native format
#   <when necessary insert terp processing function>

# create the cpu subsystem, add the required IP, parameterize it as appropriate,
# add internal connections, and add interfaces to the boundary of the subsystem

proc create_dniosvg_subsystem {} {

  set v_project_path            [get_shell_parameter PROJECT_PATH]
  set v_instance_name           [get_shell_parameter INSTANCE_NAME]

  set v_timer0_irq_priority     [get_shell_parameter TIMER0_IRQ_PRIORITY]
  set v_timer1_irq_priority     [get_shell_parameter TIMER1_IRQ_PRIORITY]
  set v_uart_irq_priority       [get_shell_parameter UART_IRQ_PRIORITY ]

  set v_irq_bridge_width        [get_shell_parameter DRV_IRQ_BRIDGE_WIDTH]
  set v_irq_bridge_priorities   [get_shell_parameter DRV_IRQ_BRIDGE_PRIORITIES]

  set v_peripheral_rega_base    [get_shell_parameter PERIPHERAL_REGA_BASE]
  set v_peripheral_rega_size    [get_shell_parameter PERIPHERAL_REGA_SIZE]
  set v_peripheral_regb_base    [get_shell_parameter PERIPHERAL_REGB_BASE]
  set v_peripheral_regb_size    [get_shell_parameter PERIPHERAL_REGB_SIZE]

  set v_nios_dcache_size_bytes  [get_shell_parameter NIOS_DCACHE_SIZE_BYTES]
  set v_nios_icache_size_bytes  [get_shell_parameter NIOS_ICACHE_SIZE_BYTES]

  set v_sysid                   [get_shell_parameter SYSID]

  set v_memory_size             [get_shell_parameter MEMORY_SIZE]

  set v_cpu2ram_bridge          [get_shell_parameter CPU2RAM_AXI_BRIDGE]

  create_system ${v_instance_name}
  save_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

  load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

  # create instances

  add_instance  cpu_clk_bridge              altera_clock_bridge
  add_instance  cpu_rst_bridge              altera_reset_bridge

  # standard cpu subsystem components
  add_instance  cpu                         intel_niosv_g
  if {${v_cpu2ram_bridge} == "1"} {
    add_instance  cpu_axi_bridge            altera_axi_bridge
  }
  add_instance  cpu_ram                     intel_onchip_memory
  add_instance  cpu_jtag_uart               altera_avalon_jtag_uart
  add_instance  cpu_timer                   altera_avalon_timer

  # custom components for dniosvg
  add_instance  doc_tmr_1                   altera_avalon_timer

  add_instance  sysid_0                     altera_avalon_sysid_qsys
  add_instance  jtag_master                 altera_jtag_avalon_master
  add_instance  performance_counter_0       altera_avalon_performance_counter

  # used to consolidate CPU and JTAG hosts into a single interface
  add_instance ctrl_mm_bridge               altera_avalon_mm_bridge

  # used to export consolidated avmm interface to other subsystems
  add_instance export_mm_bridge             altera_avalon_mm_bridge

  # setting all instance parameters

  #---------------------------------------------------------------
  # cpu_clk_bridge
  if {${v_cpu2ram_bridge} == "1"} {
      set_instance_parameter_value  cpu_clk_bridge  EXPLICIT_CLOCK_RATE         {180000000.0}
  } else {
      set_instance_parameter_value  cpu_clk_bridge  EXPLICIT_CLOCK_RATE         {200000000.0}
  }
  set_instance_parameter_value  cpu_clk_bridge  NUM_CLOCK_OUTPUTS               1

  #---------------------------------------------------------------
  # cpu_rst_bridge
  set_instance_parameter_value  cpu_rst_bridge  ACTIVE_LOW_RESET          0
  set_instance_parameter_value  cpu_rst_bridge  SYNCHRONOUS_EDGES         deassert
  set_instance_parameter_value  cpu_rst_bridge  NUM_RESET_OUTPUTS         1
  set_instance_parameter_value  cpu_rst_bridge  USE_RESET_REQUEST         0
  set_instance_parameter_value  cpu_rst_bridge  SYNC_RESET                0

  #---------------------------------------------------------------
  # cpu
  set_instance_parameter_value cpu enableFPU                    {0}
  set_instance_parameter_value cpu enableBranchPrediction       {1}
  set_instance_parameter_value cpu disableFsqrtFdiv             {0}
  set_instance_parameter_value cpu hartId                       {0}
  set_instance_parameter_value cpu enableDebug                  {1}
  set_instance_parameter_value cpu enableDebugReset             {0}

  set_instance_parameter_value cpu enableLockStep               {0}
  set_instance_parameter_value cpu Blind_Window_Period          {1000}
  set_instance_parameter_value cpu Default_Timeout_Period       {255}

  set_instance_parameter_value cpu useResetReq                  {0}
  set_instance_parameter_value cpu resetSlave                   {cpu_ram.axi_s1}
  set_instance_parameter_value cpu resetOffset                  {0}

  set_instance_parameter_value cpu enableCoreLevelInterruptController   {0}
  set_instance_parameter_value cpu basicInterruptMode                   {0}
  set_instance_parameter_value cpu basicShadowRegisterFiles             {0}

  set_instance_parameter_value cpu dataCacheSize                ${v_nios_dcache_size_bytes}
  set_instance_parameter_value cpu instCacheSize                ${v_nios_icache_size_bytes}
  set_instance_parameter_value cpu peripheralRegionABase        ${v_peripheral_rega_base}
  set_instance_parameter_value cpu peripheralRegionASize        ${v_peripheral_rega_size}
  set_instance_parameter_value cpu peripheralRegionBBase        ${v_peripheral_regb_base}
  set_instance_parameter_value cpu peripheralRegionBSize        ${v_peripheral_regb_size}

  set_instance_parameter_value cpu itcm1Size                    {0}
  set_instance_parameter_value cpu itcm1Base                    {0}
  set_instance_parameter_value cpu itcm1InitFile                {""}
  set_instance_parameter_value cpu itcm2Size                    {0}
  set_instance_parameter_value cpu itcm2Base                    {0}
  set_instance_parameter_value cpu itcm2InitFile                {""}

  set_instance_parameter_value cpu dtcm1Size                    {0}
  set_instance_parameter_value cpu dtcm1Base                    {0}
  set_instance_parameter_value cpu dtcm1InitFile                {""}
  set_instance_parameter_value cpu dtcm2Size                    {0}
  set_instance_parameter_value cpu dtcm2Base                    {0}
  set_instance_parameter_value cpu dtcm2InitFile                {""}

  set_instance_parameter_value cpu enableECCLite                {0}
  set_instance_parameter_value cpu enableECCFull                {0}

  if {${v_cpu2ram_bridge} == "1"} {
    # cpu_axi_bridge
    set_instance_parameter_value cpu_axi_bridge SYNC_RESET                  {0}
    set_instance_parameter_value cpu_axi_bridge BACKPRESSURE_DURING_RESET   {0}

    set_instance_parameter_value cpu_axi_bridge AXI_VERSION                 {AXI4}
    set_instance_parameter_value cpu_axi_bridge ACE_LITE_SUPPORT            {0}
    set_instance_parameter_value cpu_axi_bridge DATA_WIDTH                  {32}
    set_instance_parameter_value cpu_axi_bridge ADDR_WIDTH                  {19}

    set_instance_parameter_value cpu_axi_bridge WRITE_ADDR_USER_WIDTH       {64}
    set_instance_parameter_value cpu_axi_bridge READ_ADDR_USER_WIDTH        {64}
    set_instance_parameter_value cpu_axi_bridge WRITE_DATA_USER_WIDTH       {16}
    set_instance_parameter_value cpu_axi_bridge READ_DATA_USER_WIDTH        {16}
    set_instance_parameter_value cpu_axi_bridge WRITE_RESP_USER_WIDTH       {16}

    set_instance_parameter_value cpu_axi_bridge BITSPERBYTE                 {0}
    set_instance_parameter_value cpu_axi_bridge SAI_WIDTH                   {1}
    set_instance_parameter_value cpu_axi_bridge UNTRANSLATED_TXN            {0}
    set_instance_parameter_value cpu_axi_bridge SID_WIDTH                   {1}

    set_instance_parameter_value cpu_axi_bridge S0_ID_WIDTH                           {8}
    set_instance_parameter_value cpu_axi_bridge WRITE_ACCEPTANCE_CAPABILITY           {16}
    set_instance_parameter_value cpu_axi_bridge READ_ACCEPTANCE_CAPABILITY            {16}
    set_instance_parameter_value cpu_axi_bridge COMBINED_ACCEPTANCE_CAPABILITY        {16}
    set_instance_parameter_value cpu_axi_bridge READ_DATA_REORDERING_DEPTH            {1}

    set_instance_parameter_value cpu_axi_bridge USE_S0_AWREGION         {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_AWLOCK           {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_AWCACHE          {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_AWQOS            {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_AWPROT           {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_AWUSER           {0}

    set_instance_parameter_value cpu_axi_bridge USE_S0_WLAST            {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_WUSER            {0}

    set_instance_parameter_value cpu_axi_bridge USE_S0_BRESP            {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_BUSER            {0}

    set_instance_parameter_value cpu_axi_bridge USE_S0_ARREGION         {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_ARLOCK           {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_ARCACHE          {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_ARQOS            {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_ARPROT           {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_ARUSER           {0}

    set_instance_parameter_value cpu_axi_bridge USE_S0_RRESP            {1}
    set_instance_parameter_value cpu_axi_bridge USE_S0_RUSER            {0}

    set_instance_parameter_value cpu_axi_bridge USE_S0_ADDRCHK          {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_SAI              {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_DATACHK          {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_POISON           {0}
    set_instance_parameter_value cpu_axi_bridge USE_S0_USER_DATA        {0}

    set_instance_parameter_value cpu_axi_bridge M0_ID_WIDTH                           {8}
    set_instance_parameter_value cpu_axi_bridge WRITE_ISSUING_CAPABILITY              {16}
    set_instance_parameter_value cpu_axi_bridge READ_ISSUING_CAPABILITY               {16}
    set_instance_parameter_value cpu_axi_bridge COMBINED_ISSUING_CAPABILITY           {16}
    set_instance_parameter_value cpu_axi_bridge ENABLE_CONCURRENT_SUBORDINATE_ACCESS  {0}
    set_instance_parameter_value cpu_axi_bridge NO_REPEATED_IDS_BETWEEN_SUBORDINATES  {0}

    set_instance_parameter_value cpu_axi_bridge USE_M0_AWID             {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWREGION         {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWLEN            {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWSIZE           {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWBURST          {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWLOCK           {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWCACHE          {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWQOS            {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWUSER           {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_AWUNIQUE         {0}

    set_instance_parameter_value cpu_axi_bridge USE_M0_WSTRB            {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_WUSER            {0}

    set_instance_parameter_value cpu_axi_bridge USE_M0_BID              {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_BRESP            {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_BUSER            {0}

    set_instance_parameter_value cpu_axi_bridge USE_M0_ARID             {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARREGION         {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARLEN            {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARSIZE           {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARBURST          {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARLOCK           {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARCACHE          {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARQOS            {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_ARUSER           {0}

    set_instance_parameter_value cpu_axi_bridge USE_M0_RID              {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_RRESP            {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_RLAST            {1}
    set_instance_parameter_value cpu_axi_bridge USE_M0_RUSER            {0}

    set_instance_parameter_value cpu_axi_bridge USE_M0_ADDRCHK          {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_SAI              {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_DATACHK          {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_USER_DATA        {0}
    set_instance_parameter_value cpu_axi_bridge USE_M0_POISON           {0}


  }

  #---------------------------------------------------------------
  # cpu_ram
  set_instance_parameter_value cpu_ram   AXI_interface                          {1}
  set_instance_parameter_value cpu_ram   interfaceType                          {1}
  set_instance_parameter_value cpu_ram   idWidth                                {3}
  set_instance_parameter_value cpu_ram   memorySize                             ${v_memory_size}
  set_instance_parameter_value cpu_ram   initMemContent                         {1}
  set_instance_parameter_value cpu_ram   useNonDefaultInitFile                  {0}
  set_instance_parameter_value cpu_ram   initializationFileName                 {""}
  set_instance_parameter_value cpu_ram   dataWidth                              {32}

  set_instance_parameter_value cpu_ram   allowInSystemMemoryContentEditor       {0}
  set_instance_parameter_value cpu_ram   blockType                              {AUTO}
  set_instance_parameter_value cpu_ram   clockEnable                            {0}
  set_instance_parameter_value cpu_ram   copyInitFile                           {0}
  set_instance_parameter_value cpu_ram   dualPort                               {0}
  set_instance_parameter_value cpu_ram   ecc_check                              {0}
  set_instance_parameter_value cpu_ram   ecc_encoder_bypass                     {0}
  set_instance_parameter_value cpu_ram   ecc_pipeline_reg                       {0}
  set_instance_parameter_value cpu_ram   enPRInitMode                           {0}
  set_instance_parameter_value cpu_ram   enableDiffWidth                        {0}
  set_instance_parameter_value cpu_ram   gui_debugaccess                        {0}
  set_instance_parameter_value cpu_ram   instanceID                             {NONE}
  set_instance_parameter_value cpu_ram   lvl1OutputRegA                         {0}
  set_instance_parameter_value cpu_ram   lvl1OutputRegB                         {0}
  set_instance_parameter_value cpu_ram   lvl2OutputRegA                         {0}
  set_instance_parameter_value cpu_ram   lvl2OutputRegB                         {0}
  set_instance_parameter_value cpu_ram   poison_enable                          {0}
  set_instance_parameter_value cpu_ram   readDuringWriteMode_Mixed              {DONT_CARE}
  set_instance_parameter_value cpu_ram   resetrequest_enabled                   {1}
  set_instance_parameter_value cpu_ram   singleClockOperation                   {0}
  set_instance_parameter_value cpu_ram   tightly_coupled_ecc                    {0}
  set_instance_parameter_value cpu_ram   writable                               {1}
  if {${v_cpu2ram_bridge} == "1"} {
      set_instance_parameter_value cpu_ram   idWidth                            {8}
  }

  #---------------------------------------------------------------
  # cpu_jtag_uart
  set_instance_parameter_value  cpu_jtag_uart   writeBufferDepth            64
  set_instance_parameter_value  cpu_jtag_uart   writeIRQThreshold           8
  set_instance_parameter_value  cpu_jtag_uart   useRegistersForWriteBuffer  0
  set_instance_parameter_value  cpu_jtag_uart   printingMethod              0
  set_instance_parameter_value  cpu_jtag_uart   readBufferDepth             64
  set_instance_parameter_value  cpu_jtag_uart   readIRQThreshold            8
  set_instance_parameter_value  cpu_jtag_uart   useRegistersForReadBuffer   0

  #---------------------------------------------------------------
  # cpu_timer
  set v_drv_timer_preset [get_shell_parameter DRV_TIMER_PRESET]
  set v_timer_period     [get_shell_parameter TIMER_PERIOD]
  set v_timer_units      [get_shell_parameter TIMER_UNITS]

  apply_instance_preset cpu_timer ${v_drv_timer_preset}

  set_instance_parameter_value  cpu_timer   period              ${v_timer_period}
  set_instance_parameter_value  cpu_timer   periodUnits         ${v_timer_units}

  #---------------------------------------------------------------
  # doc_tmr_1
  set_instance_parameter_value  doc_tmr_1   period              1
  set_instance_parameter_value  doc_tmr_1   periodUnits         {MSEC}
  set_instance_parameter_value  doc_tmr_1   counterSize         32
  set_instance_parameter_value  doc_tmr_1   alwaysRun           0
  set_instance_parameter_value  doc_tmr_1   fixedPeriod         0
  set_instance_parameter_value  doc_tmr_1   snapshot            1
  set_instance_parameter_value  doc_tmr_1   resetOutput         0
  set_instance_parameter_value  doc_tmr_1   timeoutPulseOutput  0

  #---------------------------------------------------------------
  # sysid_0
  set_instance_parameter_value sysid_0    id     ${v_sysid}

  #---------------------------------------------------------------
  # jtag_master
  set_instance_parameter_value jtag_master  USE_PLI   0
  set_instance_parameter_value jtag_master  PLI_PORT  50000

  #---------------------------------------------------------------
  # performance_counter_0
  set_instance_parameter_value performance_counter_0 numberOfSections 3

  #---------------------------------------------------------------
  # ctrl_mm_bridge
  set_instance_parameter_value  ctrl_mm_bridge   SYNC_RESET                0
  set_instance_parameter_value  ctrl_mm_bridge   DATA_WIDTH                32
  set_instance_parameter_value  ctrl_mm_bridge   SYMBOL_WIDTH              8
  set_instance_parameter_value  ctrl_mm_bridge   ADDRESS_WIDTH             0
  set_instance_parameter_value  ctrl_mm_bridge   USE_AUTO_ADDRESS_WIDTH    1
  set_instance_parameter_value  ctrl_mm_bridge   ADDRESS_UNITS             SYMBOLS
  set_instance_parameter_value  ctrl_mm_bridge   MAX_BURST_SIZE            1
  set_instance_parameter_value  ctrl_mm_bridge   LINEWRAPBURSTS            0
  set_instance_parameter_value  ctrl_mm_bridge   MAX_PENDING_RESPONSES     4
  set_instance_parameter_value  ctrl_mm_bridge   PIPELINE_COMMAND          1
  set_instance_parameter_value  ctrl_mm_bridge   PIPELINE_RESPONSE         1
  set_instance_parameter_value  ctrl_mm_bridge   USE_RESPONSE              0
  set_instance_parameter_value  ctrl_mm_bridge   USE_WRITERESPONSE         0

  # export_mm_bridge
  set_instance_parameter_value  export_mm_bridge   SYNC_RESET                0
  set_instance_parameter_value  export_mm_bridge   DATA_WIDTH                32
  set_instance_parameter_value  export_mm_bridge   SYMBOL_WIDTH              8
  set_instance_parameter_value  export_mm_bridge   ADDRESS_WIDTH             0
  set_instance_parameter_value  export_mm_bridge   USE_AUTO_ADDRESS_WIDTH    1
  set_instance_parameter_value  export_mm_bridge   ADDRESS_UNITS             SYMBOLS
  set_instance_parameter_value  export_mm_bridge   MAX_BURST_SIZE            1
  set_instance_parameter_value  export_mm_bridge   LINEWRAPBURSTS            0
  set_instance_parameter_value  export_mm_bridge   MAX_PENDING_RESPONSES     4
  set_instance_parameter_value  export_mm_bridge   MAX_PENDING_WRITES        0
  set_instance_parameter_value  export_mm_bridge   PIPELINE_COMMAND          1
  set_instance_parameter_value  export_mm_bridge   PIPELINE_RESPONSE         1
  set_instance_parameter_value  export_mm_bridge   USE_RESPONSE              0
  set_instance_parameter_value  export_mm_bridge   USE_WRITERESPONSE         0

  #---------------------------------------------------------------
  # create internal subsystem connections

  add_connection  cpu_clk_bridge.out_clk    cpu_rst_bridge.clk
  add_connection  cpu_clk_bridge.out_clk    cpu.clk
  if {${v_cpu2ram_bridge} == "1"} {
      add_connection  cpu_clk_bridge.out_clk    cpu_axi_bridge.clk
  }
  add_connection  cpu_clk_bridge.out_clk    cpu_ram.clk1
  add_connection  cpu_clk_bridge.out_clk    cpu_jtag_uart.clk
  add_connection  cpu_clk_bridge.out_clk    cpu_timer.clk
  add_connection  cpu_clk_bridge.out_clk    doc_tmr_1.clk
  add_connection  cpu_clk_bridge.out_clk    sysid_0.clk
  add_connection  cpu_clk_bridge.out_clk    jtag_master.clk
  add_connection  cpu_clk_bridge.out_clk    performance_counter_0.clk
  add_connection  cpu_clk_bridge.out_clk    ctrl_mm_bridge.clk
  add_connection  cpu_clk_bridge.out_clk    export_mm_bridge.clk

  add_connection  cpu_rst_bridge.out_reset  cpu.reset
  if {${v_cpu2ram_bridge} == "1"} {
      add_connection  cpu_rst_bridge.out_reset  cpu_axi_bridge.clk_reset
  }
  add_connection  cpu_rst_bridge.out_reset  cpu_ram.reset1
  add_connection  cpu_rst_bridge.out_reset  cpu_jtag_uart.reset
  add_connection  cpu_rst_bridge.out_reset  cpu_timer.reset
  add_connection  cpu_rst_bridge.out_reset  doc_tmr_1.reset
  add_connection  cpu_rst_bridge.out_reset  sysid_0.reset
  add_connection  cpu_rst_bridge.out_reset  jtag_master.clk_reset
  add_connection  cpu_rst_bridge.out_reset  performance_counter_0.reset
  add_connection  cpu_rst_bridge.out_reset  ctrl_mm_bridge.reset
  add_connection  cpu_rst_bridge.out_reset  export_mm_bridge.reset

  add_connection  cpu.data_manager           cpu.dm_agent
  add_connection  cpu.data_manager           cpu.timer_sw_agent
  if {${v_cpu2ram_bridge} == "1"} {
      add_connection  cpu.data_manager           cpu_axi_bridge.s0
  } else {
      add_connection  cpu.data_manager           cpu_ram.axi_s1
  }
  add_connection  cpu.data_manager           ctrl_mm_bridge.s0

  add_connection  cpu.instruction_manager    cpu.dm_agent
  if {${v_cpu2ram_bridge} == "1"} {
      add_connection  cpu.instruction_manager    cpu_axi_bridge.s0
  } else {
      add_connection  cpu.instruction_manager    cpu_ram.axi_s1
  }

  if {${v_cpu2ram_bridge} == "1"} {
      add_connection  cpu_axi_bridge.m0          cpu_ram.axi_s1
  }

  if {${v_cpu2ram_bridge} == "1"} {
      add_connection  jtag_master.master         cpu_axi_bridge.s0
  } else {
      add_connection  jtag_master.master         cpu_ram.axi_s1
  }
  add_connection  jtag_master.master         ctrl_mm_bridge.s0

  add_connection  ctrl_mm_bridge.m0         cpu_jtag_uart.avalon_jtag_slave
  add_connection  ctrl_mm_bridge.m0         cpu_timer.s1
  add_connection  ctrl_mm_bridge.m0         doc_tmr_1.s1
  add_connection  ctrl_mm_bridge.m0         sysid_0.control_slave
  add_connection  ctrl_mm_bridge.m0         performance_counter_0.control_slave
  add_connection  ctrl_mm_bridge.m0         export_mm_bridge.s0

  # Set IRQs

  if {${v_uart_irq_priority} != "X"} {
    add_connection  cpu.platform_irq_rx   cpu_jtag_uart.irq
    set_connection_parameter_value  cpu.platform_irq_rx/cpu_jtag_uart.irq irqNumber ${v_uart_irq_priority}
  }

  if {${v_timer0_irq_priority} != "X"} {
    add_connection  cpu.platform_irq_rx   cpu_timer.irq
    set_connection_parameter_value  cpu.platform_irq_rx/cpu_timer.irq irqNumber ${v_timer0_irq_priority}
  }

  if {${v_timer1_irq_priority} != "X"} {
    add_connection  cpu.platform_irq_rx   doc_tmr_1.irq
    set_connection_parameter_value  cpu.platform_irq_rx/doc_tmr_1.irq irqNumber ${v_timer1_irq_priority}
  }

  #---------------------------------------------------------------
  # add interfaces to the boundary of the subsystem

  add_interface          i_clk_cpu              clock       sink
  set_interface_property i_clk_cpu              export_of   cpu_clk_bridge.in_clk

  add_interface          i_reset_cpu            reset       sink
  set_interface_property i_reset_cpu            export_of   cpu_rst_bridge.in_reset

  add_interface          o_reset_cpu_debug_req  reset       source
  set_interface_property o_reset_cpu_debug_req  export_of   jtag_master.master_reset

  add_interface          o_cpu_mm_master        avalon      host
  set_interface_property o_cpu_mm_master        export_of   export_mm_bridge.m0

  # add irq bridge if required

  if {(${v_irq_bridge_width} >= 1)} {

    add_instance  irq_bridge      altera_irq_bridge

    # irq_bridge
    set_instance_parameter_value  irq_bridge  IRQ_WIDTH           ${v_irq_bridge_width}
    set_instance_parameter_value  irq_bridge  IRQ_N               {Active High}
    set_instance_parameter_value  irq_bridge  SYNC_RESET          0

    add_connection  cpu_clk_bridge.out_clk    irq_bridge.clk
    add_connection  cpu_rst_bridge.out_reset  irq_bridge.clk_reset

    for {set v_i 0} {${v_i} < ${v_irq_bridge_width}} {incr v_i} {
      set v_priority [lindex ${v_irq_bridge_priorities} ${v_i}]
      add_connection  cpu.platform_irq_rx   irq_bridge.sender${v_i}_irq
      set_connection_parameter_value  cpu.platform_irq_rx/irq_bridge.sender${v_i}_irq irqNumber ${v_priority}
    }

    add_interface          ia_cpu_irq_receiver     interrupt  receiver
    set_interface_property ia_cpu_irq_receiver     export_of  irq_bridge.receiver_irq

  }

  # add fixed base addresses

  # the memory mapped bridge to other subsystems should be at the end of the address
  # space to allow width expansion based on the requirements of other subsystems

  set_connection_parameter_value  cpu.instruction_manager/cpu.dm_agent              baseAddress   "0x25100000"
  if {${v_cpu2ram_bridge} == "1"} {
      set_connection_parameter_value  cpu.instruction_manager/cpu_axi_bridge.s0     baseAddress   "0x20000000"
  } else {
      set_connection_parameter_value  cpu.instruction_manager/cpu_ram.axi_s1        baseAddress   "0x20000000"
  }

  set_connection_parameter_value  cpu.data_manager/cpu.dm_agent                     baseAddress   "0x25100000"
  set_connection_parameter_value  cpu.data_manager/cpu.timer_sw_agent               baseAddress   "0x25110000"
  if {${v_cpu2ram_bridge} == "1"} {
      set_connection_parameter_value  cpu.data_manager/cpu_axi_bridge.s0            baseAddress   "0x20000000"
  } else {
      set_connection_parameter_value  cpu.data_manager/cpu_ram.axi_s1               baseAddress   "0x20000000"
  }
  set_connection_parameter_value  cpu.data_manager/ctrl_mm_bridge.s0                baseAddress   "0x00000000"

  if {${v_cpu2ram_bridge} == "1"} {
      set_connection_parameter_value  jtag_master.master/cpu_axi_bridge.s0          baseAddress   "0x20000000"
  } else {
      set_connection_parameter_value  jtag_master.master/cpu_ram.axi_s1             baseAddress   "0x20000000"
  }

  set_connection_parameter_value  jtag_master.master/ctrl_mm_bridge.s0              baseAddress   "0x00000000"

  if {${v_cpu2ram_bridge} == "1"} {
      set_connection_parameter_value  cpu_axi_bridge.m0/cpu_ram.axi_s1              baseAddress   "0x00000000"
  }

  lock_avalon_base_address cpu_ram.axi_s1
  if {${v_cpu2ram_bridge} == "1"} {
      lock_avalon_base_address cpu_axi_bridge.s0
  }


  sync_sysinfo_parameters
  save_system

}

# insert the cpu subsystem into the top level qsys system, and add interfaces
# to the boundary of the top level qsys system

proc edit_top_level_qsys {} {

  set v_project_name  [get_shell_parameter PROJECT_NAME]
  set v_project_path  [get_shell_parameter PROJECT_PATH]
  set v_instance_name [get_shell_parameter INSTANCE_NAME]

  load_system ${v_project_path}/rtl/${v_project_name}_qsys.qsys

  add_instance ${v_instance_name} ${v_instance_name}

  sync_sysinfo_parameters
  save_system

}

# enable a subset of subsystem interfaces to be available for auto-connection
# to other subsystems at the top qsys level

proc add_auto_connections {} {

  set v_instance_name [get_shell_parameter INSTANCE_NAME]
  set v_drv_irq_bridge_width  [get_shell_parameter DRV_IRQ_BRIDGE_WIDTH]
  set v_cpu2ram_bridge          [get_shell_parameter CPU2RAM_AXI_BRIDGE]

  if {${v_cpu2ram_bridge} == "1"} {
      add_auto_connection ${v_instance_name}  i_clk_cpu     180000000
      add_auto_connection ${v_instance_name}  i_reset_cpu   180000000
  } else {
      add_auto_connection ${v_instance_name}  i_clk_cpu     200000000
      add_auto_connection ${v_instance_name}  i_reset_cpu   200000000
  }

  add_avmm_connections o_cpu_mm_master "host"

  add_auto_connection ${v_instance_name}  o_reset_cpu_debug_req   ${v_instance_name}_jtag_reset

  if {${v_drv_irq_bridge_width} >= 1} {
    add_irq_connection ${v_instance_name} "ia_cpu_irq_receiver" 0 ${v_instance_name}_irq
  }

}

# insert lines of code into the top level hdl file
# <if necessary add function "edit_top_v_file" to insert code to top.v>

proc modify_avmm_domains {} {

  set v_project_name  [get_shell_parameter PROJECT_NAME]
  set v_project_path  [get_shell_parameter PROJECT_PATH]
  set v_instance_name [get_shell_parameter INSTANCE_NAME]

  load_system ${v_project_path}/rtl/${v_project_name}_qsys.qsys

  set v_conns [get_connections ${v_instance_name}.o_cpu_mm_master]
  set v_num_conns [llength ${v_conns}]

  if {${v_num_conns} > 0} {
    set_domain_assignment ${v_instance_name}.o_cpu_mm_master qsys_mm.maxAdditionalLatency 4
  }

  sync_sysinfo_parameters
  save_system

}
