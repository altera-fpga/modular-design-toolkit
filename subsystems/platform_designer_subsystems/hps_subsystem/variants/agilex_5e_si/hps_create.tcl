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

set_shell_parameter INCLUDE_DIR                         ""
set_shell_parameter SOURCE_DIR                          ""
set_shell_parameter LIBRARY_DIR                         ""

set_shell_parameter FPGA_EMIF_ENABLED                   {0}
set_shell_parameter FPGA_EMIF_WINDOW_BASE_ADDRESS       {0}
# valid option: 0x4000
set_shell_parameter FPGA_EMIF_WINDOW_CTRL_BASE_ADDRESS  {0x0000}
# valid option: 31
set_shell_parameter FPGA_EMIF_HOST_ADDR_WIDTH           {0}
# valid option: 27
set_shell_parameter FPGA_EMIF_AGENT_ADDR_WIDTH          {0}

set_shell_parameter H2F_ADDRESS_WIDTH                   {38}

set_shell_parameter HPS_AXI_CLK                         {100000000}

set_shell_parameter MSGDMA_AGENT                        {}
set_shell_parameter MSGDMA_AGENT_ADDR_WIDTH             {0}
set_shell_parameter MSGDMA_AGENT_CLK_FREQ               {200000000.0}

set_shell_parameter F2H_EN                              {0}
set_shell_parameter I2C0_EXT_EN                         {0}
set_shell_parameter I2C1_EXT_EN                         {0}

set_shell_parameter I2C0_SCLK                           {125.0}
set_shell_parameter I2C1_SCLK                           {125.0}

# To add delay to EMAC RX/TX CLk ACCORDING TO KERNEL 6.6.37
# MAC drivers compatible with 24.3 onwards
set_shell_parameter ENABLE_EMAC2_TXRX_CLK_DELAY         {1}

# valid options "HPS FIRST" or "AFTER INIT_DONE"
set_shell_parameter HPS_INIT                            "HPS FIRST"

set_shell_parameter F2SDRAM_ADDR_WIDTH                  {32}


# resolve interdependencies
proc derive_parameters {param_array} {

    upvar $param_array p_array

    set v_instance_name [get_shell_parameter INSTANCE_NAME]

    set_shell_parameter DRV_ENABLE_H2F    "0"
    set_shell_parameter DRV_ENABLE_H2F_LW "0"

    # look for HPS memory preset
    for {set id 0} {$id < $p_array(project,id)} {incr id} {
    #  board has DDR soldered directly onto the PCB get preset file from the board subsystem
        if {$p_array($id,type) == "board"} {
            set params $p_array($id,params)

            foreach v_pair ${params} {
                set v_name  [lindex ${v_pair} 0]
                set v_value [lindex ${v_pair} 1]
                set v_temp_array(${v_name}) ${v_value}
            }

            if {[info exists v_temp_array(PORT)]} {
                set v_temp_port $v_temp_array(PORT)

                if {${v_temp_port} == "hps"} {
                    if {[info exists v_temp_array(DDR4_PRESET_HPS)]} {
                        set_shell_parameter DRV_DDR_PRESET $v_temp_array(DDR4_PRESET_HPS)
                    }
                    if {[info exists v_temp_array(DDR4_PRESET_HPS_FILE)]} {
                        set_shell_parameter DRV_DDR_PRESET_FILE $v_temp_array(DDR4_PRESET_HPS_FILE)
                    }
                    break
                }
            }
        }
    }

    # create derived parameters to enable the correct AXI bridges for the
    # HPS-2-FPGA AXI Buses
    set v_h2f_export          [get_shell_parameter H2F_EXPORT]

    if {${v_h2f_export} == "BOTH"} {
        set_shell_parameter DRV_ENABLE_H2F    1
        set_shell_parameter DRV_ENABLE_H2F_LW 1
    } elseif {${v_h2f_export} == "FULL"} {
        set_shell_parameter DRV_ENABLE_H2F    1
    } elseif {${v_h2f_export} == "LIGHT"} {
        set_shell_parameter DRV_ENABLE_H2F_LW 1
    }

    # check if the msgdma is enabled
    set v_msgdma_agent  [get_shell_parameter MSGDMA_AGENT]

    if {[llength ${v_msgdma_agent}] != 0} {
        set_shell_parameter DRV_MSGDMA_EN {1}
    } else {
        set_shell_parameter DRV_MSGDMA_EN {0}
    }

    # organize external interrupts
    set v_internal_priorities []

    if {[::irq_connect_pkg::check_duplicate_priorities ${v_internal_priorities}]} {
        puts "found duplicate internal priorities"
        return
    }

    # get an ordered list of priorities from external irqs to this receiver
    # both H2F host labels are used to get the external priorities
    set v_external_priorities \
        [::irq_connect_pkg::get_external_irqs p_array ${v_instance_name} ${v_internal_priorities}]
    set v_lw_external_priorities \
        [::irq_connect_pkg::get_external_irqs p_array "${v_instance_name}_lw" ${v_internal_priorities}]

    foreach v_priority ${v_lw_external_priorities} {
        lappend v_external_priorities ${v_priority}
    }

    set_shell_parameter DRV_IRQ_BRIDGE_WIDTH      [llength ${v_external_priorities}]
    set_shell_parameter DRV_IRQ_BRIDGE_PRIORITIES ${v_external_priorities}
}

proc pre_creation_step {} {
    initialize_software
    transfer_files
    evaluate_terp
}

proc creation_step {} {
    create_cpu_subsystem
}

proc post_creation_step {} {
  edit_top_level_qsys
  add_auto_connections
  edit_top_v_file
}


# initialize the subsystem instance software via the software_manager package
proc initialize_software {} {
    set v_project_name                [get_shell_parameter PROJECT_NAME]
    set v_project_path                [get_shell_parameter PROJECT_PATH]
    set v_instance_name               [get_shell_parameter INSTANCE_NAME]

    set v_user_app_dir                [get_shell_parameter APPLICATION_DIR]
    set v_user_custom_cmakefile       [get_shell_parameter CUSTOM_CMAKEFILE]
    set v_user_custom_makefile        [get_shell_parameter CUSTOM_MAKEFILE]

    array set v_software_array {}

    set v_software_array(project_name)      ${v_project_name}
    set v_software_array(project_directory) ${v_project_path}
    set v_software_array(instance_name)     ${v_instance_name}
    set v_software_array(cpu_type)          "HPS"

    set v_software_array(bsp_type)          ""
    set v_software_array(bsp_settings_file) ""
    set v_software_array(application_dir)   ${v_user_app_dir}
    set v_software_array(custom_cmakefile)  ${v_user_custom_cmakefile}
    set v_software_array(custom_makefile)   ${v_user_custom_makefile}

    ::software_manager_pkg::initialize_software v_software_array
}

# copy files from the shell install directory to the target project directory
proc transfer_files {} {
    set v_shell_design_root [get_shell_parameter SHELL_DESIGN_ROOT]
    set v_project_path      [get_shell_parameter PROJECT_PATH]
    set v_instance_name     [get_shell_parameter INSTANCE_NAME]
    set v_subsys_dir        "${v_shell_design_root}/hps_subsystem"

    file_copy ${v_subsys_dir}/variants/agilex_5e_si/hps_subsystem.qsf.terp \
              ${v_project_path}/quartus/shell/${v_instance_name}.qsf.terp

    # software setup
    set v_library_dir [get_shell_parameter LIBRARY_DIR]
    set v_include_dir [get_shell_parameter INCLUDE_DIR]
    set v_source_dir  [get_shell_parameter SOURCE_DIR]

    if {${v_library_dir}!=""} {
        file mkdir ${v_project_path}/software/${v_instance_name}/lib

        foreach v_path ${v_library_dir} {
            file_copy ${v_path} ${v_project_path}/software/${v_instance_name}/lib
        }
    }

    if {${v_include_dir}!=""} {
        file mkdir ${v_project_path}/software/${v_instance_name}/app/inc

        foreach v_path ${v_include_dir} {
            file_copy ${v_path} ${v_project_path}/software/${v_instance_name}/app/inc
        }
    }
    if {${v_source_dir}!=""} {
        file mkdir ${v_project_path}/software/${v_instance_name}/app/

        foreach v_path ${v_source_dir} {
            file_copy ${v_path} ${v_project_path}/software/${v_instance_name}/app/
        }
    }

    file_copy ${v_subsys_dir}/../../common/non_qpds_ip/intel_fpga_axi_gpio      ${v_project_path}/non_qpds_ip/shell
    file_copy ${v_subsys_dir}/../../common/non_qpds_ip/intel_fpga_axil2apb      ${v_project_path}/non_qpds_ip/shell
    file_copy ${v_subsys_dir}/../../common/non_qpds_ip/intel_fpga_axi.ipx       ${v_project_path}/non_qpds_ip/shell

    set v_msgdma_en     [get_shell_parameter DRV_MSGDMA_EN]

    if {${v_msgdma_en}} {
        exec cp -rf ${v_subsys_dir}/../../common/non_qpds_ip/msgdma2axi4_256 \
                                                              ${v_project_path}/non_qpds_ip/shell
        file_copy   ${v_subsys_dir}/../../common/non_qpds_ip/msgdma2axi4_256.ipx \
                                                              ${v_project_path}/non_qpds_ip/shell

        exec cp -rf ${v_subsys_dir}/../../common/non_qpds_ip/f2sdram_adapter_256 \
                                                              ${v_project_path}/non_qpds_ip/shell
        file_copy   ${v_subsys_dir}/../../common/non_qpds_ip/f2sdram_adapter_256.ipx \
                                                              ${v_project_path}/non_qpds_ip/shell
    }
}

proc evaluate_terp {} {
    set v_project_name  [get_shell_parameter PROJECT_NAME]
    set v_project_path  [get_shell_parameter PROJECT_PATH]
    set v_instance_name [get_shell_parameter INSTANCE_NAME]
    set v_board_name    [get_shell_parameter DEVKIT]
    set v_hps_init      [get_shell_parameter HPS_INIT]

    evaluate_terp_file ${v_project_path}/quartus/shell/${v_instance_name}.qsf.terp \
                        [list ${v_project_name} ${v_board_name} ${v_hps_init}] 0 1
}

proc create_cpu_subsystem {} {
    set v_project_path            [get_shell_parameter PROJECT_PATH]
    set v_instance_name           [get_shell_parameter INSTANCE_NAME]
    set v_board_name              [get_shell_parameter DEVKIT]

    set v_drv_ddr_preset_file     [get_shell_parameter DRV_DDR_PRESET_FILE]

    set v_irq_bridge_width        [get_shell_parameter DRV_IRQ_BRIDGE_WIDTH]
    set v_irq_bridge_priorities   [get_shell_parameter DRV_IRQ_BRIDGE_PRIORITIES]

    set v_fpga_emif_enabled       [get_shell_parameter FPGA_EMIF_ENABLED]

    set v_drv_enable_h2f          [get_shell_parameter DRV_ENABLE_H2F]
    set v_drv_enable_h2f_lw       [get_shell_parameter DRV_ENABLE_H2F_LW]

    set v_h2f_is_axi              [get_shell_parameter H2F_IS_AXI]
    set v_h2f_lw_is_axi           [get_shell_parameter H2F_LW_IS_AXI]

    set v_num_gpo                 [get_shell_parameter NUM_GPO]
    set v_num_gpi                 [get_shell_parameter NUM_GPI]

    set v_msgdma_en               [get_shell_parameter DRV_MSGDMA_EN]

    set v_f2h_en                  [get_shell_parameter F2H_EN]
    set v_i2c0_ext_en             [get_shell_parameter I2C0_EXT_EN]
    set v_i2c1_ext_en             [get_shell_parameter I2C1_EXT_EN]

    set v_hps_axi_clk             [get_shell_parameter HPS_AXI_CLK]

    set v_h2f_address_width       [get_shell_parameter H2F_ADDRESS_WIDTH]

    set v_i2c0_sclk               [get_shell_parameter I2C0_SCLK]
    set v_i2c1_sclk               [get_shell_parameter I2C1_SCLK]
    set v_f2sdram_addr_width      [get_shell_parameter F2SDRAM_ADDR_WIDTH]

    set v_emac2_txrx_clk_delay_en [get_shell_parameter ENABLE_EMAC2_TXRX_CLK_DELAY]


    create_system ${v_instance_name}
    save_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys


    ############################
    #### Add Instances      ####
    ############################

    add_instance  agilex_hps                                intel_agilex_5_soc
    add_instance  emif_agilex_hps                           emif_io96b_hps
    add_instance  gts_reset_sequencer                       intel_srcss_gts

    add_instance  hps_axi_clk_bridge                        altera_clock_bridge
    add_instance  hps_axi_rst_bridge                        altera_reset_bridge

    add_instance  hps_h2f_user0_clk_bridge                  altera_clock_bridge

    if {${v_f2h_en}} {
        add_instance  fpga2hps_axi_bridge                     altera_axi_bridge
    }


    ############################
    #### Set Parameters     ####
    ############################

    # set_hps_parameters agilex_hps
    set_instance_parameter_value agilex_hps ATB_Enable                 {0}
    set_instance_parameter_value agilex_hps CM_Mode                    {N/A}
    set_instance_parameter_value agilex_hps CM_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps CTI_Enable                 {0}
    set_instance_parameter_value agilex_hps DMA_Enable                 {No No No No No No No No}
    set_instance_parameter_value agilex_hps Debug_APB_Enable           {0}
    set_instance_parameter_value agilex_hps EMAC0_Mode                 {N/A}
    set_instance_parameter_value agilex_hps EMAC0_PTP                  {0}
    set_instance_parameter_value agilex_hps EMAC0_PinMuxing            {Unused}
    set_instance_parameter_value agilex_hps EMAC1_Mode                 {N/A}
    set_instance_parameter_value agilex_hps EMAC1_PTP                  {0}
    set_instance_parameter_value agilex_hps EMAC1_PinMuxing            {Unused}
    set_instance_parameter_value agilex_hps EMAC2_Mode                 {RGMII_with_MDIO}
    set_instance_parameter_value agilex_hps EMAC2_PTP                  {0}
    set_instance_parameter_value agilex_hps EMAC2_PinMuxing            {IO}
    set_instance_parameter_value agilex_hps EMIF_AXI_Enable            {1}
    set_instance_parameter_value agilex_hps EMIF_Topology              {1}
    set_instance_parameter_value agilex_hps F2H_IRQ_Enable             {1}
    set_instance_parameter_value agilex_hps F2H_free_clk_mhz           {125}
    set_instance_parameter_value agilex_hps F2H_free_clock_enable      {0}
    set_instance_parameter_value agilex_hps FPGA_EMAC0_gtx_clk_mhz     {125.0}
    set_instance_parameter_value agilex_hps FPGA_EMAC0_md_clk_mhz      {2.5}
    set_instance_parameter_value agilex_hps FPGA_EMAC1_gtx_clk_mhz     {125.0}
    set_instance_parameter_value agilex_hps FPGA_EMAC1_md_clk_mhz      {2.5}
    set_instance_parameter_value agilex_hps FPGA_EMAC2_gtx_clk_mhz     {125.0}
    set_instance_parameter_value agilex_hps FPGA_EMAC2_md_clk_mhz      {2.5}
    set_instance_parameter_value agilex_hps FPGA_I2C0_sclk_mhz         ${v_i2c0_sclk}
    set_instance_parameter_value agilex_hps FPGA_I2C1_sclk_mhz         ${v_i2c1_sclk}
    set_instance_parameter_value agilex_hps FPGA_I2CEMAC0_clk_mhz      {125.0}
    set_instance_parameter_value agilex_hps FPGA_I2CEMAC1_clk_mhz      {125.0}
    set_instance_parameter_value agilex_hps FPGA_I2CEMAC2_clk_mhz      {125.0}
    set_instance_parameter_value agilex_hps FPGA_I3C0_sclk_mhz         {125.0}
    set_instance_parameter_value agilex_hps FPGA_I3C1_sclk_mhz         {125.0}
    set_instance_parameter_value agilex_hps FPGA_SPIM0_sclk_mhz        {125.0}
    set_instance_parameter_value agilex_hps FPGA_SPIM1_sclk_mhz        {125.0}
    set_instance_parameter_value agilex_hps GP_Enable                  {0}
    set_instance_parameter_value agilex_hps H2F_Address_Width          ${v_h2f_address_width}
    set_instance_parameter_value agilex_hps H2F_IRQ_DMA_Enable0        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_DMA_Enable1        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_ECC_SERR_Enable    {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_EMAC0_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_EMAC1_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_EMAC2_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_GPIO0_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_GPIO1_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_I2C0_Enable        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_I2C1_Enable        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_I2CEMAC0_Enable    {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_I2CEMAC1_Enable    {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_I2CEMAC2_Enable    {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_I3C0_Enable        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_I3C1_Enable        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_L4Timer_Enable     {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_NAND_Enable        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_PeriphClock_Enable {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_SDMMC_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_SPIM0_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_SPIM1_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_SPIS0_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_SPIS1_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_SYSTimer_Enable    {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_UART0_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_UART1_Enable       {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_USB0_Enable        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_USB1_Enable        {0}
    set_instance_parameter_value agilex_hps H2F_IRQ_Watchdog_Enable    {0}
    set_instance_parameter_value agilex_hps H2F_Width                  {128}
    if {${v_board_name} == "AGX_5E_Si_Devkit"} {
        set_instance_parameter_value agilex_hps HPS_IO_Enable {GPIO0:IO0 GPIO0:IO1 UART0:TX UART0:RX EMAC2:PPS2 EMAC2:PPSTRIG2 MDIO2:MDIO MDIO2:MDC I3C1:SDA I3C1:SCL HCLK:HPS_OSC_CLK GPIO0:IO11 USB1:CLK USB1:STP USB1:DIR USB1:DATA0 USB1:DATA1 USB1:NXT USB1:DATA2 USB1:DATA3 USB1:DATA4 USB1:DATA5 USB1:DATA6 USB1:DATA7 SDMMC:DATA0 SDMMC:DATA1 SDMMC:CCLK GPIO1:IO3 GPIO1:IO4 SDMMC:DATA2 SDMMC:DATA3 SDMMC:CMD JTAG:TCK JTAG:TMS JTAG:TDO JTAG:TDI EMAC2:TX_CLK EMAC2:TX_CTL EMAC2:RX_CLK EMAC2:RX_CTL EMAC2:TXD0 EMAC2:TXD1 EMAC2:RXD0 EMAC2:RXD1 EMAC2:TXD2 EMAC2:TXD3 EMAC2:RXD2 EMAC2:RXD3}
    } elseif {${v_board_name} == "AGX_5E_Modular_Devkit"} {
        set_instance_parameter_value agilex_hps HPS_IO_Enable {GPIO0:IO0 GPIO0:IO1 UART0:TX UART0:RX EMAC2:PPS2 EMAC2:PPSTRIG2 MDIO2:MDIO MDIO2:MDC I2C_EMAC1:SDA I2C_EMAC1:SCL GPIO0:IO10 HCLK:HPS_OSC_CLK USB1:CLK USB1:STP USB1:DIR USB1:DATA0 USB1:DATA1 USB1:NXT USB1:DATA2 USB1:DATA3 USB1:DATA4 USB1:DATA5 USB1:DATA6 USB1:DATA7 SDMMC:DATA0 SDMMC:DATA1 SDMMC:CCLK GPIO1:IO3 GPIO1:IO4 SDMMC:DATA2 SDMMC:DATA3 SDMMC:CMD JTAG:TCK JTAG:TMS JTAG:TDO JTAG:TDI EMAC2:TX_CLK EMAC2:TX_CTL EMAC2:RX_CLK EMAC2:RX_CTL EMAC2:TXD0 EMAC2:TXD1 EMAC2:RXD0 EMAC2:RXD1 EMAC2:TXD2 EMAC2:TXD3 EMAC2:RXD2 EMAC2:RXD3}
    } else {
        set_instance_parameter_value agilex_hps HPS_IO_Enable {GPIO0:IO0 GPIO0:IO1 UART0:TX UART0:RX EMAC2:PPS2 EMAC2:PPSTRIG2 MDIO2:MDIO MDIO2:MDC I3C1:SDA I3C1:SCL HCLK:HPS_OSC_CLK GPIO0:IO11 USB1:CLK USB1:STP USB1:DIR USB1:DATA0 USB1:DATA1 USB1:NXT USB1:DATA2 USB1:DATA3 USB1:DATA4 USB1:DATA5 USB1:DATA6 USB1:DATA7 SDMMC:DATA0 SDMMC:DATA1 SDMMC:CCLK GPIO1:IO3 GPIO1:IO4 SDMMC:DATA2 SDMMC:DATA3 SDMMC:CMD JTAG:TCK JTAG:TMS JTAG:TDO JTAG:TDI EMAC2:TX_CLK EMAC2:TX_CTL EMAC2:RX_CLK EMAC2:RX_CTL EMAC2:TXD0 EMAC2:TXD1 EMAC2:RXD0 EMAC2:RXD1 EMAC2:TXD2 EMAC2:TXD3 EMAC2:RXD2 EMAC2:RXD3}
    }
    if {${v_i2c0_ext_en}} {
        set_instance_parameter_value agilex_hps I2C0_Mode                 {default}
        set_instance_parameter_value agilex_hps I2C0_PinMuxing            {FPGA}
    } else {
        set_instance_parameter_value agilex_hps I2C0_Mode                 {N/A}
        set_instance_parameter_value agilex_hps I2C0_PinMuxing            {Unused}
    }
    if {${v_i2c1_ext_en}} {
        set_instance_parameter_value agilex_hps I2C1_Mode                 {default}
        set_instance_parameter_value agilex_hps I2C1_PinMuxing            {FPGA}
    } else {
        set_instance_parameter_value agilex_hps I2C1_Mode                 {N/A}
        set_instance_parameter_value agilex_hps I2C1_PinMuxing            {Unused}
    }
    set_instance_parameter_value agilex_hps I2CEMAC0_Mode                 {N/A}
    set_instance_parameter_value agilex_hps I2CEMAC0_PinMuxing            {Unused}
    set_instance_parameter_value agilex_hps I2CEMAC1_Mode                 {default}
    set_instance_parameter_value agilex_hps I2CEMAC1_PinMuxing            {IO}
    set_instance_parameter_value agilex_hps I2CEMAC2_Mode                 {N/A}
    set_instance_parameter_value agilex_hps I2CEMAC2_PinMuxing            {Unused}
    set_instance_parameter_value agilex_hps I3C0_Mode                     {N/A}
    set_instance_parameter_value agilex_hps I3C0_PinMuxing                {Unused}
    set_instance_parameter_value agilex_hps I3C1_Mode                     {N/A}
    set_instance_parameter_value agilex_hps I3C1_PinMuxing                {Unused}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY0               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY1               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY10              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY11              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY12              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY13              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY14              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY15              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY16              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY17              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY18              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY19              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY2               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY20              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY21              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY22              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY23              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY24              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY25              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY26              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY27              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY28              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY29              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY3               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY30              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY31              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY32              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY33              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY34              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY35              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY36              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY37              {-1}
    if {${v_emac2_txrx_clk_delay_en} == 1} {
        set_instance_parameter_value agilex_hps IO_INPUT_DELAY38          {21}
    } else {
        set_instance_parameter_value agilex_hps IO_INPUT_DELAY38          {-1}
    }
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY39              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY4               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY40              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY41              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY42              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY43              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY44              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY45              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY46              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY47              {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY5               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY6               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY7               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY8               {-1}
    set_instance_parameter_value agilex_hps IO_INPUT_DELAY9               {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY0              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY1              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY10             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY11             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY12             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY13             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY14             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY15             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY16             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY17             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY18             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY19             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY2              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY20             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY21             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY22             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY23             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY24             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY25             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY26             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY27             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY28             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY29             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY3              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY30             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY31             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY32             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY33             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY34             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY35             {-1}
    if {${v_emac2_txrx_clk_delay_en} == 1} {
        set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY36         {21}
    } else {
        set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY36         {-1}
    }
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY37             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY38             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY39             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY4              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY40             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY41             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY42             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY43             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY44             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY45             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY46             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY47             {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY5              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY6              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY7              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY8              {-1}
    set_instance_parameter_value agilex_hps IO_OUTPUT_DELAY9              {-1}
    set_instance_parameter_value agilex_hps JTAG_Enable                   {0}
    set_instance_parameter_value agilex_hps LWH2F_Address_Width           {29}
    set_instance_parameter_value agilex_hps LWH2F_Width                   {32}
    set_instance_parameter_value agilex_hps MPLL_C0_Override_mhz          {1600.0}
    set_instance_parameter_value agilex_hps MPLL_C1_Override_mhz          {800.0}
    set_instance_parameter_value agilex_hps MPLL_C2_Override_mhz          {1066.67}
    set_instance_parameter_value agilex_hps MPLL_C3_Override_mhz          {400.0}
    set_instance_parameter_value agilex_hps MPLL_Clock_Source             {0}
    set_instance_parameter_value agilex_hps MPLL_Override                 {0}
    set_instance_parameter_value agilex_hps MPLL_VCO_Override_mhz         {3200.0}
    set_instance_parameter_value agilex_hps MPU_Events_Enable             {0}
    set_instance_parameter_value agilex_hps MPU_clk_ccu_div               {2}
    set_instance_parameter_value agilex_hps MPU_clk_freq_override_mhz     {1066.67}
    set_instance_parameter_value agilex_hps MPU_clk_override              {0}
    set_instance_parameter_value agilex_hps MPU_clk_periph_div            {4}
    set_instance_parameter_value agilex_hps MPU_clk_src_override          {2}
    set_instance_parameter_value agilex_hps MPU_core01_src_override       {1}
    set_instance_parameter_value agilex_hps MPU_core23_src_override       {0}
    set_instance_parameter_value agilex_hps MPU_core2_freq_override_mhz   {1600.0}
    set_instance_parameter_value agilex_hps MPU_core3_freq_override_mhz   {1600.0}
    set_instance_parameter_value agilex_hps NAND_Mode                     {N/A}
    set_instance_parameter_value agilex_hps NAND_PinMuxing                {Unused}
    set_instance_parameter_value agilex_hps NOC_clk_cs_debug_div          {4}
    set_instance_parameter_value agilex_hps NOC_clk_cs_div                {1}
    set_instance_parameter_value agilex_hps NOC_clk_cs_trace_div          {4}
    set_instance_parameter_value agilex_hps NOC_clk_free_l4_div           {4}
    set_instance_parameter_value agilex_hps NOC_clk_periph_l4_div         {2}
    set_instance_parameter_value agilex_hps NOC_clk_phy_div               {4}
    set_instance_parameter_value agilex_hps NOC_clk_slow_l4_div           {4}
    set_instance_parameter_value agilex_hps NOC_clk_src_select            {3}
    set_instance_parameter_value agilex_hps PLL_CLK0                      {Unused}
    set_instance_parameter_value agilex_hps PLL_CLK1                      {Unused}
    set_instance_parameter_value agilex_hps PLL_CLK2                      {Unused}
    set_instance_parameter_value agilex_hps PLL_CLK3                      {Unused}
    set_instance_parameter_value agilex_hps PLL_CLK4                      {Unused}
    set_instance_parameter_value agilex_hps PPLL_C0_Override_mhz          {1600.0}
    set_instance_parameter_value agilex_hps PPLL_C1_Override_mhz          {800.0}
    set_instance_parameter_value agilex_hps PPLL_C2_Override_mhz          {1066.67}
    set_instance_parameter_value agilex_hps PPLL_C3_Override_mhz          {400.0}
    set_instance_parameter_value agilex_hps PPLL_Clock_Source             {0}
    set_instance_parameter_value agilex_hps PPLL_Override                 {0}
    set_instance_parameter_value agilex_hps PPLL_VCO_Override_mhz         {3200.0}
    set_instance_parameter_value agilex_hps Periph_clk_emac0_sel          {50}
    set_instance_parameter_value agilex_hps Periph_clk_emac1_sel          {50}
    set_instance_parameter_value agilex_hps Periph_clk_emac2_sel          {50}
    set_instance_parameter_value agilex_hps Periph_clk_override           {0}
    set_instance_parameter_value agilex_hps Periph_emac_ptp_freq_override {400.0}
    set_instance_parameter_value agilex_hps Periph_emac_ptp_src_override  {7}
    set_instance_parameter_value agilex_hps Periph_emaca_src_override     {7}
    set_instance_parameter_value agilex_hps Periph_emacb_src_override     {7}
    set_instance_parameter_value agilex_hps Periph_gpio_freq_override     {400.0}
    set_instance_parameter_value agilex_hps Periph_gpio_src_override      {3}
    set_instance_parameter_value agilex_hps Periph_psi_freq_override      {500.0}
    set_instance_parameter_value agilex_hps Periph_psi_src_override       {7}
    set_instance_parameter_value agilex_hps Periph_usb_freq_override      {20.0}
    set_instance_parameter_value agilex_hps Periph_usb_src_override       {3}
    set_instance_parameter_value agilex_hps Pwr_a55_core0_1_on            {1}
    set_instance_parameter_value agilex_hps Pwr_a76_core2_on              {1}
    set_instance_parameter_value agilex_hps Pwr_a76_core3_on              {1}
    set_instance_parameter_value agilex_hps Pwr_boot_core_sel             {0}
    set_instance_parameter_value agilex_hps Pwr_cpu_app_select            {0}
    set_instance_parameter_value agilex_hps Pwr_mpu_l3_cache_size         {2}
    set_instance_parameter_value agilex_hps Rst_h2f_cold_en               {0}
    set_instance_parameter_value agilex_hps Rst_hps_warm_en               {0}
    set_instance_parameter_value agilex_hps Rst_sdm_wd_config             {0}
    set_instance_parameter_value agilex_hps Rst_watchdog_en               {0}
    set_instance_parameter_value agilex_hps SDMMC_Mode                    {N/A}
    set_instance_parameter_value agilex_hps SDMMC_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps SPIM0_Mode                    {N/A}
    set_instance_parameter_value agilex_hps SPIM0_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps SPIM1_Mode                    {N/A}
    set_instance_parameter_value agilex_hps SPIM1_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps SPIS0_Mode                    {N/A}
    set_instance_parameter_value agilex_hps SPIS0_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps SPIS1_Mode                    {N/A}
    set_instance_parameter_value agilex_hps SPIS1_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps STM_Enable                    {0}
    set_instance_parameter_value agilex_hps TPIU_Select                   {HPS Clock Manager}
    set_instance_parameter_value agilex_hps TRACE_Mode                    {N/A}
    set_instance_parameter_value agilex_hps TRACE_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps UART0_Mode                    {No_flow_control}
    set_instance_parameter_value agilex_hps UART0_PinMuxing               {IO}
    set_instance_parameter_value agilex_hps UART1_Mode                    {N/A}
    set_instance_parameter_value agilex_hps UART1_PinMuxing               {Unused}
    set_instance_parameter_value agilex_hps USB0_Mode                     {N/A}
    set_instance_parameter_value agilex_hps USB0_PinMuxing                {Unused}
    set_instance_parameter_value agilex_hps USB1_Mode                     {default}
    set_instance_parameter_value agilex_hps USB1_PinMuxing                {IO}
    set_instance_parameter_value agilex_hps User0_clk_enable              {1}
    set_instance_parameter_value agilex_hps User0_clk_freq                {100.0}
    set_instance_parameter_value agilex_hps User0_clk_src_select          {7}
    set_instance_parameter_value agilex_hps User1_clk_enable              {0}
    set_instance_parameter_value agilex_hps User1_clk_freq                {500.0}
    set_instance_parameter_value agilex_hps User1_clk_src_select          {7}
    set_instance_parameter_value agilex_hps eosc1_clk_mhz                 {25.0}
    set_instance_parameter_value agilex_hps f2s_SMMU                      {0}
    set_instance_parameter_value agilex_hps f2s_address_width             {32}
    if {${v_f2h_en}} {
        set_instance_parameter_value agilex_hps f2s_data_width            {256}
    } else {
        set_instance_parameter_value agilex_hps f2s_data_width            {0}
    }
    set_instance_parameter_value agilex_hps f2sdram_address_width         ${v_f2sdram_addr_width}
    set_instance_parameter_value agilex_hps f2sdram_data_width            {256}
    set_instance_parameter_value agilex_hps f2sdram_SMMU                  {0}
    set_instance_parameter_value agilex_hps hps_ioa10_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa11_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa12_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa13_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa14_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa15_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa16_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa17_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa18_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa19_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa1_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa20_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa21_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa22_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa23_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa24_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_ioa2_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa3_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa4_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa5_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa6_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa7_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa8_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_ioa9_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob10_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob11_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob12_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob13_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob14_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob15_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob16_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob17_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob18_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob19_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob1_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob20_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob21_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob22_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob23_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob24_opd_en              {0}
    set_instance_parameter_value agilex_hps hps_iob2_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob3_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob4_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob5_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob6_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob7_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob8_opd_en               {0}
    set_instance_parameter_value agilex_hps hps_iob9_opd_en               {0}

    # emif_agilex_hps
    set_instance_parameter_value emif_agilex_hps EMIF_PROTOCOL            {DDR4_COMP}
    set_instance_parameter_value emif_agilex_hps EMIF_TOPOLOGY            {1x32}

    apply_instance_preset emif_agilex_hps ${v_project_path}/non_qpds_ip/shell/${v_drv_ddr_preset_file}

    # gts_reset_sequencer
    set_instance_parameter_value gts_reset_sequencer SRC_RS_DISABLE       {1}
    set_instance_parameter_value gts_reset_sequencer NUM_LANES_SHORELINE  {1}
    set_instance_parameter_value gts_reset_sequencer NUM_BANKS_SHORELINE  {1}

    # hps_axi_clk_bridge
    set_instance_parameter_value hps_axi_clk_bridge EXPLICIT_CLOCK_RATE   ${v_hps_axi_clk}
    set_instance_parameter_value hps_axi_clk_bridge NUM_CLOCK_OUTPUTS     {1}

    # hps_axi_rst_bridge
    set_instance_parameter_value hps_axi_rst_bridge ACTIVE_LOW_RESET      {0}
    set_instance_parameter_value hps_axi_rst_bridge NUM_RESET_OUTPUTS     {1}
    set_instance_parameter_value hps_axi_rst_bridge SYNCHRONOUS_EDGES     {deassert}
    set_instance_parameter_value hps_axi_rst_bridge SYNC_RESET            {0}
    set_instance_parameter_value hps_axi_rst_bridge USE_RESET_REQUEST     {0}

    # fpga2hps_axi_bridge
    if {${v_f2h_en}} {
        set_instance_parameter_value fpga2hps_axi_bridge  AXI_VERSION       {AXI4}
        set_instance_parameter_value fpga2hps_axi_bridge  DATA_WIDTH        {256}
        set_instance_parameter_value fpga2hps_axi_bridge  ADDR_WIDTH        {32}
        set_instance_parameter_value fpga2hps_axi_bridge  S0_ID_WIDTH       {3}
        set_instance_parameter_value fpga2hps_axi_bridge  M0_ID_WIDTH       {3}
    }

    # hps_h2f_user0_clk_bridge
    set_instance_parameter_value hps_h2f_user0_clk_bridge EXPLICIT_CLOCK_RATE {100000000.0}
    set_instance_parameter_value hps_h2f_user0_clk_bridge NUM_CLOCK_OUTPUTS   {1}


    if {${v_msgdma_en} == 0} {
        # NOTE: temp IP to get around issues with f2sdram not being connected (and cannot be unused!)
        add_instance temp_ext_hps_m_master  altera_address_span_extender
        add_instance temp_hps_m             altera_jtag_avalon_master

        set_instance_parameter_value temp_ext_hps_m_master BURSTCOUNT_WIDTH     {1}
        set_instance_parameter_value temp_ext_hps_m_master DATA_WIDTH           {32}
        set_instance_parameter_value temp_ext_hps_m_master ENABLE_SLAVE_PORT    {0}
        set_instance_parameter_value temp_ext_hps_m_master MASTER_ADDRESS_DEF   {0}
        set_instance_parameter_value temp_ext_hps_m_master MASTER_ADDRESS_WIDTH {33}
        set_instance_parameter_value temp_ext_hps_m_master MAX_PENDING_READS    {1}
        set_instance_parameter_value temp_ext_hps_m_master SLAVE_ADDRESS_WIDTH  {30}
        set_instance_parameter_value temp_ext_hps_m_master SUB_WINDOW_COUNT     {1}
        set_instance_parameter_value temp_ext_hps_m_master SYNC_RESET           {0}

        add_connection  hps_axi_clk_bridge.out_clk            temp_ext_hps_m_master.clock
        add_connection  hps_axi_rst_bridge.out_reset          temp_ext_hps_m_master.reset
        add_connection  hps_axi_clk_bridge.out_clk            temp_hps_m.clk
        add_connection  hps_axi_rst_bridge.out_reset          temp_hps_m.clk_reset
        add_connection  temp_ext_hps_m_master.expanded_master agilex_hps.f2sdram
        add_connection  temp_hps_m.master                     temp_ext_hps_m_master.windowed_slave
    }


    ############################
    #### Create Connections ####
    ############################

    # clock / reset bridge connections
    add_connection  hps_axi_clk_bridge.out_clk        hps_axi_rst_bridge.clk
    add_connection  hps_axi_clk_bridge.out_clk        agilex_hps.hps2fpga_axi_clock
    add_connection  hps_axi_clk_bridge.out_clk        agilex_hps.lwhps2fpga_axi_clock
    add_connection  hps_axi_clk_bridge.out_clk        agilex_hps.usb31_phy_reconfig_clk
    add_connection  hps_axi_clk_bridge.out_clk        agilex_hps.f2sdram_axi_clock

    add_connection  agilex_hps.h2f_user0_clk          hps_h2f_user0_clk_bridge.in_clk

    add_connection  hps_axi_rst_bridge.out_reset      agilex_hps.hps2fpga_axi_reset
    add_connection  hps_axi_rst_bridge.out_reset      agilex_hps.lwhps2fpga_axi_reset
    add_connection  hps_axi_rst_bridge.out_reset      agilex_hps.usb31_phy_reconfig_rst
    add_connection  hps_axi_rst_bridge.out_reset      agilex_hps.f2sdram_axi_reset

    if {${v_f2h_en}} {
        add_connection  hps_axi_clk_bridge.out_clk      agilex_hps.fpga2hps_clock
        add_connection  hps_axi_rst_bridge.out_reset    agilex_hps.fpga2hps_reset
        add_connection  hps_axi_clk_bridge.out_clk      fpga2hps_axi_bridge.clk
        add_connection  hps_axi_rst_bridge.out_reset    fpga2hps_axi_bridge.clk_reset
        add_connection  fpga2hps_axi_bridge.m0          agilex_hps.fpga2hps
    }

    # HPS / EMIF connections
    add_connection  emif_agilex_hps.io96b0_to_hps     agilex_hps.io96b0_to_hps

    # Export interfaces

    # Clock / Reset bridges
    add_interface          hps_axi_clk_bridge_in_clk clock sink
    set_interface_property hps_axi_clk_bridge_in_clk  EXPORT_OF hps_axi_clk_bridge.in_clk

    add_interface          hps_axi_rst_bridge_in_reset reset sink
    set_interface_property hps_axi_rst_bridge_in_reset EXPORT_OF hps_axi_rst_bridge.in_reset

    set_interface_property o_hps_h2f_user0_clock EXPORT_OF hps_h2f_user0_clk_bridge.out_clk

    # HPS IO interfaces
    add_interface           agilex_hps_hps_io conduit end
    set_interface_property  agilex_hps_hps_io EXPORT_OF agilex_hps.hps_io

    # HPS USB 3.1 interfaces
    add_interface           agilex_hps_usb31_io conduit end
    set_interface_property  agilex_hps_usb31_io EXPORT_OF agilex_hps.usb31_io

    add_interface           agilex_hps_usb31_phy_pma_cpu_clk clock sink
    set_interface_property  agilex_hps_usb31_phy_pma_cpu_clk EXPORT_OF agilex_hps.usb31_phy_pma_cpu_clk

    add_interface           agilex_hps_usb31_phy_refclk_p clock sink
    set_interface_property  agilex_hps_usb31_phy_refclk_p EXPORT_OF agilex_hps.usb31_phy_refclk_p

    add_interface           agilex_hps_usb31_phy_refclk_n clock sink
    set_interface_property  agilex_hps_usb31_phy_refclk_n EXPORT_OF agilex_hps.usb31_phy_refclk_n

    add_interface           agilex_hps_usb31_phy_rx_serial_p conduit end
    set_interface_property  agilex_hps_usb31_phy_rx_serial_p EXPORT_OF agilex_hps.usb31_phy_rx_serial_p

    add_interface           agilex_hps_usb31_phy_rx_serial_n conduit end
    set_interface_property  agilex_hps_usb31_phy_rx_serial_n EXPORT_OF agilex_hps.usb31_phy_rx_serial_n

    add_interface           agilex_hps_usb31_phy_tx_serial_p conduit end
    set_interface_property  agilex_hps_usb31_phy_tx_serial_p EXPORT_OF agilex_hps.usb31_phy_tx_serial_p

    add_interface           agilex_hps_usb31_phy_tx_serial_n conduit end
    set_interface_property  agilex_hps_usb31_phy_tx_serial_n EXPORT_OF agilex_hps.usb31_phy_tx_serial_n

    # EMIF interfaces
    add_interface           agilex_hps_emif_mem conduit end
    set_interface_property  agilex_hps_emif_mem EXPORT_OF emif_agilex_hps.mem_0

    add_interface           agilex_hps_emif_mem_ck conduit end
    set_interface_property  agilex_hps_emif_mem_ck EXPORT_OF emif_agilex_hps.mem_ck_0

    add_interface           agilex_hps_emif_mem_reset_n conduit end
    set_interface_property  agilex_hps_emif_mem_reset_n EXPORT_OF emif_agilex_hps.mem_reset_n

    add_interface           agilex_hps_emif_oct conduit end
    set_interface_property  agilex_hps_emif_oct EXPORT_OF emif_agilex_hps.oct_0

    add_interface           agilex_hps_emif_ref_clk clock sink
    set_interface_property  agilex_hps_emif_ref_clk EXPORT_OF emif_agilex_hps.ref_clk

    # Misc interfaces
    add_interface           agilex_hps_h2f_reset    reset       source
    set_interface_property  agilex_hps_h2f_reset    EXPORT_OF   agilex_hps.h2f_reset

    add_interface           o_pma_cu_clk            conduit     end
    set_interface_property  o_pma_cu_clk            EXPORT_OF   gts_reset_sequencer.o_pma_cu_clk

    # I2C0
    if {${v_i2c0_ext_en}} {
        add_interface          agilex_hps_i2c0_scl_i  clock       sink
        set_interface_property agilex_hps_i2c0_scl_i  EXPORT_OF   agilex_hps.I2C0_scl_i

        add_interface          agilex_hps_i2c0_scl_oe clock      source
        set_interface_property agilex_hps_i2c0_scl_oe EXPORT_OF  agilex_hps.I2C0_scl_oe

        add_interface          agilex_hps_i2c0    conduit    end
        set_interface_property agilex_hps_i2c0    EXPORT_OF  agilex_hps.I2C0
    }

    # I2C1
    if {${v_i2c1_ext_en}} {
        add_interface           agilex_hps_i2c1_scl_i   clock       sink
        set_interface_property  agilex_hps_i2c1_scl_i   EXPORT_OF   agilex_hps.I2C1_scl_i

        add_interface           agilex_hps_i2c1_scl_oe  clock       source
        set_interface_property  agilex_hps_i2c1_scl_oe  EXPORT_OF   agilex_hps.I2C1_scl_oe

        add_interface           agilex_hps_i2c1         conduit     end
        set_interface_property  agilex_hps_i2c1         EXPORT_OF   agilex_hps.I2C1
    }

    if {${v_f2h_en}} {
        add_interface           agilex_hps_f2h_axi_s0   AXI4        subordinate
        set_interface_property  agilex_hps_f2h_axi_s0   EXPORT_OF   fpga2hps_axi_bridge.s0
    }


    ##############################
    ##### Optional Instances #####
    ##############################
    if {${v_drv_enable_h2f}} {
        if {${v_h2f_is_axi} == 0} {
            add_instance                    hps_mm_bridge_h2f           altera_avalon_mm_bridge

            set_instance_parameter_value    hps_mm_bridge_h2f           ADDRESS_UNITS             {SYMBOLS}
            set_instance_parameter_value    hps_mm_bridge_h2f           ADDRESS_WIDTH             {20}
            set_instance_parameter_value    hps_mm_bridge_h2f           DATA_WIDTH                {32}
            set_instance_parameter_value    hps_mm_bridge_h2f           LINEWRAPBURSTS            {0}
            set_instance_parameter_value    hps_mm_bridge_h2f           MAX_BURST_SIZE            {1}
            set_instance_parameter_value    hps_mm_bridge_h2f           MAX_PENDING_RESPONSES     {4}
            set_instance_parameter_value    hps_mm_bridge_h2f           MAX_PENDING_WRITES        {0}
            set_instance_parameter_value    hps_mm_bridge_h2f           PIPELINE_COMMAND          {1}
            set_instance_parameter_value    hps_mm_bridge_h2f           PIPELINE_RESPONSE         {1}
            set_instance_parameter_value    hps_mm_bridge_h2f           SYMBOL_WIDTH              {8}
            set_instance_parameter_value    hps_mm_bridge_h2f           SYNC_RESET                {0}
            set_instance_parameter_value    hps_mm_bridge_h2f           USE_AUTO_ADDRESS_WIDTH    {1}
            set_instance_parameter_value    hps_mm_bridge_h2f           USE_RESPONSE              {0}
            set_instance_parameter_value    hps_mm_bridge_h2f           USE_WRITERESPONSE         {0}

            add_connection                  hps_axi_clk_bridge.out_clk      hps_mm_bridge_h2f.clk
            add_connection                  hps_axi_rst_bridge.out_reset    hps_mm_bridge_h2f.reset

            add_connection                  agilex_hps.hps2fpga             hps_mm_bridge_h2f.s0

            set_connection_parameter_value  agilex_hps.hps2fpga/hps_mm_bridge_h2f.s0  baseAddress 0x000000
            lock_avalon_base_address        hps_mm_bridge_h2f.s0

            set_interface_property hps_mm_bridge_h2f_m0 EXPORT_OF hps_mm_bridge_h2f.m0
            # increase performance
            set_connection_parameter_value agilex_hps.hps2fpga/hps_mm_bridge_h2f.s0 \
                    qsys_mm.burstAdapterImplementation {PER_BURST_TYPE_CONVERTER}
            set_postadaptation_assignment \
                    mm_interconnect_2|hps_mm_bridge_h2f_s0_burst_adapter.source0/hps_mm_bridge_h2f_s0_agent.cp \
                    qsys_mm.postTransform.pipelineCount 1
        } else {
            # set_interface_property hps_hps2fpga  EXPORT_OF agilex_hps.hps2fpga
            add_instance hps_axi_bridge_h2f altera_axi_bridge
            set_instance_parameter_value hps_axi_bridge_h2f SYNC_RESET                            {0}
            set_instance_parameter_value hps_axi_bridge_h2f BACKPRESSURE_DURING_RESET             {0}

            set_instance_parameter_value hps_axi_bridge_h2f AXI_VERSION                           {AXI4-Lite}
            set_instance_parameter_value hps_axi_bridge_h2f ACE_LITE_SUPPORT                      {0}
            set_instance_parameter_value hps_axi_bridge_h2f DATA_WIDTH                            {32}
            set_instance_parameter_value hps_axi_bridge_h2f ADDR_WIDTH                            {21}

            set_instance_parameter_value hps_axi_bridge_h2f WRITE_ADDR_USER_WIDTH                 {1}
            set_instance_parameter_value hps_axi_bridge_h2f READ_ADDR_USER_WIDTH                  {1}
            set_instance_parameter_value hps_axi_bridge_h2f WRITE_DATA_USER_WIDTH                 {1}
            set_instance_parameter_value hps_axi_bridge_h2f READ_DATA_USER_WIDTH                  {1}
            set_instance_parameter_value hps_axi_bridge_h2f WRITE_RESP_USER_WIDTH                 {1}

            set_instance_parameter_value hps_axi_bridge_h2f BITSPERBYTE                           {0}
            set_instance_parameter_value hps_axi_bridge_h2f SAI_WIDTH                             {1}
            set_instance_parameter_value hps_axi_bridge_h2f UNTRANSLATED_TXN                      {0}
            set_instance_parameter_value hps_axi_bridge_h2f SID_WIDTH                             {1}

            set_instance_parameter_value hps_axi_bridge_h2f S0_ID_WIDTH                           {8}
            set_instance_parameter_value hps_axi_bridge_h2f WRITE_ACCEPTANCE_CAPABILITY           {16}
            set_instance_parameter_value hps_axi_bridge_h2f READ_ACCEPTANCE_CAPABILITY            {16}
            set_instance_parameter_value hps_axi_bridge_h2f COMBINED_ACCEPTANCE_CAPABILITY        {16}
            set_instance_parameter_value hps_axi_bridge_h2f READ_DATA_REORDERING_DEPTH            {1}

            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_AWREGION                       {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_AWLOCK                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_AWCACHE                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_AWQOS                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_AWPROT                         {1}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_AWUSER                         {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_WLAST                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_WUSER                          {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_BRESP                          {1}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_BUSER                          {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_ARREGION                       {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_ARLOCK                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_ARCACHE                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_ARQOS                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_ARPROT                         {1}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_ARUSER                         {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_RRESP                          {1}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_RUSER                          {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_ADDRCHK                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_SAI                            {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_DATACHK                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_POISON                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_S0_USER_DATA                      {0}

            set_instance_parameter_value hps_axi_bridge_h2f M0_ID_WIDTH                           {8}
            set_instance_parameter_value hps_axi_bridge_h2f WRITE_ISSUING_CAPABILITY              {16}
            set_instance_parameter_value hps_axi_bridge_h2f READ_ISSUING_CAPABILITY               {16}
            set_instance_parameter_value hps_axi_bridge_h2f COMBINED_ISSUING_CAPABILITY           {16}
            set_instance_parameter_value hps_axi_bridge_h2f ENABLE_CONCURRENT_SUBORDINATE_ACCESS  {0}
            set_instance_parameter_value hps_axi_bridge_h2f ENABLE_OOO                            {0}
            set_instance_parameter_value hps_axi_bridge_h2f NO_REPEATED_IDS_BETWEEN_SUBORDINATES  {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWID                           {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWREGION                       {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWLEN                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWSIZE                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWBURST                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWLOCK                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWCACHE                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWQOS                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWUSER                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_AWUNIQUE                       {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_WSTRB                          {1}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_WUSER                          {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_BID                            {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_BRESP                          {1}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_BUSER                          {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARID                           {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARREGION                       {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARLEN                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARSIZE                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARBURST                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARLOCK                         {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARCACHE                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARQOS                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ARUSER                         {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_RID                            {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_RRESP                          {1}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_RLAST                          {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_RUSER                          {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_ADDRCHK                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_SAI                            {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_DATACHK                        {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_USER_DATA                      {0}
            set_instance_parameter_value hps_axi_bridge_h2f USE_M0_POISON                         {0}

            set_instance_parameter_value hps_axi_bridge_h2f USE_PIPELINE                          {1}

            add_connection agilex_hps.hps2fpga      hps_axi_bridge_h2f.s0
            set_connection_parameter_value          agilex_hps.hps2fpga/hps_axi_bridge_h2f.s0  baseAddress 0x000000
            lock_avalon_base_address                hps_axi_bridge_h2f.s0

            add_connection hps_axi_clk_bridge.out_clk     hps_axi_bridge_h2f.clk
            add_connection hps_axi_rst_bridge.out_reset   hps_axi_bridge_h2f.clk_reset

            set_interface_property hps_axi_bridge_h2f_m0  EXPORT_OF hps_axi_bridge_h2f.m0
        }
    }

    if {${v_drv_enable_h2f_lw}} {
        if {${v_h2f_lw_is_axi} == 0} {
            add_instance  hps_mm_bridge_h2f_lw                           altera_avalon_mm_bridge

            set_instance_parameter_value      hps_mm_bridge_h2f_lw       ADDRESS_UNITS          {SYMBOLS}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       ADDRESS_WIDTH          {20}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       DATA_WIDTH             {32}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       LINEWRAPBURSTS         {0}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       MAX_BURST_SIZE         {1}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       MAX_PENDING_RESPONSES  {4}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       MAX_PENDING_WRITES     {0}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       PIPELINE_COMMAND       {1}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       PIPELINE_RESPONSE      {1}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       SYMBOL_WIDTH           {8}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       SYNC_RESET             {0}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       USE_AUTO_ADDRESS_WIDTH {1}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       USE_RESPONSE           {0}
            set_instance_parameter_value      hps_mm_bridge_h2f_lw       USE_WRITERESPONSE      {0}

            add_connection         hps_axi_clk_bridge.out_clk           hps_mm_bridge_h2f_lw.clk
            add_connection         hps_axi_rst_bridge.out_reset         hps_mm_bridge_h2f_lw.reset
            add_connection         agilex_hps.lwhps2fpga                hps_mm_bridge_h2f_lw.s0

            set_interface_property hps_mm_bridge_h2f_lw_m0 EXPORT_OF hps_mm_bridge_h2f_lw.m0
        } else {
            set_interface_property hps_lwhps2fpga  EXPORT_OF agilex_hps.lwhps2fpga
        }
    }

    if {${v_fpga_emif_enabled}} {
        set v_fpga_emif_host_addr_width           [get_shell_parameter FPGA_EMIF_HOST_ADDR_WIDTH]
        set v_fpga_emif_agent_addr_width          [get_shell_parameter FPGA_EMIF_AGENT_ADDR_WIDTH]
        set v_fpga_emif_window_base_address       [get_shell_parameter FPGA_EMIF_WINDOW_BASE_ADDRESS]
        set v_fpga_emif_window_ctrl_base_address  [get_shell_parameter FPGA_EMIF_WINDOW_CTRL_BASE_ADDRESS]

        add_instance  hps_fpga_emif_clk_bridge        altera_clock_bridge
        add_instance  hps_fpga_emif_rst_bridge        altera_reset_bridge
        add_instance  hps_fpga_emif_address_se        altera_address_span_extender
        add_instance  hps_fpga_emif_cc_bridge         mm_ccb

        set_instance_parameter_value  hps_fpga_emif_clk_bridge    EXPLICIT_CLOCK_RATE   {200000000.0}
        set_instance_parameter_value  hps_fpga_emif_clk_bridge    NUM_CLOCK_OUTPUTS     {1}

        set_instance_parameter_value  hps_fpga_emif_rst_bridge    ACTIVE_LOW_RESET      {0}
        set_instance_parameter_value  hps_fpga_emif_rst_bridge    NUM_RESET_OUTPUTS     {1}
        set_instance_parameter_value  hps_fpga_emif_rst_bridge    SYNCHRONOUS_EDGES     {deassert}
        set_instance_parameter_value  hps_fpga_emif_rst_bridge    SYNC_RESET            {0}
        set_instance_parameter_value  hps_fpga_emif_rst_bridge    USE_RESET_REQUEST     {0}

        set_instance_parameter_value  hps_fpga_emif_address_se    BURSTCOUNT_WIDTH      {1}
        set_instance_parameter_value  hps_fpga_emif_address_se    DATA_WIDTH            {128}
        set_instance_parameter_value  hps_fpga_emif_address_se    ENABLE_SLAVE_PORT     {1}
        set_instance_parameter_value  hps_fpga_emif_address_se    MASTER_ADDRESS_DEF    {0}
        set_instance_parameter_value  hps_fpga_emif_address_se    MASTER_ADDRESS_WIDTH  ${v_fpga_emif_host_addr_width}
        set_instance_parameter_value  hps_fpga_emif_address_se    MAX_PENDING_READS     {1}
        set_instance_parameter_value  hps_fpga_emif_address_se    SLAVE_ADDRESS_WIDTH   ${v_fpga_emif_agent_addr_width}
        set_instance_parameter_value  hps_fpga_emif_address_se    SUB_WINDOW_COUNT      {1}
        set_instance_parameter_value  hps_fpga_emif_address_se    SYNC_RESET            {0}

        set_instance_parameter_value  hps_fpga_emif_cc_bridge     ADDRESS_UNITS          {SYMBOLS}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     ADDRESS_WIDTH          ${v_fpga_emif_host_addr_width}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     COMMAND_FIFO_DEPTH     {4}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     DATA_WIDTH             {256}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     MASTER_SYNC_DEPTH      {2}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     MAX_BURST_SIZE         {1}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     RESPONSE_FIFO_DEPTH    {4}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     SLAVE_SYNC_DEPTH       {2}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     SYMBOL_WIDTH           {8}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     SYNC_RESET             {0}
        set_instance_parameter_value  hps_fpga_emif_cc_bridge     USE_AUTO_ADDRESS_WIDTH {0}

        add_connection  hps_fpga_emif_clk_bridge.out_clk           hps_fpga_emif_rst_bridge.clk
        add_connection  hps_fpga_emif_clk_bridge.out_clk           hps_fpga_emif_cc_bridge.m0_clk

        add_connection  hps_fpga_emif_rst_bridge.out_reset         hps_fpga_emif_cc_bridge.m0_reset

        add_connection   hps_axi_clk_bridge.out_clk                  hps_fpga_emif_address_se.clock
        add_connection   hps_axi_clk_bridge.out_clk                  hps_fpga_emif_cc_bridge.s0_clk

        add_connection   hps_axi_rst_bridge.out_reset                hps_fpga_emif_address_se.reset
        add_connection   hps_axi_rst_bridge.out_reset                hps_fpga_emif_cc_bridge.s0_reset

        add_connection   hps_fpga_emif_address_se.expanded_master    hps_fpga_emif_cc_bridge.s0

        add_connection   agilex_hps.hps2fpga                         hps_fpga_emif_address_se.windowed_slave
        add_connection   agilex_hps.hps2fpga                         hps_fpga_emif_address_se.cntl

        add_interface           fpga_emif_clock   clock         sink
        set_interface_property  fpga_emif_clock   EXPORT_OF     hps_fpga_emif_clk_bridge.in_clk

        add_interface           fpga_emif_reset   reset         sink
        set_interface_property  fpga_emif_reset   EXPORT_OF     hps_fpga_emif_rst_bridge.in_reset

        add_interface           fpga_emif_avmm_m0   avalon      host
        set_interface_property  fpga_emif_avmm_m0   EXPORT_OF   hps_fpga_emif_cc_bridge.m0

        set_connection_parameter_value agilex_hps.hps2fpga/hps_fpga_emif_address_se.windowed_slave \
                    baseAddress ${v_fpga_emif_window_base_address}
        set_connection_parameter_value agilex_hps.hps2fpga/hps_fpga_emif_address_se.cntl \
                    baseAddress ${v_fpga_emif_window_ctrl_base_address}

        lock_avalon_base_address hps_fpga_emif_address_se.windowed_slave
        lock_avalon_base_address hps_fpga_emif_address_se.cntl

        # increase performance
        set_connection_parameter_value agilex_hps.hps2fpga/hps_fpga_emif_address_se.cntl \
                        qsys_mm.burstAdapterImplementation {PER_BURST_TYPE_CONVERTER}
        set_connection_parameter_value agilex_hps.hps2fpga/hps_fpga_emif_address_se.windowed_slave \
                        qsys_mm.burstAdapterImplementation {PER_BURST_TYPE_CONVERTER}
        set_connection_parameter_value hps_fpga_emif_address_se.expanded_master/hps_fpga_emif_cc_bridge.s0 \
                        qsys_mm.burstAdapterImplementation {PER_BURST_TYPE_CONVERTER}
        set_domain_assignment agilex_hps.hps2fpga qsys_mm.burstAdapterImplementation PER_BURST_TYPE_CONVERTER
        set_domain_assignment hps_fpga_emif_address_se.expanded_master \
                        qsys_mm.burstAdapterImplementation PER_BURST_TYPE_CONVERTER
        set_postadaptation_assignment mm_interconnect_2|cmd_mux_002 qsys_mm.postTransform.pipelineCount 1
        set_postadaptation_assignment mm_interconnect_2|\
                        hps_fpga_emif_address_se_cntl_burst_adapter.source0/\
                        hps_fpga_emif_address_se_cntl_agent.cp \
                        qsys_mm.postTransform.pipelineCount 1
        set_postadaptation_assignment mm_interconnect_2|\
                        hps_fpga_emif_address_se_windowed_slave_burst_adapter.source0/\
                        hps_fpga_emif_address_se_windowed_slave_agent.cp \
                        qsys_mm.postTransform.pipelineCount 1
    }

    if {(${v_num_gpo} != 0) || (${v_num_gpi} != 0)} {
        add_instance hps_fpga_gpio    intel_fpga_axi_gpio

        if {${v_num_gpo} != 0} {
            set_instance_parameter_value      hps_fpga_gpio         P_EN_GPO      {1}
            set_instance_parameter_value      hps_fpga_gpio         P_GPO_WIDTH   ${v_num_gpo}

            add_interface           o_gpo   conduit      start
            set_interface_property  o_gpo   EXPORT_OF    hps_fpga_gpio.o_gpo
        } else {
            set_instance_parameter_value      hps_fpga_gpio         P_EN_GPO      {0}
        }
        if {${v_num_gpi} != 0} {
            set_instance_parameter_value      hps_fpga_gpio         P_EN_GPI      {1}
            set_instance_parameter_value      hps_fpga_gpio         P_GPI_WIDTH   ${v_num_gpi}

            add_interface           i_gpi   conduit      end
            set_interface_property  i_gpi   EXPORT_OF    hps_fpga_gpio.i_gpi
        } else {
            set_instance_parameter_value      hps_fpga_gpio         P_EN_GPI      {0}
        }

        add_connection agilex_hps.hps2fpga           hps_fpga_gpio.s_axi
        add_connection hps_axi_clk_bridge.out_clk    hps_fpga_gpio.s_axi_aclk
        add_connection hps_axi_rst_bridge.out_reset  hps_fpga_gpio.s_axi_aresetn

        set_connection_parameter_value agilex_hps.hps2fpga/hps_fpga_gpio.s_axi  baseAddress 0x200000
        lock_avalon_base_address  hps_fpga_gpio.s_axi
    }

    # add irq bridge if required by external IP
    if {(${v_irq_bridge_width} >= 1)} {
        add_instance  irq_bridge      altera_irq_bridge

        # irq_bridge
        set_instance_parameter_value  irq_bridge  IRQ_WIDTH           ${v_irq_bridge_width}
        set_instance_parameter_value  irq_bridge  IRQ_N               {Active High}
        set_instance_parameter_value  irq_bridge  SYNC_RESET          0

        add_connection  hps_axi_clk_bridge.out_clk    irq_bridge.clk
        add_connection  hps_axi_rst_bridge.out_reset  irq_bridge.clk_reset

        for {set v_i 0} {${v_i} < ${v_irq_bridge_width}} {incr v_i} {
            set v_priority [lindex ${v_irq_bridge_priorities} ${v_i}]

            add_connection  agilex_hps.fpga2hps_interrupt_irq0   irq_bridge.sender${v_i}_irq
            set_connection_parameter_value  agilex_hps.fpga2hps_interrupt_irq0/irq_bridge.sender${v_i}_irq \
                                                                                      irqNumber ${v_priority}
        }

        add_interface          ia_cpu_irq_receiver     interrupt  receiver
        set_interface_property ia_cpu_irq_receiver     export_of  irq_bridge.receiver_irq
    }

    # modular-scatter-gather DMA
    if {${v_msgdma_en}} {
        set v_MSGDMA_AGENT_ADDR_WIDTH          [get_shell_parameter MSGDMA_AGENT_ADDR_WIDTH]
        set v_MSGDMA_AGENT_CLK_FREQ            [get_shell_parameter MSGDMA_AGENT_CLK_FREQ]

        # Instances #
        add_instance  msgdma_fpga_emif_clk          altera_clock_bridge
        add_instance  msgdma_fpga_emif_rst          altera_reset_bridge
        add_instance  msgdma_256b                   altera_msgdma
        add_instance  limiter_removal_256b          msgdma2axi4_256
        add_instance  f2sdram_adapt_256b            f2sdram_adapter_256
        add_instance  msgdma_fpga_emif              mm_ccb

        # Parameters #
        # msgdma_fpga_emif_clk
        set_instance_parameter_value      msgdma_fpga_emif_clk      EXPLICIT_CLOCK_RATE   ${v_MSGDMA_AGENT_CLK_FREQ}
        set_instance_parameter_value      msgdma_fpga_emif_clk      NUM_CLOCK_OUTPUTS     {1}

        # msgdma_fpga_emif_rst
        set_instance_parameter_value      msgdma_fpga_emif_rst      ACTIVE_LOW_RESET      {0}
        set_instance_parameter_value      msgdma_fpga_emif_rst      NUM_RESET_OUTPUTS     {1}
        set_instance_parameter_value      msgdma_fpga_emif_rst      SYNCHRONOUS_EDGES     {deassert}
        set_instance_parameter_value      msgdma_fpga_emif_rst      SYNC_RESET            {0}
        set_instance_parameter_value      msgdma_fpga_emif_rst      USE_RESET_REQUEST     {0}

        # msgdma_256b
        set_instance_parameter_value  msgdma_256b         BURST_ENABLE                      {1}
        set_instance_parameter_value  msgdma_256b         BURST_WRAPPING_SUPPORT            {0}
        set_instance_parameter_value  msgdma_256b         CHANNEL_ENABLE                    {0}
        set_instance_parameter_value  msgdma_256b         CHANNEL_WIDTH                     {8}
        set_instance_parameter_value  msgdma_256b         DATA_FIFO_DEPTH                   {16}
        set_instance_parameter_value  msgdma_256b         DATA_WIDTH                        {256}
        set_instance_parameter_value  msgdma_256b         DESCRIPTOR_FIFO_DEPTH             {8}
        set_instance_parameter_value  msgdma_256b         ENHANCED_FEATURES                 {1}
        set_instance_parameter_value  msgdma_256b         ERROR_ENABLE                      {0}
        set_instance_parameter_value  msgdma_256b         ERROR_WIDTH                       {8}
        set_instance_parameter_value  msgdma_256b         EXPOSE_ST_PORT                    {0}
        set_instance_parameter_value  msgdma_256b         FIX_ADDRESS_WIDTH                 {64}
        set_instance_parameter_value  msgdma_256b         MAX_BURST_COUNT                   {2}
        set_instance_parameter_value  msgdma_256b         MAX_BYTE                          {4194304}
        set_instance_parameter_value  msgdma_256b         MAX_STRIDE                        {1}
        set_instance_parameter_value  msgdma_256b         MODE                              {0}
        set_instance_parameter_value  msgdma_256b         NO_BYTEENABLES                    {1}
        set_instance_parameter_value  msgdma_256b         PACKET_ENABLE                     {0}
        set_instance_parameter_value  msgdma_256b         PREFETCHER_DATA_WIDTH             {32}
        set_instance_parameter_value  msgdma_256b         PREFETCHER_ENABLE                 {0}
        set_instance_parameter_value  msgdma_256b         PREFETCHER_MAX_READ_BURST_COUNT   {2}
        set_instance_parameter_value  msgdma_256b         PREFETCHER_READ_BURST_ENABLE      {0}
        set_instance_parameter_value  msgdma_256b         PROGRAMMABLE_BURST_ENABLE         {0}
        set_instance_parameter_value  msgdma_256b         RESPONSE_PORT                     {2}
        set_instance_parameter_value  msgdma_256b         STRIDE_ENABLE                     {0}
        set_instance_parameter_value  msgdma_256b         TRANSFER_TYPE                     {Aligned Accesses}
        set_instance_parameter_value  msgdma_256b         USE_FIX_ADDRESS_WIDTH             {1}
        set_instance_parameter_value  msgdma_256b         WRITE_RESPONSE_ENABLE             {0}

        # msgdma_fpga_emif
        set_instance_parameter_value  msgdma_fpga_emif    ADDRESS_UNITS           {SYMBOLS}
        set_instance_parameter_value  msgdma_fpga_emif    ADDRESS_WIDTH           ${v_MSGDMA_AGENT_ADDR_WIDTH}
        set_instance_parameter_value  msgdma_fpga_emif    COMMAND_FIFO_DEPTH      {2}
        set_instance_parameter_value  msgdma_fpga_emif    DATA_WIDTH              {256}
        set_instance_parameter_value  msgdma_fpga_emif    MASTER_SYNC_DEPTH       {2}
        set_instance_parameter_value  msgdma_fpga_emif    MAX_BURST_SIZE          {2}
        set_instance_parameter_value  msgdma_fpga_emif    RESPONSE_FIFO_DEPTH     {4}
        set_instance_parameter_value  msgdma_fpga_emif    SLAVE_SYNC_DEPTH        {2}
        set_instance_parameter_value  msgdma_fpga_emif    SYMBOL_WIDTH            {8}
        set_instance_parameter_value  msgdma_fpga_emif    SYNC_RESET              {0}
        set_instance_parameter_value  msgdma_fpga_emif    USE_AUTO_ADDRESS_WIDTH  {0}

        # Connections #
        # msgdma_fpga_emif_clk
        add_connection  msgdma_fpga_emif_clk.out_clk          msgdma_fpga_emif_rst.clk
        add_connection  msgdma_fpga_emif_clk.out_clk          msgdma_fpga_emif.m0_clk

        # msgdma_fpga_emif_rst
        add_connection  msgdma_fpga_emif_rst.out_reset        msgdma_fpga_emif.m0_reset

        # hps_axi_clk_bridge
        add_connection  hps_axi_clk_bridge.out_clk            msgdma_256b.clock
        add_connection  hps_axi_clk_bridge.out_clk            limiter_removal_256b.clock
        add_connection  hps_axi_clk_bridge.out_clk            f2sdram_adapt_256b.clock
        add_connection  hps_axi_clk_bridge.out_clk            msgdma_fpga_emif.s0_clk

        # hps_axi_rst_bridge
        add_connection  hps_axi_rst_bridge.out_reset          msgdma_256b.reset_n
        add_connection  hps_axi_rst_bridge.out_reset          limiter_removal_256b.reset
        add_connection  hps_axi_rst_bridge.out_reset          f2sdram_adapt_256b.reset
        add_connection  hps_axi_rst_bridge.out_reset          msgdma_fpga_emif.s0_reset

        # agilex_hps
        add_connection  agilex_hps.hps2fpga                   msgdma_256b.csr
        add_connection  agilex_hps.hps2fpga                   msgdma_256b.descriptor_slave
        add_connection  agilex_hps.fpga2hps_interrupt_irq1    msgdma_256b.csr_irq
        add_connection  agilex_hps.h2f_reset                  msgdma_256b.reset_n
        add_connection  agilex_hps.h2f_reset                  limiter_removal_256b.reset
        add_connection  agilex_hps.h2f_reset                  f2sdram_adapt_256b.reset
        add_connection  agilex_hps.h2f_reset                  msgdma_fpga_emif.s0_reset

        # msgdma_256b
        add_connection  msgdma_256b.mm_read                   limiter_removal_256b.s0
        add_connection  msgdma_256b.mm_write                  limiter_removal_256b.s1
        add_connection  msgdma_256b.mm_read                   msgdma_fpga_emif.s0
        add_connection  msgdma_256b.mm_write                  msgdma_fpga_emif.s0

        # limiter_removal_256b
        add_connection  limiter_removal_256b.m0               f2sdram_adapt_256b.axi4_sub

        # f2sdram_adapt_256b
        add_connection  f2sdram_adapt_256b.axi4_man           agilex_hps.f2sdram

        # Exports #
        add_interface           msgdma_fpga_emif_clock   clock         sink
        set_interface_property  msgdma_fpga_emif_clock   EXPORT_OF     msgdma_fpga_emif_clk.in_clk

        add_interface           msgdma_fpga_emif_reset   reset         sink
        set_interface_property  msgdma_fpga_emif_reset   EXPORT_OF     msgdma_fpga_emif_rst.in_reset

        add_interface           msgdma_fpga_emif_avmm_m0    avalon      host
        set_interface_property  msgdma_fpga_emif_avmm_m0    EXPORT_OF   msgdma_fpga_emif.m0

        # Addresses #
        set_connection_parameter_value msgdma_256b.mm_read/limiter_removal_256b.s0 \
                                                                              baseAddress "0x000000000000"
        set_connection_parameter_value msgdma_256b.mm_write/limiter_removal_256b.s1 \
                                                                              baseAddress "0x000000000000"
        set_connection_parameter_value limiter_removal_256b.m0/f2sdram_adapt_256b.axi4_sub \
                                                                              baseAddress "0x000000000000"
        set_connection_parameter_value msgdma_256b.mm_read/msgdma_fpga_emif.s0 \
                                                                              baseAddress "0x001000000000"
        set_connection_parameter_value msgdma_256b.mm_write/msgdma_fpga_emif.s0 \
                                                                              baseAddress "0x001000000000"
        set_connection_parameter_value agilex_hps.hps2fpga/msgdma_256b.csr \
                                                                              baseAddress "0x00800000"
        set_connection_parameter_value agilex_hps.hps2fpga/msgdma_256b.descriptor_slave \
                                                                              baseAddress "0x00800020"

        lock_avalon_base_address  limiter_removal_256b.s0
        lock_avalon_base_address  limiter_removal_256b.s1
        lock_avalon_base_address  f2sdram_adapt_256b.axi4_sub
        lock_avalon_base_address  msgdma_fpga_emif.s0
        lock_avalon_base_address  msgdma_256b.csr
        lock_avalon_base_address  msgdma_256b.descriptor_slave
    }

    ##### Sync / Validation #####
    sync_sysinfo_parameters
    save_system
}

proc edit_top_level_qsys {} {
    set v_project_name  [get_shell_parameter PROJECT_NAME]
    set v_project_path  [get_shell_parameter PROJECT_PATH]
    set v_instance_name [get_shell_parameter INSTANCE_NAME]

    set v_num_gpo       [get_shell_parameter NUM_GPO]
    set v_num_gpi       [get_shell_parameter NUM_GPI]

    set v_i2c0_ext_en   [get_shell_parameter I2C0_EXT_EN]
    set v_i2c1_ext_en   [get_shell_parameter I2C1_EXT_EN]

    load_system ${v_project_path}/rtl/${v_project_name}_qsys.qsys

    add_instance ${v_instance_name} ${v_instance_name}

    # add interfaces to the boundary of the subsystem
    add_interface           "${v_instance_name}_c_hps_io" conduit end
    set_interface_property  "${v_instance_name}_c_hps_io" export_of   ${v_instance_name}.agilex_hps_hps_io

    # HPS USB 3.1 interfaces
    add_interface           "${v_instance_name}_c_usb31_io" conduit end
    set_interface_property  "${v_instance_name}_c_usb31_io" export_of ${v_instance_name}.agilex_hps_usb31_io

    add_interface           "${v_instance_name}_i_usb31_phy_pma_cpu_clk" clock sink
    set_interface_property  "${v_instance_name}_i_usb31_phy_pma_cpu_clk" \
                                                export_of ${v_instance_name}.agilex_hps_usb31_phy_pma_cpu_clk

    add_interface           "${v_instance_name}_i_usb31_phy_refclk_p" clock sink
    set_interface_property  "${v_instance_name}_i_usb31_phy_refclk_p" \
                                                export_of ${v_instance_name}.agilex_hps_usb31_phy_refclk_p

    add_interface           "${v_instance_name}_i_usb31_phy_refclk_n" clock sink
    set_interface_property  "${v_instance_name}_i_usb31_phy_refclk_n" \
                                                export_of ${v_instance_name}.agilex_hps_usb31_phy_refclk_n

    add_interface           "${v_instance_name}_i_usb31_phy_rx_serial_p" conduit end
    set_interface_property  "${v_instance_name}_i_usb31_phy_rx_serial_p" \
                                                export_of ${v_instance_name}.agilex_hps_usb31_phy_rx_serial_p

    add_interface           "${v_instance_name}_i_usb31_phy_rx_serial_n" conduit end
    set_interface_property  "${v_instance_name}_i_usb31_phy_rx_serial_n" \
                                                export_of ${v_instance_name}.agilex_hps_usb31_phy_rx_serial_n

    add_interface           "${v_instance_name}_o_usb31_phy_tx_serial_p" conduit end
    set_interface_property  "${v_instance_name}_o_usb31_phy_tx_serial_p" \
                                                export_of ${v_instance_name}.agilex_hps_usb31_phy_tx_serial_p

    add_interface           "${v_instance_name}_o_usb31_phy_tx_serial_n" conduit end
    set_interface_property  "${v_instance_name}_o_usb31_phy_tx_serial_n" \
                                                export_of ${v_instance_name}.agilex_hps_usb31_phy_tx_serial_n

  # EMIF interfaces
    add_interface           "${v_instance_name}_i_emif_ref_clk" clock sink
    set_interface_property  "${v_instance_name}_i_emif_ref_clk" export_of ${v_instance_name}.agilex_hps_emif_ref_clk

    add_interface           "${v_instance_name}_c_emif_oct" conduit end
    set_interface_property  "${v_instance_name}_c_emif_oct" export_of ${v_instance_name}.agilex_hps_emif_oct

    add_interface           "${v_instance_name}_c_emif_mem" conduit end
    set_interface_property  "${v_instance_name}_c_emif_mem" export_of ${v_instance_name}.agilex_hps_emif_mem

    add_interface           "${v_instance_name}_c_emif_mem_ck" conduit end
    set_interface_property  "${v_instance_name}_c_emif_mem_ck" export_of ${v_instance_name}.agilex_hps_emif_mem_ck

    add_interface           "${v_instance_name}_c_emif_mem_reset_n" conduit end
    set_interface_property  "${v_instance_name}_c_emif_mem_reset_n" \
                                                            export_of ${v_instance_name}.agilex_hps_emif_mem_reset_n

    # Misc interfaces
    # NOTE : this is connected back to the USB 3.1 clock (only exported due to type mismatch)
    add_interface           "${v_instance_name}_c_pma_cu_clk" conduit end
    set_interface_property  "${v_instance_name}_c_pma_cu_clk" EXPORT_OF ${v_instance_name}.o_pma_cu_clk

    if {${v_num_gpo} != 0} {
        add_interface           "${v_instance_name}_o_hps_gpo"  conduit start
        set_interface_property  "${v_instance_name}_o_hps_gpo"  export_of   ${v_instance_name}.o_gpo
    }

    if {${v_num_gpi} != 0} {
        add_interface           "${v_instance_name}_i_hps_gpi"  conduit end
        set_interface_property  "${v_instance_name}_i_hps_gpi"  export_of   ${v_instance_name}.i_gpi
    }

    # I2C0
    if {${v_i2c0_ext_en}} {
        add_interface           "${v_instance_name}_agilex_hps_i2c0_scl_i"  clock     source
        set_interface_property  "${v_instance_name}_agilex_hps_i2c0_scl_i" \
                                                          export_of ${v_instance_name}.agilex_hps_i2c0_scl_i

        add_interface           "${v_instance_name}_agilex_hps_i2c0_scl_oe" clock     sink
        set_interface_property  "${v_instance_name}_agilex_hps_i2c0_scl_oe" \
                                                          export_of ${v_instance_name}.agilex_hps_i2c0_scl_oe

        add_interface           "${v_instance_name}_agilex_hps_i2c0"        conduit   end
        set_interface_property  "${v_instance_name}_agilex_hps_i2c0" \
                                                          export_of ${v_instance_name}.agilex_hps_i2c0
    }

    # I2C1
    if {${v_i2c1_ext_en}} {
        add_interface           "${v_instance_name}_agilex_hps_i2c1_scl_i"   clock      source
        set_interface_property  "${v_instance_name}_agilex_hps_i2c1_scl_i" \
                                                            export_of  ${v_instance_name}.agilex_hps_i2c1_scl_i

        add_interface           "${v_instance_name}_agilex_hps_i2c1_scl_oe"  clock      sink
        set_interface_property  "${v_instance_name}_agilex_hps_i2c1_scl_oe" \
                                                            export_of  ${v_instance_name}.agilex_hps_i2c1_scl_oe

        add_interface           "${v_instance_name}_agilex_hps_i2c1"         conduit    end
        set_interface_property  "${v_instance_name}_agilex_hps_i2c1" \
                                                            export_of  ${v_instance_name}.agilex_hps_i2c1
    }

    sync_sysinfo_parameters
    save_system
}

proc add_auto_connections {} {
    set v_instance_name         [get_shell_parameter INSTANCE_NAME]
    set v_drv_irq_bridge_width  [get_shell_parameter DRV_IRQ_BRIDGE_WIDTH]
    set v_hps_axi_clk           [get_shell_parameter HPS_AXI_CLK]

    add_auto_connection ${v_instance_name} hps_axi_clk_bridge_in_clk    ${v_hps_axi_clk}
    add_auto_connection ${v_instance_name} hps_axi_rst_bridge_in_reset  ${v_hps_axi_clk}

    add_auto_connection ${v_instance_name} o_hps_h2f_user0_clock h2f_user0_clock

    if {${v_drv_irq_bridge_width} >= 1} {
        add_irq_connection ${v_instance_name} "ia_cpu_irq_receiver" 0 ${v_instance_name}_irq
        add_irq_connection ${v_instance_name} "ia_cpu_irq_receiver" 0 ${v_instance_name}_lw_irq
    }

    set v_drv_enable_h2f      [get_shell_parameter DRV_ENABLE_H2F]
    set v_drv_enable_h2f_lw   [get_shell_parameter DRV_ENABLE_H2F_LW]

    set v_h2f_is_axi          [get_shell_parameter H2F_IS_AXI]
    set v_h2f_lw_is_axi       [get_shell_parameter H2F_LW_IS_AXI]

    set v_fpga_emif_enabled   [get_shell_parameter FPGA_EMIF_ENABLED]

    set v_drv_msgdma_en       [get_shell_parameter DRV_MSGDMA_EN]
    set v_msgdma_agent        [get_shell_parameter MSGDMA_AGENT]

    if {(${v_drv_enable_h2f} ) && (${v_h2f_is_axi} == 0) && (${v_drv_enable_h2f_lw} ) && (${v_h2f_lw_is_axi} == 0)} {
        set v_full_avmm_host [list [list auto X]]
        set v_lw_avmm_host   [list [list auto X]]

        lappend v_full_avmm_host [list ${v_instance_name} X]
        lappend v_lw_avmm_host   [list ${v_instance_name}_lw X]

        add_avmm_connections hps_mm_bridge_h2f_m0     ${v_full_avmm_host}
        add_avmm_connections hps_mm_bridge_h2f_lw_m0  ${v_lw_avmm_host}
    } else {
        if {${v_drv_enable_h2f}} {
            if {${v_h2f_is_axi} == 0} {
                add_avmm_connections hps_mm_bridge_h2f_m0     "host"
            } else {
                add_auto_connection ${v_instance_name} hps_axi_bridge_h2f_m0     auto_axi_host
                add_auto_connection ${v_instance_name} hps_axi_bridge_h2f_m0     ${v_instance_name}_axi_host
            }
        }

        if {${v_drv_enable_h2f_lw}} {
            if {${v_h2f_lw_is_axi} == 0} {
                add_avmm_connections hps_mm_bridge_h2f_lw_m0  "host"
            } else {
                add_auto_connection ${v_instance_name} hps_lwhps2fpga   auto_lw_axi_host
                add_auto_connection ${v_instance_name} hps_lwhps2fpga   ${v_instance_name}_lw_axi_host
            }
        }
    }

    if {${v_fpga_emif_enabled}} {
        add_auto_connection ${v_instance_name} fpga_emif_clock    "emif_user_clk"
        add_auto_connection ${v_instance_name} fpga_emif_reset    "emif_user_rst"
        add_auto_connection ${v_instance_name} fpga_emif_avmm_m0  "emif_user_data"
    }

    if {${v_drv_msgdma_en}} {
        add_auto_connection ${v_instance_name} msgdma_fpga_emif_clock       "${v_msgdma_agent}_user_clk"
        add_auto_connection ${v_instance_name} msgdma_fpga_emif_reset       "${v_msgdma_agent}_user_rst"
        add_auto_connection ${v_instance_name} msgdma_fpga_emif_avmm_m0     "${v_msgdma_agent}_user_data"
    }
}

# # insert lines of code into the top level hdl file
proc edit_top_v_file {} {
    set v_instance_name     [get_shell_parameter INSTANCE_NAME]
    set v_board_name        [get_shell_parameter DEVKIT]
    set v_num_gpo           [get_shell_parameter NUM_GPO]
    set v_num_gpi           [get_shell_parameter NUM_GPI]
    set v_i2c0_ext_en       [get_shell_parameter I2C0_EXT_EN]
    set v_i2c1_ext_en       [get_shell_parameter I2C1_EXT_EN]

    # add port connections to the instantiation of the top level qsys system
    # HPS
    add_top_port_list input    ""         hps_ref_clk

    add_top_port_list input    ""         hps_jtag_tck
    add_top_port_list input    ""         hps_jtag_tms
    add_top_port_list output   ""         hps_jtag_tdo
    add_top_port_list input    ""         hps_jtag_tdi

    add_top_port_list output   ""         hps_sdmmc_cclk
    add_top_port_list inout    ""         hps_sdmmc_cmd
    add_top_port_list inout    ""         hps_sdmmc_data0
    add_top_port_list inout    ""         hps_sdmmc_data1
    add_top_port_list inout    ""         hps_sdmmc_data2
    add_top_port_list inout    ""         hps_sdmmc_data3

    add_top_port_list input    ""         hps_usb1_clk
    add_top_port_list output   ""         hps_usb1_stp
    add_top_port_list input    ""         hps_usb1_dir
    add_top_port_list input    ""         hps_usb1_nxt
    add_top_port_list inout    ""         hps_usb1_data0
    add_top_port_list inout    ""         hps_usb1_data1
    add_top_port_list inout    ""         hps_usb1_data2
    add_top_port_list inout    ""         hps_usb1_data3
    add_top_port_list inout    ""         hps_usb1_data4
    add_top_port_list inout    ""         hps_usb1_data5
    add_top_port_list inout    ""         hps_usb1_data6
    add_top_port_list inout    ""         hps_usb1_data7

    add_top_port_list output   ""         hps_emac2_tx_clk
    add_top_port_list input    ""         hps_emac2_rx_clk
    add_top_port_list output   ""         hps_emac2_tx_ctl
    add_top_port_list input    ""         hps_emac2_rx_ctl
    add_top_port_list output   ""         hps_emac2_txd0
    add_top_port_list output   ""         hps_emac2_txd1
    add_top_port_list output   ""         hps_emac2_txd2
    add_top_port_list output   ""         hps_emac2_txd3
    add_top_port_list input    ""         hps_emac2_rxd0
    add_top_port_list input    ""         hps_emac2_rxd1
    add_top_port_list input    ""         hps_emac2_rxd2
    add_top_port_list input    ""         hps_emac2_rxd3
    add_top_port_list output   ""         hps_emac2_pps
    add_top_port_list input    ""         hps_emac2_pps_trig
    add_top_port_list inout    ""         hps_mdio2_mdio
    add_top_port_list output   ""         hps_mdio2_mdc

    add_top_port_list output   ""         hps_uart0_tx
    add_top_port_list input    ""         hps_uart0_rx

    if {(${v_board_name} == "AGX_5E_Si_Devkit")} {
        add_top_port_list inout    ""         hps_i3c1_sda
        add_top_port_list inout    ""         hps_i3c1_scl
    } elseif {(${v_board_name} == "AGX_5E_Modular_Devkit")} {
        add_top_port_list inout    ""         hps_i2c_emac1_sda
        add_top_port_list inout    ""         hps_i2c_emac1_scl
    } else {
        add_top_port_list inout    ""         hps_i3c1_sda
        add_top_port_list inout    ""         hps_i3c1_scl
    }
    add_top_port_list inout    ""         hps_gpio0_io0
    add_top_port_list inout    ""         hps_gpio0_io1
    add_top_port_list inout    ""         hps_gpio0_io11
    add_top_port_list inout    ""         hps_gpio1_io3
    add_top_port_list inout    ""         hps_gpio1_io4

    # USB 3.1
    add_top_port_list input    ""         usb31_io_vbus_det
    add_top_port_list input    ""         usb31_io_flt_bar
    add_top_port_list output   "\[1:0\]"  usb31_io_usb_ctrl
    add_top_port_list input    ""         usb31_io_usb31_id
    add_top_port_list input    ""         usb31_phy_refclk_p_clk
    add_top_port_list input    ""         usb31_phy_rx_serial_n
    add_top_port_list input    ""         usb31_phy_rx_serial_p
    add_top_port_list output   ""         usb31_phy_tx_serial_n
    add_top_port_list output   ""         usb31_phy_tx_serial_p

    add_declaration_list wire ""  usb31_phy_pma_cpu_clk

    if {${v_i2c0_ext_en}} {
        add_declaration_list wire ""            "hps_i2c0_scl_in"
        add_declaration_list wire ""            "hps_i2c0_sda_in"
        add_declaration_list wire ""            "hps_i2c0_scl_oe"
        add_declaration_list wire ""            "hps_i2c0_sda_oe"
    }

    if {${v_i2c1_ext_en}} {
        add_declaration_list wire ""            "hps_i2c1_scl_in"
        add_declaration_list wire ""            "hps_i2c1_sda_in"
        add_declaration_list wire ""            "hps_i2c1_scl_oe"
        add_declaration_list wire ""            "hps_i2c1_sda_oe"
    }

    # HPS
    if {${v_num_gpo} != 0} {
        add_declaration_list wire   "\[[expr ${v_num_gpo} - 1] : 0\]"   hps_gpo
        add_qsys_inst_exports_list  "${v_instance_name}_o_hps_gpo_gpo"  hps_gpo
    }
    if {${v_num_gpi} != 0} {
        add_declaration_list wire   "\[[expr ${v_num_gpi} - 1] : 0\]"   hps_gpi
        add_qsys_inst_exports_list  "${v_instance_name}_i_hps_gpi_gpi"  hps_gpi
    }

    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_hps_osc_clk"     hps_ref_clk

    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_jtag_tck"        hps_jtag_tck
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_jtag_tms"        hps_jtag_tms
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_jtag_tdo"        hps_jtag_tdo
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_jtag_tdi"        hps_jtag_tdi

    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_sdmmc_cclk"      hps_sdmmc_cclk
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_sdmmc_cmd"       hps_sdmmc_cmd
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_sdmmc_data0"     hps_sdmmc_data0
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_sdmmc_data1"     hps_sdmmc_data1
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_sdmmc_data2"     hps_sdmmc_data2
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_sdmmc_data3"     hps_sdmmc_data3

    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_clk"        hps_usb1_clk
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_stp"        hps_usb1_stp
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_dir"        hps_usb1_dir
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_nxt"        hps_usb1_nxt
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data0"      hps_usb1_data0
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data1"      hps_usb1_data1
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data2"      hps_usb1_data2
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data3"      hps_usb1_data3
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data4"      hps_usb1_data4
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data5"      hps_usb1_data5
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data6"      hps_usb1_data6
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_usb1_data7"      hps_usb1_data7

    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_tx_clk"    hps_emac2_tx_clk
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_rx_clk"    hps_emac2_rx_clk
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_tx_ctl"    hps_emac2_tx_ctl
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_rx_ctl"    hps_emac2_rx_ctl
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_txd0"      hps_emac2_txd0
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_txd1"      hps_emac2_txd1
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_txd2"      hps_emac2_txd2
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_txd3"      hps_emac2_txd3
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_rxd0"      hps_emac2_rxd0
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_rxd1"      hps_emac2_rxd1
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_rxd2"      hps_emac2_rxd2
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_rxd3"      hps_emac2_rxd3
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_pps"       hps_emac2_pps
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_emac2_pps_trig"  hps_emac2_pps_trig
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_mdio2_mdio"      hps_mdio2_mdio
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_mdio2_mdc"       hps_mdio2_mdc

    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_uart0_tx"        hps_uart0_tx
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_uart0_rx"        hps_uart0_rx

    if {(${v_board_name} == "AGX_5E_Si_Devkit")} {
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_i3c1_sda"        hps_i3c1_sda
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_i3c1_scl"        hps_i3c1_scl
    } elseif {(${v_board_name} == "AGX_5E_Modular_Devkit")} {
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_i2c_emac1_sda"   hps_i2c_emac1_sda
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_i2c_emac1_scl"   hps_i2c_emac1_scl
    } else {
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_i3c1_sda"        hps_i3c1_sda
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_i3c1_scl"        hps_i3c1_scl
    }

    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_gpio0"           hps_gpio0_io0
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_gpio1"           hps_gpio0_io1

    set v_board_name [get_shell_parameter DEVKIT]
    if {${v_board_name} == "AGX_5E_Si_Devkit"} {
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_gpio11"          hps_gpio0_io11
    } elseif {${v_board_name} == "AGX_5E_Modular_Devkit"} {
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_gpio10"          hps_gpio0_io11
    } else {
        add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_gpio11"          hps_gpio0_io11
    }
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_gpio27"          hps_gpio1_io3
    add_qsys_inst_exports_list    "${v_instance_name}_c_hps_io_gpio28"          hps_gpio1_io4

    # USB 3.1
    add_qsys_inst_exports_list    "${v_instance_name}_c_usb31_io_vbus_det"      usb31_io_vbus_det
    add_qsys_inst_exports_list    "${v_instance_name}_c_usb31_io_flt_bar"       usb31_io_flt_bar
    add_qsys_inst_exports_list    "${v_instance_name}_c_usb31_io_usb_ctrl"      usb31_io_usb_ctrl
    add_qsys_inst_exports_list    "${v_instance_name}_c_usb31_io_usb31_id"      usb31_io_usb31_id

    add_qsys_inst_exports_list    "${v_instance_name}_i_usb31_phy_pma_cpu_clk_clk"            usb31_phy_pma_cpu_clk
    add_qsys_inst_exports_list    "${v_instance_name}_i_usb31_phy_refclk_p_clk"               usb31_phy_refclk_p_clk
    add_qsys_inst_exports_list    "${v_instance_name}_i_usb31_phy_rx_serial_n_i_rx_serial_n"  usb31_phy_rx_serial_n
    add_qsys_inst_exports_list    "${v_instance_name}_i_usb31_phy_rx_serial_p_i_rx_serial_p"  usb31_phy_rx_serial_p
    add_qsys_inst_exports_list    "${v_instance_name}_o_usb31_phy_tx_serial_n_o_tx_serial_n"  usb31_phy_tx_serial_n
    add_qsys_inst_exports_list    "${v_instance_name}_o_usb31_phy_tx_serial_p_o_tx_serial_p"  usb31_phy_tx_serial_p

    # Misc
    add_qsys_inst_exports_list    "${v_instance_name}_c_pma_cu_clk_clk"         usb31_phy_pma_cpu_clk

    # HPS memory
    add_qsys_inst_exports_list    "${v_instance_name}_i_emif_ref_clk_clk"             hps_mem_pll_ref_clk
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_oct_oct_rzqin"           hps_mem_oct_rzqin
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_ck_mem_ck_t"         hps_mem_ck
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_ck_mem_ck_c"         hps_mem_ck_n
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_a"               hps_mem_a
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_act_n"           hps_mem_act_n
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_ba"              hps_mem_ba
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_bg"              hps_mem_bg
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_cke"             hps_mem_cke
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_cs_n"            hps_mem_cs_n
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_odt"             hps_mem_odt
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_reset_n_mem_reset_n" hps_mem_reset_n
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_par"             hps_mem_par
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_alert_n"         hps_mem_alert_n
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_dq"              hps_mem_dq
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_dqs_t"           hps_mem_dqs
    add_qsys_inst_exports_list    "${v_instance_name}_c_emif_mem_mem_dqs_c"           hps_mem_dqs_n

    if {${v_i2c0_ext_en}} {
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c0_scl_i_clk"    hps_i2c0_scl_in
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c0_scl_oe_clk"   hps_i2c0_scl_oe
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c0_sda_i"        hps_i2c0_sda_in
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c0_sda_oe"       hps_i2c0_sda_oe
    }

    if {${v_i2c1_ext_en}} {
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c1_scl_i_clk"    hps_i2c1_scl_in
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c1_scl_oe_clk"   hps_i2c1_scl_oe
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c1_sda_i"        hps_i2c1_sda_in
        add_qsys_inst_exports_list    "${v_instance_name}_agilex_hps_i2c1_sda_oe"       hps_i2c1_sda_oe
    }
}
