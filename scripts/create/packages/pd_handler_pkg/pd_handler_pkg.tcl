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

package provide pd_handler_pkg 1.0
package require Tcl            8.0

namespace eval pd_handler_pkg {

  namespace export timeoutEvent setInternalError eventLoop channelEvent startMultiLineMsg endMultiLineMsg parsePDOutput addToLog updatePDState updateSystem forcePDExit createTempFile deleteTempFiles run init setError getInstruction endProcess sendStatus sendMessage waitForInstruction

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

  # CMD HANDLER VARIABLES ======================================

  # Quartus Shell (parent process) related variables
  set qs_error_code {}  ;# list of internal error codes (relating to Platform Designer state changes)
  set qs_exit_flag  0   ;# flag to indicate that the event loop should exit
  set qs_exit_cnt   0   ;# count for number of lines read during exit

  set qs_tmp_pid 0      ;# current process process id
  set qs_tmp_dir ""     ;# directory for temporary files
  set qs_tmp_cnt 0      ;# running count of the temporary files created

  set qs_timeout_ms 600000  ;# timeout time in ms

  # Platform Designer (child process) related variables
  set pd_state "PD_ACTIVE"  ;# Platform Designer process state

    # PD_ACTIVE = active and returning messages as expected
    # PD_WAIT   = waiting for an acknowledgement from parent process
    # PD_ACK    = acknowledged parent process instruction (continue/exit)
    # PD_EXIT   = process is exiting

  set pd_ml_flag 0      ;# multi-line message flag
  set pd_ml_msg  ""     ;# multi-line message storage

  set pd_error_msg {}   ;# list of error messages that have been received from Platform Designer
  set pd_exit_flag 0    ;# flag to indicate that platform designer should exit

  set pd_pid ""    ;# Platform Designer process id
  set pd_tid ""    ;# timeout id

  set pd_log {}    ;# log of the output from the Platform Designer process

  set pd_timeout_ms 10000  ;# timeout time in ms

  # COMMS HANDLER VARIABLES ====================================

  # Loop exit related variables
  set exit_flag 0     ;# flag to indicate that the while loop should exit
  set exit_code ""    ;# list of internal error codes (relating to temp file queries)

  # Temporary file related variables
  set tmp_pid 0       ;# process id of the script that spawned this process
  set tmp_dir ""      ;# directory in which the temporary files will be written
  set tmp_cnt 0       ;# running count of the temporary files read

}

# COMMON FUNCTIONS ============================================================
proc ::pd_handler_pkg::timeoutEvent {} {
    pd_handler_pkg::setInternalError "TIMEOUT_ERROR"
}

proc ::pd_handler_pkg::setInternalError {error_code} {
  lappend pd_handler_pkg::qs_error_code $error_code
  set pd_handler_pkg::exit_code $error_code
  set pd_handler_pkg::exit_flag 1       ;# set flag to exit the event loop
  set pd_handler_pkg::qs_exit_flag 1    ;# set flag to exit the event loop
}

#==============================================================================

proc ::pd_handler_pkg::eventLoop {} {
  set return_value 0
  set pd_handler_pkg::qs_exit_flag 0
  vwait pd_handler_pkg::qs_exit_flag                     ;# process events until variable changes
  if {$pd_handler_pkg::pd_exit_flag} {                   ;# exit due to Platform Designer error
    post_message -type error "Shell Design encountered an error during Platform Designer execution:"
    foreach line $pd_handler_pkg::pd_error_msg {
      if {$line!=""} {
        post_message -type error $line
      }
    }
    set return_value 1
  } elseif {[llength $pd_handler_pkg::qs_error_code]} {  ;# exit due to internal error
    post_message -type error "Shell Design encountered an error during Platform Designer execution due to internal error: $pd_handler_pkg::qs_error_code"
    set return_value 1
  }
  deleteTempFiles       ;# clean up
  return $return_value
}

# Called when there is data available on the channel
proc ::pd_handler_pkg::channelEvent {cc} {
  after cancel $pd_handler_pkg::pd_tid         ;# cancel timeout
  if {[gets $cc line] > 0} {              ;# the line is valid
    pd_handler_pkg::addToLog $line             ;# add the line to the log
    set prev_state $pd_handler_pkg::pd_state
    set curr_state [parsePDOutput $line]                                ;# infer the current state from the line
    updateSystem $curr_state $prev_state
    set pd_handler_pkg::pd_state [updatePDState $curr_state $prev_state]     ;# update the process state
    set pd_handler_pkg::pd_tid [after $pd_handler_pkg::qs_timeout_ms [list pd_handler_pkg::timeoutEvent]]  ;# restart timeout
  } elseif {[eof $cc]} {                          ;# the channel has been closed at the Platform Designer end
    if {$pd_handler_pkg::pd_state=="PD_EXIT"} {
      set pd_handler_pkg::qs_exit_flag 1               ;# channel close expected
    } else {
      setInternalError "EH_ERROR_CHANNEL_CLOSED"  ;# channel closed unexpectedly by the Platform Designer process
    }
  }
}

proc ::pd_handler_pkg::startMultiLineMsg {} {
  if {$pd_handler_pkg::pd_ml_flag} {
    setInternalError "EH_ERROR_INVALID_ML_MSG_S"
  } else {
    set pd_handler_pkg::pd_ml_flag 1
    set pd_handler_pkg::pd_ml_msg ""
  }
}

proc ::pd_handler_pkg::endMultiLineMsg {} {
  if {$pd_handler_pkg::pd_ml_flag} {
    set pd_handler_pkg::pd_ml_flag 0
    set pd_handler_pkg::pd_ml_msg ""
  } else {
    setInternalError "EH_ERROR_INVALID_ML_MSG_E"
  }
}

# Parse the line output from the platform designer process stdout/stderr channel
# Returns the state of the process inferred from the line contents

proc ::pd_handler_pkg::parsePDOutput {line} {
  if {[string first "Error:" $line] >=0 } {
    lappend pd_handler_pkg::pd_error_msg $line    ;# add error to list of errors
    set pd_handler_pkg::pd_exit_flag 1            ;# set flag to instruct the Platform Designer process to exit
    return "PD_ACTIVE"
  } elseif {[string first "SHELL_DESIGN_PD_ACKNOWLEDGE" $line] >=0 } {
    return "PD_ACK"
  } elseif {[string first "SHELL_DESIGN_PD_WAITING" $line] >=0 } {
    return "PD_WAIT"
  } elseif {[string first "SHELL_DESIGN_PD_EXITING" $line] >=0 } {
    return "PD_EXIT"
  } elseif {[string first "SHELL_DESIGN_PD_MESSAGE_S" $line] >=0 } {        ;# forward the message from the PD process to the terminal
    pd_handler_pkg::startMultiLineMsg
    return "PD_ACTIVE"
  } elseif {[string first "SHELL_DESIGN_PD_MESSAGE_E" $line] >=0 } {
    puts -nonewline $pd_handler_pkg::pd_ml_msg
    pd_handler_pkg::endMultiLineMsg
    return "PD_ACTIVE"
  } elseif {[string first "SHELL_DESIGN_PD_ERROR_S" $line] >=0 } {
    pd_handler_pkg::startMultiLineMsg
    return "PD_ACTIVE"
  } elseif {[string first "SHELL_DESIGN_PD_ERROR_E" $line] >=0 } {
    lappend pd_handler_pkg::pd_error_msg $pd_handler_pkg::pd_ml_msg           ;# add error to list of errors
    set pd_handler_pkg::pd_exit_flag 1                                   ;# set flag to instruct the Platform Designer process to exit
    pd_handler_pkg::endMultiLineMsg
    return "PD_ACTIVE"
  } else {
    if {$pd_handler_pkg::pd_ml_flag} {
      append pd_handler_pkg::pd_ml_msg "$line\n"
    }
    return "PD_ACTIVE"
  }
  return "PD_ACTIVE"
}

# strip the channel output of any internal messaging (for logging purposes)
proc ::pd_handler_pkg::addToLog {line} {
  set line_out [string map {"SHELL_DESIGN_PD_ACKNOWLEDGE" "" \
                            "SHELL_DESIGN_PD_WAITING"     "" \
                            "SHELL_DESIGN_PD_EXITING"     "" \
                            "SHELL_DESIGN_PD_MESSAGE_S"   "" \
                            "SHELL_DESIGN_PD_MESSAGE_E"   "" \
                            "SHELL_DESIGN_PD_ERROR_S"     "" \
                            "SHELL_DESIGN_PD_ERROR_E"     "" \
                           } $line]
    if {$line_out!=""} {
      append pd_handler_pkg::pd_log "$line_out\n"    ;# add the line to the log
    }
}

# Update the state of the Platform Designer process based on the current and previous states
proc ::pd_handler_pkg::updatePDState {curr_state prev_state} {
  if {$curr_state == "PD_ACTIVE" && $prev_state == "PD_EXIT"} {
    set curr_state $prev_state
  }
  return $curr_state
}

# Update the state of the Platform Designer process based on the current and previous states
proc ::pd_handler_pkg::updateSystem {curr_state prev_state} {
  switch $curr_state {
    PD_ACTIVE   {
      if {$prev_state == "PD_WAIT"} {
        setInternalError "EH_ERROR_NO_ACK"          ;# no ack received, flag an error
      } elseif {$prev_state == "PD_EXIT"} {
        incr pd_handler_pkg::qs_exit_cnt                 ;# during exit the subprocess can return stdout messages
        if {$pd_handler_pkg::qs_exit_cnt>=50} {          ;# limit the number of messages that can be returned during exit state
            setInternalError "EH_ERROR_EXIT_LOOP"   ;# stuck exiting, flag an error
        }
      }
    }
    PD_WAIT  {
      if {$prev_state == "PD_WAIT"} {
        setInternalError "EH_ERROR_NO_ACK"          ;# no acknowledgement, flag an error
      } elseif {$prev_state == "PD_EXIT"} {
        setInternalError "EH_ERROR_NO_EXIT"         ;# incorrect exit, flag an error
      } else {
        if {$pd_handler_pkg::pd_exit_flag} {
          createTempFile 1                          ;# send exit code
        } else {
          createTempFile 0                          ;# send continue code
        }
      }
    }
    PD_ACK {
      if {$prev_state != "PD_WAIT"} {
        setInternalError "EH_ERROR_ACK"             ;# acknowledgement received out of sequence, flag an error
      }
    }
    PD_EXIT  {
      # n/a : transfer to exit state is valid from all other states
    }
  }
}

# Manually kill the platform designer process
proc ::pd_handler_pkg::forcePDExit {} {
  exec kill $pd_handler_pkg::pd_pid
}

#===================================================================================================
# Create the temporary file to signal to the Platform Designer process

proc ::pd_handler_pkg::createTempFile {exit} {
  
  set pid $pd_handler_pkg::qs_tmp_pid                                 ;# get process id
  set cnt $pd_handler_pkg::qs_tmp_cnt                                 ;# get temp file count
  set file_name "${pid}_${cnt}_${exit}"                               ;# construct file name
  set full_path [file join $pd_handler_pkg::qs_tmp_dir $file_name]    ;# construct file path
  
  # attempt to create the temporary file 

  for {set i 0} {$i < 5} {incr i} {
    set result [catch {open $full_path w} result_text result_options]
    if {$result == 0} {
      close $result_text
      break
    } else {
      # sleep for 1ms
      after 1
    }
  }

  # failed to communicate to Platform Designer
  if {$result != 0} {
    ::pd_handler_pkg::forcePDExit
    post_message -type error "Shell Design encountered an error during Platform Designer execution: unable to create temp file ($full_path)"
  } else {
    incr pd_handler_pkg::qs_tmp_cnt                                     ;# increment temp file count
  }

}

proc ::pd_handler_pkg::deleteTempFiles {} {
  file delete -force ${pd_handler_pkg::qs_tmp_dir}
}

proc ::pd_handler_pkg::run {cmd tmpDir} {
  if {![file exists $tmpDir]} {
    puts "Error: tmp dir doesn't exist $tmpDir"
    return
  } elseif {![file isdirectory $tmpDir]} {
    puts "Error: tmp dir is not a directory $tmpDir"
    return
  }
  set pd_handler_pkg::qs_tmp_dir [file join $tmpDir temp]
  file mkdir $pd_handler_pkg::qs_tmp_dir
  set pd_handler_pkg::qs_tmp_pid [pid]
  set new_cmd [linsert $cmd 4 $pd_handler_pkg::qs_tmp_dir $pd_handler_pkg::qs_tmp_pid]
  set cc  [open "|$new_cmd" r+]
  set pid [pid $cc]                       ;# get the id of the process attached to the channel
  set pd_handler_pkg::pd_pid $pid
  chan configure $cc -buffering none      ;# set the i/o to be immediately flushed through the channel
  chan event $cc readable [list pd_handler_pkg::channelEvent $cc]
  set pd_handler_pkg::pd_tid [after $pd_handler_pkg::qs_timeout_ms [list pd_handler_pkg::timeoutEvent]]
  set return_value [pd_handler_pkg::eventLoop]
  return $return_value
  }


#COMMS HANDLER FUNCTIONS ======================================
  # initialise the namespace variables

proc ::pd_handler_pkg::init {tmpFileName pid} {
  set pd_handler_pkg::tmp_pid $pid
  set pd_handler_pkg::tmp_dir $tmpFileName
  set pd_handler_pkg::tmp_cnt 0
}


# raise an error, and exit the process. this can be used outside of the
# waitForInstruction procedure whilst using the catch tcl command
proc ::pd_handler_pkg::setError {{msg ""}} {
  pd_handler_pkg::sendStatus "ERROR" $msg     ;# send the tcl error message back to parent process
  pd_handler_pkg::endProcess
}

# locate the correct temporary file, and act upon the instruction determined from its filename
proc ::pd_handler_pkg::getInstruction {} {
  set pid $pd_handler_pkg::tmp_pid      ;# get process id
  set cnt $pd_handler_pkg::tmp_cnt      ;# get temp file index
  set file_name "${pid}_${cnt}_"                                   ;# construct file name
  set full_path [file join $pd_handler_pkg::tmp_dir $file_name]    ;# construct file path
  set files_found [glob -nocomplain -- ${full_path}*]
  set num_files_found [llength $files_found]
  if {$num_files_found == 0} {
    return                                ;# no file found, return to try again
  } elseif {$num_files_found == 1} {
    set name [file tail $files_found]     ;# single file found, get name
    set split_name [split $name "_"]      ;# split name into parts
    if {[llength $split_name]==3} {
      set exit_value [lindex $split_name 2]   ;# get exit value
      if {$exit_value==0} {
        incr pd_handler_pkg::tmp_cnt          ;# increment temp file counter
        set pd_handler_pkg::exit_flag 1       ;# exit loop, but continue process
      } elseif {$exit_value==1} {
        pd_handler_pkg::endProcess            ;# Platform Designer (instructed to exit)
      } else {
        pd_handler_pkg::setInternalError "INVALID_EXIT"     ;# invalid exit code
      }
    } else {
      pd_handler_pkg::setInternalError "INVALID_FILENAME"   ;# invalid filename error
    }
  } else {
   pd_handler_pkg::setInternalError "MULTIPLE_FILES"        ;# multiple files found error
  }
  return
}

# exit the process, with an optional post-exit message
proc ::pd_handler_pkg::endProcess {{msg ""}} {
  pd_handler_pkg::sendStatus "EXIT"   ;# send the exit message
  pd_handler_pkg::sendMessage $msg    ;# send message
  exit
}

# send the status of the process back to the parent process
proc ::pd_handler_pkg::sendStatus {status {msg ""}} {
  switch $status {
    ACK   {puts "SHELL_DESIGN_PD_ACKNOWLEDGE"}
    ERROR {
      puts "SHELL_DESIGN_PD_ERROR_S"
      puts $msg
      puts "SHELL_DESIGN_PD_ERROR_E"
    }
    EXIT  {puts "SHELL_DESIGN_PD_EXITING"}
    WAIT  {puts "SHELL_DESIGN_PD_WAITING"}
    DEFAULT {}
  }
}

# send a message to the terminal, via the parent process
proc ::pd_handler_pkg::sendMessage {{msg ""}} {
  puts "SHELL_DESIGN_PD_MESSAGE_S"
  puts $msg
  puts "SHELL_DESIGN_PD_MESSAGE_E"
}

# get instruction from the parent process, or run a timeout procedure
proc ::pd_handler_pkg::waitForInstruction {} {
  set pd_handler_pkg::exit_flag 0
  set tid [after $pd_handler_pkg::pd_timeout_ms [list pd_handler_pkg::timeoutEvent]]   ;# start timeout timer
  pd_handler_pkg::sendStatus "WAIT"     ;# update status to waiting
  while {1} {
    pd_handler_pkg::getInstruction        ;# attempt to get instruction
    if {$pd_handler_pkg::exit_flag} {
      after cancel $tid                   ;# cancel the timeout event
      break                               ;# exit while loop
    } else {
      update                              ;# process any pending events (i.e. timeout)
      after 100                           ;# sleep for a small amount of time 100ms
    }
  }
  if {$pd_handler_pkg::exit_code==""} {
    pd_handler_pkg::sendStatus "ACK"    ;# no error, continue script
    return
  } else {
    pd_handler_pkg::setError "Internal Error: $pd_handler_pkg::exit_code"   ;# internal error, exit process
  }
}