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

package provide timer_pkg 1.0

package require Thread

# Helper to display build progress on the command line

namespace eval timerOO_pkg {

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    ::oo::class create timer {

        variable v_thread_id     0
        variable v_start_time    0
        variable v_last_duration 0

        constructor {{v_silent_mode 0}} {

            variable v_thread_id

            # Script to execute as a separate thread
            set v_script {

                variable v_message
                variable v_start_time
                variable v_stop        0
                variable v_silent_mode 0

                proc timer {} {
                    variable v_message
                    variable v_start_time
                    variable v_stop
                    variable v_silent_mode

                    set v_current_time [clock seconds]
                    set v_wait_time    [expr ${v_current_time} - ${v_start_time}]

                    if {${v_stop} == 0} {
                        if {${v_silent_mode} == 0} {
                            set v_formatted_time [clock format ${v_wait_time} -format "%H:%M:%S" -gmt 1]
                            puts -nonewline "\r${v_message} - ${v_formatted_time}"
                            flush stdout
                        }
                        after 100 [list timer]
                    } else {
                        set v_stop 0
                    }
                    return
                }

                proc start {message} {
                    variable v_message
                    variable v_start_time

                    set v_message    ${message}
                    set v_start_time [clock seconds]

                    puts -nonewline ${v_message}
                    flush stdout

                    timer

                    return
                }

                proc stop {} {
                    variable v_stop
                    variable v_start_time

                    set v_stop           1
                    set v_current_time   [clock seconds]
                    set v_wait_time      [expr ${v_current_time} - ${v_start_time}]
                    set v_formatted_time [clock format ${v_wait_time} -format "%H:%M:%S" -gmt 1]

                    return ${v_formatted_time}
                }

                proc set_silent_mode {enable} {
                    variable v_silent_mode
                    set v_silent_mode ${enable}

                    return
                }

                thread::wait

            }

            # create a thread with a set of timer procedures;
            # messages are sent to the thread to run script procedures
            set v_thread_id [thread::create ${v_script}]

            thread::send -async ${v_thread_id} [list set_silent_mode ${v_silent_mode}]

        }

        method start {message} {

            variable v_thread_id
            thread::send -async ${v_thread_id} [list start ${message}]
            return

        }

        method stop {} {

            variable v_thread_id
            variable v_last_duration

            set v_result {}
            thread::send ${v_thread_id} [list stop] v_result

            set v_last_duration ${v_result}
            return ${v_result}

        }

        method get_last_duration {} {

          variable v_last_duration
          return   ${v_last_duration}

        }

        method set_silent_mode {enable} {

          thread::send -async ${v_thread_id} [list set v_silent_mode ${enable}]
          return

        }

        destructor {

            if {${v_thread_id} != 0} {
                thread::release -wait ${v_thread_id}
            }

            return

        }
    }

}
