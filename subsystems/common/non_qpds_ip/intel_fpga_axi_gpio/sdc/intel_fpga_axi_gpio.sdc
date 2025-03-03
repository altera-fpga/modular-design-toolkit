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

set inst [get_current_instance]
set_false_path -to [get_keepers ${inst}|gpi_meta[*]]
set_false_path -from [get_fanins -async [get_keepers ${inst}|aresetn_sr[*]]] -to [get_keepers ${inst}|aresetn_sr[*]]