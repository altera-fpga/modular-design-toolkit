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

set_time_format -unit ns -decimal_places 3

proc set_jtag_timing_constraints { } {
    set use_fitter_specific_constraint 1

    if { ${use_fitter_specific_constraint} && [string equal quartus_fit $::TimeQuestInfo(nameofexecutable)] } {
        set_default_quartus_fit_timing_directive
    }  else {
        set_jtag_timing_spec_for_timing_analysis
    }
}

proc set_default_quartus_fit_timing_directive { } {
    set jtag_33Mhz_t_period 30

    create_clock -name {altera_reserved_tck} -period ${jtag_33Mhz_t_period} [get_ports {altera_reserved_tck}]
    set_clock_groups -asynchronous -group {altera_reserved_tck}

    set_max_delay -to [get_ports { altera_reserved_tdo } ] 10
}

proc set_jtag_timing_spec_for_timing_analysis { } {
    derive_clock_uncertainty

    set_tck_timing_spec
    set_tms_timing_spec

    set tdi_is_driven_by_blaster 1

    if { ${tdi_is_driven_by_blaster} } {
        set_tdi_timing_spec_when_driven_by_blaster
    } else {
        set_tdi_timing_spec_when_driven_by_device
    }

    set tdo_drive_blaster 1

    if { ${tdo_drive_blaster} } {
        set_tdo_timing_spec_when_drive_blaster
    } else {
        set_tdo_timing_spec_when_drive_device
    }

    set_optional_ntrst_timing_spec

    set_false_path -from [get_ports {altera_reserved_tdi}] -to [get_ports {altera_reserved_tdo}]

    if { [get_collection_size [get_registers -nowarn *~jtag_reg]] > 0 } {
        set_false_path -from [get_registers *~jtag_reg] -to [get_ports {altera_reserved_tdo}]
    }
}

proc set_tck_timing_spec { } {
    set ub1_t_period          166.666
    set ub2_default_t_period  41.666
    set ub2_safe_t_period     62.5
    set tck_t_period          ${ub2_safe_t_period}

    create_clock -name {altera_reserved_tck} -period ${tck_t_period}  [get_ports {altera_reserved_tck}]
    set_clock_groups -asynchronous -group {altera_reserved_tck}
}

proc get_tck_delay_max { } {
    set tck_blaster_tco_max   14.603
    set tck_cable_max         11.627
    set tck_header_trace_max  0.5

    return [expr ${tck_blaster_tco_max} + ${tck_cable_max} + ${tck_header_trace_max}]
}

proc get_tck_delay_min { } {
    set tck_blaster_tco_min   14.603
    set tck_cable_min         10.00
    set tck_header_trace_min  0.1

    return [expr ${tck_blaster_tco_min} + ${tck_cable_min} + ${tck_header_trace_min}]
}

proc set_tms_timing_spec { } {
    set tms_blaster_tco_max   9.468
    set tms_blaster_tco_min   9.468
    set tms_cable_max         11.627
    set tms_cable_min         10.0
    set tms_header_trace_max  0.5
    set tms_header_trace_min  0.1

    set tms_in_max \
    [expr ${tms_cable_max} + ${tms_header_trace_max} + ${tms_blaster_tco_max} - [get_tck_delay_min]]

    set tms_in_min \
    [expr ${tms_cable_min} + ${tms_header_trace_min} + ${tms_blaster_tco_min} - [get_tck_delay_max]]

    set_input_delay -add_delay -clock_fall -clock altera_reserved_tck \
                    -max ${tms_in_max} [get_ports {altera_reserved_tms}]

    set_input_delay -add_delay -clock_fall -clock altera_reserved_tck \
                    -min ${tms_in_min} [get_ports {altera_reserved_tms}]
}

proc set_tdi_timing_spec_when_driven_by_blaster { } {
    set tdi_blaster_tco_max   8.551
    set tdi_blaster_tco_min   8.551
    set tdi_cable_max         11.627
    set tdi_cable_min         10.0
    set tdi_header_trace_max  0.5
    set tdi_header_trace_min  0.1

    set tdi_in_max \
    [expr ${tdi_cable_max} + ${tdi_header_trace_max} + ${tdi_blaster_tco_max} - [get_tck_delay_min]]

    set tdi_in_min \
    [expr ${tdi_cable_min} + ${tdi_header_trace_min} + ${tdi_blaster_tco_min} - [get_tck_delay_max]]

    set_input_delay -add_delay -clock_fall -clock altera_reserved_tck \
                    -max ${tdi_in_max} [get_ports {altera_reserved_tdi}]

    set_input_delay -add_delay -clock_fall -clock altera_reserved_tck \
                    -min ${tdi_in_min} [get_ports {altera_reserved_tdi}]
}

proc set_tdi_timing_spec_when_driven_by_device { } {
    set previous_device_tdo_tco_max   10.0
    set previous_device_tdo_tco_min   10.0
    set tdi_trace_max                 0.5
    set tdi_trace_min                 0.1

    set tdi_in_max \
    [expr ${previous_device_tdo_tco_max} + ${tdi_trace_max} - [get_tck_delay_min]]

    set tdi_in_min \
    [expr ${previous_device_tdo_tco_min} + ${tdi_trace_min} - [get_tck_delay_max]]

    set_input_delay -add_delay -clock_fall -clock altera_reserved_tck \
                    -max ${tdi_in_max} [get_ports {altera_reserved_tdi}]

    set_input_delay -add_delay -clock_fall -clock altera_reserved_tck \
                    -min ${tdi_in_min} [get_ports {altera_reserved_tdi}]
}

proc set_tdo_timing_spec_when_drive_blaster { } {
    set tdo_blaster_tsu       5.831
    set tdo_blaster_th        -1.651
    set tdo_cable_max         11.627
    set tdo_cable_min         10.0
    set tdo_header_trace_max  0.5
    set tdo_header_trace_min  0.1

    set tdo_out_max \
    [expr ${tdo_cable_max} + ${tdo_header_trace_max} + ${tdo_blaster_tsu} + [get_tck_delay_max]]

    set tdo_out_min \
    [expr ${tdo_cable_min} + ${tdo_header_trace_min} - ${tdo_blaster_th} + [get_tck_delay_min]]

    set_output_delay  -add_delay -clock_fall -clock altera_reserved_tck \
                      -max ${tdo_out_max} [get_ports {altera_reserved_tdo}]

    set_output_delay  -add_delay -clock_fall -clock altera_reserved_tck \
                      -min ${tdo_out_min} [get_ports {altera_reserved_tdo}]
}

proc set_tdo_timing_spec_when_drive_device { } {
    set next_device_tdi_tco_max   10.0
    set next_device_tdi_tco_min   10.0
    set tdo_trace_max             0.5
    set tdo_trace_min             0.1
    set tdo_out_max \

    [expr ${next_device_tdi_tco_max} + ${tdo_trace_max} + [get_tck_delay_max]]

    set tdo_out_min \
    [expr ${next_device_tdi_tco_min} + ${tdo_trace_min} + [get_tck_delay_min]]

    set_output_delay  -add_delay -clock altera_reserved_tck \
                      -max ${tdo_out_max} [get_ports {altera_reserved_tdo}]

    set_output_delay  -add_delay -clock altera_reserved_tck \
                      -min ${tdo_out_min} [get_ports {altera_reserved_tdo}]
}

proc set_optional_ntrst_timing_spec { } {
    if { [get_collection_size [get_ports -nowarn {altera_reserved_ntrst}]] > 0 } {
        set_false_path -from [get_ports {altera_reserved_ntrst}]
    }
}

if { [get_collection_size [get_ports -nowarn {altera_reserved_tck}]] > 0 } {
    set_jtag_timing_constraints
    if {[string equal quartus_sta $::TimeQuestInfo(nameofexecutable)]} {
        post_message -type warning "This design is using default JTAG timing constraints from jtag_example.sdc. \
                                    For correct hardware behavior, you must review the timing constraints in JTAG.\
                                    sdc and ensure that they accurately reflect your JTAG topology and clock speed."
    }
}

