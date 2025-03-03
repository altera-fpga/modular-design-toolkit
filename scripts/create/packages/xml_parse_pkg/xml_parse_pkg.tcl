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

# Package of functions used for the xml parsing

package provide xml_parse_pkg 1.0
package require Tcl           8.0

set script_dir [file dirname [info script]]
lappend auto_path "$script_dir/../"

package require query_pkg                 1.0

namespace eval ::xml_parse_pkg {
  # export commands
  namespace export parse_xml_settings_file

  variable pkg_dir [file join [pwd] [file dirname [info script]]]

  # setup state
  #variable <variable_name>
  variable xml_path 
  variable shell_root 
  variable param_array
  variable path
  variable subsystem_array

}

# SUB/INTERNAL FUNCTIONS ==============================================================

proc check_required_params {param_array} {

  # based on the bare minimum to open a Quartus project
  set required_params [list  DEVICE DEVKIT FAMILY]    

  upvar $param_array p_array

  array set temp_array [join $p_array(project,params)]

  foreach param $required_params {
    if {![info exist temp_array($param)]} {
      post_message -type error "Project parameter $param is not defined in the XML file"
      exit
    }
  }

  array unset temp_array

  return 1

}

# loop for all children of node and return addon cards

proc get_xml_element_type {xml_node element_type} {

  set node_list {}

  foreach child [::dom::node children $xml_node] {

    # ignore nodes that are not elements
    if {[dom::node cget $child -nodeType] != "element"} {
      continue
    }

    set child_name [dom::node cget $child -nodeName]

    if {$child_name == $element_type} {
      lappend node_list $child
    }

  }

  return $node_list

}

proc get_xml_subsystems {xml_node} {
  return [get_xml_element_type $xml_node "SUBSYSTEM"]
}

proc get_xml_addon_cards {xml_node} {
  return [get_xml_element_type $xml_node "ADDON_CARD"]
}

proc get_abs_path {xml_path path} {

  # if script path is relative (to XML file) then convert to absolute path
  if {[file pathtype $path]=="relative"} {           
    set xml_dir     [file dirname $xml_path]
    set full_path   [file join $xml_dir $path]
    set output_path [file normalize $full_path]

    # special case for a directory that ends with a /.
    # this is used to indicate contents copy vs folder copy
    # with the cp command. Hence ensure this is kept after
    # path normalization
    if {[file tail $full_path] == "."} {
      set output_path [file join $output_path .]
    }

  } else {
    set output_path $path
  }

  # ensure that the file exists
  if {![file exists $output_path]} {
    post_message -type error "XML Parse - path ($output_path) does not exist"
    exit
  }

  return $output_path

}

proc get_xml_param_pair {xml_node xml_path param_name param_value} {

  upvar $param_name   p_name
  upvar $param_value  p_value

  set p_name  [dom::node cget $xml_node -nodeName]
  set p_value ""

  if {[lsearch -exact [list PROJECT SUBSYSTEM ADDON_CARD] $p_name] >= 0} {
    return 0
  }

  # loop for all lines of text in textnode (for multiline parameter)
  foreach child [::dom::node children $xml_node] {

    # ignore non-text child nodes
    if {[dom::node cget $child -nodeType]!="textNode"} {
      puts "ignored - something in $p_name"
      continue
    }
    
    # append current text node value to running value
    set sub_value [dom::node cget $child -nodeValue]
    set p_value $p_value$sub_value

  }

  # special nodes/parameters
  #======================================================

  if {[string match AVMM_HOST* $p_name]} {
    set p_value [parse_avmm_parameter $xml_node $xml_path]
    set p_value [list $p_value]
  }

  if {[string match IRQ_RX* $p_name]} {
    set p_value [parse_irq_parameter $xml_node $xml_path]
    set p_value [list $p_value]
  }

  # if the parameter is a directory 
  if {[string match *_DIR $p_name]} {
    set p_value [get_abs_path $xml_path $p_value]
  }

  # if the parameter is a file
  if {[string match *_FILE $p_name]} {
    set p_value [get_abs_path $xml_path $p_value]
  }

  return 1

}

proc add_param_pair_to_array {param_name param_value param_array} {

  upvar $param_array p_array
    
  set len [llength $param_value]

  puts "adding parameter ($len): $param_name - $param_value"

  if {[info exists p_array($param_name)]} {
    #lappend p_array($param_name) $param_value 
    lappend p_array($param_name) {*}$param_value 
  } else {
    set p_array($param_name) $param_value
  }

}

proc param_array_to_pair_list {} {

    set params_list {}

    foreach {name value} [array get param_array] {
      lappend params_list [list $name $value]
    }

    return params_list

}

proc get_xml_params {xml_node xml_path} {

  # create a temporary array for parameters (for search and replace operations)
  array set param_array {}

  # loop for all child nodes of the input node
  foreach child [::dom::node children $xml_node] {

    # ignore non-element child nodes
    if {[dom::node cget $child -nodeType]!="element"} {
      continue
    }

    set param_name  ""
    set param_value ""

    set success [get_xml_param_pair $child $xml_path param_name param_value]

    if {$success} {
      add_param_pair_to_array $param_name $param_value param_array
    }
  }

  set params_list {}

  foreach {name value} [array get param_array] {
    lappend params_list [list $name $value]
  }

  return $params_list

}


proc get_xml_project_attributes {xml_node param_array} {

  upvar $param_array p_array
  
  set attributes [dom::node cget $xml_node -attributes]      

  # name attribute
  if {[info exists ${attributes}(name)]} {                  
    set p_array(project,name) [set ${attributes}(name)]
  }

}

proc get_xml_attributes {xml_node xml_path param_array} {

  upvar $param_array p_array

  set id $p_array(project,id)
  set p_array($id,class) [dom::node cget $xml_node -nodeName]
  set attributes [dom::node cget $xml_node -attributes]      

  # name attribute
  if {[info exists ${attributes}(name)]} {                  
    
    set name [set ${attributes}(name)]

    if {$name=="project"} {
      post_message -type error "Name $name, cannot be used as a project or subsystem name"
      return
    } elseif {[info exists p_array($name,id)]} {
      post_message -type error "Name $name, used by multiple subsystems"
      return
    }

    set p_array($id,name) $name
    set p_array($name,id) $id

  }

  # type attribute
  if {[info exists ${attributes}(type)]} {
    set p_array($id,type) [set ${attributes}(type)]
  } elseif {${project} == 0} {
    post_message -type error "Subsystem must have a type"
    return
  }

}

proc parse_project_params {param_array} {

  upvar $param_array p_array
  
  array set temp_array [join $p_array(project,params)]

  # concat all ip search paths into a single path

  set paths $temp_array(DEFAULT_IP_SEARCH_PATH)
  set ip_search_path_concat ""

  foreach path $paths {
    append ip_search_path_concat $path ";"
  }

  if {[info exists temp_array(IP_SEARCH_PATH)]} {

    set paths $temp_array(IP_SEARCH_PATH)

    # check all ip_search paths exist
    foreach path $paths {
      # remove the string **/* if it exists at the end of the path (used to indicate recursive)
      regsub -all {\*\*/\*$} $path {} path_trim

      if {![file exists $path_trim]} {
        post_message -type error "IP Search Path: $path, does not exist"
      } elseif {[file pathtype $path_trim]=="relative"} {
        post_message -type error "IP Search Path: $path, must be an absolute path"
      } else {
        append ip_search_path_concat $path ";"
      }
    }
  }

  set params [list [list "IP_SEARCH_PATH_CONCAT" $ip_search_path_concat]]
  set p_array(project,params) [list {*}$p_array(project,params) {*}$params]

}

proc parse_board_subsystem {xml_node xml_path param_array} {

  upvar $param_array p_array

  set addon_cards [get_xml_addon_cards $xml_node]

  foreach card $addon_cards {

    incr p_array(project,id)
    set id $p_array(project,id)

    get_xml_attributes $card $xml_path p_array
    set p_array($id,params) [get_xml_params $card $xml_path]

  }

}

proc parse_user_subsystem {xml_node xml_path param_array} {

  upvar $param_array p_array

    set id $p_array(project,id)

    set attributes [dom::node cget $xml_node -attributes]   

    if {[info exists ${attributes}(script)]} {
      set script_path [set ${attributes}(script)]
      set script_path [get_abs_path $xml_path $script_path]
      set p_array($id,script) $script_path
    } else {
      post_message -type error "Subsystem of type $p_array($id,class) must have a script attribute"
      return
    }
  
}

proc parse_import_subsystem {xml_node xml_path param_array} {

    upvar $param_array p_array

    set id $p_array(project,id)

    set attributes [dom::node cget $xml_node -attributes]   

    if {[info exists ${attributes}(script)]} {
      set script_path [set ${attributes}(script)]
      set script_path [get_abs_path $xml_path $script_path]
      set p_array($id,script) $script_path
    } else {
      post_message -type error "Subsystem of type $p_array($id,class) must have a script attribute"
      return
    }
}

#==================================================================================================
# special parameter parsing ( i.e. not just <parameter_name>value</parameter_name> )

proc parse_avmm_parameter {xml_node xml_path} {

  # offset defaults to "don't care"
  set output_name ""
  set output_offset "X"

  # loop for all child nodes of the input node
  foreach child [::dom::node children $xml_node] {

    # ignore non-element child nodes
    if {[dom::node cget $child -nodeType]!="element"} {
      continue
    }

    set param_name  ""
    set param_value ""

    set success [get_xml_param_pair $child $xml_path param_name param_value]

    if {$success} {
      if {$param_name == "NAME"} {
        set output_name $param_value
      } elseif {$param_name == "OFFSET"} {
        set output_offset $param_value
      }
    }

  }

  return [list $output_name $output_offset]

}

proc parse_irq_parameter {xml_node xml_path} {

  # offset defaults to "don't care"
  set output_name     ""
  set output_priority "X"

  # loop for all child nodes of the input node
  foreach child [::dom::node children $xml_node] {

    # ignore non-element child nodes
    if {[dom::node cget $child -nodeType]!="element"} {
      continue
    }

    set param_name  ""
    set param_value ""

    set success [get_xml_param_pair $child $xml_path param_name param_value]

    if {$success} {
      if {$param_name == "NAME"} {
        set output_name $param_value
      } elseif {$param_name == "PRIORITY"} {
        set output_priority $param_value
      }
    }

  }

  return [list $output_name $output_priority]

}

proc init_param_array {param_array xml_path} {

  upvar $param_array p_array

  # set project level parameters
  set p_array(project,name) "top"         ;# set default project name
  set p_array(project,params) {}
  set p_array(project,id) 0               ;# this keeps track of the number of subsystems in the shell design

  set p_array(project,xml_path) $xml_path

  set DEFAULT_IP_SEARCH_PATH [list "./../non_qpds_ip/**/*"              \
                                   "./../rtl/shell/**/*"                \
                                   "./../rtl/user/**/*"                 \
                              ]

  set param_pair [list [list "DEFAULT_IP_SEARCH_PATH" $DEFAULT_IP_SEARCH_PATH]]
  set p_array(project,params) [list {*}$p_array(project,params) {*}$param_pair]

  # top subsystem must be included as a subsystem, but is not explicitly defined by the user in the XML file
  # this also shares its name with the project name

  set id $p_array(project,id)
  set p_array($id,name) $p_array(project,name)
  set p_array($p_array(project,name),id) $id
  set p_array($id,class) "SUBSYSTEM"
  set p_array($id,type) "top"
  set p_array($id,params) {}

  incr p_array(project,id)

}


proc get_xml_doc_element {xml_path} {

  if {![file exists $xml_path]} {
    post_message -type error "XML path does not exist"
    qexit -error
  }

  set fp [open $xml_path r]                       ;# open file, read contents, and close file
  set xml_data [read $fp]
  close $fp

  set doc_data [::dom::parse $xml_data]       ;# convert xml to dom format

  set doc_el [dom::document cget $doc_data -documentElement]  ;# get the main wrapper element

  if {[dom::node cget $doc_el -nodeName] != "PROJECT"} {      
    post_message -type error "incorrect document element"
    qexit -error
  }

  return $doc_el

}

proc print_param_array {param_array} {

  upvar $param_array p_array

  puts "\n============================================="

  if {[info exists p_array(project,name)]} {
    puts "Project name: $p_array(project,name)"
  }

  if {[info exists p_array(project,params)]} {
    foreach param_pair $p_array(project,params) {
      set name  [lindex $param_pair 0]
      set value [lindex $param_pair 1]
      puts "\tParameter: $name : $value"
    }
  }

  puts "---------------------------------------------"

  for {set id 0} {$id < $p_array(project,id)} {incr id} {
    
    if {[info exists p_array($id,class)]} {
      set type $p_array($id,class)
    }  

    if {[info exists p_array($id,name)]} {
      puts "$type name: $p_array($id,name)"
    }

    if {[info exists p_array($id,type)]} {
      puts "$type type: $p_array($id,type)"
    }  

    if {[info exists p_array($id,script)]} {
      puts "$type script: $p_array($id,script)"
    }

    if {[info exists p_array($id,params)]} {
      foreach param_pair $p_array($id,params) {
        set name  [lindex $param_pair 0]
        set value [lindex $param_pair 1]
        puts "\tParameter: $name - $value"
      }
    }

    if {$id < [expr $p_array(project,id)-1]} {
      puts "---------------------------------------------"
    }

  }

  puts "=============================================\n"

}

proc assign_unique_names {param_array} {

  upvar $param_array p_array

  # use a temporary array to store the subsystem name index <type>_<class>_<index>
  # which saves iterating through previously searched indexes
  array set temp_array {}
                              
  for {set id 0} {$id < $p_array(project,id)} {incr id} {

    # skip if name exists
    if {[info exists p_array($id,name)]} {    
      lappend p_array($id,params) [list "INSTANCE_NAME" $p_array($id,name)]
      continue
    }

    set index 0
    set class $p_array($id,class)
    set lower_class [string tolower $class]
    set type  $p_array($id,type)

    # if a name has already been generated for this class/type combination
    # use the saved index to create the first autogenerated name
    if {[info exists temp_array($class,$type)]} {
      set index $temp_array($class,$type)                    
    }                                                 

    set name "${type}_${lower_class}_${index}"

    # loop until a unique name is generated (by incrementing the index in each loop)
    # or, the number of attempts is exceeded
    while {[info exists p_array($name,id)]} {

      incr index                                      
      set name "${type}_${lower_class}_${index}"      

      # exit condition to ensure we don't get stuck in an infinite loop
      if {($index >= 100)} {
        post_message -type error "Error: Unable to generate subsystem name automatically"
        return
      }

    }

    # write generated name to the parameter array
    set p_array($id,name) $name                 
    set p_array($name,id) $id
    lappend p_array($id,params) [list "INSTANCE_NAME" $p_array($id,name)]

    # save the index for later use
    incr index
    set temp_array($class,$type) $index

  }

  array unset temp_array

}


proc assign_scripts {shell_root param_array} {
  
  upvar $param_array p_array

  array set valid_subsystems {}
  ::xml_parse_pkg::get_available_subsystems $shell_root valid_subsystems

  array set valid_addon_cards {}
  ::xml_parse_pkg::get_available_addon_cards $shell_root valid_addon_cards

  # assign creation scripts to the subsystems requested in the xml file
  for {set id 0} {$id < $p_array(project,id)} {incr id} {

    set class $p_array($id,class)
    set type  $p_array($id,type)

    # skip any subsystems that already have scripts defined
    if {[info exists p_array($id,script)]} {
      continue
    }

    if {$class == "SUBSYSTEM"} {
      if {[info exists valid_subsystems($type)]} {
        set p_array($id,script) $valid_subsystems($type)
      } else {
        post_message -type error "Error - The $class ($p_array($id,name)) of type ($type) does not match any available $class"
        return
      }
    } elseif {$class == "ADDON_CARD"} {
      if {[info exists valid_addon_cards($type)]} {
        set p_array($id,script) $valid_addon_cards($type)
      } else {
        post_message -type error "Error - The $class ($p_array($id,name)) of type ($type) does not match any available $class"
        return
      }
    } else {
        post_message -type error "Unknown $class"
        return
    }

  }

}

proc check_avmm_hosts {param_array} {
  
  upvar $param_array p_array

  set avmm_hosts_list {}

  for {set id 0} {$id < $p_array(project,id)} {incr id} {

    set class $p_array($id,class)
    set type  $p_array($id,type)

    if {$class == "SUBSYSTEM"} {

      set index [lsearch -exact {hps cpu niosv} $type]

      if {$index >= 0} {
        lappend avmm_hosts_list $id
      }

    } 

  }

  return

}

# function to pre-process the xml_path input argument to arrive at the full-absolute xml file path

proc process_xml_path { xml_path shell_designs_root } {
  set v_extension [file extension $xml_path]

  if { $v_extension == ""} {
    # if xml_path argument has no extension
    set v_xml_list [fileutil::findByPattern $shell_designs_root -glob -- $xml_path.xml]
  } elseif { $v_extension == ".xml" } {
    # if xml_path has xml extension then check for the existance of the file based on absolute path or in the shell_designs folder
    set v_nor_xml_path  [file normalize $xml_path]
    if {![file exists $v_nor_xml_path]} {
      set v_xml_list [fileutil::findByPattern $shell_designs_root -glob -- $xml_path]
    } else {
      set v_xml_list $v_nor_xml_path
    }
  } else {
    post_message -type error "Provide a valid XML file"
    qexit -error
  }

  return [lindex $v_xml_list 0]
}


# MAIN FUNCTIONS ======================================================================

proc ::xml_parse_pkg::parse_xml_settings_file {xml_path shell_root shell_designs_root param_array} {

  upvar $param_array p_array

  set xml_path [process_xml_path $xml_path $shell_designs_root]

  set doc_el [get_xml_doc_element $xml_path]

  init_param_array p_array $xml_path

  # get project level information (note: params list is concatenated 
  # as default parameters are set for ip search path)

  get_xml_project_attributes $doc_el p_array
  set params [get_xml_params $doc_el $xml_path]
  set p_array(project,params) [list {*}$p_array(project,params) {*}$params]

  parse_project_params p_array

  # get subsystem level information
  set subsystem_nodes [get_xml_subsystems $doc_el]

  foreach subsystem $subsystem_nodes {

    set id $p_array(project,id)

    get_xml_attributes $subsystem $xml_path p_array
    set p_array($id,params) [get_xml_params $subsystem $xml_path]

    # handle subsystem specific information not captured by default
    switch -exact $p_array($id,type) {
      board     { parse_board_subsystem   $subsystem $xml_path  p_array}
      user      { parse_user_subsystem    $subsystem $xml_path  p_array}
      #import    { parse_import_subsystem  $subsystem $xml_path  p_array}
      default   {}
    }

    incr p_array(project,id)

  }

  check_required_params p_array

  assign_unique_names p_array

  assign_scripts $shell_root p_array

  check_avmm_hosts p_array

  print_param_array p_array

  return

}

# searches the path for subsystem creation scripts and writes the results to the input array

proc ::xml_parse_pkg::get_available_subsystems {path subsystem_array} {

  upvar $subsystem_array s_array

  set found_subsystems [glob -directory $path -type f *_subsystem/*_create.tcl]
  
  foreach subsystem $found_subsystems {
    set name [string range [file tail $subsystem] 0 end-11]
    set s_array($name) $subsystem
  }

}

proc ::xml_parse_pkg::get_available_addon_cards {path subsystem_array} {

  upvar $subsystem_array s_array

#  set found_addon_cards [glob -directory $path -type f board_subsystem/addon_cards/*/*_create.tcl]
  if {[file exists $path/board_subsystem/addon_cards] && [file isdirectory $path/board_subsystem/addon_cards]} {
    set found_addon_cards [glob -nocomplain -directory $path -type f board_subsystem/addon_cards/*/*_create.tcl]
} else {
    set found_addon_cards {}
}

  
  foreach addon_card $found_addon_cards {
    set name [string range [file tail $addon_card] 0 end-11]
    set s_array($name) $addon_card
  }

}