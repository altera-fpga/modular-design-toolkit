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

# internal call script. runs in the qsys-script tcl environment

# ATTENTION !!
# DO NOT CALL IN COMMAND LINE - use ip_list_generate.tcl script with build path as input argument

package require -exact qsys 21.1

##################################################################

proc extract_xml_value { xml keys } {

  set i 0
  set l [llength $keys]

  foreach line [split $xml "\n"] {
    set key [lindex $keys $i]
    if {[regexp <$key> $line]} {
      incr i
      if {$i == $l} {
        regexp <$key>(.*)</$key> $line a b
        return $b
      }
    }
    if {[regexp </$key> $line]} {
      incr i -1
    }
  }

}

##################################################################

puts ","

set instances_list [get_instances]
foreach instance $instances_list {
  if {![regexp "subsystem" $instance]} {
    set ip_core_name [extract_xml_value [get_instance_parameter_value $instance componentDefinition] {originalModuleInfo className} ]
    set version [extract_xml_value [get_instance_parameter_value $instance componentDefinition] {originalModuleInfo version} ]
    puts "$ip_core_name version: $version,"
  }
}