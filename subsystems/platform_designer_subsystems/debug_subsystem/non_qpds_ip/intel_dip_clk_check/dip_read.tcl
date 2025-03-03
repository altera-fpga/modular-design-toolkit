###################################################################################
# INTEL CONFIDENTIAL
# 
# Copyright (C) 2022 Intel Corporation
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

# !!! MUST BE SETUP SO THE REF CLOCK THRESHOLD IS 1SEC. ELSE RESULT WILL NOT BE IN Hz. !!!

# Doesn't change
set service_paths [get_service_paths master];

# Depending on designs, service path may be a number other than 0
set master_service_path [lindex $service_paths 0];

# Doesn't change
set claim_path [claim_service master $master_service_path mylib];

# Depending on designs, Addresses may be different
set addr 0x00000000;

# This bit remains the same
set temp [master_read_32 $claim_path $addr 0x08];
set clock_freq [lindex $temp 1]
scan $clock_freq %x decimal
set decimal
puts "clock under test frequency is: $decimal Hz"