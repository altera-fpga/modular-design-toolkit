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

package provide pd_handler_pkg 1.0

package require Tcl            8.0

# This package is used to manage communication between Quartus and a Platform Designer subprocess.
#
# From Quartus: the Platform Designer subprocess is spawned, all stdout/stderr channel messages are
# captured and used to determine the state of the subprocess. If there is no activity from the
# subprocess for a period of time (set by qs_timeout_ms) it will be terminated from the parent
# Quartus process.
#
# From the Platform Designer subprocess: executes the script provided during creation. The subprocess
# can pause execution and wait for confirmation from the parent Quartus process to continue. This
# message is passed via a temporary file (due to Platform Designer TCL version).
#
# - Quartus -> Platform Designer, communication: via temporary files
# - Platform Designer -> Quartus, communication: via stdout/stderr channel
#
# Note: Temporary files do not contain any data, the message is encoded in the filename:
#       (<pid>_<message_count>_<exit>)
#       pid           = process id of the parent process
#       message_count = running total of messages sent (for error checking)
#       exit          = flag to indicate if the process should continue (0) or exit (1)

namespace eval pd_handler_pkg {

    namespace export run init sendStatus sendMessage waitForInstruction

    variable pkg_dir [file join [pwd] [file dirname [info script]]]

    #=========================================
    # Quartus Shell (parent process) variables

    # list of internal error codes (relating to Platform Designer state changes)
    variable qs_error_code {}

    # flag to indicate that the event loop should exit
    variable qs_exit_flag 0

    # count for number of lines read during exit
    variable qs_exit_cnt 0

    # current process id
    variable qs_pid 0

    # directory for temporary files
    variable qs_message_dir ""

    # running count of the temporary files created
    variable qs_message_count 0

    # timeout time in ms
    variable qs_timeout_ms 600000

    #============================================
    # Platform Designer (child process) variables

    # Platform Designer process state
    variable pd_state "PD_ACTIVE"

    # PD_ACTIVE = active and returning messages as expected
    # PD_WAIT   = waiting for an acknowledgement from parent process
    # PD_ACK    = acknowledged parent process instruction (continue/exit)
    # PD_EXIT   = process is exiting

    # multi-line message flag
    variable pd_ml_flag 0

    # multi-line message storage
    variable pd_ml_msg  ""

    # list of error messages that have been received from Platform Designer
    variable pd_error_msg {}

    # flag to indicate platform designer should exit
    variable pd_exit_flag 0

    # Platform Designer process id
    variable pd_pid ""

    # timeout id
    variable pd_tid ""

    # log of the output from the Platform Designer process
    variable pd_log {}

    # timeout time in ms
    variable pd_timeout_ms 10000

    #================================
    # General communication variables

    # flag to indicate that the while loop should exit
    variable exit_flag 0

    #========================================================

    proc ::pd_handler_pkg::timeoutEvent {} {

        ::pd_handler_pkg::setInternalError "TIMEOUT_ERROR"
        return

    }

    proc ::pd_handler_pkg::setInternalError {error_code} {

        variable qs_exit_flag
        variable qs_error_code

        variable exit_flag

        set qs_exit_flag  1
        set qs_error_code ${error_code}

        set exit_flag 1

        return

    }

    # main event loop

    proc ::pd_handler_pkg::eventLoop {} {

        variable qs_exit_flag
        variable pd_exit_flag

        set qs_exit_flag 0
        set pd_exit_flag 0

        variable qs_error_code
        variable pd_error_msg

        set v_result 0

        # enter the event loop the variable changes (process after and non-blocking channel events)
        vwait ::pd_handler_pkg::qs_exit_flag

        # Platform Designer requested exit
        if {${pd_exit_flag}} {
            set v_result 1
            post_message -type error "Shell Design encountered an error during Platform Designer execution:"

            foreach v_line ${pd_error_msg} {
                if {${v_line} != ""} {
                    post_message -type error ${v_line}
                }
            }

        # Internal error requested exit
        } elseif {[llength ${qs_error_code}] > 0} {
            set v_result 1
            post_message -type error "Shell Design encountered an error during Platform Designer execution\
                                      due to internal error: ${qs_error_code}"
        }

        ::pd_handler_pkg::deleteMessageFiles

        return ${v_result}

    }

    # process channel data (called during event loop, when channel event occurs)

    proc ::pd_handler_pkg::channelEvent {channel_id} {

        variable qs_timeout_ms
        variable qs_exit_flag

        variable pd_tid
        variable pd_state

        # cancel timeout task
        after cancel ${pd_tid}

        # read line from the channel
        set v_characters [gets ${channel_id} v_line]

        if {${v_characters} > 0} {
            # update system state based on channel message (from Platform Designer)
            set v_new_state  [::pd_handler_pkg::parsePDOutput ${v_line}]
            ::pd_handler_pkg::updateSystem  ${v_new_state}

            # restart timeout task
            set pd_tid   [after ${qs_timeout_ms} [list ::pd_handler_pkg::timeoutEvent]]

            ::pd_handler_pkg::addToLog ${v_line}

        # channel closed by Platform Designer
        } elseif {[eof ${channel_id}]} {

            # expected channel closure
            if {${pd_state}=="PD_EXIT"} {
                set qs_exit_flag 1

            # unexpected channel closure
            } else {
                ::pd_handler_pkg::setInternalError "EH_ERROR_CHANNEL_CLOSED"
            }
        }

        return

    }

    # multiline message from Platform Designer start

    proc ::pd_handler_pkg::startMultiLineMsg {} {

        variable pd_ml_flag
        variable pd_ml_msg

        # currently processing multiline message (raise error)
        if {${pd_ml_flag} == 1} {
            ::pd_handler_pkg::setInternalError "EH_ERROR_INVALID_ML_MSG_S"
        } else {
            set pd_ml_flag 1
            set pd_ml_msg  ""
        }

        return

    }

    # multiline message from Platform Designer end

    proc ::pd_handler_pkg::endMultiLineMsg {} {

        variable pd_ml_flag
        variable pd_ml_msg

        if {${pd_ml_flag} == 1} {
            set pd_ml_flag 0
            set pd_ml_msg  ""
        # not currently processing multiline message (raise error)
        } else {
            ::pd_handler_pkg::setInternalError "EH_ERROR_INVALID_ML_MSG_E"
        }
    }

    # Parse the line output from the platform designer process stdout/stderr channel

    proc ::pd_handler_pkg::parsePDOutput {line} {

        variable pd_error_msg
        variable pd_exit_flag

        variable pd_ml_msg
        variable pd_ml_flag

        # Platform Designer standard output
        if {[string first "Error:" ${line}] >=0 } {
            lappend pd_error_msg ${line}
            set pd_exit_flag     1
            return "PD_ACTIVE"

        # Platform Designer acknowledges command from script
        } elseif {[string first "SHELL_DESIGN_PD_ACKNOWLEDGE" ${line}] >=0 } {
            return "PD_ACK"

        # Platform Designer waiting for command from script
        } elseif {[string first "SHELL_DESIGN_PD_WAITING" ${line}] >=0 } {
            return "PD_WAIT"

        # Platform Designer is exiting
        } elseif {[string first "SHELL_DESIGN_PD_EXITING" ${line}] >=0 } {
            return "PD_EXIT"

        # Platform Designer message start
        } elseif {[string first "SHELL_DESIGN_PD_MESSAGE_S" ${line}] >=0 } {
            ::pd_handler_pkg::startMultiLineMsg
            return "PD_ACTIVE"

        # Platform Designer message end (forward to the terminal)
        } elseif {[string first "SHELL_DESIGN_PD_MESSAGE_E" ${line}] >=0 } {
            puts -nonewline ${pd_ml_msg}
            ::pd_handler_pkg::endMultiLineMsg
            return "PD_ACTIVE"

        # Platform Designer error message start
        } elseif {[string first "SHELL_DESIGN_PD_ERROR_S" ${line}] >=0 } {
            ::pd_handler_pkg::startMultiLineMsg
            return "PD_ACTIVE"

        # Platform Designer error message end (terminate Platform Designer)
        } elseif {[string first "SHELL_DESIGN_PD_ERROR_E" ${line}] >=0 } {
            lappend pd_error_msg ${pd_ml_msg}
            set pd_exit_flag 1
            ::pd_handler_pkg::endMultiLineMsg
            return "PD_ACTIVE"

        # Platform Designer message
        } elseif {${pd_ml_flag} == 1} {
            append pd_ml_msg "${line}\n"
            return "PD_ACTIVE"
        }

        # All other Platform Designer messages are treated as signalling activity
        return "PD_ACTIVE"

    }

    # Remove internal messaging (for logging purposes)

    proc ::pd_handler_pkg::addToLog {line} {

        variable pd_log

        set v_output [string map {"SHELL_DESIGN_PD_ACKNOWLEDGE" "" \
                                  "SHELL_DESIGN_PD_WAITING"     "" \
                                  "SHELL_DESIGN_PD_EXITING"     "" \
                                  "SHELL_DESIGN_PD_MESSAGE_S"   "" \
                                  "SHELL_DESIGN_PD_MESSAGE_E"   "" \
                                  "SHELL_DESIGN_PD_ERROR_S"     "" \
                                  "SHELL_DESIGN_PD_ERROR_E"     "" \
                                 } ${line}]

        if {${v_output} != ""} {
            append pd_log "${v_output}\n"
        }

        return

    }

    # Update the state of the Platform Designer process based on the current and previous states

    proc ::pd_handler_pkg::updateSystem {new_state} {

        variable pd_state
        variable pd_exit_flag

        variable qs_exit_cnt

        set v_new_state ${new_state}

        switch ${new_state} {
            PD_ACTIVE   {
                # Platform Designer process active without acknowledging command
                if {${pd_state} == "PD_WAIT"} {
                    ::pd_handler_pkg::setInternalError "EH_ERROR_NO_ACK"

                # Platform Designer process active whilst exiting (stdout/stderr can occur during exit)
                } elseif {${pd_state} == "PD_EXIT"} {
                    # ensure Platform Designer state remains exiting
                    set v_new_state ${pd_state}
                    incr qs_exit_cnt
                    if {${qs_exit_cnt} >= 50} {
                        ::pd_handler_pkg::setInternalError "EH_ERROR_EXIT_LOOP"
                    }
                }
            }
            PD_WAIT  {
                # Platform Designer process waiting for command without acknowledging previous command
                if {${pd_state} == "PD_WAIT"} {
                    ::pd_handler_pkg::setInternalError "EH_ERROR_NO_ACK"

                # Platform Designer process waiting for command whilst exiting
                } elseif {${pd_state} == "PD_EXIT"} {
                    ::pd_handler_pkg::setInternalError "EH_ERROR_NO_EXIT"

                # Platform Designer process waiting for command, so send command
                } else {
                    if {${pd_exit_flag}} {
                        ::pd_handler_pkg::createMessageFile 1
                    } else {
                        ::pd_handler_pkg::createMessageFile 0
                    }
                }
            }
            PD_ACK {
                # Platform Designer process acknowledged out of sequence
                if {${pd_state} != "PD_WAIT"} {
                    ::pd_handler_pkg::setInternalError "EH_ERROR_ACK"
                }
            }
            PD_EXIT {
                # n/a : transfer to exit state is valid from all other states
            }
            default {
                ::pd_handler_pkg::setInternalError "EH_ERROR_UNKNOWN_STATE"
            }
        }

        set pd_state ${v_new_state}

        return

    }

    # Manually kill the platform designer process

    proc ::pd_handler_pkg::forcePDExit {} {

        variable pd_pid

        if {${pd_pid} != ""} {
            set v_result [catch {exec kill ${pd_pid}} result_text]
            if {${v_result} != 0} {
                return -code ${v_result} ${result_text}
            }
        }

        return

    }

    # Create temporary file to message the Platform Designer process

    proc ::pd_handler_pkg::createMessageFile {exit} {

        variable qs_pid
        variable qs_message_dir
        variable qs_message_count

        set v_file_name "${qs_pid}_${qs_message_count}_${exit}"
        set v_full_path [file join ${qs_message_dir} ${v_file_name}]

        for {set v_attempt 0} {${v_attempt} < 10} {incr v_attempt} {
            set v_result [catch {open ${v_full_path} w} result_text]

            if {${v_result} == 0} {
                close ${result_text}
                break
            } else {
                after 10
            }
        }

        # failed to communicate to Platform Designer
        if {${v_result} != 0} {
            ::pd_handler_pkg::forcePDExit
            post_message -type error "Shell Design encountered an error during Platform Designer execution:\
                                      unable to create temp file (${v_full_path})"

        } else {
            incr qs_message_count
        }

        return

    }

    # Delete temporary message files (and directory)

    proc ::pd_handler_pkg::deleteMessageFiles {} {

        variable qs_message_dir

        set v_result [catch {file delete -force -- ${qs_message_dir}} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        return

    }

    # Run the Platform Designer command

    proc ::pd_handler_pkg::run {command message_directory} {

        variable qs_pid
        variable qs_message_dir
        variable qs_timeout_ms

        variable pd_pid
        variable pd_tid

        set qs_pid         [pid]
        set qs_message_dir [file join ${message_directory} "temp"]

        set v_result [catch {file mkdir ${qs_message_dir}} result_text]
        if {${v_result} != 0} {
            return -code ${v_result} ${result_text}
        }

        set v_command [linsert ${command} 4 ${qs_message_dir} ${qs_pid}]

        # Execute command with channel access
        set pd_channel_id [open "|${v_command}" r+]
        set pd_pid        [pid ${pd_channel_id}]

        chan configure ${pd_channel_id} -buffering none

        # Set callback procedure on channel event
        chan event ${pd_channel_id} readable [list ::pd_handler_pkg::channelEvent ${pd_channel_id}]

        # Start the timeout event
        set pd_tid [after ${qs_timeout_ms} [list ::pd_handler_pkg::timeoutEvent]]

        # Enter the event loop
        set v_return_value [::pd_handler_pkg::eventLoop]

        return ${v_return_value}

    }

    #===========================================================
    # Platform Designer commands

    # Initialize variables

    proc ::pd_handler_pkg::init {message_directory pid} {

        variable qs_pid
        variable qs_message_dir
        variable qs_message_count

        set qs_pid           ${pid}
        set qs_message_dir   ${message_directory}
        set qs_message_count 0

        return

    }

    # Raise an error, and close Platform Designer

    proc ::pd_handler_pkg::setError {{message ""}} {

        ::pd_handler_pkg::sendStatus "ERROR" ${message}
        ::pd_handler_pkg::endProcess

        return

    }

    # End the process, with an optional message

    proc ::pd_handler_pkg::endProcess {{message ""}} {

        ::pd_handler_pkg::sendStatus "EXIT"
        ::pd_handler_pkg::sendMessage ${message}
        exit

    }

    # send the status of the process back to the parent process

    proc ::pd_handler_pkg::sendStatus {status {message ""}} {

        switch ${status} {
            ACK     {
                        puts "SHELL_DESIGN_PD_ACKNOWLEDGE"
                    }
            ERROR   {
                        puts "SHELL_DESIGN_PD_ERROR_S"
                        puts ${message}
                        puts "SHELL_DESIGN_PD_ERROR_E"
                    }
            EXIT    {
                        puts "SHELL_DESIGN_PD_EXITING"
                    }
            WAIT    {
                        puts "SHELL_DESIGN_PD_WAITING"
                    }
            DEFAULT {}
        }

        return

    }

    # send a message to the terminal, via the parent process

    proc ::pd_handler_pkg::sendMessage {{message ""}} {

        puts "SHELL_DESIGN_PD_MESSAGE_S"
        puts ${message}
        puts "SHELL_DESIGN_PD_MESSAGE_E"

    }

    # Read instruction from message file

    proc ::pd_handler_pkg::getInstruction {} {

        variable qs_pid
        variable qs_message_dir
        variable qs_message_count

        set v_file_name "${qs_pid}_${qs_message_count}_"
        set v_full_path [file join ${qs_message_dir} ${v_file_name}]

        set v_files       [glob -nocomplain -- ${v_full_path}*]
        set v_files_count [llength ${v_files}]

        if {${v_files_count} == 1} {
            set v_result [regexp {([0-9]+)_([0-9]+)_(0|1)[ \f\n\r\t\v]*$} ${v_files} v_match v_pid v_count v_exit]
            if {${v_result} != 1} {
                return -code error "invalid filename"
            }

            if {${v_exit} == 0} {
                incr qs_message_count
            }

            return ${v_exit}

        } elseif {${v_files_count} == 0} {
            return -1
        } else {
            return -code error "Multiple Files"
        }

        return

    }

    # get instruction from the parent process, or run a timeout procedure

    proc ::pd_handler_pkg::waitForInstruction {} {

        variable pd_timeout_ms
        variable exit_flag

        set exit_flag 0

        set v_tid [after ${pd_timeout_ms} [list ::pd_handler_pkg::timeoutEvent]]

        ::pd_handler_pkg::sendStatus "WAIT"

        while {1} {

            set v_result [catch {::pd_handler_pkg::getInstruction} result_text]

            if {${v_result} != 0} {
                ::pd_handler_pkg::setError "Internal Error: ${result_text}"
            }

            # Message file found
            if {${result_text} >= 0} {
                after cancel ${v_tid}
                ::pd_handler_pkg::sendStatus "ACK"

                if {${result_text} == 1} {
                    ::pd_handler_pkg::endProcess
                }

                return

            }

            # Timeout occurred
            if {${exit_flag} == 1} {
                ::pd_handler_pkg::setError "Internal Error: timeout"
                return

            # Check timeout and try again
            } else {
                update
                after 100

            }

        }

        return

    }

}
