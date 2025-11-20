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

set_shell_parameter UART_IRQ_PRIORITY   "0"
set_shell_parameter TIMER_IRQ_PRIORITY  "1"

set_shell_parameter MEMORY_SIZE         "0x400000"

set_shell_parameter JTAG_UART_EN        {1}
set_shell_parameter CPU_TIMER_EN        {1}

proc derive_parameters {param_array} {

    upvar ${param_array} p_array

    # =====================================================================
    # resolve interdependencies

    set v_instance_name      [get_shell_parameter INSTANCE_NAME]
    set v_timer_irq_priority [get_shell_parameter TIMER_IRQ_PRIORITY]
    set v_uart_irq_priority  [get_shell_parameter UART_IRQ_PRIORITY]

    set v_internal_priorities [list ${v_timer_irq_priority} ${v_uart_irq_priority}]

    if {[::irq_connect_pkg::check_duplicate_priorities ${v_internal_priorities}]} {
        puts "found duplicate internal priorities"
        return
    }

    # get an ordered list of priorities from external irqs to this receiver
    set v_external_priorities [::irq_connect_pkg::get_external_irqs p_array \
                                                    ${v_instance_name} ${v_internal_priorities}]

    set_shell_parameter DRV_IRQ_BRIDGE_WIDTH      [llength ${v_external_priorities}]
    set_shell_parameter DRV_IRQ_BRIDGE_PRIORITIES ${v_external_priorities}
}

# define the procedures used by the create subsystem tcl script

proc pre_creation_step {} {
}

proc creation_step {} {
    create_niosv_subsystem
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

    set v_user_bsp_type               [get_shell_parameter BSP_TYPE]
    set v_user_bsp_settings_file      [get_shell_parameter BSP_SETTINGS_FILE]
    set v_user_app_dir                [get_shell_parameter APPLICATION_DIR]
    set v_user_custom_cmakefile       [get_shell_parameter CUSTOM_CMAKEFILE]
    set v_user_custom_makefile        [get_shell_parameter CUSTOM_MAKEFILE]

    #==============================================================================
    # for Nios V software building the memory base address and size must be known
    # collect this information from the created system rather than parameterization
    # as Platform Designer can resize memory

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    set v_memory_base [get_connection_parameter_value cpu.data_manager/cpu_ram.axi_s1 baseAddress]
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


# create the cpu subsystem, add the required IP, parameterize it as appropriate,
# add internal connections, and add interfaces to the boundary of the subsystem

proc create_niosv_subsystem {} {
    set v_project_path            [get_shell_parameter PROJECT_PATH]
    set v_instance_name           [get_shell_parameter INSTANCE_NAME]

    set v_timer_irq_priority      [get_shell_parameter TIMER_IRQ_PRIORITY]
    set v_uart_irq_priority       [get_shell_parameter UART_IRQ_PRIORITY]

    set v_irq_bridge_width        [get_shell_parameter DRV_IRQ_BRIDGE_WIDTH]
    set v_irq_bridge_priorities   [get_shell_parameter DRV_IRQ_BRIDGE_PRIORITIES]

    set v_memory_size             [get_shell_parameter MEMORY_SIZE]

    set v_jtag_uart_en            [get_shell_parameter JTAG_UART_EN]
    set v_cpu_timer_en            [get_shell_parameter CPU_TIMER_EN]

    create_system ${v_instance_name}
    save_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    load_system   ${v_project_path}/rtl/shell/${v_instance_name}.qsys

    # create instances

    add_instance  cpu_clk_bridge  altera_clock_bridge
    add_instance  cpu_rst_bridge  altera_reset_bridge
    add_instance  cpu_mm_bridge   altera_avalon_mm_bridge
    add_instance  cpu             intel_niosv_m
    add_instance  cpu_ram         intel_onchip_memory
    if {${v_jtag_uart_en}} {
        add_instance  cpu_jtag_uart   altera_avalon_jtag_uart
    }
    if {${v_cpu_timer_en}} {
        add_instance  cpu_timer       altera_avalon_timer
    }

    # instance parameters

    # cpu_clk_bridge
    set_instance_parameter_value  cpu_clk_bridge  EXPLICIT_CLOCK_RATE         {100000000.0}
    set_instance_parameter_value  cpu_clk_bridge  NUM_CLOCK_OUTPUTS           1

    # cpu_rst_bridge
    set_instance_parameter_value  cpu_rst_bridge  ACTIVE_LOW_RESET            0
    set_instance_parameter_value  cpu_rst_bridge  SYNCHRONOUS_EDGES           deassert
    set_instance_parameter_value  cpu_rst_bridge  NUM_RESET_OUTPUTS           1
    set_instance_parameter_value  cpu_rst_bridge  USE_RESET_REQUEST           0
    set_instance_parameter_value  cpu_rst_bridge  SYNC_RESET                  0

    # cpu_mm_bridge
    set_instance_parameter_value  cpu_mm_bridge   SYNC_RESET                  0
    set_instance_parameter_value  cpu_mm_bridge   DATA_WIDTH                  32
    set_instance_parameter_value  cpu_mm_bridge   SYMBOL_WIDTH                8
    set_instance_parameter_value  cpu_mm_bridge   ADDRESS_WIDTH               0
    set_instance_parameter_value  cpu_mm_bridge   USE_AUTO_ADDRESS_WIDTH      1
    set_instance_parameter_value  cpu_mm_bridge   ADDRESS_UNITS               SYMBOLS
    set_instance_parameter_value  cpu_mm_bridge   MAX_BURST_SIZE              1
    set_instance_parameter_value  cpu_mm_bridge   LINEWRAPBURSTS              0
    set_instance_parameter_value  cpu_mm_bridge   MAX_PENDING_RESPONSES       4
    set_instance_parameter_value  cpu_mm_bridge   PIPELINE_COMMAND            1
    set_instance_parameter_value  cpu_mm_bridge   PIPELINE_RESPONSE           1
    set_instance_parameter_value  cpu_mm_bridge   USE_RESPONSE                0

    # cpu
    set_instance_parameter_value  cpu             enableDebug                 1
    set_instance_parameter_value  cpu             numGpr                      32
    set_instance_parameter_value  cpu             resetOffset                 0
    set_instance_parameter_value  cpu             resetSlave                  cpu_ram.axi_s1

    # cpu_ram
    set_instance_parameter_value  cpu_ram         AXI_interface               1
    set_instance_parameter_value  cpu_ram         interfaceType               1
    set_instance_parameter_value  cpu_ram         idWidth                     2
    set_instance_parameter_value  cpu_ram         memorySize                  ${v_memory_size}
    set_instance_parameter_value  cpu_ram         initMemContent              1
    set_instance_parameter_value  cpu_ram         useNonDefaultInitFile       0
    set_instance_parameter_value  cpu_ram         initializationFileName      ""
    set_instance_parameter_value  cpu_ram         dataWidth                   32

    if {${v_jtag_uart_en}} {
        # cpu_jtag_uart
        set_instance_parameter_value  cpu_jtag_uart   writeBufferDepth            1024
        set_instance_parameter_value  cpu_jtag_uart   writeIRQThreshold           8
        set_instance_parameter_value  cpu_jtag_uart   useRegistersForWriteBuffer  0
        set_instance_parameter_value  cpu_jtag_uart   readBufferDepth             1024
        set_instance_parameter_value  cpu_jtag_uart   readIRQThreshold            8
        set_instance_parameter_value  cpu_jtag_uart   useRegistersForReadBuffer   0
    }

    if {${v_cpu_timer_en}} {
        # cpu_timer
        set v_drv_timer_preset [get_shell_parameter DRV_TIMER_PRESET]
        set v_timer_period     [get_shell_parameter TIMER_PERIOD]
        set v_timer_units      [get_shell_parameter TIMER_UNITS]

        apply_instance_preset cpu_timer ${v_drv_timer_preset}

        set_instance_parameter_value  cpu_timer   period          ${v_timer_period}
        set_instance_parameter_value  cpu_timer   periodUnits     ${v_timer_units}
    }

    # create internal subsystem connections

    add_connection  cpu_clk_bridge.out_clk    cpu_rst_bridge.clk
    add_connection  cpu_clk_bridge.out_clk    cpu_mm_bridge.clk
    add_connection  cpu_clk_bridge.out_clk    cpu.clk
    add_connection  cpu_clk_bridge.out_clk    cpu_ram.clk1
    if {${v_jtag_uart_en}} {
        add_connection  cpu_clk_bridge.out_clk    cpu_jtag_uart.clk
    }
    if {${v_cpu_timer_en}} {
        add_connection  cpu_clk_bridge.out_clk    cpu_timer.clk
    }

    add_connection  cpu_rst_bridge.out_reset  cpu_mm_bridge.reset
    add_connection  cpu_rst_bridge.out_reset  cpu.reset
    add_connection  cpu_rst_bridge.out_reset  cpu_ram.reset1
    if {${v_jtag_uart_en}} {
        add_connection  cpu_rst_bridge.out_reset  cpu_jtag_uart.reset
    }
    if {${v_cpu_timer_en}} {
        add_connection  cpu_rst_bridge.out_reset  cpu_timer.reset
    }

    add_connection  cpu.data_manager          cpu_mm_bridge.s0
    add_connection  cpu.data_manager          cpu.dm_agent
    add_connection  cpu.data_manager          cpu.timer_sw_agent
    add_connection  cpu.data_manager          cpu_ram.axi_s1
    if {${v_jtag_uart_en}} {
        add_connection  cpu.data_manager          cpu_jtag_uart.avalon_jtag_slave
    }
    if {${v_cpu_timer_en}} {
        add_connection  cpu.data_manager          cpu_timer.s1
    }

    add_connection  cpu.instruction_manager    cpu.dm_agent
    add_connection  cpu.instruction_manager    cpu_ram.axi_s1

    if {(${v_jtag_uart_en} ) && (${v_uart_irq_priority} != "X")} {
        add_connection  cpu.platform_irq_rx   cpu_jtag_uart.irq
        set_connection_parameter_value  cpu.platform_irq_rx/cpu_jtag_uart.irq irqNumber ${v_uart_irq_priority}
    }

    if {(${v_cpu_timer_en} ) && (${v_timer_irq_priority} != "X")} {
        add_connection  cpu.platform_irq_rx   cpu_timer.irq
        set_connection_parameter_value  cpu.platform_irq_rx/cpu_timer.irq irqNumber ${v_timer_irq_priority}
    }

    # add interfaces to the boundary of the subsystem

    add_interface          i_clk_cpu              clock      sink
    set_interface_property i_clk_cpu              export_of  cpu_clk_bridge.in_clk

    add_interface          i_reset_cpu            reset      sink
    set_interface_property i_reset_cpu            export_of  cpu_rst_bridge.in_reset

    add_interface          o_cpu_mm_master        avalon     host
    set_interface_property o_cpu_mm_master        export_of  cpu_mm_bridge.m0

    # add irq bridge if required

    if {(${v_irq_bridge_width} >= 1)} {
        add_instance  irq_bridge      altera_irq_bridge

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

    set_connection_parameter_value  cpu.data_manager/cpu_ram.axi_s1                    baseAddress   "0x00000000"
    set_connection_parameter_value  cpu.data_manager/cpu.dm_agent                      baseAddress   "0x00400000"
    set_connection_parameter_value  cpu.data_manager/cpu.timer_sw_agent                baseAddress   "0x00410000"
    if {${v_cpu_timer_en}} {
        set_connection_parameter_value  cpu.data_manager/cpu_timer.s1                      baseAddress   "0x00410040"
    }
    if {${v_jtag_uart_en}} {
        set_connection_parameter_value  cpu.data_manager/cpu_jtag_uart.avalon_jtag_slave   baseAddress   "0x00410060"
    }
    set_connection_parameter_value  cpu.data_manager/cpu_mm_bridge.s0                  baseAddress   "0x00420000"

    set_connection_parameter_value  cpu.instruction_manager/cpu_ram.axi_s1             baseAddress   "0x00000000"
    set_connection_parameter_value  cpu.instruction_manager/cpu.dm_agent               baseAddress   "0x00400000"

    lock_avalon_base_address  cpu_ram.axi_s1
    lock_avalon_base_address  cpu.dm_agent
    lock_avalon_base_address  cpu.timer_sw_agent
    if {${v_cpu_timer_en}} {
        lock_avalon_base_address  cpu_timer.s1
    }
    if {${v_jtag_uart_en}} {
        lock_avalon_base_address  cpu_jtag_uart.avalon_jtag_slave
    }
    lock_avalon_base_address  cpu_mm_bridge.s0

    sync_sysinfo_parameters
    save_system

}

# insert the cpu subsystem into the top level Platform Designer system, and add interfaces
# to the boundary of the top level Platform Designer system

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
# to other subsystems at the top Platform Designer level

proc add_auto_connections {} {
    set v_instance_name [get_shell_parameter INSTANCE_NAME]
    set v_drv_irq_bridge_width  [get_shell_parameter DRV_IRQ_BRIDGE_WIDTH]

    add_auto_connection ${v_instance_name}  i_clk_cpu    100000000
    add_auto_connection ${v_instance_name}  i_reset_cpu  100000000

    add_avmm_connections o_cpu_mm_master "host"

    if {${v_drv_irq_bridge_width} >= 1} {
        add_irq_connection ${v_instance_name} "ia_cpu_irq_receiver" 0 ${v_instance_name}_irq
    }
}

# insert lines of code into the top level hdl file

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
