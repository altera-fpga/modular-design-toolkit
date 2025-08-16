-- ##################################################################################
-- Copyright (C) 2025 Altera Corporation
--
-- This software and the related documents are Altera copyrighted materials, and
-- your use of them is governed by the express license under which they were
-- provided to you ("License"). Unless the License provides otherwise, you may
-- not use, modify, copy, publish, distribute, disclose or transmit this software
-- or the related documents without Altera's prior written permission.
--
-- This software and the related documents are provided as is, with no express
-- or implied warranties, other than those that are expressly stated in the License.
-- ##################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;

entity intel_offset_capability is
  generic (
    C_BASEADDR             : std_logic_vector(31 downto 0) := X"00000000";
    C_IS_NATIVE            : integer range 0 to 1 := 0;
    C_AUTO                 : integer := 0;
    C_NEXT                 : integer;
    C_BASE                 : integer := 0;

    C_CAP0_TYPE            : integer := 0;
    C_CAP0_VERSION         : integer := 0;
    C_CAP0_BASE            : integer := 0;
    C_CAP0_IRQ             : integer := 0;
    C_CAP0_SIZE            : integer := 0;
    C_CAP0_ID_ASSOCIATED   : integer := 0;
    C_CAP0_ID_COMPONENT    : integer := 0;
    C_CAP0_IRQ_ENABLE_EN   : integer := 0;
    C_CAP0_IRQ_STATUS_EN   : integer := 0;
    C_CAP0_IRQ_ENABLE      : integer := 0;
    C_CAP0_IRQ_STATUS      : integer := 0;

    C_CAP1_TYPE            : integer := 0;
    C_CAP1_VERSION         : integer := 0;
    C_CAP1_BASE            : integer := 0;
    C_CAP1_IRQ             : integer := 0;
    C_CAP1_SIZE            : integer := 0;
    C_CAP1_ID_ASSOCIATED   : integer := 0;
    C_CAP1_ID_COMPONENT    : integer := 0;
    C_CAP1_IRQ_ENABLE_EN   : integer := 0;
    C_CAP1_IRQ_STATUS_EN   : integer := 0;
    C_CAP1_IRQ_ENABLE      : integer := 0;
    C_CAP1_IRQ_STATUS      : integer := 0;

    C_CAP2_TYPE            : integer := 0;
    C_CAP2_VERSION         : integer := 0;
    C_CAP2_BASE            : integer := 0;
    C_CAP2_IRQ             : integer := 0;
    C_CAP2_SIZE            : integer := 0;
    C_CAP2_ID_ASSOCIATED   : integer := 0;
    C_CAP2_ID_COMPONENT    : integer := 0;
    C_CAP2_IRQ_ENABLE_EN   : integer := 0;
    C_CAP2_IRQ_STATUS_EN   : integer := 0;
    C_CAP2_IRQ_ENABLE      : integer := 0;
    C_CAP2_IRQ_STATUS      : integer := 0;

    C_CAP3_TYPE            : integer := 0;
    C_CAP3_VERSION         : integer := 0;
    C_CAP3_BASE            : integer := 0;
    C_CAP3_IRQ             : integer := 0;
    C_CAP3_SIZE            : integer := 0;
    C_CAP3_ID_ASSOCIATED   : integer := 0;
    C_CAP3_ID_COMPONENT    : integer := 0;
    C_CAP3_IRQ_ENABLE_EN   : integer := 0;
    C_CAP3_IRQ_STATUS_EN   : integer := 0;
    C_CAP3_IRQ_ENABLE      : integer := 0;
    C_CAP3_IRQ_STATUS      : integer := 0;

    C_CAP4_TYPE            : integer := 0;
    C_CAP4_VERSION         : integer := 0;
    C_CAP4_BASE            : integer := 0;
    C_CAP4_IRQ             : integer := 0;
    C_CAP4_SIZE            : integer := 0;
    C_CAP4_ID_ASSOCIATED   : integer := 0;
    C_CAP4_ID_COMPONENT    : integer := 0;
    C_CAP4_IRQ_ENABLE_EN   : integer := 0;
    C_CAP4_IRQ_STATUS_EN   : integer := 0;
    C_CAP4_IRQ_ENABLE      : integer := 0;
    C_CAP4_IRQ_STATUS      : integer := 0;

    C_CAP5_TYPE            : integer := 0;
    C_CAP5_VERSION         : integer := 0;
    C_CAP5_BASE            : integer := 0;
    C_CAP5_IRQ             : integer := 0;
    C_CAP5_SIZE            : integer := 0;
    C_CAP5_ID_ASSOCIATED   : integer := 0;
    C_CAP5_ID_COMPONENT    : integer := 0;
    C_CAP5_IRQ_ENABLE_EN   : integer := 0;
    C_CAP5_IRQ_STATUS_EN   : integer := 0;
    C_CAP5_IRQ_ENABLE      : integer := 0;
    C_CAP5_IRQ_STATUS      : integer := 0;

    C_CAP6_TYPE            : integer := 0;
    C_CAP6_VERSION         : integer := 0;
    C_CAP6_BASE            : integer := 0;
    C_CAP6_IRQ             : integer := 0;
    C_CAP6_SIZE            : integer := 0;
    C_CAP6_ID_ASSOCIATED   : integer := 0;
    C_CAP6_ID_COMPONENT    : integer := 0;
    C_CAP6_IRQ_ENABLE_EN   : integer := 0;
    C_CAP6_IRQ_STATUS_EN   : integer := 0;
    C_CAP6_IRQ_ENABLE      : integer := 0;
    C_CAP6_IRQ_STATUS      : integer := 0;

    C_CAP7_TYPE            : integer := 0;
    C_CAP7_VERSION         : integer := 0;
    C_CAP7_BASE            : integer := 0;
    C_CAP7_IRQ             : integer := 0;
    C_CAP7_SIZE            : integer := 0;
    C_CAP7_ID_ASSOCIATED   : integer := 0;
    C_CAP7_ID_COMPONENT    : integer := 0;
    C_CAP7_IRQ_ENABLE_EN   : integer := 0;
    C_CAP7_IRQ_STATUS_EN   : integer := 0;
    C_CAP7_IRQ_ENABLE      : integer := 0;
    C_CAP7_IRQ_STATUS      : integer := 0;

    C_CAP8_TYPE            : integer := 0;
    C_CAP8_VERSION         : integer := 0;
    C_CAP8_BASE            : integer := 0;
    C_CAP8_IRQ             : integer := 0;
    C_CAP8_SIZE            : integer := 0;
    C_CAP8_ID_ASSOCIATED   : integer := 0;
    C_CAP8_ID_COMPONENT    : integer := 0;
    C_CAP8_IRQ_ENABLE_EN   : integer := 0;
    C_CAP8_IRQ_STATUS_EN   : integer := 0;
    C_CAP8_IRQ_ENABLE      : integer := 0;
    C_CAP8_IRQ_STATUS      : integer := 0;

    C_CAP9_TYPE            : integer := 0;
    C_CAP9_VERSION         : integer := 0;
    C_CAP9_BASE            : integer := 0;
    C_CAP9_IRQ             : integer := 0;
    C_CAP9_SIZE            : integer := 0;
    C_CAP9_ID_ASSOCIATED   : integer := 0;
    C_CAP9_ID_COMPONENT    : integer := 0;
    C_CAP9_IRQ_ENABLE_EN   : integer := 0;
    C_CAP9_IRQ_STATUS_EN   : integer := 0;
    C_CAP9_IRQ_ENABLE      : integer := 0;
    C_CAP9_IRQ_STATUS      : integer := 0;

    C_CAP10_TYPE            : integer := 0;
    C_CAP10_VERSION         : integer := 0;
    C_CAP10_BASE            : integer := 0;
    C_CAP10_IRQ             : integer := 0;
    C_CAP10_SIZE            : integer := 0;
    C_CAP10_ID_ASSOCIATED   : integer := 0;
    C_CAP10_ID_COMPONENT    : integer := 0;
    C_CAP10_IRQ_ENABLE_EN   : integer := 0;
    C_CAP10_IRQ_STATUS_EN   : integer := 0;
    C_CAP10_IRQ_ENABLE      : integer := 0;
    C_CAP10_IRQ_STATUS      : integer := 0;

    C_CAP11_TYPE            : integer := 0;
    C_CAP11_VERSION         : integer := 0;
    C_CAP11_BASE            : integer := 0;
    C_CAP11_IRQ             : integer := 0;
    C_CAP11_SIZE            : integer := 0;
    C_CAP11_ID_ASSOCIATED   : integer := 0;
    C_CAP11_ID_COMPONENT    : integer := 0;
    C_CAP11_IRQ_ENABLE_EN   : integer := 0;
    C_CAP11_IRQ_STATUS_EN   : integer := 0;
    C_CAP11_IRQ_ENABLE      : integer := 0;
    C_CAP11_IRQ_STATUS      : integer := 0;

    C_CAP12_TYPE            : integer := 0;
    C_CAP12_VERSION         : integer := 0;
    C_CAP12_BASE            : integer := 0;
    C_CAP12_IRQ             : integer := 0;
    C_CAP12_SIZE            : integer := 0;
    C_CAP12_ID_ASSOCIATED   : integer := 0;
    C_CAP12_ID_COMPONENT    : integer := 0;
    C_CAP12_IRQ_ENABLE_EN   : integer := 0;
    C_CAP12_IRQ_STATUS_EN   : integer := 0;
    C_CAP12_IRQ_ENABLE      : integer := 0;
    C_CAP12_IRQ_STATUS      : integer := 0;

    C_CAP13_TYPE            : integer := 0;
    C_CAP13_VERSION         : integer := 0;
    C_CAP13_BASE            : integer := 0;
    C_CAP13_IRQ             : integer := 0;
    C_CAP13_SIZE            : integer := 0;
    C_CAP13_ID_ASSOCIATED   : integer := 0;
    C_CAP13_ID_COMPONENT    : integer := 0;
    C_CAP13_IRQ_ENABLE_EN   : integer := 0;
    C_CAP13_IRQ_STATUS_EN   : integer := 0;
    C_CAP13_IRQ_ENABLE      : integer := 0;
    C_CAP13_IRQ_STATUS      : integer := 0;

    C_CAP14_TYPE            : integer := 0;
    C_CAP14_VERSION         : integer := 0;
    C_CAP14_BASE            : integer := 0;
    C_CAP14_IRQ             : integer := 0;
    C_CAP14_SIZE            : integer := 0;
    C_CAP14_ID_ASSOCIATED   : integer := 0;
    C_CAP14_ID_COMPONENT    : integer := 0;
    C_CAP14_IRQ_ENABLE_EN   : integer := 0;
    C_CAP14_IRQ_STATUS_EN   : integer := 0;
    C_CAP14_IRQ_ENABLE      : integer := 0;
    C_CAP14_IRQ_STATUS      : integer := 0;

    C_CAP15_TYPE            : integer := 0;
    C_CAP15_VERSION         : integer := 0;
    C_CAP15_BASE            : integer := 0;
    C_CAP15_IRQ             : integer := 0;
    C_CAP15_SIZE            : integer := 0;
    C_CAP15_ID_ASSOCIATED   : integer := 0;
    C_CAP15_ID_COMPONENT    : integer := 0;
    C_CAP15_IRQ_ENABLE_EN   : integer := 0;
    C_CAP15_IRQ_STATUS_EN   : integer := 0;
    C_CAP15_IRQ_ENABLE      : integer := 0;
    C_CAP15_IRQ_STATUS      : integer := 0;

    C_CAP16_TYPE            : integer := 0;
    C_CAP16_VERSION         : integer := 0;
    C_CAP16_BASE            : integer := 0;
    C_CAP16_IRQ             : integer := 0;
    C_CAP16_SIZE            : integer := 0;
    C_CAP16_ID_ASSOCIATED   : integer := 0;
    C_CAP16_ID_COMPONENT    : integer := 0;
    C_CAP16_IRQ_ENABLE_EN   : integer := 0;
    C_CAP16_IRQ_STATUS_EN   : integer := 0;
    C_CAP16_IRQ_ENABLE      : integer := 0;
    C_CAP16_IRQ_STATUS      : integer := 0;

    C_CAP17_TYPE            : integer := 0;
    C_CAP17_VERSION         : integer := 0;
    C_CAP17_BASE            : integer := 0;
    C_CAP17_IRQ             : integer := 0;
    C_CAP17_SIZE            : integer := 0;
    C_CAP17_ID_ASSOCIATED   : integer := 0;
    C_CAP17_ID_COMPONENT    : integer := 0;
    C_CAP17_IRQ_ENABLE_EN   : integer := 0;
    C_CAP17_IRQ_STATUS_EN   : integer := 0;
    C_CAP17_IRQ_ENABLE      : integer := 0;
    C_CAP17_IRQ_STATUS      : integer := 0;

    C_CAP18_TYPE            : integer := 0;
    C_CAP18_VERSION         : integer := 0;
    C_CAP18_BASE            : integer := 0;
    C_CAP18_IRQ             : integer := 0;
    C_CAP18_SIZE            : integer := 0;
    C_CAP18_ID_ASSOCIATED   : integer := 0;
    C_CAP18_ID_COMPONENT    : integer := 0;
    C_CAP18_IRQ_ENABLE_EN   : integer := 0;
    C_CAP18_IRQ_STATUS_EN   : integer := 0;
    C_CAP18_IRQ_ENABLE      : integer := 0;
    C_CAP18_IRQ_STATUS      : integer := 0;

    C_CAP19_TYPE            : integer := 0;
    C_CAP19_VERSION         : integer := 0;
    C_CAP19_BASE            : integer := 0;
    C_CAP19_IRQ             : integer := 0;
    C_CAP19_SIZE            : integer := 0;
    C_CAP19_ID_ASSOCIATED   : integer := 0;
    C_CAP19_ID_COMPONENT    : integer := 0;
    C_CAP19_IRQ_ENABLE_EN   : integer := 0;
    C_CAP19_IRQ_STATUS_EN   : integer := 0;
    C_CAP19_IRQ_ENABLE      : integer := 0;
    C_CAP19_IRQ_STATUS      : integer := 0;

    C_CAP20_TYPE            : integer := 0;
    C_CAP20_VERSION         : integer := 0;
    C_CAP20_BASE            : integer := 0;
    C_CAP20_IRQ             : integer := 0;
    C_CAP20_SIZE            : integer := 0;
    C_CAP20_ID_ASSOCIATED   : integer := 0;
    C_CAP20_ID_COMPONENT    : integer := 0;
    C_CAP20_IRQ_ENABLE_EN   : integer := 0;
    C_CAP20_IRQ_STATUS_EN   : integer := 0;
    C_CAP20_IRQ_ENABLE      : integer := 0;
    C_CAP20_IRQ_STATUS      : integer := 0;

    C_CAP21_TYPE            : integer := 0;
    C_CAP21_VERSION         : integer := 0;
    C_CAP21_BASE            : integer := 0;
    C_CAP21_IRQ             : integer := 0;
    C_CAP21_SIZE            : integer := 0;
    C_CAP21_ID_ASSOCIATED   : integer := 0;
    C_CAP21_ID_COMPONENT    : integer := 0;
    C_CAP21_IRQ_ENABLE_EN   : integer := 0;
    C_CAP21_IRQ_STATUS_EN   : integer := 0;
    C_CAP21_IRQ_ENABLE      : integer := 0;
    C_CAP21_IRQ_STATUS      : integer := 0;

    C_CAP22_TYPE            : integer := 0;
    C_CAP22_VERSION         : integer := 0;
    C_CAP22_BASE            : integer := 0;
    C_CAP22_IRQ             : integer := 0;
    C_CAP22_SIZE            : integer := 0;
    C_CAP22_ID_ASSOCIATED   : integer := 0;
    C_CAP22_ID_COMPONENT    : integer := 0;
    C_CAP22_IRQ_ENABLE_EN   : integer := 0;
    C_CAP22_IRQ_STATUS_EN   : integer := 0;
    C_CAP22_IRQ_ENABLE      : integer := 0;
    C_CAP22_IRQ_STATUS      : integer := 0;

    C_CAP23_TYPE            : integer := 0;
    C_CAP23_VERSION         : integer := 0;
    C_CAP23_BASE            : integer := 0;
    C_CAP23_IRQ             : integer := 0;
    C_CAP23_SIZE            : integer := 0;
    C_CAP23_ID_ASSOCIATED   : integer := 0;
    C_CAP23_ID_COMPONENT    : integer := 0;
    C_CAP23_IRQ_ENABLE_EN   : integer := 0;
    C_CAP23_IRQ_STATUS_EN   : integer := 0;
    C_CAP23_IRQ_ENABLE      : integer := 0;
    C_CAP23_IRQ_STATUS      : integer := 0;

    C_CAP24_TYPE            : integer := 0;
    C_CAP24_VERSION         : integer := 0;
    C_CAP24_BASE            : integer := 0;
    C_CAP24_IRQ             : integer := 0;
    C_CAP24_SIZE            : integer := 0;
    C_CAP24_ID_ASSOCIATED   : integer := 0;
    C_CAP24_ID_COMPONENT    : integer := 0;
    C_CAP24_IRQ_ENABLE_EN   : integer := 0;
    C_CAP24_IRQ_STATUS_EN   : integer := 0;
    C_CAP24_IRQ_ENABLE      : integer := 0;
    C_CAP24_IRQ_STATUS      : integer := 0;

    C_CAP25_TYPE            : integer := 0;
    C_CAP25_VERSION         : integer := 0;
    C_CAP25_BASE            : integer := 0;
    C_CAP25_IRQ             : integer := 0;
    C_CAP25_SIZE            : integer := 0;
    C_CAP25_ID_ASSOCIATED   : integer := 0;
    C_CAP25_ID_COMPONENT    : integer := 0;
    C_CAP25_IRQ_ENABLE_EN   : integer := 0;
    C_CAP25_IRQ_STATUS_EN   : integer := 0;
    C_CAP25_IRQ_ENABLE      : integer := 0;
    C_CAP25_IRQ_STATUS      : integer := 0;

    C_CAP26_TYPE            : integer := 0;
    C_CAP26_VERSION         : integer := 0;
    C_CAP26_BASE            : integer := 0;
    C_CAP26_IRQ             : integer := 0;
    C_CAP26_SIZE            : integer := 0;
    C_CAP26_ID_ASSOCIATED   : integer := 0;
    C_CAP26_ID_COMPONENT    : integer := 0;
    C_CAP26_IRQ_ENABLE_EN   : integer := 0;
    C_CAP26_IRQ_STATUS_EN   : integer := 0;
    C_CAP26_IRQ_ENABLE      : integer := 0;
    C_CAP26_IRQ_STATUS      : integer := 0;

    C_CAP27_TYPE            : integer := 0;
    C_CAP27_VERSION         : integer := 0;
    C_CAP27_BASE            : integer := 0;
    C_CAP27_IRQ             : integer := 0;
    C_CAP27_SIZE            : integer := 0;
    C_CAP27_ID_ASSOCIATED   : integer := 0;
    C_CAP27_ID_COMPONENT    : integer := 0;
    C_CAP27_IRQ_ENABLE_EN   : integer := 0;
    C_CAP27_IRQ_STATUS_EN   : integer := 0;
    C_CAP27_IRQ_ENABLE      : integer := 0;
    C_CAP27_IRQ_STATUS      : integer := 0;

    C_CAP28_TYPE            : integer := 0;
    C_CAP28_VERSION         : integer := 0;
    C_CAP28_BASE            : integer := 0;
    C_CAP28_IRQ             : integer := 0;
    C_CAP28_SIZE            : integer := 0;
    C_CAP28_ID_ASSOCIATED   : integer := 0;
    C_CAP28_ID_COMPONENT    : integer := 0;
    C_CAP28_IRQ_ENABLE_EN   : integer := 0;
    C_CAP28_IRQ_STATUS_EN   : integer := 0;
    C_CAP28_IRQ_ENABLE      : integer := 0;
    C_CAP28_IRQ_STATUS      : integer := 0;

    C_CAP29_TYPE            : integer := 0;
    C_CAP29_VERSION         : integer := 0;
    C_CAP29_BASE            : integer := 0;
    C_CAP29_IRQ             : integer := 0;
    C_CAP29_SIZE            : integer := 0;
    C_CAP29_ID_ASSOCIATED   : integer := 0;
    C_CAP29_ID_COMPONENT    : integer := 0;
    C_CAP29_IRQ_ENABLE_EN   : integer := 0;
    C_CAP29_IRQ_STATUS_EN   : integer := 0;
    C_CAP29_IRQ_ENABLE      : integer := 0;
    C_CAP29_IRQ_STATUS      : integer := 0;

    C_CAP30_TYPE            : integer := 0;
    C_CAP30_VERSION         : integer := 0;
    C_CAP30_BASE            : integer := 0;
    C_CAP30_IRQ             : integer := 0;
    C_CAP30_SIZE            : integer := 0;
    C_CAP30_ID_ASSOCIATED   : integer := 0;
    C_CAP30_ID_COMPONENT    : integer := 0;
    C_CAP30_IRQ_ENABLE_EN   : integer := 0;
    C_CAP30_IRQ_STATUS_EN   : integer := 0;
    C_CAP30_IRQ_ENABLE      : integer := 0;
    C_CAP30_IRQ_STATUS      : integer := 0;

    C_CAP31_TYPE            : integer := 0;
    C_CAP31_VERSION         : integer := 0;
    C_CAP31_BASE            : integer := 0;
    C_CAP31_IRQ             : integer := 0;
    C_CAP31_SIZE            : integer := 0;
    C_CAP31_ID_ASSOCIATED   : integer := 0;
    C_CAP31_ID_COMPONENT    : integer := 0;
    C_CAP31_IRQ_ENABLE_EN   : integer := 0;
    C_CAP31_IRQ_STATUS_EN   : integer := 0;
    C_CAP31_IRQ_ENABLE      : integer := 0;
    C_CAP31_IRQ_STATUS      : integer := 0;

    C_CAP32_TYPE            : integer := 0;
    C_CAP32_VERSION         : integer := 0;
    C_CAP32_BASE            : integer := 0;
    C_CAP32_IRQ             : integer := 0;
    C_CAP32_SIZE            : integer := 0;
    C_CAP32_ID_ASSOCIATED   : integer := 0;
    C_CAP32_ID_COMPONENT    : integer := 0;
    C_CAP32_IRQ_ENABLE_EN   : integer := 0;
    C_CAP32_IRQ_STATUS_EN   : integer := 0;
    C_CAP32_IRQ_ENABLE      : integer := 0;
    C_CAP32_IRQ_STATUS      : integer := 0;

    C_CAP33_TYPE            : integer := 0;
    C_CAP33_VERSION         : integer := 0;
    C_CAP33_BASE            : integer := 0;
    C_CAP33_IRQ             : integer := 0;
    C_CAP33_SIZE            : integer := 0;
    C_CAP33_ID_ASSOCIATED   : integer := 0;
    C_CAP33_ID_COMPONENT    : integer := 0;
    C_CAP33_IRQ_ENABLE_EN   : integer := 0;
    C_CAP33_IRQ_STATUS_EN   : integer := 0;
    C_CAP33_IRQ_ENABLE      : integer := 0;
    C_CAP33_IRQ_STATUS      : integer := 0;

    C_CAP34_TYPE            : integer := 0;
    C_CAP34_VERSION         : integer := 0;
    C_CAP34_BASE            : integer := 0;
    C_CAP34_IRQ             : integer := 0;
    C_CAP34_SIZE            : integer := 0;
    C_CAP34_ID_ASSOCIATED   : integer := 0;
    C_CAP34_ID_COMPONENT    : integer := 0;
    C_CAP34_IRQ_ENABLE_EN   : integer := 0;
    C_CAP34_IRQ_STATUS_EN   : integer := 0;
    C_CAP34_IRQ_ENABLE      : integer := 0;
    C_CAP34_IRQ_STATUS      : integer := 0;

    C_CAP35_TYPE            : integer := 0;
    C_CAP35_VERSION         : integer := 0;
    C_CAP35_BASE            : integer := 0;
    C_CAP35_IRQ             : integer := 0;
    C_CAP35_SIZE            : integer := 0;
    C_CAP35_ID_ASSOCIATED   : integer := 0;
    C_CAP35_ID_COMPONENT    : integer := 0;
    C_CAP35_IRQ_ENABLE_EN   : integer := 0;
    C_CAP35_IRQ_STATUS_EN   : integer := 0;
    C_CAP35_IRQ_ENABLE      : integer := 0;
    C_CAP35_IRQ_STATUS      : integer := 0;

    C_CAP36_TYPE            : integer := 0;
    C_CAP36_VERSION         : integer := 0;
    C_CAP36_BASE            : integer := 0;
    C_CAP36_IRQ             : integer := 0;
    C_CAP36_SIZE            : integer := 0;
    C_CAP36_ID_ASSOCIATED   : integer := 0;
    C_CAP36_ID_COMPONENT    : integer := 0;
    C_CAP36_IRQ_ENABLE_EN   : integer := 0;
    C_CAP36_IRQ_STATUS_EN   : integer := 0;
    C_CAP36_IRQ_ENABLE      : integer := 0;
    C_CAP36_IRQ_STATUS      : integer := 0;

    C_CAP37_TYPE            : integer := 0;
    C_CAP37_VERSION         : integer := 0;
    C_CAP37_BASE            : integer := 0;
    C_CAP37_IRQ             : integer := 0;
    C_CAP37_SIZE            : integer := 0;
    C_CAP37_ID_ASSOCIATED   : integer := 0;
    C_CAP37_ID_COMPONENT    : integer := 0;
    C_CAP37_IRQ_ENABLE_EN   : integer := 0;
    C_CAP37_IRQ_STATUS_EN   : integer := 0;
    C_CAP37_IRQ_ENABLE      : integer := 0;
    C_CAP37_IRQ_STATUS      : integer := 0;

    C_CAP38_TYPE            : integer := 0;
    C_CAP38_VERSION         : integer := 0;
    C_CAP38_BASE            : integer := 0;
    C_CAP38_IRQ             : integer := 0;
    C_CAP38_SIZE            : integer := 0;
    C_CAP38_ID_ASSOCIATED   : integer := 0;
    C_CAP38_ID_COMPONENT    : integer := 0;
    C_CAP38_IRQ_ENABLE_EN   : integer := 0;
    C_CAP38_IRQ_STATUS_EN   : integer := 0;
    C_CAP38_IRQ_ENABLE      : integer := 0;
    C_CAP38_IRQ_STATUS      : integer := 0;

    C_CAP39_TYPE            : integer := 0;
    C_CAP39_VERSION         : integer := 0;
    C_CAP39_BASE            : integer := 0;
    C_CAP39_IRQ             : integer := 0;
    C_CAP39_SIZE            : integer := 0;
    C_CAP39_ID_ASSOCIATED   : integer := 0;
    C_CAP39_ID_COMPONENT    : integer := 0;
    C_CAP39_IRQ_ENABLE_EN   : integer := 0;
    C_CAP39_IRQ_STATUS_EN   : integer := 0;
    C_CAP39_IRQ_ENABLE      : integer := 0;
    C_CAP39_IRQ_STATUS      : integer := 0;

    C_CAP40_TYPE            : integer := 0;
    C_CAP40_VERSION         : integer := 0;
    C_CAP40_BASE            : integer := 0;
    C_CAP40_IRQ             : integer := 0;
    C_CAP40_SIZE            : integer := 0;
    C_CAP40_ID_ASSOCIATED   : integer := 0;
    C_CAP40_ID_COMPONENT    : integer := 0;
    C_CAP40_IRQ_ENABLE_EN   : integer := 0;
    C_CAP40_IRQ_STATUS_EN   : integer := 0;
    C_CAP40_IRQ_ENABLE      : integer := 0;
    C_CAP40_IRQ_STATUS      : integer := 0;

    C_CAP41_TYPE            : integer := 0;
    C_CAP41_VERSION         : integer := 0;
    C_CAP41_BASE            : integer := 0;
    C_CAP41_IRQ             : integer := 0;
    C_CAP41_SIZE            : integer := 0;
    C_CAP41_ID_ASSOCIATED   : integer := 0;
    C_CAP41_ID_COMPONENT    : integer := 0;
    C_CAP41_IRQ_ENABLE_EN   : integer := 0;
    C_CAP41_IRQ_STATUS_EN   : integer := 0;
    C_CAP41_IRQ_ENABLE      : integer := 0;
    C_CAP41_IRQ_STATUS      : integer := 0;

    C_CAP42_TYPE            : integer := 0;
    C_CAP42_VERSION         : integer := 0;
    C_CAP42_BASE            : integer := 0;
    C_CAP42_IRQ             : integer := 0;
    C_CAP42_SIZE            : integer := 0;
    C_CAP42_ID_ASSOCIATED   : integer := 0;
    C_CAP42_ID_COMPONENT    : integer := 0;
    C_CAP42_IRQ_ENABLE_EN   : integer := 0;
    C_CAP42_IRQ_STATUS_EN   : integer := 0;
    C_CAP42_IRQ_ENABLE      : integer := 0;
    C_CAP42_IRQ_STATUS      : integer := 0;

    C_CAP43_TYPE            : integer := 0;
    C_CAP43_VERSION         : integer := 0;
    C_CAP43_BASE            : integer := 0;
    C_CAP43_IRQ             : integer := 0;
    C_CAP43_SIZE            : integer := 0;
    C_CAP43_ID_ASSOCIATED   : integer := 0;
    C_CAP43_ID_COMPONENT    : integer := 0;
    C_CAP43_IRQ_ENABLE_EN   : integer := 0;
    C_CAP43_IRQ_STATUS_EN   : integer := 0;
    C_CAP43_IRQ_ENABLE      : integer := 0;
    C_CAP43_IRQ_STATUS      : integer := 0;

    C_CAP44_TYPE            : integer := 0;
    C_CAP44_VERSION         : integer := 0;
    C_CAP44_BASE            : integer := 0;
    C_CAP44_IRQ             : integer := 0;
    C_CAP44_SIZE            : integer := 0;
    C_CAP44_ID_ASSOCIATED   : integer := 0;
    C_CAP44_ID_COMPONENT    : integer := 0;
    C_CAP44_IRQ_ENABLE_EN   : integer := 0;
    C_CAP44_IRQ_STATUS_EN   : integer := 0;
    C_CAP44_IRQ_ENABLE      : integer := 0;
    C_CAP44_IRQ_STATUS      : integer := 0;

    C_CAP45_TYPE            : integer := 0;
    C_CAP45_VERSION         : integer := 0;
    C_CAP45_BASE            : integer := 0;
    C_CAP45_IRQ             : integer := 0;
    C_CAP45_SIZE            : integer := 0;
    C_CAP45_ID_ASSOCIATED   : integer := 0;
    C_CAP45_ID_COMPONENT    : integer := 0;
    C_CAP45_IRQ_ENABLE_EN   : integer := 0;
    C_CAP45_IRQ_STATUS_EN   : integer := 0;
    C_CAP45_IRQ_ENABLE      : integer := 0;
    C_CAP45_IRQ_STATUS      : integer := 0;

    C_CAP46_TYPE            : integer := 0;
    C_CAP46_VERSION         : integer := 0;
    C_CAP46_BASE            : integer := 0;
    C_CAP46_IRQ             : integer := 0;
    C_CAP46_SIZE            : integer := 0;
    C_CAP46_ID_ASSOCIATED   : integer := 0;
    C_CAP46_ID_COMPONENT    : integer := 0;
    C_CAP46_IRQ_ENABLE_EN   : integer := 0;
    C_CAP46_IRQ_STATUS_EN   : integer := 0;
    C_CAP46_IRQ_ENABLE      : integer := 0;
    C_CAP46_IRQ_STATUS      : integer := 0;

    C_CAP47_TYPE            : integer := 0;
    C_CAP47_VERSION         : integer := 0;
    C_CAP47_BASE            : integer := 0;
    C_CAP47_IRQ             : integer := 0;
    C_CAP47_SIZE            : integer := 0;
    C_CAP47_ID_ASSOCIATED   : integer := 0;
    C_CAP47_ID_COMPONENT    : integer := 0;
    C_CAP47_IRQ_ENABLE_EN   : integer := 0;
    C_CAP47_IRQ_STATUS_EN   : integer := 0;
    C_CAP47_IRQ_ENABLE      : integer := 0;
    C_CAP47_IRQ_STATUS      : integer := 0;

    C_CAP48_TYPE            : integer := 0;
    C_CAP48_VERSION         : integer := 0;
    C_CAP48_BASE            : integer := 0;
    C_CAP48_IRQ             : integer := 0;
    C_CAP48_SIZE            : integer := 0;
    C_CAP48_ID_ASSOCIATED   : integer := 0;
    C_CAP48_ID_COMPONENT    : integer := 0;
    C_CAP48_IRQ_ENABLE_EN   : integer := 0;
    C_CAP48_IRQ_STATUS_EN   : integer := 0;
    C_CAP48_IRQ_ENABLE      : integer := 0;
    C_CAP48_IRQ_STATUS      : integer := 0;

    C_CAP49_TYPE            : integer := 0;
    C_CAP49_VERSION         : integer := 0;
    C_CAP49_BASE            : integer := 0;
    C_CAP49_IRQ             : integer := 0;
    C_CAP49_SIZE            : integer := 0;
    C_CAP49_ID_ASSOCIATED   : integer := 0;
    C_CAP49_ID_COMPONENT    : integer := 0;
    C_CAP49_IRQ_ENABLE_EN   : integer := 0;
    C_CAP49_IRQ_STATUS_EN   : integer := 0;
    C_CAP49_IRQ_ENABLE      : integer := 0;
    C_CAP49_IRQ_STATUS      : integer := 0;

    C_CAP50_TYPE            : integer := 0;
    C_CAP50_VERSION         : integer := 0;
    C_CAP50_BASE            : integer := 0;
    C_CAP50_IRQ             : integer := 0;
    C_CAP50_SIZE            : integer := 0;
    C_CAP50_ID_ASSOCIATED   : integer := 0;
    C_CAP50_ID_COMPONENT    : integer := 0;
    C_CAP50_IRQ_ENABLE_EN   : integer := 0;
    C_CAP50_IRQ_STATUS_EN   : integer := 0;
    C_CAP50_IRQ_ENABLE      : integer := 0;
    C_CAP50_IRQ_STATUS      : integer := 0;

    C_CAP51_TYPE            : integer := 0;
    C_CAP51_VERSION         : integer := 0;
    C_CAP51_BASE            : integer := 0;
    C_CAP51_IRQ             : integer := 0;
    C_CAP51_SIZE            : integer := 0;
    C_CAP51_ID_ASSOCIATED   : integer := 0;
    C_CAP51_ID_COMPONENT    : integer := 0;
    C_CAP51_IRQ_ENABLE_EN   : integer := 0;
    C_CAP51_IRQ_STATUS_EN   : integer := 0;
    C_CAP51_IRQ_ENABLE      : integer := 0;
    C_CAP51_IRQ_STATUS      : integer := 0;

    C_CAP52_TYPE            : integer := 0;
    C_CAP52_VERSION         : integer := 0;
    C_CAP52_BASE            : integer := 0;
    C_CAP52_IRQ             : integer := 0;
    C_CAP52_SIZE            : integer := 0;
    C_CAP52_ID_ASSOCIATED   : integer := 0;
    C_CAP52_ID_COMPONENT    : integer := 0;
    C_CAP52_IRQ_ENABLE_EN   : integer := 0;
    C_CAP52_IRQ_STATUS_EN   : integer := 0;
    C_CAP52_IRQ_ENABLE      : integer := 0;
    C_CAP52_IRQ_STATUS      : integer := 0;

    C_CAP53_TYPE            : integer := 0;
    C_CAP53_VERSION         : integer := 0;
    C_CAP53_BASE            : integer := 0;
    C_CAP53_IRQ             : integer := 0;
    C_CAP53_SIZE            : integer := 0;
    C_CAP53_ID_ASSOCIATED   : integer := 0;
    C_CAP53_ID_COMPONENT    : integer := 0;
    C_CAP53_IRQ_ENABLE_EN   : integer := 0;
    C_CAP53_IRQ_STATUS_EN   : integer := 0;
    C_CAP53_IRQ_ENABLE      : integer := 0;
    C_CAP53_IRQ_STATUS      : integer := 0;

    C_CAP54_TYPE            : integer := 0;
    C_CAP54_VERSION         : integer := 0;
    C_CAP54_BASE            : integer := 0;
    C_CAP54_IRQ             : integer := 0;
    C_CAP54_SIZE            : integer := 0;
    C_CAP54_ID_ASSOCIATED   : integer := 0;
    C_CAP54_ID_COMPONENT    : integer := 0;
    C_CAP54_IRQ_ENABLE_EN   : integer := 0;
    C_CAP54_IRQ_STATUS_EN   : integer := 0;
    C_CAP54_IRQ_ENABLE      : integer := 0;
    C_CAP54_IRQ_STATUS      : integer := 0;

    C_CAP55_TYPE            : integer := 0;
    C_CAP55_VERSION         : integer := 0;
    C_CAP55_BASE            : integer := 0;
    C_CAP55_IRQ             : integer := 0;
    C_CAP55_SIZE            : integer := 0;
    C_CAP55_ID_ASSOCIATED   : integer := 0;
    C_CAP55_ID_COMPONENT    : integer := 0;
    C_CAP55_IRQ_ENABLE_EN   : integer := 0;
    C_CAP55_IRQ_STATUS_EN   : integer := 0;
    C_CAP55_IRQ_ENABLE      : integer := 0;
    C_CAP55_IRQ_STATUS      : integer := 0;

    C_CAP56_TYPE            : integer := 0;
    C_CAP56_VERSION         : integer := 0;
    C_CAP56_BASE            : integer := 0;
    C_CAP56_IRQ             : integer := 0;
    C_CAP56_SIZE            : integer := 0;
    C_CAP56_ID_ASSOCIATED   : integer := 0;
    C_CAP56_ID_COMPONENT    : integer := 0;
    C_CAP56_IRQ_ENABLE_EN   : integer := 0;
    C_CAP56_IRQ_STATUS_EN   : integer := 0;
    C_CAP56_IRQ_ENABLE      : integer := 0;
    C_CAP56_IRQ_STATUS      : integer := 0;

    C_CAP57_TYPE            : integer := 0;
    C_CAP57_VERSION         : integer := 0;
    C_CAP57_BASE            : integer := 0;
    C_CAP57_IRQ             : integer := 0;
    C_CAP57_SIZE            : integer := 0;
    C_CAP57_ID_ASSOCIATED   : integer := 0;
    C_CAP57_ID_COMPONENT    : integer := 0;
    C_CAP57_IRQ_ENABLE_EN   : integer := 0;
    C_CAP57_IRQ_STATUS_EN   : integer := 0;
    C_CAP57_IRQ_ENABLE      : integer := 0;
    C_CAP57_IRQ_STATUS      : integer := 0;

    C_CAP58_TYPE            : integer := 0;
    C_CAP58_VERSION         : integer := 0;
    C_CAP58_BASE            : integer := 0;
    C_CAP58_IRQ             : integer := 0;
    C_CAP58_SIZE            : integer := 0;
    C_CAP58_ID_ASSOCIATED   : integer := 0;
    C_CAP58_ID_COMPONENT    : integer := 0;
    C_CAP58_IRQ_ENABLE_EN   : integer := 0;
    C_CAP58_IRQ_STATUS_EN   : integer := 0;
    C_CAP58_IRQ_ENABLE      : integer := 0;
    C_CAP58_IRQ_STATUS      : integer := 0;

    C_CAP59_TYPE            : integer := 0;
    C_CAP59_VERSION         : integer := 0;
    C_CAP59_BASE            : integer := 0;
    C_CAP59_IRQ             : integer := 0;
    C_CAP59_SIZE            : integer := 0;
    C_CAP59_ID_ASSOCIATED   : integer := 0;
    C_CAP59_ID_COMPONENT    : integer := 0;
    C_CAP59_IRQ_ENABLE_EN   : integer := 0;
    C_CAP59_IRQ_STATUS_EN   : integer := 0;
    C_CAP59_IRQ_ENABLE      : integer := 0;
    C_CAP59_IRQ_STATUS      : integer := 0;

    C_CAP60_TYPE            : integer := 0;
    C_CAP60_VERSION         : integer := 0;
    C_CAP60_BASE            : integer := 0;
    C_CAP60_IRQ             : integer := 0;
    C_CAP60_SIZE            : integer := 0;
    C_CAP60_ID_ASSOCIATED   : integer := 0;
    C_CAP60_ID_COMPONENT    : integer := 0;
    C_CAP60_IRQ_ENABLE_EN   : integer := 0;
    C_CAP60_IRQ_STATUS_EN   : integer := 0;
    C_CAP60_IRQ_ENABLE      : integer := 0;
    C_CAP60_IRQ_STATUS      : integer := 0;

    C_CAP61_TYPE            : integer := 0;
    C_CAP61_VERSION         : integer := 0;
    C_CAP61_BASE            : integer := 0;
    C_CAP61_IRQ             : integer := 0;
    C_CAP61_SIZE            : integer := 0;
    C_CAP61_ID_ASSOCIATED   : integer := 0;
    C_CAP61_ID_COMPONENT    : integer := 0;
    C_CAP61_IRQ_ENABLE_EN   : integer := 0;
    C_CAP61_IRQ_STATUS_EN   : integer := 0;
    C_CAP61_IRQ_ENABLE      : integer := 0;
    C_CAP61_IRQ_STATUS      : integer := 0;

    C_CAP62_TYPE            : integer := 0;
    C_CAP62_VERSION         : integer := 0;
    C_CAP62_BASE            : integer := 0;
    C_CAP62_IRQ             : integer := 0;
    C_CAP62_SIZE            : integer := 0;
    C_CAP62_ID_ASSOCIATED   : integer := 0;
    C_CAP62_ID_COMPONENT    : integer := 0;
    C_CAP62_IRQ_ENABLE_EN   : integer := 0;
    C_CAP62_IRQ_STATUS_EN   : integer := 0;
    C_CAP62_IRQ_ENABLE      : integer := 0;
    C_CAP62_IRQ_STATUS      : integer := 0;

    C_CAP63_TYPE            : integer := 0;
    C_CAP63_VERSION         : integer := 0;
    C_CAP63_BASE            : integer := 0;
    C_CAP63_IRQ             : integer := 0;
    C_CAP63_SIZE            : integer := 0;
    C_CAP63_ID_ASSOCIATED   : integer := 0;
    C_CAP63_ID_COMPONENT    : integer := 0;
    C_CAP63_IRQ_ENABLE_EN   : integer := 0;
    C_CAP63_IRQ_STATUS_EN   : integer := 0;
    C_CAP63_IRQ_ENABLE      : integer := 0;
    C_CAP63_IRQ_STATUS      : integer := 0;

    C_CAP64_TYPE            : integer := 0;
    C_CAP64_VERSION         : integer := 0;
    C_CAP64_BASE            : integer := 0;
    C_CAP64_IRQ             : integer := 0;
    C_CAP64_SIZE            : integer := 0;
    C_CAP64_ID_ASSOCIATED   : integer := 0;
    C_CAP64_ID_COMPONENT    : integer := 0;
    C_CAP64_IRQ_ENABLE_EN   : integer := 0;
    C_CAP64_IRQ_STATUS_EN   : integer := 0;
    C_CAP64_IRQ_ENABLE      : integer := 0;
    C_CAP64_IRQ_STATUS      : integer := 0;

    C_CAP65_TYPE            : integer := 0;
    C_CAP65_VERSION         : integer := 0;
    C_CAP65_BASE            : integer := 0;
    C_CAP65_IRQ             : integer := 0;
    C_CAP65_SIZE            : integer := 0;
    C_CAP65_ID_ASSOCIATED   : integer := 0;
    C_CAP65_ID_COMPONENT    : integer := 0;
    C_CAP65_IRQ_ENABLE_EN   : integer := 0;
    C_CAP65_IRQ_STATUS_EN   : integer := 0;
    C_CAP65_IRQ_ENABLE      : integer := 0;
    C_CAP65_IRQ_STATUS      : integer := 0;

    C_CAP66_TYPE            : integer := 0;
    C_CAP66_VERSION         : integer := 0;
    C_CAP66_BASE            : integer := 0;
    C_CAP66_IRQ             : integer := 0;
    C_CAP66_SIZE            : integer := 0;
    C_CAP66_ID_ASSOCIATED   : integer := 0;
    C_CAP66_ID_COMPONENT    : integer := 0;
    C_CAP66_IRQ_ENABLE_EN   : integer := 0;
    C_CAP66_IRQ_STATUS_EN   : integer := 0;
    C_CAP66_IRQ_ENABLE      : integer := 0;
    C_CAP66_IRQ_STATUS      : integer := 0;

    C_CAP67_TYPE            : integer := 0;
    C_CAP67_VERSION         : integer := 0;
    C_CAP67_BASE            : integer := 0;
    C_CAP67_IRQ             : integer := 0;
    C_CAP67_SIZE            : integer := 0;
    C_CAP67_ID_ASSOCIATED   : integer := 0;
    C_CAP67_ID_COMPONENT    : integer := 0;
    C_CAP67_IRQ_ENABLE_EN   : integer := 0;
    C_CAP67_IRQ_STATUS_EN   : integer := 0;
    C_CAP67_IRQ_ENABLE      : integer := 0;
    C_CAP67_IRQ_STATUS      : integer := 0;

    C_CAP68_TYPE            : integer := 0;
    C_CAP68_VERSION         : integer := 0;
    C_CAP68_BASE            : integer := 0;
    C_CAP68_IRQ             : integer := 0;
    C_CAP68_SIZE            : integer := 0;
    C_CAP68_ID_ASSOCIATED   : integer := 0;
    C_CAP68_ID_COMPONENT    : integer := 0;
    C_CAP68_IRQ_ENABLE_EN   : integer := 0;
    C_CAP68_IRQ_STATUS_EN   : integer := 0;
    C_CAP68_IRQ_ENABLE      : integer := 0;
    C_CAP68_IRQ_STATUS      : integer := 0;

    C_CAP69_TYPE            : integer := 0;
    C_CAP69_VERSION         : integer := 0;
    C_CAP69_BASE            : integer := 0;
    C_CAP69_IRQ             : integer := 0;
    C_CAP69_SIZE            : integer := 0;
    C_CAP69_ID_ASSOCIATED   : integer := 0;
    C_CAP69_ID_COMPONENT    : integer := 0;
    C_CAP69_IRQ_ENABLE_EN   : integer := 0;
    C_CAP69_IRQ_STATUS_EN   : integer := 0;
    C_CAP69_IRQ_ENABLE      : integer := 0;
    C_CAP69_IRQ_STATUS      : integer := 0;

    C_CAP70_TYPE            : integer := 0;
    C_CAP70_VERSION         : integer := 0;
    C_CAP70_BASE            : integer := 0;
    C_CAP70_IRQ             : integer := 0;
    C_CAP70_SIZE            : integer := 0;
    C_CAP70_ID_ASSOCIATED   : integer := 0;
    C_CAP70_ID_COMPONENT    : integer := 0;
    C_CAP70_IRQ_ENABLE_EN   : integer := 0;
    C_CAP70_IRQ_STATUS_EN   : integer := 0;
    C_CAP70_IRQ_ENABLE      : integer := 0;
    C_CAP70_IRQ_STATUS      : integer := 0;

    C_CAP71_TYPE            : integer := 0;
    C_CAP71_VERSION         : integer := 0;
    C_CAP71_BASE            : integer := 0;
    C_CAP71_IRQ             : integer := 0;
    C_CAP71_SIZE            : integer := 0;
    C_CAP71_ID_ASSOCIATED   : integer := 0;
    C_CAP71_ID_COMPONENT    : integer := 0;
    C_CAP71_IRQ_ENABLE_EN   : integer := 0;
    C_CAP71_IRQ_STATUS_EN   : integer := 0;
    C_CAP71_IRQ_ENABLE      : integer := 0;
    C_CAP71_IRQ_STATUS      : integer := 0;

    C_CAP72_TYPE            : integer := 0;
    C_CAP72_VERSION         : integer := 0;
    C_CAP72_BASE            : integer := 0;
    C_CAP72_IRQ             : integer := 0;
    C_CAP72_SIZE            : integer := 0;
    C_CAP72_ID_ASSOCIATED   : integer := 0;
    C_CAP72_ID_COMPONENT    : integer := 0;
    C_CAP72_IRQ_ENABLE_EN   : integer := 0;
    C_CAP72_IRQ_STATUS_EN   : integer := 0;
    C_CAP72_IRQ_ENABLE      : integer := 0;
    C_CAP72_IRQ_STATUS      : integer := 0;

    C_CAP73_TYPE            : integer := 0;
    C_CAP73_VERSION         : integer := 0;
    C_CAP73_BASE            : integer := 0;
    C_CAP73_IRQ             : integer := 0;
    C_CAP73_SIZE            : integer := 0;
    C_CAP73_ID_ASSOCIATED   : integer := 0;
    C_CAP73_ID_COMPONENT    : integer := 0;
    C_CAP73_IRQ_ENABLE_EN   : integer := 0;
    C_CAP73_IRQ_STATUS_EN   : integer := 0;
    C_CAP73_IRQ_ENABLE      : integer := 0;
    C_CAP73_IRQ_STATUS      : integer := 0;

    C_CAP74_TYPE            : integer := 0;
    C_CAP74_VERSION         : integer := 0;
    C_CAP74_BASE            : integer := 0;
    C_CAP74_IRQ             : integer := 0;
    C_CAP74_SIZE            : integer := 0;
    C_CAP74_ID_ASSOCIATED   : integer := 0;
    C_CAP74_ID_COMPONENT    : integer := 0;
    C_CAP74_IRQ_ENABLE_EN   : integer := 0;
    C_CAP74_IRQ_STATUS_EN   : integer := 0;
    C_CAP74_IRQ_ENABLE      : integer := 0;
    C_CAP74_IRQ_STATUS      : integer := 0;

    C_CAP75_TYPE            : integer := 0;
    C_CAP75_VERSION         : integer := 0;
    C_CAP75_BASE            : integer := 0;
    C_CAP75_IRQ             : integer := 0;
    C_CAP75_SIZE            : integer := 0;
    C_CAP75_ID_ASSOCIATED   : integer := 0;
    C_CAP75_ID_COMPONENT    : integer := 0;
    C_CAP75_IRQ_ENABLE_EN   : integer := 0;
    C_CAP75_IRQ_STATUS_EN   : integer := 0;
    C_CAP75_IRQ_ENABLE      : integer := 0;
    C_CAP75_IRQ_STATUS      : integer := 0;

    C_CAP76_TYPE            : integer := 0;
    C_CAP76_VERSION         : integer := 0;
    C_CAP76_BASE            : integer := 0;
    C_CAP76_IRQ             : integer := 0;
    C_CAP76_SIZE            : integer := 0;
    C_CAP76_ID_ASSOCIATED   : integer := 0;
    C_CAP76_ID_COMPONENT    : integer := 0;
    C_CAP76_IRQ_ENABLE_EN   : integer := 0;
    C_CAP76_IRQ_STATUS_EN   : integer := 0;
    C_CAP76_IRQ_ENABLE      : integer := 0;
    C_CAP76_IRQ_STATUS      : integer := 0;

    C_CAP77_TYPE            : integer := 0;
    C_CAP77_VERSION         : integer := 0;
    C_CAP77_BASE            : integer := 0;
    C_CAP77_IRQ             : integer := 0;
    C_CAP77_SIZE            : integer := 0;
    C_CAP77_ID_ASSOCIATED   : integer := 0;
    C_CAP77_ID_COMPONENT    : integer := 0;
    C_CAP77_IRQ_ENABLE_EN   : integer := 0;
    C_CAP77_IRQ_STATUS_EN   : integer := 0;
    C_CAP77_IRQ_ENABLE      : integer := 0;
    C_CAP77_IRQ_STATUS      : integer := 0;

    C_CAP78_TYPE            : integer := 0;
    C_CAP78_VERSION         : integer := 0;
    C_CAP78_BASE            : integer := 0;
    C_CAP78_IRQ             : integer := 0;
    C_CAP78_SIZE            : integer := 0;
    C_CAP78_ID_ASSOCIATED   : integer := 0;
    C_CAP78_ID_COMPONENT    : integer := 0;
    C_CAP78_IRQ_ENABLE_EN   : integer := 0;
    C_CAP78_IRQ_STATUS_EN   : integer := 0;
    C_CAP78_IRQ_ENABLE      : integer := 0;
    C_CAP78_IRQ_STATUS      : integer := 0;

    C_CAP79_TYPE            : integer := 0;
    C_CAP79_VERSION         : integer := 0;
    C_CAP79_BASE            : integer := 0;
    C_CAP79_IRQ             : integer := 0;
    C_CAP79_SIZE            : integer := 0;
    C_CAP79_ID_ASSOCIATED   : integer := 0;
    C_CAP79_ID_COMPONENT    : integer := 0;
    C_CAP79_IRQ_ENABLE_EN   : integer := 0;
    C_CAP79_IRQ_STATUS_EN   : integer := 0;
    C_CAP79_IRQ_ENABLE      : integer := 0;
    C_CAP79_IRQ_STATUS      : integer := 0;

    C_CAP80_TYPE            : integer := 0;
    C_CAP80_VERSION         : integer := 0;
    C_CAP80_BASE            : integer := 0;
    C_CAP80_IRQ             : integer := 0;
    C_CAP80_SIZE            : integer := 0;
    C_CAP80_ID_ASSOCIATED   : integer := 0;
    C_CAP80_ID_COMPONENT    : integer := 0;
    C_CAP80_IRQ_ENABLE_EN   : integer := 0;
    C_CAP80_IRQ_STATUS_EN   : integer := 0;
    C_CAP80_IRQ_ENABLE      : integer := 0;
    C_CAP80_IRQ_STATUS      : integer := 0;

    C_CAP81_TYPE            : integer := 0;
    C_CAP81_VERSION         : integer := 0;
    C_CAP81_BASE            : integer := 0;
    C_CAP81_IRQ             : integer := 0;
    C_CAP81_SIZE            : integer := 0;
    C_CAP81_ID_ASSOCIATED   : integer := 0;
    C_CAP81_ID_COMPONENT    : integer := 0;
    C_CAP81_IRQ_ENABLE_EN   : integer := 0;
    C_CAP81_IRQ_STATUS_EN   : integer := 0;
    C_CAP81_IRQ_ENABLE      : integer := 0;
    C_CAP81_IRQ_STATUS      : integer := 0;

    C_CAP82_TYPE            : integer := 0;
    C_CAP82_VERSION         : integer := 0;
    C_CAP82_BASE            : integer := 0;
    C_CAP82_IRQ             : integer := 0;
    C_CAP82_SIZE            : integer := 0;
    C_CAP82_ID_ASSOCIATED   : integer := 0;
    C_CAP82_ID_COMPONENT    : integer := 0;
    C_CAP82_IRQ_ENABLE_EN   : integer := 0;
    C_CAP82_IRQ_STATUS_EN   : integer := 0;
    C_CAP82_IRQ_ENABLE      : integer := 0;
    C_CAP82_IRQ_STATUS      : integer := 0;

    C_CAP83_TYPE            : integer := 0;
    C_CAP83_VERSION         : integer := 0;
    C_CAP83_BASE            : integer := 0;
    C_CAP83_IRQ             : integer := 0;
    C_CAP83_SIZE            : integer := 0;
    C_CAP83_ID_ASSOCIATED   : integer := 0;
    C_CAP83_ID_COMPONENT    : integer := 0;
    C_CAP83_IRQ_ENABLE_EN   : integer := 0;
    C_CAP83_IRQ_STATUS_EN   : integer := 0;
    C_CAP83_IRQ_ENABLE      : integer := 0;
    C_CAP83_IRQ_STATUS      : integer := 0;

    C_CAP84_TYPE            : integer := 0;
    C_CAP84_VERSION         : integer := 0;
    C_CAP84_BASE            : integer := 0;
    C_CAP84_IRQ             : integer := 0;
    C_CAP84_SIZE            : integer := 0;
    C_CAP84_ID_ASSOCIATED   : integer := 0;
    C_CAP84_ID_COMPONENT    : integer := 0;
    C_CAP84_IRQ_ENABLE_EN   : integer := 0;
    C_CAP84_IRQ_STATUS_EN   : integer := 0;
    C_CAP84_IRQ_ENABLE      : integer := 0;
    C_CAP84_IRQ_STATUS      : integer := 0;

    C_CAP85_TYPE            : integer := 0;
    C_CAP85_VERSION         : integer := 0;
    C_CAP85_BASE            : integer := 0;
    C_CAP85_IRQ             : integer := 0;
    C_CAP85_SIZE            : integer := 0;
    C_CAP85_ID_ASSOCIATED   : integer := 0;
    C_CAP85_ID_COMPONENT    : integer := 0;
    C_CAP85_IRQ_ENABLE_EN   : integer := 0;
    C_CAP85_IRQ_STATUS_EN   : integer := 0;
    C_CAP85_IRQ_ENABLE      : integer := 0;
    C_CAP85_IRQ_STATUS      : integer := 0;

    C_CAP86_TYPE            : integer := 0;
    C_CAP86_VERSION         : integer := 0;
    C_CAP86_BASE            : integer := 0;
    C_CAP86_IRQ             : integer := 0;
    C_CAP86_SIZE            : integer := 0;
    C_CAP86_ID_ASSOCIATED   : integer := 0;
    C_CAP86_ID_COMPONENT    : integer := 0;
    C_CAP86_IRQ_ENABLE_EN   : integer := 0;
    C_CAP86_IRQ_STATUS_EN   : integer := 0;
    C_CAP86_IRQ_ENABLE      : integer := 0;
    C_CAP86_IRQ_STATUS      : integer := 0;

    C_CAP87_TYPE            : integer := 0;
    C_CAP87_VERSION         : integer := 0;
    C_CAP87_BASE            : integer := 0;
    C_CAP87_IRQ             : integer := 0;
    C_CAP87_SIZE            : integer := 0;
    C_CAP87_ID_ASSOCIATED   : integer := 0;
    C_CAP87_ID_COMPONENT    : integer := 0;
    C_CAP87_IRQ_ENABLE_EN   : integer := 0;
    C_CAP87_IRQ_STATUS_EN   : integer := 0;
    C_CAP87_IRQ_ENABLE      : integer := 0;
    C_CAP87_IRQ_STATUS      : integer := 0;

    C_CAP88_TYPE            : integer := 0;
    C_CAP88_VERSION         : integer := 0;
    C_CAP88_BASE            : integer := 0;
    C_CAP88_IRQ             : integer := 0;
    C_CAP88_SIZE            : integer := 0;
    C_CAP88_ID_ASSOCIATED   : integer := 0;
    C_CAP88_ID_COMPONENT    : integer := 0;
    C_CAP88_IRQ_ENABLE_EN   : integer := 0;
    C_CAP88_IRQ_STATUS_EN   : integer := 0;
    C_CAP88_IRQ_ENABLE      : integer := 0;
    C_CAP88_IRQ_STATUS      : integer := 0;

    C_CAP89_TYPE            : integer := 0;
    C_CAP89_VERSION         : integer := 0;
    C_CAP89_BASE            : integer := 0;
    C_CAP89_IRQ             : integer := 0;
    C_CAP89_SIZE            : integer := 0;
    C_CAP89_ID_ASSOCIATED   : integer := 0;
    C_CAP89_ID_COMPONENT    : integer := 0;
    C_CAP89_IRQ_ENABLE_EN   : integer := 0;
    C_CAP89_IRQ_STATUS_EN   : integer := 0;
    C_CAP89_IRQ_ENABLE      : integer := 0;
    C_CAP89_IRQ_STATUS      : integer := 0;

    C_CAP90_TYPE            : integer := 0;
    C_CAP90_VERSION         : integer := 0;
    C_CAP90_BASE            : integer := 0;
    C_CAP90_IRQ             : integer := 0;
    C_CAP90_SIZE            : integer := 0;
    C_CAP90_ID_ASSOCIATED   : integer := 0;
    C_CAP90_ID_COMPONENT    : integer := 0;
    C_CAP90_IRQ_ENABLE_EN   : integer := 0;
    C_CAP90_IRQ_STATUS_EN   : integer := 0;
    C_CAP90_IRQ_ENABLE      : integer := 0;
    C_CAP90_IRQ_STATUS      : integer := 0;

    C_CAP91_TYPE            : integer := 0;
    C_CAP91_VERSION         : integer := 0;
    C_CAP91_BASE            : integer := 0;
    C_CAP91_IRQ             : integer := 0;
    C_CAP91_SIZE            : integer := 0;
    C_CAP91_ID_ASSOCIATED   : integer := 0;
    C_CAP91_ID_COMPONENT    : integer := 0;
    C_CAP91_IRQ_ENABLE_EN   : integer := 0;
    C_CAP91_IRQ_STATUS_EN   : integer := 0;
    C_CAP91_IRQ_ENABLE      : integer := 0;
    C_CAP91_IRQ_STATUS      : integer := 0;

    C_CAP92_TYPE            : integer := 0;
    C_CAP92_VERSION         : integer := 0;
    C_CAP92_BASE            : integer := 0;
    C_CAP92_IRQ             : integer := 0;
    C_CAP92_SIZE            : integer := 0;
    C_CAP92_ID_ASSOCIATED   : integer := 0;
    C_CAP92_ID_COMPONENT    : integer := 0;
    C_CAP92_IRQ_ENABLE_EN   : integer := 0;
    C_CAP92_IRQ_STATUS_EN   : integer := 0;
    C_CAP92_IRQ_ENABLE      : integer := 0;
    C_CAP92_IRQ_STATUS      : integer := 0;

    C_CAP93_TYPE            : integer := 0;
    C_CAP93_VERSION         : integer := 0;
    C_CAP93_BASE            : integer := 0;
    C_CAP93_IRQ             : integer := 0;
    C_CAP93_SIZE            : integer := 0;
    C_CAP93_ID_ASSOCIATED   : integer := 0;
    C_CAP93_ID_COMPONENT    : integer := 0;
    C_CAP93_IRQ_ENABLE_EN   : integer := 0;
    C_CAP93_IRQ_STATUS_EN   : integer := 0;
    C_CAP93_IRQ_ENABLE      : integer := 0;
    C_CAP93_IRQ_STATUS      : integer := 0;

    C_CAP94_TYPE            : integer := 0;
    C_CAP94_VERSION         : integer := 0;
    C_CAP94_BASE            : integer := 0;
    C_CAP94_IRQ             : integer := 0;
    C_CAP94_SIZE            : integer := 0;
    C_CAP94_ID_ASSOCIATED   : integer := 0;
    C_CAP94_ID_COMPONENT    : integer := 0;
    C_CAP94_IRQ_ENABLE_EN   : integer := 0;
    C_CAP94_IRQ_STATUS_EN   : integer := 0;
    C_CAP94_IRQ_ENABLE      : integer := 0;
    C_CAP94_IRQ_STATUS      : integer := 0;

    C_CAP95_TYPE            : integer := 0;
    C_CAP95_VERSION         : integer := 0;
    C_CAP95_BASE            : integer := 0;
    C_CAP95_IRQ             : integer := 0;
    C_CAP95_SIZE            : integer := 0;
    C_CAP95_ID_ASSOCIATED   : integer := 0;
    C_CAP95_ID_COMPONENT    : integer := 0;
    C_CAP95_IRQ_ENABLE_EN   : integer := 0;
    C_CAP95_IRQ_STATUS_EN   : integer := 0;
    C_CAP95_IRQ_ENABLE      : integer := 0;
    C_CAP95_IRQ_STATUS      : integer := 0;

    C_CAP96_TYPE            : integer := 0;
    C_CAP96_VERSION         : integer := 0;
    C_CAP96_BASE            : integer := 0;
    C_CAP96_IRQ             : integer := 0;
    C_CAP96_SIZE            : integer := 0;
    C_CAP96_ID_ASSOCIATED   : integer := 0;
    C_CAP96_ID_COMPONENT    : integer := 0;
    C_CAP96_IRQ_ENABLE_EN   : integer := 0;
    C_CAP96_IRQ_STATUS_EN   : integer := 0;
    C_CAP96_IRQ_ENABLE      : integer := 0;
    C_CAP96_IRQ_STATUS      : integer := 0;

    C_CAP97_TYPE            : integer := 0;
    C_CAP97_VERSION         : integer := 0;
    C_CAP97_BASE            : integer := 0;
    C_CAP97_IRQ             : integer := 0;
    C_CAP97_SIZE            : integer := 0;
    C_CAP97_ID_ASSOCIATED   : integer := 0;
    C_CAP97_ID_COMPONENT    : integer := 0;
    C_CAP97_IRQ_ENABLE_EN   : integer := 0;
    C_CAP97_IRQ_STATUS_EN   : integer := 0;
    C_CAP97_IRQ_ENABLE      : integer := 0;
    C_CAP97_IRQ_STATUS      : integer := 0;

    C_CAP98_TYPE            : integer := 0;
    C_CAP98_VERSION         : integer := 0;
    C_CAP98_BASE            : integer := 0;
    C_CAP98_IRQ             : integer := 0;
    C_CAP98_SIZE            : integer := 0;
    C_CAP98_ID_ASSOCIATED   : integer := 0;
    C_CAP98_ID_COMPONENT    : integer := 0;
    C_CAP98_IRQ_ENABLE_EN   : integer := 0;
    C_CAP98_IRQ_STATUS_EN   : integer := 0;
    C_CAP98_IRQ_ENABLE      : integer := 0;
    C_CAP98_IRQ_STATUS      : integer := 0;

    C_CAP99_TYPE            : integer := 0;
    C_CAP99_VERSION         : integer := 0;
    C_CAP99_BASE            : integer := 0;
    C_CAP99_IRQ             : integer := 0;
    C_CAP99_SIZE            : integer := 0;
    C_CAP99_ID_ASSOCIATED   : integer := 0;
    C_CAP99_ID_COMPONENT    : integer := 0;
    C_CAP99_IRQ_ENABLE_EN   : integer := 0;
    C_CAP99_IRQ_STATUS_EN   : integer := 0;
    C_CAP99_IRQ_ENABLE      : integer := 0;
    C_CAP99_IRQ_STATUS      : integer := 0;

    C_CAP100_TYPE            : integer := 0;
    C_CAP100_VERSION         : integer := 0;
    C_CAP100_BASE            : integer := 0;
    C_CAP100_IRQ             : integer := 0;
    C_CAP100_SIZE            : integer := 0;
    C_CAP100_ID_ASSOCIATED   : integer := 0;
    C_CAP100_ID_COMPONENT    : integer := 0;
    C_CAP100_IRQ_ENABLE_EN   : integer := 0;
    C_CAP100_IRQ_STATUS_EN   : integer := 0;
    C_CAP100_IRQ_ENABLE      : integer := 0;
    C_CAP100_IRQ_STATUS      : integer := 0;

    C_CAP101_TYPE            : integer := 0;
    C_CAP101_VERSION         : integer := 0;
    C_CAP101_BASE            : integer := 0;
    C_CAP101_IRQ             : integer := 0;
    C_CAP101_SIZE            : integer := 0;
    C_CAP101_ID_ASSOCIATED   : integer := 0;
    C_CAP101_ID_COMPONENT    : integer := 0;
    C_CAP101_IRQ_ENABLE_EN   : integer := 0;
    C_CAP101_IRQ_STATUS_EN   : integer := 0;
    C_CAP101_IRQ_ENABLE      : integer := 0;
    C_CAP101_IRQ_STATUS      : integer := 0;

    C_CAP102_TYPE            : integer := 0;
    C_CAP102_VERSION         : integer := 0;
    C_CAP102_BASE            : integer := 0;
    C_CAP102_IRQ             : integer := 0;
    C_CAP102_SIZE            : integer := 0;
    C_CAP102_ID_ASSOCIATED   : integer := 0;
    C_CAP102_ID_COMPONENT    : integer := 0;
    C_CAP102_IRQ_ENABLE_EN   : integer := 0;
    C_CAP102_IRQ_STATUS_EN   : integer := 0;
    C_CAP102_IRQ_ENABLE      : integer := 0;
    C_CAP102_IRQ_STATUS      : integer := 0;

    C_CAP103_TYPE            : integer := 0;
    C_CAP103_VERSION         : integer := 0;
    C_CAP103_BASE            : integer := 0;
    C_CAP103_IRQ             : integer := 0;
    C_CAP103_SIZE            : integer := 0;
    C_CAP103_ID_ASSOCIATED   : integer := 0;
    C_CAP103_ID_COMPONENT    : integer := 0;
    C_CAP103_IRQ_ENABLE_EN   : integer := 0;
    C_CAP103_IRQ_STATUS_EN   : integer := 0;
    C_CAP103_IRQ_ENABLE      : integer := 0;
    C_CAP103_IRQ_STATUS      : integer := 0;

    C_CAP104_TYPE            : integer := 0;
    C_CAP104_VERSION         : integer := 0;
    C_CAP104_BASE            : integer := 0;
    C_CAP104_IRQ             : integer := 0;
    C_CAP104_SIZE            : integer := 0;
    C_CAP104_ID_ASSOCIATED   : integer := 0;
    C_CAP104_ID_COMPONENT    : integer := 0;
    C_CAP104_IRQ_ENABLE_EN   : integer := 0;
    C_CAP104_IRQ_STATUS_EN   : integer := 0;
    C_CAP104_IRQ_ENABLE      : integer := 0;
    C_CAP104_IRQ_STATUS      : integer := 0;

    C_CAP105_TYPE            : integer := 0;
    C_CAP105_VERSION         : integer := 0;
    C_CAP105_BASE            : integer := 0;
    C_CAP105_IRQ             : integer := 0;
    C_CAP105_SIZE            : integer := 0;
    C_CAP105_ID_ASSOCIATED   : integer := 0;
    C_CAP105_ID_COMPONENT    : integer := 0;
    C_CAP105_IRQ_ENABLE_EN   : integer := 0;
    C_CAP105_IRQ_STATUS_EN   : integer := 0;
    C_CAP105_IRQ_ENABLE      : integer := 0;
    C_CAP105_IRQ_STATUS      : integer := 0;

    C_CAP106_TYPE            : integer := 0;
    C_CAP106_VERSION         : integer := 0;
    C_CAP106_BASE            : integer := 0;
    C_CAP106_IRQ             : integer := 0;
    C_CAP106_SIZE            : integer := 0;
    C_CAP106_ID_ASSOCIATED   : integer := 0;
    C_CAP106_ID_COMPONENT    : integer := 0;
    C_CAP106_IRQ_ENABLE_EN   : integer := 0;
    C_CAP106_IRQ_STATUS_EN   : integer := 0;
    C_CAP106_IRQ_ENABLE      : integer := 0;
    C_CAP106_IRQ_STATUS      : integer := 0;

    C_CAP107_TYPE            : integer := 0;
    C_CAP107_VERSION         : integer := 0;
    C_CAP107_BASE            : integer := 0;
    C_CAP107_IRQ             : integer := 0;
    C_CAP107_SIZE            : integer := 0;
    C_CAP107_ID_ASSOCIATED   : integer := 0;
    C_CAP107_ID_COMPONENT    : integer := 0;
    C_CAP107_IRQ_ENABLE_EN   : integer := 0;
    C_CAP107_IRQ_STATUS_EN   : integer := 0;
    C_CAP107_IRQ_ENABLE      : integer := 0;
    C_CAP107_IRQ_STATUS      : integer := 0;

    C_CAP108_TYPE            : integer := 0;
    C_CAP108_VERSION         : integer := 0;
    C_CAP108_BASE            : integer := 0;
    C_CAP108_IRQ             : integer := 0;
    C_CAP108_SIZE            : integer := 0;
    C_CAP108_ID_ASSOCIATED   : integer := 0;
    C_CAP108_ID_COMPONENT    : integer := 0;
    C_CAP108_IRQ_ENABLE_EN   : integer := 0;
    C_CAP108_IRQ_STATUS_EN   : integer := 0;
    C_CAP108_IRQ_ENABLE      : integer := 0;
    C_CAP108_IRQ_STATUS      : integer := 0;

    C_CAP109_TYPE            : integer := 0;
    C_CAP109_VERSION         : integer := 0;
    C_CAP109_BASE            : integer := 0;
    C_CAP109_IRQ             : integer := 0;
    C_CAP109_SIZE            : integer := 0;
    C_CAP109_ID_ASSOCIATED   : integer := 0;
    C_CAP109_ID_COMPONENT    : integer := 0;
    C_CAP109_IRQ_ENABLE_EN   : integer := 0;
    C_CAP109_IRQ_STATUS_EN   : integer := 0;
    C_CAP109_IRQ_ENABLE      : integer := 0;
    C_CAP109_IRQ_STATUS      : integer := 0;

    C_CAP110_TYPE            : integer := 0;
    C_CAP110_VERSION         : integer := 0;
    C_CAP110_BASE            : integer := 0;
    C_CAP110_IRQ             : integer := 0;
    C_CAP110_SIZE            : integer := 0;
    C_CAP110_ID_ASSOCIATED   : integer := 0;
    C_CAP110_ID_COMPONENT    : integer := 0;
    C_CAP110_IRQ_ENABLE_EN   : integer := 0;
    C_CAP110_IRQ_STATUS_EN   : integer := 0;
    C_CAP110_IRQ_ENABLE      : integer := 0;
    C_CAP110_IRQ_STATUS      : integer := 0;

    C_CAP111_TYPE            : integer := 0;
    C_CAP111_VERSION         : integer := 0;
    C_CAP111_BASE            : integer := 0;
    C_CAP111_IRQ             : integer := 0;
    C_CAP111_SIZE            : integer := 0;
    C_CAP111_ID_ASSOCIATED   : integer := 0;
    C_CAP111_ID_COMPONENT    : integer := 0;
    C_CAP111_IRQ_ENABLE_EN   : integer := 0;
    C_CAP111_IRQ_STATUS_EN   : integer := 0;
    C_CAP111_IRQ_ENABLE      : integer := 0;
    C_CAP111_IRQ_STATUS      : integer := 0;

    C_CAP112_TYPE            : integer := 0;
    C_CAP112_VERSION         : integer := 0;
    C_CAP112_BASE            : integer := 0;
    C_CAP112_IRQ             : integer := 0;
    C_CAP112_SIZE            : integer := 0;
    C_CAP112_ID_ASSOCIATED   : integer := 0;
    C_CAP112_ID_COMPONENT    : integer := 0;
    C_CAP112_IRQ_ENABLE_EN   : integer := 0;
    C_CAP112_IRQ_STATUS_EN   : integer := 0;
    C_CAP112_IRQ_ENABLE      : integer := 0;
    C_CAP112_IRQ_STATUS      : integer := 0;

    C_CAP113_TYPE            : integer := 0;
    C_CAP113_VERSION         : integer := 0;
    C_CAP113_BASE            : integer := 0;
    C_CAP113_IRQ             : integer := 0;
    C_CAP113_SIZE            : integer := 0;
    C_CAP113_ID_ASSOCIATED   : integer := 0;
    C_CAP113_ID_COMPONENT    : integer := 0;
    C_CAP113_IRQ_ENABLE_EN   : integer := 0;
    C_CAP113_IRQ_STATUS_EN   : integer := 0;
    C_CAP113_IRQ_ENABLE      : integer := 0;
    C_CAP113_IRQ_STATUS      : integer := 0;

    C_CAP114_TYPE            : integer := 0;
    C_CAP114_VERSION         : integer := 0;
    C_CAP114_BASE            : integer := 0;
    C_CAP114_IRQ             : integer := 0;
    C_CAP114_SIZE            : integer := 0;
    C_CAP114_ID_ASSOCIATED   : integer := 0;
    C_CAP114_ID_COMPONENT    : integer := 0;
    C_CAP114_IRQ_ENABLE_EN   : integer := 0;
    C_CAP114_IRQ_STATUS_EN   : integer := 0;
    C_CAP114_IRQ_ENABLE      : integer := 0;
    C_CAP114_IRQ_STATUS      : integer := 0;

    C_CAP115_TYPE            : integer := 0;
    C_CAP115_VERSION         : integer := 0;
    C_CAP115_BASE            : integer := 0;
    C_CAP115_IRQ             : integer := 0;
    C_CAP115_SIZE            : integer := 0;
    C_CAP115_ID_ASSOCIATED   : integer := 0;
    C_CAP115_ID_COMPONENT    : integer := 0;
    C_CAP115_IRQ_ENABLE_EN   : integer := 0;
    C_CAP115_IRQ_STATUS_EN   : integer := 0;
    C_CAP115_IRQ_ENABLE      : integer := 0;
    C_CAP115_IRQ_STATUS      : integer := 0;

    C_CAP116_TYPE            : integer := 0;
    C_CAP116_VERSION         : integer := 0;
    C_CAP116_BASE            : integer := 0;
    C_CAP116_IRQ             : integer := 0;
    C_CAP116_SIZE            : integer := 0;
    C_CAP116_ID_ASSOCIATED   : integer := 0;
    C_CAP116_ID_COMPONENT    : integer := 0;
    C_CAP116_IRQ_ENABLE_EN   : integer := 0;
    C_CAP116_IRQ_STATUS_EN   : integer := 0;
    C_CAP116_IRQ_ENABLE      : integer := 0;
    C_CAP116_IRQ_STATUS      : integer := 0;

    C_CAP117_TYPE            : integer := 0;
    C_CAP117_VERSION         : integer := 0;
    C_CAP117_BASE            : integer := 0;
    C_CAP117_IRQ             : integer := 0;
    C_CAP117_SIZE            : integer := 0;
    C_CAP117_ID_ASSOCIATED   : integer := 0;
    C_CAP117_ID_COMPONENT    : integer := 0;
    C_CAP117_IRQ_ENABLE_EN   : integer := 0;
    C_CAP117_IRQ_STATUS_EN   : integer := 0;
    C_CAP117_IRQ_ENABLE      : integer := 0;
    C_CAP117_IRQ_STATUS      : integer := 0;

    C_CAP118_TYPE            : integer := 0;
    C_CAP118_VERSION         : integer := 0;
    C_CAP118_BASE            : integer := 0;
    C_CAP118_IRQ             : integer := 0;
    C_CAP118_SIZE            : integer := 0;
    C_CAP118_ID_ASSOCIATED   : integer := 0;
    C_CAP118_ID_COMPONENT    : integer := 0;
    C_CAP118_IRQ_ENABLE_EN   : integer := 0;
    C_CAP118_IRQ_STATUS_EN   : integer := 0;
    C_CAP118_IRQ_ENABLE      : integer := 0;
    C_CAP118_IRQ_STATUS      : integer := 0;

    C_CAP119_TYPE            : integer := 0;
    C_CAP119_VERSION         : integer := 0;
    C_CAP119_BASE            : integer := 0;
    C_CAP119_IRQ             : integer := 0;
    C_CAP119_SIZE            : integer := 0;
    C_CAP119_ID_ASSOCIATED   : integer := 0;
    C_CAP119_ID_COMPONENT    : integer := 0;
    C_CAP119_IRQ_ENABLE_EN   : integer := 0;
    C_CAP119_IRQ_STATUS_EN   : integer := 0;
    C_CAP119_IRQ_ENABLE      : integer := 0;
    C_CAP119_IRQ_STATUS      : integer := 0;

    C_CAP120_TYPE            : integer := 0;
    C_CAP120_VERSION         : integer := 0;
    C_CAP120_BASE            : integer := 0;
    C_CAP120_IRQ             : integer := 0;
    C_CAP120_SIZE            : integer := 0;
    C_CAP120_ID_ASSOCIATED   : integer := 0;
    C_CAP120_ID_COMPONENT    : integer := 0;
    C_CAP120_IRQ_ENABLE_EN   : integer := 0;
    C_CAP120_IRQ_STATUS_EN   : integer := 0;
    C_CAP120_IRQ_ENABLE      : integer := 0;
    C_CAP120_IRQ_STATUS      : integer := 0;

    C_CAP121_TYPE            : integer := 0;
    C_CAP121_VERSION         : integer := 0;
    C_CAP121_BASE            : integer := 0;
    C_CAP121_IRQ             : integer := 0;
    C_CAP121_SIZE            : integer := 0;
    C_CAP121_ID_ASSOCIATED   : integer := 0;
    C_CAP121_ID_COMPONENT    : integer := 0;
    C_CAP121_IRQ_ENABLE_EN   : integer := 0;
    C_CAP121_IRQ_STATUS_EN   : integer := 0;
    C_CAP121_IRQ_ENABLE      : integer := 0;
    C_CAP121_IRQ_STATUS      : integer := 0;

    C_CAP122_TYPE            : integer := 0;
    C_CAP122_VERSION         : integer := 0;
    C_CAP122_BASE            : integer := 0;
    C_CAP122_IRQ             : integer := 0;
    C_CAP122_SIZE            : integer := 0;
    C_CAP122_ID_ASSOCIATED   : integer := 0;
    C_CAP122_ID_COMPONENT    : integer := 0;
    C_CAP122_IRQ_ENABLE_EN   : integer := 0;
    C_CAP122_IRQ_STATUS_EN   : integer := 0;
    C_CAP122_IRQ_ENABLE      : integer := 0;
    C_CAP122_IRQ_STATUS      : integer := 0;

    C_CAP123_TYPE            : integer := 0;
    C_CAP123_VERSION         : integer := 0;
    C_CAP123_BASE            : integer := 0;
    C_CAP123_IRQ             : integer := 0;
    C_CAP123_SIZE            : integer := 0;
    C_CAP123_ID_ASSOCIATED   : integer := 0;
    C_CAP123_ID_COMPONENT    : integer := 0;
    C_CAP123_IRQ_ENABLE_EN   : integer := 0;
    C_CAP123_IRQ_STATUS_EN   : integer := 0;
    C_CAP123_IRQ_ENABLE      : integer := 0;
    C_CAP123_IRQ_STATUS      : integer := 0;

    C_CAP124_TYPE            : integer := 0;
    C_CAP124_VERSION         : integer := 0;
    C_CAP124_BASE            : integer := 0;
    C_CAP124_IRQ             : integer := 0;
    C_CAP124_SIZE            : integer := 0;
    C_CAP124_ID_ASSOCIATED   : integer := 0;
    C_CAP124_ID_COMPONENT    : integer := 0;
    C_CAP124_IRQ_ENABLE_EN   : integer := 0;
    C_CAP124_IRQ_STATUS_EN   : integer := 0;
    C_CAP124_IRQ_ENABLE      : integer := 0;
    C_CAP124_IRQ_STATUS      : integer := 0;

    C_CAP125_TYPE            : integer := 0;
    C_CAP125_VERSION         : integer := 0;
    C_CAP125_BASE            : integer := 0;
    C_CAP125_IRQ             : integer := 0;
    C_CAP125_SIZE            : integer := 0;
    C_CAP125_ID_ASSOCIATED   : integer := 0;
    C_CAP125_ID_COMPONENT    : integer := 0;
    C_CAP125_IRQ_ENABLE_EN   : integer := 0;
    C_CAP125_IRQ_STATUS_EN   : integer := 0;
    C_CAP125_IRQ_ENABLE      : integer := 0;
    C_CAP125_IRQ_STATUS      : integer := 0;

    C_CAP126_TYPE            : integer := 0;
    C_CAP126_VERSION         : integer := 0;
    C_CAP126_BASE            : integer := 0;
    C_CAP126_IRQ             : integer := 0;
    C_CAP126_SIZE            : integer := 0;
    C_CAP126_ID_ASSOCIATED   : integer := 0;
    C_CAP126_ID_COMPONENT    : integer := 0;
    C_CAP126_IRQ_ENABLE_EN   : integer := 0;
    C_CAP126_IRQ_STATUS_EN   : integer := 0;
    C_CAP126_IRQ_ENABLE      : integer := 0;
    C_CAP126_IRQ_STATUS      : integer := 0;

    C_CAP127_TYPE            : integer := 0;
    C_CAP127_VERSION         : integer := 0;
    C_CAP127_BASE            : integer := 0;
    C_CAP127_IRQ             : integer := 0;
    C_CAP127_SIZE            : integer := 0;
    C_CAP127_ID_ASSOCIATED   : integer := 0;
    C_CAP127_ID_COMPONENT    : integer := 0;
    C_CAP127_IRQ_ENABLE_EN   : integer := 0;
    C_CAP127_IRQ_STATUS_EN   : integer := 0;
    C_CAP127_IRQ_ENABLE      : integer := 0;
    C_CAP127_IRQ_STATUS      : integer := 0;

    C_NUM_CAPS             : integer := 0

  );
  port (
    s_avlmm_clk                : in  std_logic;
    s_avlmm_reset              : in  std_logic;

    s_avlmm_base_addr          : in  std_logic_vector(10 downto 0);
    s_avlmm_burstcount         : in  std_logic_vector(7 downto 0);
    s_avlmm_waitrequest        : out std_logic;

    s_avlmm_byteenable         : in  std_logic_vector(3 downto 0);
    s_avlmm_write              : in  std_logic;
    s_avlmm_writedata          : in  std_logic_vector(31 downto 0);
    s_avlmm_read               : in  std_logic;
    s_avlmm_readdatavalid      : out std_logic;
    s_avlmm_readdata           : out std_logic_vector(31 downto 0)

);
end intel_offset_capability;

architecture struct of intel_offset_capability is

signal current_direction              : std_logic;
signal registered_address             : std_logic_vector(10 DOWNTO 0);
signal current_address                : std_logic_vector(10 DOWNTO 0);
signal transactions_remaining         : std_logic_vector(7 DOWNTO 0) := (others => '0');
signal s_avlmm_base_addr_d1           : std_logic_vector(10 downto 0);
signal s_avlmm_byteenable_d1          : std_logic_vector(3 downto 0);
signal s_avlmm_write_d1               : std_logic;
signal s_avlmm_writedata_d1           : std_logic_vector(31 downto 0);
signal s_avlmm_read_d1                : std_logic;

type t_cap is record
    c_type           : std_logic_vector(15 downto 0);
    c_version        : std_logic_vector(7 downto 0);
    c_irq            : std_logic_vector(7 downto 0);
    c_id_associated  : std_logic_vector(15 downto 0);
    c_id_component   : std_logic_vector(15 downto 0);
    c_irq_enable_en  : std_logic;
    c_irq_status_en  : std_logic;
    c_irq_enable     : std_logic_vector(14 downto 0);
    c_irq_status     : std_logic_vector(14 downto 0);
    c_size           : std_logic_vector(23 downto 0);
    c_next           : std_logic_vector(31 downto 0);
    c_base           : std_logic_vector(31 downto 0);
end record;

type t_caps is array(0 to 127) of t_cap;

signal caps : t_caps;
signal cap  : t_cap;

begin

  g_axi : if C_IS_NATIVE = 0 generate

  begin

    -----------------------------------------------------------------------------
    -- burst controller
    -----------------------------------------------------------------------------
    process(s_avlmm_clk)
    begin
      if rising_edge(s_avlmm_clk) then
        if transactions_remaining = 0 then
          if s_avlmm_read = '1' then
            current_direction <= '1';
          else
            current_direction <= '0';
          end if;
        end if;
      end if;
    end process;

    process(s_avlmm_clk)
    begin
      if rising_edge(s_avlmm_clk) then
        if conv_integer(unsigned(transactions_remaining)) = 0 then
          registered_address <= s_avlmm_base_addr + 1;
        elsif (current_direction = '1' or s_avlmm_write = '1') and conv_integer(unsigned(transactions_remaining)) /= 0 then
          registered_address <= registered_address + 1;
        end if;
      end if;
    end process;

    current_address <= s_avlmm_base_addr when conv_integer(unsigned(transactions_remaining)) = 0 else registered_address;

    process(s_avlmm_clk, s_avlmm_reset)
    begin
      if s_avlmm_reset = '1' then
        transactions_remaining <= (others => '0');
      elsif rising_edge(s_avlmm_clk) then
        if s_avlmm_read = '1' or (s_avlmm_write = '1' and conv_integer(unsigned(transactions_remaining)) = 0) then
          transactions_remaining <= s_avlmm_burstcount - 1;
        elsif (current_direction = '1' or s_avlmm_write = '1') and conv_integer(unsigned(transactions_remaining)) /= 0 then
          transactions_remaining <= transactions_remaining - 1;
        end if;
      end if;
    end process;

    s_avlmm_waitrequest <= '1' when current_direction = '1' and conv_integer(unsigned(transactions_remaining)) /= 0 else '0';

    -----------------------------------------------------------------------------
    -- register the write data for timing reasons
    -----------------------------------------------------------------------------
    process(s_avlmm_clk)
    begin
      if rising_edge(s_avlmm_clk) then
        s_avlmm_base_addr_d1 <= current_address;
        s_avlmm_byteenable_d1 <= s_avlmm_byteenable;
        s_avlmm_write_d1 <= s_avlmm_write;
        s_avlmm_writedata_d1 <= s_avlmm_writedata;
        if current_direction = '1' and transactions_remaining /= 0 THEN
          s_avlmm_read_d1 <= '1';
        else
          s_avlmm_read_d1 <= s_avlmm_read;
        end if;
      end if;
    end process;

  end generate g_axi;

  cap <= caps(conv_integer(s_avlmm_base_addr_d1((7-1)+4 downto 4)));

  process(s_avlmm_clk)
  begin
    if rising_edge(s_avlmm_clk) then
      s_avlmm_readdatavalid <= s_avlmm_read_d1;
            
      case s_avlmm_base_addr_d1(3 downto 0) is
        when "0000" =>
          s_avlmm_readdata <= X"09" & X"00" & X"02" & X"FD";
        when "0001" => -- Low 32 bits of address
          s_avlmm_readdata <= cap.c_next - conv_std_logic_vector(C_BASE,32);
        when "0010" => -- Hi 32 Bits of address
          s_avlmm_readdata <= X"00000000";
        when "0011" =>
          s_avlmm_readdata(31 downto 16) <= cap.c_type;
          s_avlmm_readdata(15 downto 8)  <= cap.c_version;
          s_avlmm_readdata(7 downto 0)   <= cap.c_irq;
        when "0100" =>
          s_avlmm_readdata(31 downto 16) <= cap.c_id_associated;
          s_avlmm_readdata(15 downto 0)  <= cap.c_id_component;
        when "0101" =>
          s_avlmm_readdata(31)           <= cap.c_irq_status_en;
          s_avlmm_readdata(30 downto 16) <= cap.c_irq_status;
          s_avlmm_readdata(15)           <= cap.c_irq_enable_en;
          s_avlmm_readdata(14 downto 0)  <= cap.c_irq_enable;
        when "0110" =>
          s_avlmm_readdata(31 downto 24) <= X"01";
          s_avlmm_readdata(23 downto 0)  <= cap.c_size;
        when "0111" =>
          s_avlmm_readdata(31 downto 0)  <= cap.c_base - conv_std_logic_vector(C_BASE,32);
        when "1000" => -- Hi 32 Bits of address
          s_avlmm_readdata <= X"00000000";
        when others => 
          s_avlmm_readdata <= (others => '0');
      end case;
    end if;
  end process;

  ---------------------------------------------------------------------------------
  -- Constants for Capability 0
  caps(0).c_type          <= conv_std_logic_vector(C_CAP0_TYPE,16);
  caps(0).c_version       <= conv_std_logic_vector(C_CAP0_VERSION,8);
  caps(0).c_irq           <= conv_std_logic_vector(C_CAP0_IRQ,8);
  caps(0).c_id_associated <= conv_std_logic_vector(C_CAP0_ID_ASSOCIATED,16);
  caps(0).c_id_component  <= conv_std_logic_vector(C_CAP0_ID_COMPONENT,16);
  caps(0).c_irq_enable_en <= '0' when C_CAP0_IRQ_ENABLE_EN = 0 else '1';
  caps(0).c_irq_status_en <= '0' when C_CAP0_IRQ_STATUS_EN = 0 else '1';
  caps(0).c_irq_enable    <= (others => '0') when C_CAP0_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP0_IRQ_ENABLE,15);
  caps(0).c_irq_status    <= (others => '0') when C_CAP0_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP0_IRQ_STATUS,15);
  caps(0).c_base          <= conv_std_logic_vector(C_CAP0_BASE,32);
  caps(0).c_size          <= conv_std_logic_vector(C_CAP0_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(0).c_next          <= C_BASEADDR + conv_std_logic_vector((0+1)*64,16) when 0 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 1
  caps(1).c_type          <= conv_std_logic_vector(C_CAP1_TYPE,16);
  caps(1).c_version       <= conv_std_logic_vector(C_CAP1_VERSION,8);
  caps(1).c_irq           <= conv_std_logic_vector(C_CAP1_IRQ,8);
  caps(1).c_id_associated <= conv_std_logic_vector(C_CAP1_ID_ASSOCIATED,16);
  caps(1).c_id_component  <= conv_std_logic_vector(C_CAP1_ID_COMPONENT,16);
  caps(1).c_irq_enable_en <= '0' when C_CAP1_IRQ_ENABLE_EN = 0 else '1';
  caps(1).c_irq_status_en <= '0' when C_CAP1_IRQ_STATUS_EN = 0 else '1';
  caps(1).c_irq_enable    <= (others => '0') when C_CAP1_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP1_IRQ_ENABLE,15);
  caps(1).c_irq_status    <= (others => '0') when C_CAP1_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP1_IRQ_STATUS,15);
  caps(1).c_base          <= conv_std_logic_vector(C_CAP1_BASE,32);
  caps(1).c_size          <= conv_std_logic_vector(C_CAP1_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(1).c_next          <= C_BASEADDR + conv_std_logic_vector((1+1)*64,16) when 1 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 2
  caps(2).c_type          <= conv_std_logic_vector(C_CAP2_TYPE,16);
  caps(2).c_version       <= conv_std_logic_vector(C_CAP2_VERSION,8);
  caps(2).c_irq           <= conv_std_logic_vector(C_CAP2_IRQ,8);
  caps(2).c_id_associated <= conv_std_logic_vector(C_CAP2_ID_ASSOCIATED,16);
  caps(2).c_id_component  <= conv_std_logic_vector(C_CAP2_ID_COMPONENT,16);
  caps(2).c_irq_enable_en <= '0' when C_CAP2_IRQ_ENABLE_EN = 0 else '1';
  caps(2).c_irq_status_en <= '0' when C_CAP2_IRQ_STATUS_EN = 0 else '1';
  caps(2).c_irq_enable    <= (others => '0') when C_CAP2_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP2_IRQ_ENABLE,15);
  caps(2).c_irq_status    <= (others => '0') when C_CAP2_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP2_IRQ_STATUS,15);
  caps(2).c_base          <= conv_std_logic_vector(C_CAP2_BASE,32);
  caps(2).c_size          <= conv_std_logic_vector(C_CAP2_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(2).c_next          <= C_BASEADDR + conv_std_logic_vector((2+1)*64,16) when 2 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 3
  caps(3).c_type          <= conv_std_logic_vector(C_CAP3_TYPE,16);
  caps(3).c_version       <= conv_std_logic_vector(C_CAP3_VERSION,8);
  caps(3).c_irq           <= conv_std_logic_vector(C_CAP3_IRQ,8);
  caps(3).c_id_associated <= conv_std_logic_vector(C_CAP3_ID_ASSOCIATED,16);
  caps(3).c_id_component  <= conv_std_logic_vector(C_CAP3_ID_COMPONENT,16);
  caps(3).c_irq_enable_en <= '0' when C_CAP3_IRQ_ENABLE_EN = 0 else '1';
  caps(3).c_irq_status_en <= '0' when C_CAP3_IRQ_STATUS_EN = 0 else '1';
  caps(3).c_irq_enable    <= (others => '0') when C_CAP3_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP3_IRQ_ENABLE,15);
  caps(3).c_irq_status    <= (others => '0') when C_CAP3_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP3_IRQ_STATUS,15);
  caps(3).c_base          <= conv_std_logic_vector(C_CAP3_BASE,32);
  caps(3).c_size          <= conv_std_logic_vector(C_CAP3_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(3).c_next          <= C_BASEADDR + conv_std_logic_vector((3+1)*64,16) when 3 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 4
  caps(4).c_type          <= conv_std_logic_vector(C_CAP4_TYPE,16);
  caps(4).c_version       <= conv_std_logic_vector(C_CAP4_VERSION,8);
  caps(4).c_irq           <= conv_std_logic_vector(C_CAP4_IRQ,8);
  caps(4).c_id_associated <= conv_std_logic_vector(C_CAP4_ID_ASSOCIATED,16);
  caps(4).c_id_component  <= conv_std_logic_vector(C_CAP4_ID_COMPONENT,16);
  caps(4).c_irq_enable_en <= '0' when C_CAP4_IRQ_ENABLE_EN = 0 else '1';
  caps(4).c_irq_status_en <= '0' when C_CAP4_IRQ_STATUS_EN = 0 else '1';
  caps(4).c_irq_enable    <= (others => '0') when C_CAP4_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP4_IRQ_ENABLE,15);
  caps(4).c_irq_status    <= (others => '0') when C_CAP4_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP4_IRQ_STATUS,15);
  caps(4).c_base          <= conv_std_logic_vector(C_CAP4_BASE,32);
  caps(4).c_size          <= conv_std_logic_vector(C_CAP4_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(4).c_next          <= C_BASEADDR + conv_std_logic_vector((4+1)*64,16) when 4 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 5
  caps(5).c_type          <= conv_std_logic_vector(C_CAP5_TYPE,16);
  caps(5).c_version       <= conv_std_logic_vector(C_CAP5_VERSION,8);
  caps(5).c_irq           <= conv_std_logic_vector(C_CAP5_IRQ,8);
  caps(5).c_id_associated <= conv_std_logic_vector(C_CAP5_ID_ASSOCIATED,16);
  caps(5).c_id_component  <= conv_std_logic_vector(C_CAP5_ID_COMPONENT,16);
  caps(5).c_irq_enable_en <= '0' when C_CAP5_IRQ_ENABLE_EN = 0 else '1';
  caps(5).c_irq_status_en <= '0' when C_CAP5_IRQ_STATUS_EN = 0 else '1';
  caps(5).c_irq_enable    <= (others => '0') when C_CAP5_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP5_IRQ_ENABLE,15);
  caps(5).c_irq_status    <= (others => '0') when C_CAP5_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP5_IRQ_STATUS,15);
  caps(5).c_base          <= conv_std_logic_vector(C_CAP5_BASE,32);
  caps(5).c_size          <= conv_std_logic_vector(C_CAP5_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(5).c_next          <= C_BASEADDR + conv_std_logic_vector((5+1)*64,16) when 5 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 6
  caps(6).c_type          <= conv_std_logic_vector(C_CAP6_TYPE,16);
  caps(6).c_version       <= conv_std_logic_vector(C_CAP6_VERSION,8);
  caps(6).c_irq           <= conv_std_logic_vector(C_CAP6_IRQ,8);
  caps(6).c_id_associated <= conv_std_logic_vector(C_CAP6_ID_ASSOCIATED,16);
  caps(6).c_id_component  <= conv_std_logic_vector(C_CAP6_ID_COMPONENT,16);
  caps(6).c_irq_enable_en <= '0' when C_CAP6_IRQ_ENABLE_EN = 0 else '1';
  caps(6).c_irq_status_en <= '0' when C_CAP6_IRQ_STATUS_EN = 0 else '1';
  caps(6).c_irq_enable    <= (others => '0') when C_CAP6_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP6_IRQ_ENABLE,15);
  caps(6).c_irq_status    <= (others => '0') when C_CAP6_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP6_IRQ_STATUS,15);
  caps(6).c_base          <= conv_std_logic_vector(C_CAP6_BASE,32);
  caps(6).c_size          <= conv_std_logic_vector(C_CAP6_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(6).c_next          <= C_BASEADDR + conv_std_logic_vector((6+1)*64,16) when 6 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 7
  caps(7).c_type          <= conv_std_logic_vector(C_CAP7_TYPE,16);
  caps(7).c_version       <= conv_std_logic_vector(C_CAP7_VERSION,8);
  caps(7).c_irq           <= conv_std_logic_vector(C_CAP7_IRQ,8);
  caps(7).c_id_associated <= conv_std_logic_vector(C_CAP7_ID_ASSOCIATED,16);
  caps(7).c_id_component  <= conv_std_logic_vector(C_CAP7_ID_COMPONENT,16);
  caps(7).c_irq_enable_en <= '0' when C_CAP7_IRQ_ENABLE_EN = 0 else '1';
  caps(7).c_irq_status_en <= '0' when C_CAP7_IRQ_STATUS_EN = 0 else '1';
  caps(7).c_irq_enable    <= (others => '0') when C_CAP7_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP7_IRQ_ENABLE,15);
  caps(7).c_irq_status    <= (others => '0') when C_CAP7_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP7_IRQ_STATUS,15);
  caps(7).c_base          <= conv_std_logic_vector(C_CAP7_BASE,32);
  caps(7).c_size          <= conv_std_logic_vector(C_CAP7_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(7).c_next          <= C_BASEADDR + conv_std_logic_vector((7+1)*64,16) when 7 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 8
  caps(8).c_type          <= conv_std_logic_vector(C_CAP8_TYPE,16);
  caps(8).c_version       <= conv_std_logic_vector(C_CAP8_VERSION,8);
  caps(8).c_irq           <= conv_std_logic_vector(C_CAP8_IRQ,8);
  caps(8).c_id_associated <= conv_std_logic_vector(C_CAP8_ID_ASSOCIATED,16);
  caps(8).c_id_component  <= conv_std_logic_vector(C_CAP8_ID_COMPONENT,16);
  caps(8).c_irq_enable_en <= '0' when C_CAP8_IRQ_ENABLE_EN = 0 else '1';
  caps(8).c_irq_status_en <= '0' when C_CAP8_IRQ_STATUS_EN = 0 else '1';
  caps(8).c_irq_enable    <= (others => '0') when C_CAP8_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP8_IRQ_ENABLE,15);
  caps(8).c_irq_status    <= (others => '0') when C_CAP8_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP8_IRQ_STATUS,15);
  caps(8).c_base          <= conv_std_logic_vector(C_CAP8_BASE,32);
  caps(8).c_size          <= conv_std_logic_vector(C_CAP8_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(8).c_next          <= C_BASEADDR + conv_std_logic_vector((8+1)*64,16) when 8 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 9
  caps(9).c_type          <= conv_std_logic_vector(C_CAP9_TYPE,16);
  caps(9).c_version       <= conv_std_logic_vector(C_CAP9_VERSION,8);
  caps(9).c_irq           <= conv_std_logic_vector(C_CAP9_IRQ,8);
  caps(9).c_id_associated <= conv_std_logic_vector(C_CAP9_ID_ASSOCIATED,16);
  caps(9).c_id_component  <= conv_std_logic_vector(C_CAP9_ID_COMPONENT,16);
  caps(9).c_irq_enable_en <= '0' when C_CAP9_IRQ_ENABLE_EN = 0 else '1';
  caps(9).c_irq_status_en <= '0' when C_CAP9_IRQ_STATUS_EN = 0 else '1';
  caps(9).c_irq_enable    <= (others => '0') when C_CAP9_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP9_IRQ_ENABLE,15);
  caps(9).c_irq_status    <= (others => '0') when C_CAP9_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP9_IRQ_STATUS,15);
  caps(9).c_base          <= conv_std_logic_vector(C_CAP9_BASE,32);
  caps(9).c_size          <= conv_std_logic_vector(C_CAP9_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(9).c_next          <= C_BASEADDR + conv_std_logic_vector((9+1)*64,16) when 9 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 10
  caps(10).c_type          <= conv_std_logic_vector(C_CAP10_TYPE,16);
  caps(10).c_version       <= conv_std_logic_vector(C_CAP10_VERSION,8);
  caps(10).c_irq           <= conv_std_logic_vector(C_CAP10_IRQ,8);
  caps(10).c_id_associated <= conv_std_logic_vector(C_CAP10_ID_ASSOCIATED,16);
  caps(10).c_id_component  <= conv_std_logic_vector(C_CAP10_ID_COMPONENT,16);
  caps(10).c_irq_enable_en <= '0' when C_CAP10_IRQ_ENABLE_EN = 0 else '1';
  caps(10).c_irq_status_en <= '0' when C_CAP10_IRQ_STATUS_EN = 0 else '1';
  caps(10).c_irq_enable    <= (others => '0') when C_CAP10_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP10_IRQ_ENABLE,15);
  caps(10).c_irq_status    <= (others => '0') when C_CAP10_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP10_IRQ_STATUS,15);
  caps(10).c_base          <= conv_std_logic_vector(C_CAP10_BASE,32);
  caps(10).c_size          <= conv_std_logic_vector(C_CAP10_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(10).c_next          <= C_BASEADDR + conv_std_logic_vector((10+1)*64,16) when 10 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 11
  caps(11).c_type          <= conv_std_logic_vector(C_CAP11_TYPE,16);
  caps(11).c_version       <= conv_std_logic_vector(C_CAP11_VERSION,8);
  caps(11).c_irq           <= conv_std_logic_vector(C_CAP11_IRQ,8);
  caps(11).c_id_associated <= conv_std_logic_vector(C_CAP11_ID_ASSOCIATED,16);
  caps(11).c_id_component  <= conv_std_logic_vector(C_CAP11_ID_COMPONENT,16);
  caps(11).c_irq_enable_en <= '0' when C_CAP11_IRQ_ENABLE_EN = 0 else '1';
  caps(11).c_irq_status_en <= '0' when C_CAP11_IRQ_STATUS_EN = 0 else '1';
  caps(11).c_irq_enable    <= (others => '0') when C_CAP11_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP11_IRQ_ENABLE,15);
  caps(11).c_irq_status    <= (others => '0') when C_CAP11_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP11_IRQ_STATUS,15);
  caps(11).c_base          <= conv_std_logic_vector(C_CAP11_BASE,32);
  caps(11).c_size          <= conv_std_logic_vector(C_CAP11_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(11).c_next          <= C_BASEADDR + conv_std_logic_vector((11+1)*64,16) when 11 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 12
  caps(12).c_type          <= conv_std_logic_vector(C_CAP12_TYPE,16);
  caps(12).c_version       <= conv_std_logic_vector(C_CAP12_VERSION,8);
  caps(12).c_irq           <= conv_std_logic_vector(C_CAP12_IRQ,8);
  caps(12).c_id_associated <= conv_std_logic_vector(C_CAP12_ID_ASSOCIATED,16);
  caps(12).c_id_component  <= conv_std_logic_vector(C_CAP12_ID_COMPONENT,16);
  caps(12).c_irq_enable_en <= '0' when C_CAP12_IRQ_ENABLE_EN = 0 else '1';
  caps(12).c_irq_status_en <= '0' when C_CAP12_IRQ_STATUS_EN = 0 else '1';
  caps(12).c_irq_enable    <= (others => '0') when C_CAP12_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP12_IRQ_ENABLE,15);
  caps(12).c_irq_status    <= (others => '0') when C_CAP12_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP12_IRQ_STATUS,15);
  caps(12).c_base          <= conv_std_logic_vector(C_CAP12_BASE,32);
  caps(12).c_size          <= conv_std_logic_vector(C_CAP12_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(12).c_next          <= C_BASEADDR + conv_std_logic_vector((12+1)*64,16) when 12 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 13
  caps(13).c_type          <= conv_std_logic_vector(C_CAP13_TYPE,16);
  caps(13).c_version       <= conv_std_logic_vector(C_CAP13_VERSION,8);
  caps(13).c_irq           <= conv_std_logic_vector(C_CAP13_IRQ,8);
  caps(13).c_id_associated <= conv_std_logic_vector(C_CAP13_ID_ASSOCIATED,16);
  caps(13).c_id_component  <= conv_std_logic_vector(C_CAP13_ID_COMPONENT,16);
  caps(13).c_irq_enable_en <= '0' when C_CAP13_IRQ_ENABLE_EN = 0 else '1';
  caps(13).c_irq_status_en <= '0' when C_CAP13_IRQ_STATUS_EN = 0 else '1';
  caps(13).c_irq_enable    <= (others => '0') when C_CAP13_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP13_IRQ_ENABLE,15);
  caps(13).c_irq_status    <= (others => '0') when C_CAP13_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP13_IRQ_STATUS,15);
  caps(13).c_base          <= conv_std_logic_vector(C_CAP13_BASE,32);
  caps(13).c_size          <= conv_std_logic_vector(C_CAP13_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(13).c_next          <= C_BASEADDR + conv_std_logic_vector((13+1)*64,16) when 13 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 14
  caps(14).c_type          <= conv_std_logic_vector(C_CAP14_TYPE,16);
  caps(14).c_version       <= conv_std_logic_vector(C_CAP14_VERSION,8);
  caps(14).c_irq           <= conv_std_logic_vector(C_CAP14_IRQ,8);
  caps(14).c_id_associated <= conv_std_logic_vector(C_CAP14_ID_ASSOCIATED,16);
  caps(14).c_id_component  <= conv_std_logic_vector(C_CAP14_ID_COMPONENT,16);
  caps(14).c_irq_enable_en <= '0' when C_CAP14_IRQ_ENABLE_EN = 0 else '1';
  caps(14).c_irq_status_en <= '0' when C_CAP14_IRQ_STATUS_EN = 0 else '1';
  caps(14).c_irq_enable    <= (others => '0') when C_CAP14_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP14_IRQ_ENABLE,15);
  caps(14).c_irq_status    <= (others => '0') when C_CAP14_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP14_IRQ_STATUS,15);
  caps(14).c_base          <= conv_std_logic_vector(C_CAP14_BASE,32);
  caps(14).c_size          <= conv_std_logic_vector(C_CAP14_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(14).c_next          <= C_BASEADDR + conv_std_logic_vector((14+1)*64,16) when 14 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 15
  caps(15).c_type          <= conv_std_logic_vector(C_CAP15_TYPE,16);
  caps(15).c_version       <= conv_std_logic_vector(C_CAP15_VERSION,8);
  caps(15).c_irq           <= conv_std_logic_vector(C_CAP15_IRQ,8);
  caps(15).c_id_associated <= conv_std_logic_vector(C_CAP15_ID_ASSOCIATED,16);
  caps(15).c_id_component  <= conv_std_logic_vector(C_CAP15_ID_COMPONENT,16);
  caps(15).c_irq_enable_en <= '0' when C_CAP15_IRQ_ENABLE_EN = 0 else '1';
  caps(15).c_irq_status_en <= '0' when C_CAP15_IRQ_STATUS_EN = 0 else '1';
  caps(15).c_irq_enable    <= (others => '0') when C_CAP15_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP15_IRQ_ENABLE,15);
  caps(15).c_irq_status    <= (others => '0') when C_CAP15_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP15_IRQ_STATUS,15);
  caps(15).c_base          <= conv_std_logic_vector(C_CAP15_BASE,32);
  caps(15).c_size          <= conv_std_logic_vector(C_CAP15_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(15).c_next          <= C_BASEADDR + conv_std_logic_vector((15+1)*64,16) when 15 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 16
  caps(16).c_type          <= conv_std_logic_vector(C_CAP16_TYPE,16);
  caps(16).c_version       <= conv_std_logic_vector(C_CAP16_VERSION,8);
  caps(16).c_irq           <= conv_std_logic_vector(C_CAP16_IRQ,8);
  caps(16).c_id_associated <= conv_std_logic_vector(C_CAP16_ID_ASSOCIATED,16);
  caps(16).c_id_component  <= conv_std_logic_vector(C_CAP16_ID_COMPONENT,16);
  caps(16).c_irq_enable_en <= '0' when C_CAP16_IRQ_ENABLE_EN = 0 else '1';
  caps(16).c_irq_status_en <= '0' when C_CAP16_IRQ_STATUS_EN = 0 else '1';
  caps(16).c_irq_enable    <= (others => '0') when C_CAP16_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP16_IRQ_ENABLE,15);
  caps(16).c_irq_status    <= (others => '0') when C_CAP16_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP16_IRQ_STATUS,15);
  caps(16).c_base          <= conv_std_logic_vector(C_CAP16_BASE,32);
  caps(16).c_size          <= conv_std_logic_vector(C_CAP16_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(16).c_next          <= C_BASEADDR + conv_std_logic_vector((16+1)*64,16) when 16 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 17
  caps(17).c_type          <= conv_std_logic_vector(C_CAP17_TYPE,16);
  caps(17).c_version       <= conv_std_logic_vector(C_CAP17_VERSION,8);
  caps(17).c_irq           <= conv_std_logic_vector(C_CAP17_IRQ,8);
  caps(17).c_id_associated <= conv_std_logic_vector(C_CAP17_ID_ASSOCIATED,16);
  caps(17).c_id_component  <= conv_std_logic_vector(C_CAP17_ID_COMPONENT,16);
  caps(17).c_irq_enable_en <= '0' when C_CAP17_IRQ_ENABLE_EN = 0 else '1';
  caps(17).c_irq_status_en <= '0' when C_CAP17_IRQ_STATUS_EN = 0 else '1';
  caps(17).c_irq_enable    <= (others => '0') when C_CAP17_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP17_IRQ_ENABLE,15);
  caps(17).c_irq_status    <= (others => '0') when C_CAP17_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP17_IRQ_STATUS,15);
  caps(17).c_base          <= conv_std_logic_vector(C_CAP17_BASE,32);
  caps(17).c_size          <= conv_std_logic_vector(C_CAP17_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(17).c_next          <= C_BASEADDR + conv_std_logic_vector((17+1)*64,16) when 17 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 18
  caps(18).c_type          <= conv_std_logic_vector(C_CAP18_TYPE,16);
  caps(18).c_version       <= conv_std_logic_vector(C_CAP18_VERSION,8);
  caps(18).c_irq           <= conv_std_logic_vector(C_CAP18_IRQ,8);
  caps(18).c_id_associated <= conv_std_logic_vector(C_CAP18_ID_ASSOCIATED,16);
  caps(18).c_id_component  <= conv_std_logic_vector(C_CAP18_ID_COMPONENT,16);
  caps(18).c_irq_enable_en <= '0' when C_CAP18_IRQ_ENABLE_EN = 0 else '1';
  caps(18).c_irq_status_en <= '0' when C_CAP18_IRQ_STATUS_EN = 0 else '1';
  caps(18).c_irq_enable    <= (others => '0') when C_CAP18_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP18_IRQ_ENABLE,15);
  caps(18).c_irq_status    <= (others => '0') when C_CAP18_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP18_IRQ_STATUS,15);
  caps(18).c_base          <= conv_std_logic_vector(C_CAP18_BASE,32);
  caps(18).c_size          <= conv_std_logic_vector(C_CAP18_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(18).c_next          <= C_BASEADDR + conv_std_logic_vector((18+1)*64,16) when 18 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 19
  caps(19).c_type          <= conv_std_logic_vector(C_CAP19_TYPE,16);
  caps(19).c_version       <= conv_std_logic_vector(C_CAP19_VERSION,8);
  caps(19).c_irq           <= conv_std_logic_vector(C_CAP19_IRQ,8);
  caps(19).c_id_associated <= conv_std_logic_vector(C_CAP19_ID_ASSOCIATED,16);
  caps(19).c_id_component  <= conv_std_logic_vector(C_CAP19_ID_COMPONENT,16);
  caps(19).c_irq_enable_en <= '0' when C_CAP19_IRQ_ENABLE_EN = 0 else '1';
  caps(19).c_irq_status_en <= '0' when C_CAP19_IRQ_STATUS_EN = 0 else '1';
  caps(19).c_irq_enable    <= (others => '0') when C_CAP19_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP19_IRQ_ENABLE,15);
  caps(19).c_irq_status    <= (others => '0') when C_CAP19_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP19_IRQ_STATUS,15);
  caps(19).c_base          <= conv_std_logic_vector(C_CAP19_BASE,32);
  caps(19).c_size          <= conv_std_logic_vector(C_CAP19_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(19).c_next          <= C_BASEADDR + conv_std_logic_vector((19+1)*64,16) when 19 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 20
  caps(20).c_type          <= conv_std_logic_vector(C_CAP20_TYPE,16);
  caps(20).c_version       <= conv_std_logic_vector(C_CAP20_VERSION,8);
  caps(20).c_irq           <= conv_std_logic_vector(C_CAP20_IRQ,8);
  caps(20).c_id_associated <= conv_std_logic_vector(C_CAP20_ID_ASSOCIATED,16);
  caps(20).c_id_component  <= conv_std_logic_vector(C_CAP20_ID_COMPONENT,16);
  caps(20).c_irq_enable_en <= '0' when C_CAP20_IRQ_ENABLE_EN = 0 else '1';
  caps(20).c_irq_status_en <= '0' when C_CAP20_IRQ_STATUS_EN = 0 else '1';
  caps(20).c_irq_enable    <= (others => '0') when C_CAP20_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP20_IRQ_ENABLE,15);
  caps(20).c_irq_status    <= (others => '0') when C_CAP20_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP20_IRQ_STATUS,15);
  caps(20).c_base          <= conv_std_logic_vector(C_CAP20_BASE,32);
  caps(20).c_size          <= conv_std_logic_vector(C_CAP20_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(20).c_next          <= C_BASEADDR + conv_std_logic_vector((20+1)*64,16) when 20 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 21
  caps(21).c_type          <= conv_std_logic_vector(C_CAP21_TYPE,16);
  caps(21).c_version       <= conv_std_logic_vector(C_CAP21_VERSION,8);
  caps(21).c_irq           <= conv_std_logic_vector(C_CAP21_IRQ,8);
  caps(21).c_id_associated <= conv_std_logic_vector(C_CAP21_ID_ASSOCIATED,16);
  caps(21).c_id_component  <= conv_std_logic_vector(C_CAP21_ID_COMPONENT,16);
  caps(21).c_irq_enable_en <= '0' when C_CAP21_IRQ_ENABLE_EN = 0 else '1';
  caps(21).c_irq_status_en <= '0' when C_CAP21_IRQ_STATUS_EN = 0 else '1';
  caps(21).c_irq_enable    <= (others => '0') when C_CAP21_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP21_IRQ_ENABLE,15);
  caps(21).c_irq_status    <= (others => '0') when C_CAP21_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP21_IRQ_STATUS,15);
  caps(21).c_base          <= conv_std_logic_vector(C_CAP21_BASE,32);
  caps(21).c_size          <= conv_std_logic_vector(C_CAP21_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(21).c_next          <= C_BASEADDR + conv_std_logic_vector((21+1)*64,16) when 21 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 22
  caps(22).c_type          <= conv_std_logic_vector(C_CAP22_TYPE,16);
  caps(22).c_version       <= conv_std_logic_vector(C_CAP22_VERSION,8);
  caps(22).c_irq           <= conv_std_logic_vector(C_CAP22_IRQ,8);
  caps(22).c_id_associated <= conv_std_logic_vector(C_CAP22_ID_ASSOCIATED,16);
  caps(22).c_id_component  <= conv_std_logic_vector(C_CAP22_ID_COMPONENT,16);
  caps(22).c_irq_enable_en <= '0' when C_CAP22_IRQ_ENABLE_EN = 0 else '1';
  caps(22).c_irq_status_en <= '0' when C_CAP22_IRQ_STATUS_EN = 0 else '1';
  caps(22).c_irq_enable    <= (others => '0') when C_CAP22_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP22_IRQ_ENABLE,15);
  caps(22).c_irq_status    <= (others => '0') when C_CAP22_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP22_IRQ_STATUS,15);
  caps(22).c_base          <= conv_std_logic_vector(C_CAP22_BASE,32);
  caps(22).c_size          <= conv_std_logic_vector(C_CAP22_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(22).c_next          <= C_BASEADDR + conv_std_logic_vector((22+1)*64,16) when 22 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 23
  caps(23).c_type          <= conv_std_logic_vector(C_CAP23_TYPE,16);
  caps(23).c_version       <= conv_std_logic_vector(C_CAP23_VERSION,8);
  caps(23).c_irq           <= conv_std_logic_vector(C_CAP23_IRQ,8);
  caps(23).c_id_associated <= conv_std_logic_vector(C_CAP23_ID_ASSOCIATED,16);
  caps(23).c_id_component  <= conv_std_logic_vector(C_CAP23_ID_COMPONENT,16);
  caps(23).c_irq_enable_en <= '0' when C_CAP23_IRQ_ENABLE_EN = 0 else '1';
  caps(23).c_irq_status_en <= '0' when C_CAP23_IRQ_STATUS_EN = 0 else '1';
  caps(23).c_irq_enable    <= (others => '0') when C_CAP23_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP23_IRQ_ENABLE,15);
  caps(23).c_irq_status    <= (others => '0') when C_CAP23_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP23_IRQ_STATUS,15);
  caps(23).c_base          <= conv_std_logic_vector(C_CAP23_BASE,32);
  caps(23).c_size          <= conv_std_logic_vector(C_CAP23_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(23).c_next          <= C_BASEADDR + conv_std_logic_vector((23+1)*64,16) when 23 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 24
  caps(24).c_type          <= conv_std_logic_vector(C_CAP24_TYPE,16);
  caps(24).c_version       <= conv_std_logic_vector(C_CAP24_VERSION,8);
  caps(24).c_irq           <= conv_std_logic_vector(C_CAP24_IRQ,8);
  caps(24).c_id_associated <= conv_std_logic_vector(C_CAP24_ID_ASSOCIATED,16);
  caps(24).c_id_component  <= conv_std_logic_vector(C_CAP24_ID_COMPONENT,16);
  caps(24).c_irq_enable_en <= '0' when C_CAP24_IRQ_ENABLE_EN = 0 else '1';
  caps(24).c_irq_status_en <= '0' when C_CAP24_IRQ_STATUS_EN = 0 else '1';
  caps(24).c_irq_enable    <= (others => '0') when C_CAP24_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP24_IRQ_ENABLE,15);
  caps(24).c_irq_status    <= (others => '0') when C_CAP24_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP24_IRQ_STATUS,15);
  caps(24).c_base          <= conv_std_logic_vector(C_CAP24_BASE,32);
  caps(24).c_size          <= conv_std_logic_vector(C_CAP24_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(24).c_next          <= C_BASEADDR + conv_std_logic_vector((24+1)*64,16) when 24 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 25
  caps(25).c_type          <= conv_std_logic_vector(C_CAP25_TYPE,16);
  caps(25).c_version       <= conv_std_logic_vector(C_CAP25_VERSION,8);
  caps(25).c_irq           <= conv_std_logic_vector(C_CAP25_IRQ,8);
  caps(25).c_id_associated <= conv_std_logic_vector(C_CAP25_ID_ASSOCIATED,16);
  caps(25).c_id_component  <= conv_std_logic_vector(C_CAP25_ID_COMPONENT,16);
  caps(25).c_irq_enable_en <= '0' when C_CAP25_IRQ_ENABLE_EN = 0 else '1';
  caps(25).c_irq_status_en <= '0' when C_CAP25_IRQ_STATUS_EN = 0 else '1';
  caps(25).c_irq_enable    <= (others => '0') when C_CAP25_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP25_IRQ_ENABLE,15);
  caps(25).c_irq_status    <= (others => '0') when C_CAP25_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP25_IRQ_STATUS,15);
  caps(25).c_base          <= conv_std_logic_vector(C_CAP25_BASE,32);
  caps(25).c_size          <= conv_std_logic_vector(C_CAP25_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(25).c_next          <= C_BASEADDR + conv_std_logic_vector((25+1)*64,16) when 25 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 26
  caps(26).c_type          <= conv_std_logic_vector(C_CAP26_TYPE,16);
  caps(26).c_version       <= conv_std_logic_vector(C_CAP26_VERSION,8);
  caps(26).c_irq           <= conv_std_logic_vector(C_CAP26_IRQ,8);
  caps(26).c_id_associated <= conv_std_logic_vector(C_CAP26_ID_ASSOCIATED,16);
  caps(26).c_id_component  <= conv_std_logic_vector(C_CAP26_ID_COMPONENT,16);
  caps(26).c_irq_enable_en <= '0' when C_CAP26_IRQ_ENABLE_EN = 0 else '1';
  caps(26).c_irq_status_en <= '0' when C_CAP26_IRQ_STATUS_EN = 0 else '1';
  caps(26).c_irq_enable    <= (others => '0') when C_CAP26_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP26_IRQ_ENABLE,15);
  caps(26).c_irq_status    <= (others => '0') when C_CAP26_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP26_IRQ_STATUS,15);
  caps(26).c_base          <= conv_std_logic_vector(C_CAP26_BASE,32);
  caps(26).c_size          <= conv_std_logic_vector(C_CAP26_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(26).c_next          <= C_BASEADDR + conv_std_logic_vector((26+1)*64,16) when 26 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 27
  caps(27).c_type          <= conv_std_logic_vector(C_CAP27_TYPE,16);
  caps(27).c_version       <= conv_std_logic_vector(C_CAP27_VERSION,8);
  caps(27).c_irq           <= conv_std_logic_vector(C_CAP27_IRQ,8);
  caps(27).c_id_associated <= conv_std_logic_vector(C_CAP27_ID_ASSOCIATED,16);
  caps(27).c_id_component  <= conv_std_logic_vector(C_CAP27_ID_COMPONENT,16);
  caps(27).c_irq_enable_en <= '0' when C_CAP27_IRQ_ENABLE_EN = 0 else '1';
  caps(27).c_irq_status_en <= '0' when C_CAP27_IRQ_STATUS_EN = 0 else '1';
  caps(27).c_irq_enable    <= (others => '0') when C_CAP27_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP27_IRQ_ENABLE,15);
  caps(27).c_irq_status    <= (others => '0') when C_CAP27_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP27_IRQ_STATUS,15);
  caps(27).c_base          <= conv_std_logic_vector(C_CAP27_BASE,32);
  caps(27).c_size          <= conv_std_logic_vector(C_CAP27_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(27).c_next          <= C_BASEADDR + conv_std_logic_vector((27+1)*64,16) when 27 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 28
  caps(28).c_type          <= conv_std_logic_vector(C_CAP28_TYPE,16);
  caps(28).c_version       <= conv_std_logic_vector(C_CAP28_VERSION,8);
  caps(28).c_irq           <= conv_std_logic_vector(C_CAP28_IRQ,8);
  caps(28).c_id_associated <= conv_std_logic_vector(C_CAP28_ID_ASSOCIATED,16);
  caps(28).c_id_component  <= conv_std_logic_vector(C_CAP28_ID_COMPONENT,16);
  caps(28).c_irq_enable_en <= '0' when C_CAP28_IRQ_ENABLE_EN = 0 else '1';
  caps(28).c_irq_status_en <= '0' when C_CAP28_IRQ_STATUS_EN = 0 else '1';
  caps(28).c_irq_enable    <= (others => '0') when C_CAP28_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP28_IRQ_ENABLE,15);
  caps(28).c_irq_status    <= (others => '0') when C_CAP28_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP28_IRQ_STATUS,15);
  caps(28).c_base          <= conv_std_logic_vector(C_CAP28_BASE,32);
  caps(28).c_size          <= conv_std_logic_vector(C_CAP28_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(28).c_next          <= C_BASEADDR + conv_std_logic_vector((28+1)*64,16) when 28 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 29
  caps(29).c_type          <= conv_std_logic_vector(C_CAP29_TYPE,16);
  caps(29).c_version       <= conv_std_logic_vector(C_CAP29_VERSION,8);
  caps(29).c_irq           <= conv_std_logic_vector(C_CAP29_IRQ,8);
  caps(29).c_id_associated <= conv_std_logic_vector(C_CAP29_ID_ASSOCIATED,16);
  caps(29).c_id_component  <= conv_std_logic_vector(C_CAP29_ID_COMPONENT,16);
  caps(29).c_irq_enable_en <= '0' when C_CAP29_IRQ_ENABLE_EN = 0 else '1';
  caps(29).c_irq_status_en <= '0' when C_CAP29_IRQ_STATUS_EN = 0 else '1';
  caps(29).c_irq_enable    <= (others => '0') when C_CAP29_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP29_IRQ_ENABLE,15);
  caps(29).c_irq_status    <= (others => '0') when C_CAP29_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP29_IRQ_STATUS,15);
  caps(29).c_base          <= conv_std_logic_vector(C_CAP29_BASE,32);
  caps(29).c_size          <= conv_std_logic_vector(C_CAP29_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(29).c_next          <= C_BASEADDR + conv_std_logic_vector((29+1)*64,16) when 29 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 30
  caps(30).c_type          <= conv_std_logic_vector(C_CAP30_TYPE,16);
  caps(30).c_version       <= conv_std_logic_vector(C_CAP30_VERSION,8);
  caps(30).c_irq           <= conv_std_logic_vector(C_CAP30_IRQ,8);
  caps(30).c_id_associated <= conv_std_logic_vector(C_CAP30_ID_ASSOCIATED,16);
  caps(30).c_id_component  <= conv_std_logic_vector(C_CAP30_ID_COMPONENT,16);
  caps(30).c_irq_enable_en <= '0' when C_CAP30_IRQ_ENABLE_EN = 0 else '1';
  caps(30).c_irq_status_en <= '0' when C_CAP30_IRQ_STATUS_EN = 0 else '1';
  caps(30).c_irq_enable    <= (others => '0') when C_CAP30_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP30_IRQ_ENABLE,15);
  caps(30).c_irq_status    <= (others => '0') when C_CAP30_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP30_IRQ_STATUS,15);
  caps(30).c_base          <= conv_std_logic_vector(C_CAP30_BASE,32);
  caps(30).c_size          <= conv_std_logic_vector(C_CAP30_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(30).c_next          <= C_BASEADDR + conv_std_logic_vector((30+1)*64,16) when 30 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 31
  caps(31).c_type          <= conv_std_logic_vector(C_CAP31_TYPE,16);
  caps(31).c_version       <= conv_std_logic_vector(C_CAP31_VERSION,8);
  caps(31).c_irq           <= conv_std_logic_vector(C_CAP31_IRQ,8);
  caps(31).c_id_associated <= conv_std_logic_vector(C_CAP31_ID_ASSOCIATED,16);
  caps(31).c_id_component  <= conv_std_logic_vector(C_CAP31_ID_COMPONENT,16);
  caps(31).c_irq_enable_en <= '0' when C_CAP31_IRQ_ENABLE_EN = 0 else '1';
  caps(31).c_irq_status_en <= '0' when C_CAP31_IRQ_STATUS_EN = 0 else '1';
  caps(31).c_irq_enable    <= (others => '0') when C_CAP31_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP31_IRQ_ENABLE,15);
  caps(31).c_irq_status    <= (others => '0') when C_CAP31_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP31_IRQ_STATUS,15);
  caps(31).c_base          <= conv_std_logic_vector(C_CAP31_BASE,32);
  caps(31).c_size          <= conv_std_logic_vector(C_CAP31_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(31).c_next          <= C_BASEADDR + conv_std_logic_vector((31+1)*64,16) when 31 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 32
  caps(32).c_type          <= conv_std_logic_vector(C_CAP32_TYPE,16);
  caps(32).c_version       <= conv_std_logic_vector(C_CAP32_VERSION,8);
  caps(32).c_irq           <= conv_std_logic_vector(C_CAP32_IRQ,8);
  caps(32).c_id_associated <= conv_std_logic_vector(C_CAP32_ID_ASSOCIATED,16);
  caps(32).c_id_component  <= conv_std_logic_vector(C_CAP32_ID_COMPONENT,16);
  caps(32).c_irq_enable_en <= '0' when C_CAP32_IRQ_ENABLE_EN = 0 else '1';
  caps(32).c_irq_status_en <= '0' when C_CAP32_IRQ_STATUS_EN = 0 else '1';
  caps(32).c_irq_enable    <= (others => '0') when C_CAP32_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP32_IRQ_ENABLE,15);
  caps(32).c_irq_status    <= (others => '0') when C_CAP32_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP32_IRQ_STATUS,15);
  caps(32).c_base          <= conv_std_logic_vector(C_CAP32_BASE,32);
  caps(32).c_size          <= conv_std_logic_vector(C_CAP32_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(32).c_next          <= C_BASEADDR + conv_std_logic_vector((32+1)*64,16) when 32 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 33
  caps(33).c_type          <= conv_std_logic_vector(C_CAP33_TYPE,16);
  caps(33).c_version       <= conv_std_logic_vector(C_CAP33_VERSION,8);
  caps(33).c_irq           <= conv_std_logic_vector(C_CAP33_IRQ,8);
  caps(33).c_id_associated <= conv_std_logic_vector(C_CAP33_ID_ASSOCIATED,16);
  caps(33).c_id_component  <= conv_std_logic_vector(C_CAP33_ID_COMPONENT,16);
  caps(33).c_irq_enable_en <= '0' when C_CAP33_IRQ_ENABLE_EN = 0 else '1';
  caps(33).c_irq_status_en <= '0' when C_CAP33_IRQ_STATUS_EN = 0 else '1';
  caps(33).c_irq_enable    <= (others => '0') when C_CAP33_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP33_IRQ_ENABLE,15);
  caps(33).c_irq_status    <= (others => '0') when C_CAP33_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP33_IRQ_STATUS,15);
  caps(33).c_base          <= conv_std_logic_vector(C_CAP33_BASE,32);
  caps(33).c_size          <= conv_std_logic_vector(C_CAP33_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(33).c_next          <= C_BASEADDR + conv_std_logic_vector((33+1)*64,16) when 33 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 34
  caps(34).c_type          <= conv_std_logic_vector(C_CAP34_TYPE,16);
  caps(34).c_version       <= conv_std_logic_vector(C_CAP34_VERSION,8);
  caps(34).c_irq           <= conv_std_logic_vector(C_CAP34_IRQ,8);
  caps(34).c_id_associated <= conv_std_logic_vector(C_CAP34_ID_ASSOCIATED,16);
  caps(34).c_id_component  <= conv_std_logic_vector(C_CAP34_ID_COMPONENT,16);
  caps(34).c_irq_enable_en <= '0' when C_CAP34_IRQ_ENABLE_EN = 0 else '1';
  caps(34).c_irq_status_en <= '0' when C_CAP34_IRQ_STATUS_EN = 0 else '1';
  caps(34).c_irq_enable    <= (others => '0') when C_CAP34_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP34_IRQ_ENABLE,15);
  caps(34).c_irq_status    <= (others => '0') when C_CAP34_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP34_IRQ_STATUS,15);
  caps(34).c_base          <= conv_std_logic_vector(C_CAP34_BASE,32);
  caps(34).c_size          <= conv_std_logic_vector(C_CAP34_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(34).c_next          <= C_BASEADDR + conv_std_logic_vector((34+1)*64,16) when 34 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 35
  caps(35).c_type          <= conv_std_logic_vector(C_CAP35_TYPE,16);
  caps(35).c_version       <= conv_std_logic_vector(C_CAP35_VERSION,8);
  caps(35).c_irq           <= conv_std_logic_vector(C_CAP35_IRQ,8);
  caps(35).c_id_associated <= conv_std_logic_vector(C_CAP35_ID_ASSOCIATED,16);
  caps(35).c_id_component  <= conv_std_logic_vector(C_CAP35_ID_COMPONENT,16);
  caps(35).c_irq_enable_en <= '0' when C_CAP35_IRQ_ENABLE_EN = 0 else '1';
  caps(35).c_irq_status_en <= '0' when C_CAP35_IRQ_STATUS_EN = 0 else '1';
  caps(35).c_irq_enable    <= (others => '0') when C_CAP35_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP35_IRQ_ENABLE,15);
  caps(35).c_irq_status    <= (others => '0') when C_CAP35_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP35_IRQ_STATUS,15);
  caps(35).c_base          <= conv_std_logic_vector(C_CAP35_BASE,32);
  caps(35).c_size          <= conv_std_logic_vector(C_CAP35_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(35).c_next          <= C_BASEADDR + conv_std_logic_vector((35+1)*64,16) when 35 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 36
  caps(36).c_type          <= conv_std_logic_vector(C_CAP36_TYPE,16);
  caps(36).c_version       <= conv_std_logic_vector(C_CAP36_VERSION,8);
  caps(36).c_irq           <= conv_std_logic_vector(C_CAP36_IRQ,8);
  caps(36).c_id_associated <= conv_std_logic_vector(C_CAP36_ID_ASSOCIATED,16);
  caps(36).c_id_component  <= conv_std_logic_vector(C_CAP36_ID_COMPONENT,16);
  caps(36).c_irq_enable_en <= '0' when C_CAP36_IRQ_ENABLE_EN = 0 else '1';
  caps(36).c_irq_status_en <= '0' when C_CAP36_IRQ_STATUS_EN = 0 else '1';
  caps(36).c_irq_enable    <= (others => '0') when C_CAP36_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP36_IRQ_ENABLE,15);
  caps(36).c_irq_status    <= (others => '0') when C_CAP36_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP36_IRQ_STATUS,15);
  caps(36).c_base          <= conv_std_logic_vector(C_CAP36_BASE,32);
  caps(36).c_size          <= conv_std_logic_vector(C_CAP36_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(36).c_next          <= C_BASEADDR + conv_std_logic_vector((36+1)*64,16) when 36 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 37
  caps(37).c_type          <= conv_std_logic_vector(C_CAP37_TYPE,16);
  caps(37).c_version       <= conv_std_logic_vector(C_CAP37_VERSION,8);
  caps(37).c_irq           <= conv_std_logic_vector(C_CAP37_IRQ,8);
  caps(37).c_id_associated <= conv_std_logic_vector(C_CAP37_ID_ASSOCIATED,16);
  caps(37).c_id_component  <= conv_std_logic_vector(C_CAP37_ID_COMPONENT,16);
  caps(37).c_irq_enable_en <= '0' when C_CAP37_IRQ_ENABLE_EN = 0 else '1';
  caps(37).c_irq_status_en <= '0' when C_CAP37_IRQ_STATUS_EN = 0 else '1';
  caps(37).c_irq_enable    <= (others => '0') when C_CAP37_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP37_IRQ_ENABLE,15);
  caps(37).c_irq_status    <= (others => '0') when C_CAP37_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP37_IRQ_STATUS,15);
  caps(37).c_base          <= conv_std_logic_vector(C_CAP37_BASE,32);
  caps(37).c_size          <= conv_std_logic_vector(C_CAP37_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(37).c_next          <= C_BASEADDR + conv_std_logic_vector((37+1)*64,16) when 37 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 38
  caps(38).c_type          <= conv_std_logic_vector(C_CAP38_TYPE,16);
  caps(38).c_version       <= conv_std_logic_vector(C_CAP38_VERSION,8);
  caps(38).c_irq           <= conv_std_logic_vector(C_CAP38_IRQ,8);
  caps(38).c_id_associated <= conv_std_logic_vector(C_CAP38_ID_ASSOCIATED,16);
  caps(38).c_id_component  <= conv_std_logic_vector(C_CAP38_ID_COMPONENT,16);
  caps(38).c_irq_enable_en <= '0' when C_CAP38_IRQ_ENABLE_EN = 0 else '1';
  caps(38).c_irq_status_en <= '0' when C_CAP38_IRQ_STATUS_EN = 0 else '1';
  caps(38).c_irq_enable    <= (others => '0') when C_CAP38_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP38_IRQ_ENABLE,15);
  caps(38).c_irq_status    <= (others => '0') when C_CAP38_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP38_IRQ_STATUS,15);
  caps(38).c_base          <= conv_std_logic_vector(C_CAP38_BASE,32);
  caps(38).c_size          <= conv_std_logic_vector(C_CAP38_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(38).c_next          <= C_BASEADDR + conv_std_logic_vector((38+1)*64,16) when 38 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 39
  caps(39).c_type          <= conv_std_logic_vector(C_CAP39_TYPE,16);
  caps(39).c_version       <= conv_std_logic_vector(C_CAP39_VERSION,8);
  caps(39).c_irq           <= conv_std_logic_vector(C_CAP39_IRQ,8);
  caps(39).c_id_associated <= conv_std_logic_vector(C_CAP39_ID_ASSOCIATED,16);
  caps(39).c_id_component  <= conv_std_logic_vector(C_CAP39_ID_COMPONENT,16);
  caps(39).c_irq_enable_en <= '0' when C_CAP39_IRQ_ENABLE_EN = 0 else '1';
  caps(39).c_irq_status_en <= '0' when C_CAP39_IRQ_STATUS_EN = 0 else '1';
  caps(39).c_irq_enable    <= (others => '0') when C_CAP39_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP39_IRQ_ENABLE,15);
  caps(39).c_irq_status    <= (others => '0') when C_CAP39_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP39_IRQ_STATUS,15);
  caps(39).c_base          <= conv_std_logic_vector(C_CAP39_BASE,32);
  caps(39).c_size          <= conv_std_logic_vector(C_CAP39_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(39).c_next          <= C_BASEADDR + conv_std_logic_vector((39+1)*64,16) when 39 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 40
  caps(40).c_type          <= conv_std_logic_vector(C_CAP40_TYPE,16);
  caps(40).c_version       <= conv_std_logic_vector(C_CAP40_VERSION,8);
  caps(40).c_irq           <= conv_std_logic_vector(C_CAP40_IRQ,8);
  caps(40).c_id_associated <= conv_std_logic_vector(C_CAP40_ID_ASSOCIATED,16);
  caps(40).c_id_component  <= conv_std_logic_vector(C_CAP40_ID_COMPONENT,16);
  caps(40).c_irq_enable_en <= '0' when C_CAP40_IRQ_ENABLE_EN = 0 else '1';
  caps(40).c_irq_status_en <= '0' when C_CAP40_IRQ_STATUS_EN = 0 else '1';
  caps(40).c_irq_enable    <= (others => '0') when C_CAP40_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP40_IRQ_ENABLE,15);
  caps(40).c_irq_status    <= (others => '0') when C_CAP40_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP40_IRQ_STATUS,15);
  caps(40).c_base          <= conv_std_logic_vector(C_CAP40_BASE,32);
  caps(40).c_size          <= conv_std_logic_vector(C_CAP40_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(40).c_next          <= C_BASEADDR + conv_std_logic_vector((40+1)*64,16) when 40 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 41
  caps(41).c_type          <= conv_std_logic_vector(C_CAP41_TYPE,16);
  caps(41).c_version       <= conv_std_logic_vector(C_CAP41_VERSION,8);
  caps(41).c_irq           <= conv_std_logic_vector(C_CAP41_IRQ,8);
  caps(41).c_id_associated <= conv_std_logic_vector(C_CAP41_ID_ASSOCIATED,16);
  caps(41).c_id_component  <= conv_std_logic_vector(C_CAP41_ID_COMPONENT,16);
  caps(41).c_irq_enable_en <= '0' when C_CAP41_IRQ_ENABLE_EN = 0 else '1';
  caps(41).c_irq_status_en <= '0' when C_CAP41_IRQ_STATUS_EN = 0 else '1';
  caps(41).c_irq_enable    <= (others => '0') when C_CAP41_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP41_IRQ_ENABLE,15);
  caps(41).c_irq_status    <= (others => '0') when C_CAP41_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP41_IRQ_STATUS,15);
  caps(41).c_base          <= conv_std_logic_vector(C_CAP41_BASE,32);
  caps(41).c_size          <= conv_std_logic_vector(C_CAP41_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(41).c_next          <= C_BASEADDR + conv_std_logic_vector((41+1)*64,16) when 41 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 42
  caps(42).c_type          <= conv_std_logic_vector(C_CAP42_TYPE,16);
  caps(42).c_version       <= conv_std_logic_vector(C_CAP42_VERSION,8);
  caps(42).c_irq           <= conv_std_logic_vector(C_CAP42_IRQ,8);
  caps(42).c_id_associated <= conv_std_logic_vector(C_CAP42_ID_ASSOCIATED,16);
  caps(42).c_id_component  <= conv_std_logic_vector(C_CAP42_ID_COMPONENT,16);
  caps(42).c_irq_enable_en <= '0' when C_CAP42_IRQ_ENABLE_EN = 0 else '1';
  caps(42).c_irq_status_en <= '0' when C_CAP42_IRQ_STATUS_EN = 0 else '1';
  caps(42).c_irq_enable    <= (others => '0') when C_CAP42_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP42_IRQ_ENABLE,15);
  caps(42).c_irq_status    <= (others => '0') when C_CAP42_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP42_IRQ_STATUS,15);
  caps(42).c_base          <= conv_std_logic_vector(C_CAP42_BASE,32);
  caps(42).c_size          <= conv_std_logic_vector(C_CAP42_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(42).c_next          <= C_BASEADDR + conv_std_logic_vector((42+1)*64,16) when 42 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 43
  caps(43).c_type          <= conv_std_logic_vector(C_CAP43_TYPE,16);
  caps(43).c_version       <= conv_std_logic_vector(C_CAP43_VERSION,8);
  caps(43).c_irq           <= conv_std_logic_vector(C_CAP43_IRQ,8);
  caps(43).c_id_associated <= conv_std_logic_vector(C_CAP43_ID_ASSOCIATED,16);
  caps(43).c_id_component  <= conv_std_logic_vector(C_CAP43_ID_COMPONENT,16);
  caps(43).c_irq_enable_en <= '0' when C_CAP43_IRQ_ENABLE_EN = 0 else '1';
  caps(43).c_irq_status_en <= '0' when C_CAP43_IRQ_STATUS_EN = 0 else '1';
  caps(43).c_irq_enable    <= (others => '0') when C_CAP43_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP43_IRQ_ENABLE,15);
  caps(43).c_irq_status    <= (others => '0') when C_CAP43_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP43_IRQ_STATUS,15);
  caps(43).c_base          <= conv_std_logic_vector(C_CAP43_BASE,32);
  caps(43).c_size          <= conv_std_logic_vector(C_CAP43_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(43).c_next          <= C_BASEADDR + conv_std_logic_vector((43+1)*64,16) when 43 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 44
  caps(44).c_type          <= conv_std_logic_vector(C_CAP44_TYPE,16);
  caps(44).c_version       <= conv_std_logic_vector(C_CAP44_VERSION,8);
  caps(44).c_irq           <= conv_std_logic_vector(C_CAP44_IRQ,8);
  caps(44).c_id_associated <= conv_std_logic_vector(C_CAP44_ID_ASSOCIATED,16);
  caps(44).c_id_component  <= conv_std_logic_vector(C_CAP44_ID_COMPONENT,16);
  caps(44).c_irq_enable_en <= '0' when C_CAP44_IRQ_ENABLE_EN = 0 else '1';
  caps(44).c_irq_status_en <= '0' when C_CAP44_IRQ_STATUS_EN = 0 else '1';
  caps(44).c_irq_enable    <= (others => '0') when C_CAP44_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP44_IRQ_ENABLE,15);
  caps(44).c_irq_status    <= (others => '0') when C_CAP44_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP44_IRQ_STATUS,15);
  caps(44).c_base          <= conv_std_logic_vector(C_CAP44_BASE,32);
  caps(44).c_size          <= conv_std_logic_vector(C_CAP44_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(44).c_next          <= C_BASEADDR + conv_std_logic_vector((44+1)*64,16) when 44 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 45
  caps(45).c_type          <= conv_std_logic_vector(C_CAP45_TYPE,16);
  caps(45).c_version       <= conv_std_logic_vector(C_CAP45_VERSION,8);
  caps(45).c_irq           <= conv_std_logic_vector(C_CAP45_IRQ,8);
  caps(45).c_id_associated <= conv_std_logic_vector(C_CAP45_ID_ASSOCIATED,16);
  caps(45).c_id_component  <= conv_std_logic_vector(C_CAP45_ID_COMPONENT,16);
  caps(45).c_irq_enable_en <= '0' when C_CAP45_IRQ_ENABLE_EN = 0 else '1';
  caps(45).c_irq_status_en <= '0' when C_CAP45_IRQ_STATUS_EN = 0 else '1';
  caps(45).c_irq_enable    <= (others => '0') when C_CAP45_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP45_IRQ_ENABLE,15);
  caps(45).c_irq_status    <= (others => '0') when C_CAP45_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP45_IRQ_STATUS,15);
  caps(45).c_base          <= conv_std_logic_vector(C_CAP45_BASE,32);
  caps(45).c_size          <= conv_std_logic_vector(C_CAP45_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(45).c_next          <= C_BASEADDR + conv_std_logic_vector((45+1)*64,16) when 45 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 46
  caps(46).c_type          <= conv_std_logic_vector(C_CAP46_TYPE,16);
  caps(46).c_version       <= conv_std_logic_vector(C_CAP46_VERSION,8);
  caps(46).c_irq           <= conv_std_logic_vector(C_CAP46_IRQ,8);
  caps(46).c_id_associated <= conv_std_logic_vector(C_CAP46_ID_ASSOCIATED,16);
  caps(46).c_id_component  <= conv_std_logic_vector(C_CAP46_ID_COMPONENT,16);
  caps(46).c_irq_enable_en <= '0' when C_CAP46_IRQ_ENABLE_EN = 0 else '1';
  caps(46).c_irq_status_en <= '0' when C_CAP46_IRQ_STATUS_EN = 0 else '1';
  caps(46).c_irq_enable    <= (others => '0') when C_CAP46_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP46_IRQ_ENABLE,15);
  caps(46).c_irq_status    <= (others => '0') when C_CAP46_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP46_IRQ_STATUS,15);
  caps(46).c_base          <= conv_std_logic_vector(C_CAP46_BASE,32);
  caps(46).c_size          <= conv_std_logic_vector(C_CAP46_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(46).c_next          <= C_BASEADDR + conv_std_logic_vector((46+1)*64,16) when 46 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 47
  caps(47).c_type          <= conv_std_logic_vector(C_CAP47_TYPE,16);
  caps(47).c_version       <= conv_std_logic_vector(C_CAP47_VERSION,8);
  caps(47).c_irq           <= conv_std_logic_vector(C_CAP47_IRQ,8);
  caps(47).c_id_associated <= conv_std_logic_vector(C_CAP47_ID_ASSOCIATED,16);
  caps(47).c_id_component  <= conv_std_logic_vector(C_CAP47_ID_COMPONENT,16);
  caps(47).c_irq_enable_en <= '0' when C_CAP47_IRQ_ENABLE_EN = 0 else '1';
  caps(47).c_irq_status_en <= '0' when C_CAP47_IRQ_STATUS_EN = 0 else '1';
  caps(47).c_irq_enable    <= (others => '0') when C_CAP47_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP47_IRQ_ENABLE,15);
  caps(47).c_irq_status    <= (others => '0') when C_CAP47_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP47_IRQ_STATUS,15);
  caps(47).c_base          <= conv_std_logic_vector(C_CAP47_BASE,32);
  caps(47).c_size          <= conv_std_logic_vector(C_CAP47_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(47).c_next          <= C_BASEADDR + conv_std_logic_vector((47+1)*64,16) when 47 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 48
  caps(48).c_type          <= conv_std_logic_vector(C_CAP48_TYPE,16);
  caps(48).c_version       <= conv_std_logic_vector(C_CAP48_VERSION,8);
  caps(48).c_irq           <= conv_std_logic_vector(C_CAP48_IRQ,8);
  caps(48).c_id_associated <= conv_std_logic_vector(C_CAP48_ID_ASSOCIATED,16);
  caps(48).c_id_component  <= conv_std_logic_vector(C_CAP48_ID_COMPONENT,16);
  caps(48).c_irq_enable_en <= '0' when C_CAP48_IRQ_ENABLE_EN = 0 else '1';
  caps(48).c_irq_status_en <= '0' when C_CAP48_IRQ_STATUS_EN = 0 else '1';
  caps(48).c_irq_enable    <= (others => '0') when C_CAP48_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP48_IRQ_ENABLE,15);
  caps(48).c_irq_status    <= (others => '0') when C_CAP48_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP48_IRQ_STATUS,15);
  caps(48).c_base          <= conv_std_logic_vector(C_CAP48_BASE,32);
  caps(48).c_size          <= conv_std_logic_vector(C_CAP48_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(48).c_next          <= C_BASEADDR + conv_std_logic_vector((48+1)*64,16) when 48 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 49
  caps(49).c_type          <= conv_std_logic_vector(C_CAP49_TYPE,16);
  caps(49).c_version       <= conv_std_logic_vector(C_CAP49_VERSION,8);
  caps(49).c_irq           <= conv_std_logic_vector(C_CAP49_IRQ,8);
  caps(49).c_id_associated <= conv_std_logic_vector(C_CAP49_ID_ASSOCIATED,16);
  caps(49).c_id_component  <= conv_std_logic_vector(C_CAP49_ID_COMPONENT,16);
  caps(49).c_irq_enable_en <= '0' when C_CAP49_IRQ_ENABLE_EN = 0 else '1';
  caps(49).c_irq_status_en <= '0' when C_CAP49_IRQ_STATUS_EN = 0 else '1';
  caps(49).c_irq_enable    <= (others => '0') when C_CAP49_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP49_IRQ_ENABLE,15);
  caps(49).c_irq_status    <= (others => '0') when C_CAP49_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP49_IRQ_STATUS,15);
  caps(49).c_base          <= conv_std_logic_vector(C_CAP49_BASE,32);
  caps(49).c_size          <= conv_std_logic_vector(C_CAP49_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(49).c_next          <= C_BASEADDR + conv_std_logic_vector((49+1)*64,16) when 49 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 50
  caps(50).c_type          <= conv_std_logic_vector(C_CAP50_TYPE,16);
  caps(50).c_version       <= conv_std_logic_vector(C_CAP50_VERSION,8);
  caps(50).c_irq           <= conv_std_logic_vector(C_CAP50_IRQ,8);
  caps(50).c_id_associated <= conv_std_logic_vector(C_CAP50_ID_ASSOCIATED,16);
  caps(50).c_id_component  <= conv_std_logic_vector(C_CAP50_ID_COMPONENT,16);
  caps(50).c_irq_enable_en <= '0' when C_CAP50_IRQ_ENABLE_EN = 0 else '1';
  caps(50).c_irq_status_en <= '0' when C_CAP50_IRQ_STATUS_EN = 0 else '1';
  caps(50).c_irq_enable    <= (others => '0') when C_CAP50_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP50_IRQ_ENABLE,15);
  caps(50).c_irq_status    <= (others => '0') when C_CAP50_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP50_IRQ_STATUS,15);
  caps(50).c_base          <= conv_std_logic_vector(C_CAP50_BASE,32);
  caps(50).c_size          <= conv_std_logic_vector(C_CAP50_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(50).c_next          <= C_BASEADDR + conv_std_logic_vector((50+1)*64,16) when 50 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 51
  caps(51).c_type          <= conv_std_logic_vector(C_CAP51_TYPE,16);
  caps(51).c_version       <= conv_std_logic_vector(C_CAP51_VERSION,8);
  caps(51).c_irq           <= conv_std_logic_vector(C_CAP51_IRQ,8);
  caps(51).c_id_associated <= conv_std_logic_vector(C_CAP51_ID_ASSOCIATED,16);
  caps(51).c_id_component  <= conv_std_logic_vector(C_CAP51_ID_COMPONENT,16);
  caps(51).c_irq_enable_en <= '0' when C_CAP51_IRQ_ENABLE_EN = 0 else '1';
  caps(51).c_irq_status_en <= '0' when C_CAP51_IRQ_STATUS_EN = 0 else '1';
  caps(51).c_irq_enable    <= (others => '0') when C_CAP51_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP51_IRQ_ENABLE,15);
  caps(51).c_irq_status    <= (others => '0') when C_CAP51_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP51_IRQ_STATUS,15);
  caps(51).c_base          <= conv_std_logic_vector(C_CAP51_BASE,32);
  caps(51).c_size          <= conv_std_logic_vector(C_CAP51_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(51).c_next          <= C_BASEADDR + conv_std_logic_vector((51+1)*64,16) when 51 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 52
  caps(52).c_type          <= conv_std_logic_vector(C_CAP52_TYPE,16);
  caps(52).c_version       <= conv_std_logic_vector(C_CAP52_VERSION,8);
  caps(52).c_irq           <= conv_std_logic_vector(C_CAP52_IRQ,8);
  caps(52).c_id_associated <= conv_std_logic_vector(C_CAP52_ID_ASSOCIATED,16);
  caps(52).c_id_component  <= conv_std_logic_vector(C_CAP52_ID_COMPONENT,16);
  caps(52).c_irq_enable_en <= '0' when C_CAP52_IRQ_ENABLE_EN = 0 else '1';
  caps(52).c_irq_status_en <= '0' when C_CAP52_IRQ_STATUS_EN = 0 else '1';
  caps(52).c_irq_enable    <= (others => '0') when C_CAP52_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP52_IRQ_ENABLE,15);
  caps(52).c_irq_status    <= (others => '0') when C_CAP52_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP52_IRQ_STATUS,15);
  caps(52).c_base          <= conv_std_logic_vector(C_CAP52_BASE,32);
  caps(52).c_size          <= conv_std_logic_vector(C_CAP52_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(52).c_next          <= C_BASEADDR + conv_std_logic_vector((52+1)*64,16) when 52 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 53
  caps(53).c_type          <= conv_std_logic_vector(C_CAP53_TYPE,16);
  caps(53).c_version       <= conv_std_logic_vector(C_CAP53_VERSION,8);
  caps(53).c_irq           <= conv_std_logic_vector(C_CAP53_IRQ,8);
  caps(53).c_id_associated <= conv_std_logic_vector(C_CAP53_ID_ASSOCIATED,16);
  caps(53).c_id_component  <= conv_std_logic_vector(C_CAP53_ID_COMPONENT,16);
  caps(53).c_irq_enable_en <= '0' when C_CAP53_IRQ_ENABLE_EN = 0 else '1';
  caps(53).c_irq_status_en <= '0' when C_CAP53_IRQ_STATUS_EN = 0 else '1';
  caps(53).c_irq_enable    <= (others => '0') when C_CAP53_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP53_IRQ_ENABLE,15);
  caps(53).c_irq_status    <= (others => '0') when C_CAP53_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP53_IRQ_STATUS,15);
  caps(53).c_base          <= conv_std_logic_vector(C_CAP53_BASE,32);
  caps(53).c_size          <= conv_std_logic_vector(C_CAP53_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(53).c_next          <= C_BASEADDR + conv_std_logic_vector((53+1)*64,16) when 53 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 54
  caps(54).c_type          <= conv_std_logic_vector(C_CAP54_TYPE,16);
  caps(54).c_version       <= conv_std_logic_vector(C_CAP54_VERSION,8);
  caps(54).c_irq           <= conv_std_logic_vector(C_CAP54_IRQ,8);
  caps(54).c_id_associated <= conv_std_logic_vector(C_CAP54_ID_ASSOCIATED,16);
  caps(54).c_id_component  <= conv_std_logic_vector(C_CAP54_ID_COMPONENT,16);
  caps(54).c_irq_enable_en <= '0' when C_CAP54_IRQ_ENABLE_EN = 0 else '1';
  caps(54).c_irq_status_en <= '0' when C_CAP54_IRQ_STATUS_EN = 0 else '1';
  caps(54).c_irq_enable    <= (others => '0') when C_CAP54_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP54_IRQ_ENABLE,15);
  caps(54).c_irq_status    <= (others => '0') when C_CAP54_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP54_IRQ_STATUS,15);
  caps(54).c_base          <= conv_std_logic_vector(C_CAP54_BASE,32);
  caps(54).c_size          <= conv_std_logic_vector(C_CAP54_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(54).c_next          <= C_BASEADDR + conv_std_logic_vector((54+1)*64,16) when 54 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 55
  caps(55).c_type          <= conv_std_logic_vector(C_CAP55_TYPE,16);
  caps(55).c_version       <= conv_std_logic_vector(C_CAP55_VERSION,8);
  caps(55).c_irq           <= conv_std_logic_vector(C_CAP55_IRQ,8);
  caps(55).c_id_associated <= conv_std_logic_vector(C_CAP55_ID_ASSOCIATED,16);
  caps(55).c_id_component  <= conv_std_logic_vector(C_CAP55_ID_COMPONENT,16);
  caps(55).c_irq_enable_en <= '0' when C_CAP55_IRQ_ENABLE_EN = 0 else '1';
  caps(55).c_irq_status_en <= '0' when C_CAP55_IRQ_STATUS_EN = 0 else '1';
  caps(55).c_irq_enable    <= (others => '0') when C_CAP55_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP55_IRQ_ENABLE,15);
  caps(55).c_irq_status    <= (others => '0') when C_CAP55_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP55_IRQ_STATUS,15);
  caps(55).c_base          <= conv_std_logic_vector(C_CAP55_BASE,32);
  caps(55).c_size          <= conv_std_logic_vector(C_CAP55_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(55).c_next          <= C_BASEADDR + conv_std_logic_vector((55+1)*64,16) when 55 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 56
  caps(56).c_type          <= conv_std_logic_vector(C_CAP56_TYPE,16);
  caps(56).c_version       <= conv_std_logic_vector(C_CAP56_VERSION,8);
  caps(56).c_irq           <= conv_std_logic_vector(C_CAP56_IRQ,8);
  caps(56).c_id_associated <= conv_std_logic_vector(C_CAP56_ID_ASSOCIATED,16);
  caps(56).c_id_component  <= conv_std_logic_vector(C_CAP56_ID_COMPONENT,16);
  caps(56).c_irq_enable_en <= '0' when C_CAP56_IRQ_ENABLE_EN = 0 else '1';
  caps(56).c_irq_status_en <= '0' when C_CAP56_IRQ_STATUS_EN = 0 else '1';
  caps(56).c_irq_enable    <= (others => '0') when C_CAP56_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP56_IRQ_ENABLE,15);
  caps(56).c_irq_status    <= (others => '0') when C_CAP56_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP56_IRQ_STATUS,15);
  caps(56).c_base          <= conv_std_logic_vector(C_CAP56_BASE,32);
  caps(56).c_size          <= conv_std_logic_vector(C_CAP56_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(56).c_next          <= C_BASEADDR + conv_std_logic_vector((56+1)*64,16) when 56 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 57
  caps(57).c_type          <= conv_std_logic_vector(C_CAP57_TYPE,16);
  caps(57).c_version       <= conv_std_logic_vector(C_CAP57_VERSION,8);
  caps(57).c_irq           <= conv_std_logic_vector(C_CAP57_IRQ,8);
  caps(57).c_id_associated <= conv_std_logic_vector(C_CAP57_ID_ASSOCIATED,16);
  caps(57).c_id_component  <= conv_std_logic_vector(C_CAP57_ID_COMPONENT,16);
  caps(57).c_irq_enable_en <= '0' when C_CAP57_IRQ_ENABLE_EN = 0 else '1';
  caps(57).c_irq_status_en <= '0' when C_CAP57_IRQ_STATUS_EN = 0 else '1';
  caps(57).c_irq_enable    <= (others => '0') when C_CAP57_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP57_IRQ_ENABLE,15);
  caps(57).c_irq_status    <= (others => '0') when C_CAP57_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP57_IRQ_STATUS,15);
  caps(57).c_base          <= conv_std_logic_vector(C_CAP57_BASE,32);
  caps(57).c_size          <= conv_std_logic_vector(C_CAP57_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(57).c_next          <= C_BASEADDR + conv_std_logic_vector((57+1)*64,16) when 57 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 58
  caps(58).c_type          <= conv_std_logic_vector(C_CAP58_TYPE,16);
  caps(58).c_version       <= conv_std_logic_vector(C_CAP58_VERSION,8);
  caps(58).c_irq           <= conv_std_logic_vector(C_CAP58_IRQ,8);
  caps(58).c_id_associated <= conv_std_logic_vector(C_CAP58_ID_ASSOCIATED,16);
  caps(58).c_id_component  <= conv_std_logic_vector(C_CAP58_ID_COMPONENT,16);
  caps(58).c_irq_enable_en <= '0' when C_CAP58_IRQ_ENABLE_EN = 0 else '1';
  caps(58).c_irq_status_en <= '0' when C_CAP58_IRQ_STATUS_EN = 0 else '1';
  caps(58).c_irq_enable    <= (others => '0') when C_CAP58_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP58_IRQ_ENABLE,15);
  caps(58).c_irq_status    <= (others => '0') when C_CAP58_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP58_IRQ_STATUS,15);
  caps(58).c_base          <= conv_std_logic_vector(C_CAP58_BASE,32);
  caps(58).c_size          <= conv_std_logic_vector(C_CAP58_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(58).c_next          <= C_BASEADDR + conv_std_logic_vector((58+1)*64,16) when 58 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 59
  caps(59).c_type          <= conv_std_logic_vector(C_CAP59_TYPE,16);
  caps(59).c_version       <= conv_std_logic_vector(C_CAP59_VERSION,8);
  caps(59).c_irq           <= conv_std_logic_vector(C_CAP59_IRQ,8);
  caps(59).c_id_associated <= conv_std_logic_vector(C_CAP59_ID_ASSOCIATED,16);
  caps(59).c_id_component  <= conv_std_logic_vector(C_CAP59_ID_COMPONENT,16);
  caps(59).c_irq_enable_en <= '0' when C_CAP59_IRQ_ENABLE_EN = 0 else '1';
  caps(59).c_irq_status_en <= '0' when C_CAP59_IRQ_STATUS_EN = 0 else '1';
  caps(59).c_irq_enable    <= (others => '0') when C_CAP59_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP59_IRQ_ENABLE,15);
  caps(59).c_irq_status    <= (others => '0') when C_CAP59_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP59_IRQ_STATUS,15);
  caps(59).c_base          <= conv_std_logic_vector(C_CAP59_BASE,32);
  caps(59).c_size          <= conv_std_logic_vector(C_CAP59_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(59).c_next          <= C_BASEADDR + conv_std_logic_vector((59+1)*64,16) when 59 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 60
  caps(60).c_type          <= conv_std_logic_vector(C_CAP60_TYPE,16);
  caps(60).c_version       <= conv_std_logic_vector(C_CAP60_VERSION,8);
  caps(60).c_irq           <= conv_std_logic_vector(C_CAP60_IRQ,8);
  caps(60).c_id_associated <= conv_std_logic_vector(C_CAP60_ID_ASSOCIATED,16);
  caps(60).c_id_component  <= conv_std_logic_vector(C_CAP60_ID_COMPONENT,16);
  caps(60).c_irq_enable_en <= '0' when C_CAP60_IRQ_ENABLE_EN = 0 else '1';
  caps(60).c_irq_status_en <= '0' when C_CAP60_IRQ_STATUS_EN = 0 else '1';
  caps(60).c_irq_enable    <= (others => '0') when C_CAP60_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP60_IRQ_ENABLE,15);
  caps(60).c_irq_status    <= (others => '0') when C_CAP60_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP60_IRQ_STATUS,15);
  caps(60).c_base          <= conv_std_logic_vector(C_CAP60_BASE,32);
  caps(60).c_size          <= conv_std_logic_vector(C_CAP60_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(60).c_next          <= C_BASEADDR + conv_std_logic_vector((60+1)*64,16) when 60 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 61
  caps(61).c_type          <= conv_std_logic_vector(C_CAP61_TYPE,16);
  caps(61).c_version       <= conv_std_logic_vector(C_CAP61_VERSION,8);
  caps(61).c_irq           <= conv_std_logic_vector(C_CAP61_IRQ,8);
  caps(61).c_id_associated <= conv_std_logic_vector(C_CAP61_ID_ASSOCIATED,16);
  caps(61).c_id_component  <= conv_std_logic_vector(C_CAP61_ID_COMPONENT,16);
  caps(61).c_irq_enable_en <= '0' when C_CAP61_IRQ_ENABLE_EN = 0 else '1';
  caps(61).c_irq_status_en <= '0' when C_CAP61_IRQ_STATUS_EN = 0 else '1';
  caps(61).c_irq_enable    <= (others => '0') when C_CAP61_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP61_IRQ_ENABLE,15);
  caps(61).c_irq_status    <= (others => '0') when C_CAP61_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP61_IRQ_STATUS,15);
  caps(61).c_base          <= conv_std_logic_vector(C_CAP61_BASE,32);
  caps(61).c_size          <= conv_std_logic_vector(C_CAP61_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(61).c_next          <= C_BASEADDR + conv_std_logic_vector((61+1)*64,16) when 61 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 62
  caps(62).c_type          <= conv_std_logic_vector(C_CAP62_TYPE,16);
  caps(62).c_version       <= conv_std_logic_vector(C_CAP62_VERSION,8);
  caps(62).c_irq           <= conv_std_logic_vector(C_CAP62_IRQ,8);
  caps(62).c_id_associated <= conv_std_logic_vector(C_CAP62_ID_ASSOCIATED,16);
  caps(62).c_id_component  <= conv_std_logic_vector(C_CAP62_ID_COMPONENT,16);
  caps(62).c_irq_enable_en <= '0' when C_CAP62_IRQ_ENABLE_EN = 0 else '1';
  caps(62).c_irq_status_en <= '0' when C_CAP62_IRQ_STATUS_EN = 0 else '1';
  caps(62).c_irq_enable    <= (others => '0') when C_CAP62_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP62_IRQ_ENABLE,15);
  caps(62).c_irq_status    <= (others => '0') when C_CAP62_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP62_IRQ_STATUS,15);
  caps(62).c_base          <= conv_std_logic_vector(C_CAP62_BASE,32);
  caps(62).c_size          <= conv_std_logic_vector(C_CAP62_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(62).c_next          <= C_BASEADDR + conv_std_logic_vector((62+1)*64,16) when 62 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 63
  caps(63).c_type          <= conv_std_logic_vector(C_CAP63_TYPE,16);
  caps(63).c_version       <= conv_std_logic_vector(C_CAP63_VERSION,8);
  caps(63).c_irq           <= conv_std_logic_vector(C_CAP63_IRQ,8);
  caps(63).c_id_associated <= conv_std_logic_vector(C_CAP63_ID_ASSOCIATED,16);
  caps(63).c_id_component  <= conv_std_logic_vector(C_CAP63_ID_COMPONENT,16);
  caps(63).c_irq_enable_en <= '0' when C_CAP63_IRQ_ENABLE_EN = 0 else '1';
  caps(63).c_irq_status_en <= '0' when C_CAP63_IRQ_STATUS_EN = 0 else '1';
  caps(63).c_irq_enable    <= (others => '0') when C_CAP63_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP63_IRQ_ENABLE,15);
  caps(63).c_irq_status    <= (others => '0') when C_CAP63_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP63_IRQ_STATUS,15);
  caps(63).c_base          <= conv_std_logic_vector(C_CAP63_BASE,32);
  caps(63).c_size          <= conv_std_logic_vector(C_CAP63_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(63).c_next          <= C_BASEADDR + conv_std_logic_vector((63+1)*64,16) when 63 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 64
  caps(64).c_type          <= conv_std_logic_vector(C_CAP64_TYPE,16);
  caps(64).c_version       <= conv_std_logic_vector(C_CAP64_VERSION,8);
  caps(64).c_irq           <= conv_std_logic_vector(C_CAP64_IRQ,8);
  caps(64).c_id_associated <= conv_std_logic_vector(C_CAP64_ID_ASSOCIATED,16);
  caps(64).c_id_component  <= conv_std_logic_vector(C_CAP64_ID_COMPONENT,16);
  caps(64).c_irq_enable_en <= '0' when C_CAP64_IRQ_ENABLE_EN = 0 else '1';
  caps(64).c_irq_status_en <= '0' when C_CAP64_IRQ_STATUS_EN = 0 else '1';
  caps(64).c_irq_enable    <= (others => '0') when C_CAP64_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP64_IRQ_ENABLE,15);
  caps(64).c_irq_status    <= (others => '0') when C_CAP64_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP64_IRQ_STATUS,15);
  caps(64).c_base          <= conv_std_logic_vector(C_CAP64_BASE,32);
  caps(64).c_size          <= conv_std_logic_vector(C_CAP64_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(64).c_next          <= C_BASEADDR + conv_std_logic_vector((64+1)*64,16) when 64 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 65
  caps(65).c_type          <= conv_std_logic_vector(C_CAP65_TYPE,16);
  caps(65).c_version       <= conv_std_logic_vector(C_CAP65_VERSION,8);
  caps(65).c_irq           <= conv_std_logic_vector(C_CAP65_IRQ,8);
  caps(65).c_id_associated <= conv_std_logic_vector(C_CAP65_ID_ASSOCIATED,16);
  caps(65).c_id_component  <= conv_std_logic_vector(C_CAP65_ID_COMPONENT,16);
  caps(65).c_irq_enable_en <= '0' when C_CAP65_IRQ_ENABLE_EN = 0 else '1';
  caps(65).c_irq_status_en <= '0' when C_CAP65_IRQ_STATUS_EN = 0 else '1';
  caps(65).c_irq_enable    <= (others => '0') when C_CAP65_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP65_IRQ_ENABLE,15);
  caps(65).c_irq_status    <= (others => '0') when C_CAP65_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP65_IRQ_STATUS,15);
  caps(65).c_base          <= conv_std_logic_vector(C_CAP65_BASE,32);
  caps(65).c_size          <= conv_std_logic_vector(C_CAP65_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(65).c_next          <= C_BASEADDR + conv_std_logic_vector((65+1)*64,16) when 65 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 66
  caps(66).c_type          <= conv_std_logic_vector(C_CAP66_TYPE,16);
  caps(66).c_version       <= conv_std_logic_vector(C_CAP66_VERSION,8);
  caps(66).c_irq           <= conv_std_logic_vector(C_CAP66_IRQ,8);
  caps(66).c_id_associated <= conv_std_logic_vector(C_CAP66_ID_ASSOCIATED,16);
  caps(66).c_id_component  <= conv_std_logic_vector(C_CAP66_ID_COMPONENT,16);
  caps(66).c_irq_enable_en <= '0' when C_CAP66_IRQ_ENABLE_EN = 0 else '1';
  caps(66).c_irq_status_en <= '0' when C_CAP66_IRQ_STATUS_EN = 0 else '1';
  caps(66).c_irq_enable    <= (others => '0') when C_CAP66_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP66_IRQ_ENABLE,15);
  caps(66).c_irq_status    <= (others => '0') when C_CAP66_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP66_IRQ_STATUS,15);
  caps(66).c_base          <= conv_std_logic_vector(C_CAP66_BASE,32);
  caps(66).c_size          <= conv_std_logic_vector(C_CAP66_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(66).c_next          <= C_BASEADDR + conv_std_logic_vector((66+1)*64,16) when 66 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 67
  caps(67).c_type          <= conv_std_logic_vector(C_CAP67_TYPE,16);
  caps(67).c_version       <= conv_std_logic_vector(C_CAP67_VERSION,8);
  caps(67).c_irq           <= conv_std_logic_vector(C_CAP67_IRQ,8);
  caps(67).c_id_associated <= conv_std_logic_vector(C_CAP67_ID_ASSOCIATED,16);
  caps(67).c_id_component  <= conv_std_logic_vector(C_CAP67_ID_COMPONENT,16);
  caps(67).c_irq_enable_en <= '0' when C_CAP67_IRQ_ENABLE_EN = 0 else '1';
  caps(67).c_irq_status_en <= '0' when C_CAP67_IRQ_STATUS_EN = 0 else '1';
  caps(67).c_irq_enable    <= (others => '0') when C_CAP67_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP67_IRQ_ENABLE,15);
  caps(67).c_irq_status    <= (others => '0') when C_CAP67_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP67_IRQ_STATUS,15);
  caps(67).c_base          <= conv_std_logic_vector(C_CAP67_BASE,32);
  caps(67).c_size          <= conv_std_logic_vector(C_CAP67_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(67).c_next          <= C_BASEADDR + conv_std_logic_vector((67+1)*64,16) when 67 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 68
  caps(68).c_type          <= conv_std_logic_vector(C_CAP68_TYPE,16);
  caps(68).c_version       <= conv_std_logic_vector(C_CAP68_VERSION,8);
  caps(68).c_irq           <= conv_std_logic_vector(C_CAP68_IRQ,8);
  caps(68).c_id_associated <= conv_std_logic_vector(C_CAP68_ID_ASSOCIATED,16);
  caps(68).c_id_component  <= conv_std_logic_vector(C_CAP68_ID_COMPONENT,16);
  caps(68).c_irq_enable_en <= '0' when C_CAP68_IRQ_ENABLE_EN = 0 else '1';
  caps(68).c_irq_status_en <= '0' when C_CAP68_IRQ_STATUS_EN = 0 else '1';
  caps(68).c_irq_enable    <= (others => '0') when C_CAP68_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP68_IRQ_ENABLE,15);
  caps(68).c_irq_status    <= (others => '0') when C_CAP68_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP68_IRQ_STATUS,15);
  caps(68).c_base          <= conv_std_logic_vector(C_CAP68_BASE,32);
  caps(68).c_size          <= conv_std_logic_vector(C_CAP68_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(68).c_next          <= C_BASEADDR + conv_std_logic_vector((68+1)*64,16) when 68 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 69
  caps(69).c_type          <= conv_std_logic_vector(C_CAP69_TYPE,16);
  caps(69).c_version       <= conv_std_logic_vector(C_CAP69_VERSION,8);
  caps(69).c_irq           <= conv_std_logic_vector(C_CAP69_IRQ,8);
  caps(69).c_id_associated <= conv_std_logic_vector(C_CAP69_ID_ASSOCIATED,16);
  caps(69).c_id_component  <= conv_std_logic_vector(C_CAP69_ID_COMPONENT,16);
  caps(69).c_irq_enable_en <= '0' when C_CAP69_IRQ_ENABLE_EN = 0 else '1';
  caps(69).c_irq_status_en <= '0' when C_CAP69_IRQ_STATUS_EN = 0 else '1';
  caps(69).c_irq_enable    <= (others => '0') when C_CAP69_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP69_IRQ_ENABLE,15);
  caps(69).c_irq_status    <= (others => '0') when C_CAP69_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP69_IRQ_STATUS,15);
  caps(69).c_base          <= conv_std_logic_vector(C_CAP69_BASE,32);
  caps(69).c_size          <= conv_std_logic_vector(C_CAP69_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(69).c_next          <= C_BASEADDR + conv_std_logic_vector((69+1)*64,16) when 69 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 70
  caps(70).c_type          <= conv_std_logic_vector(C_CAP70_TYPE,16);
  caps(70).c_version       <= conv_std_logic_vector(C_CAP70_VERSION,8);
  caps(70).c_irq           <= conv_std_logic_vector(C_CAP70_IRQ,8);
  caps(70).c_id_associated <= conv_std_logic_vector(C_CAP70_ID_ASSOCIATED,16);
  caps(70).c_id_component  <= conv_std_logic_vector(C_CAP70_ID_COMPONENT,16);
  caps(70).c_irq_enable_en <= '0' when C_CAP70_IRQ_ENABLE_EN = 0 else '1';
  caps(70).c_irq_status_en <= '0' when C_CAP70_IRQ_STATUS_EN = 0 else '1';
  caps(70).c_irq_enable    <= (others => '0') when C_CAP70_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP70_IRQ_ENABLE,15);
  caps(70).c_irq_status    <= (others => '0') when C_CAP70_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP70_IRQ_STATUS,15);
  caps(70).c_base          <= conv_std_logic_vector(C_CAP70_BASE,32);
  caps(70).c_size          <= conv_std_logic_vector(C_CAP70_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(70).c_next          <= C_BASEADDR + conv_std_logic_vector((70+1)*64,16) when 70 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 71
  caps(71).c_type          <= conv_std_logic_vector(C_CAP71_TYPE,16);
  caps(71).c_version       <= conv_std_logic_vector(C_CAP71_VERSION,8);
  caps(71).c_irq           <= conv_std_logic_vector(C_CAP71_IRQ,8);
  caps(71).c_id_associated <= conv_std_logic_vector(C_CAP71_ID_ASSOCIATED,16);
  caps(71).c_id_component  <= conv_std_logic_vector(C_CAP71_ID_COMPONENT,16);
  caps(71).c_irq_enable_en <= '0' when C_CAP71_IRQ_ENABLE_EN = 0 else '1';
  caps(71).c_irq_status_en <= '0' when C_CAP71_IRQ_STATUS_EN = 0 else '1';
  caps(71).c_irq_enable    <= (others => '0') when C_CAP71_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP71_IRQ_ENABLE,15);
  caps(71).c_irq_status    <= (others => '0') when C_CAP71_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP71_IRQ_STATUS,15);
  caps(71).c_base          <= conv_std_logic_vector(C_CAP71_BASE,32);
  caps(71).c_size          <= conv_std_logic_vector(C_CAP71_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(71).c_next          <= C_BASEADDR + conv_std_logic_vector((71+1)*64,16) when 71 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 72
  caps(72).c_type          <= conv_std_logic_vector(C_CAP72_TYPE,16);
  caps(72).c_version       <= conv_std_logic_vector(C_CAP72_VERSION,8);
  caps(72).c_irq           <= conv_std_logic_vector(C_CAP72_IRQ,8);
  caps(72).c_id_associated <= conv_std_logic_vector(C_CAP72_ID_ASSOCIATED,16);
  caps(72).c_id_component  <= conv_std_logic_vector(C_CAP72_ID_COMPONENT,16);
  caps(72).c_irq_enable_en <= '0' when C_CAP72_IRQ_ENABLE_EN = 0 else '1';
  caps(72).c_irq_status_en <= '0' when C_CAP72_IRQ_STATUS_EN = 0 else '1';
  caps(72).c_irq_enable    <= (others => '0') when C_CAP72_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP72_IRQ_ENABLE,15);
  caps(72).c_irq_status    <= (others => '0') when C_CAP72_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP72_IRQ_STATUS,15);
  caps(72).c_base          <= conv_std_logic_vector(C_CAP72_BASE,32);
  caps(72).c_size          <= conv_std_logic_vector(C_CAP72_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(72).c_next          <= C_BASEADDR + conv_std_logic_vector((72+1)*64,16) when 72 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 73
  caps(73).c_type          <= conv_std_logic_vector(C_CAP73_TYPE,16);
  caps(73).c_version       <= conv_std_logic_vector(C_CAP73_VERSION,8);
  caps(73).c_irq           <= conv_std_logic_vector(C_CAP73_IRQ,8);
  caps(73).c_id_associated <= conv_std_logic_vector(C_CAP73_ID_ASSOCIATED,16);
  caps(73).c_id_component  <= conv_std_logic_vector(C_CAP73_ID_COMPONENT,16);
  caps(73).c_irq_enable_en <= '0' when C_CAP73_IRQ_ENABLE_EN = 0 else '1';
  caps(73).c_irq_status_en <= '0' when C_CAP73_IRQ_STATUS_EN = 0 else '1';
  caps(73).c_irq_enable    <= (others => '0') when C_CAP73_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP73_IRQ_ENABLE,15);
  caps(73).c_irq_status    <= (others => '0') when C_CAP73_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP73_IRQ_STATUS,15);
  caps(73).c_base          <= conv_std_logic_vector(C_CAP73_BASE,32);
  caps(73).c_size          <= conv_std_logic_vector(C_CAP73_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(73).c_next          <= C_BASEADDR + conv_std_logic_vector((73+1)*64,16) when 73 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 74
  caps(74).c_type          <= conv_std_logic_vector(C_CAP74_TYPE,16);
  caps(74).c_version       <= conv_std_logic_vector(C_CAP74_VERSION,8);
  caps(74).c_irq           <= conv_std_logic_vector(C_CAP74_IRQ,8);
  caps(74).c_id_associated <= conv_std_logic_vector(C_CAP74_ID_ASSOCIATED,16);
  caps(74).c_id_component  <= conv_std_logic_vector(C_CAP74_ID_COMPONENT,16);
  caps(74).c_irq_enable_en <= '0' when C_CAP74_IRQ_ENABLE_EN = 0 else '1';
  caps(74).c_irq_status_en <= '0' when C_CAP74_IRQ_STATUS_EN = 0 else '1';
  caps(74).c_irq_enable    <= (others => '0') when C_CAP74_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP74_IRQ_ENABLE,15);
  caps(74).c_irq_status    <= (others => '0') when C_CAP74_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP74_IRQ_STATUS,15);
  caps(74).c_base          <= conv_std_logic_vector(C_CAP74_BASE,32);
  caps(74).c_size          <= conv_std_logic_vector(C_CAP74_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(74).c_next          <= C_BASEADDR + conv_std_logic_vector((74+1)*64,16) when 74 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 75
  caps(75).c_type          <= conv_std_logic_vector(C_CAP75_TYPE,16);
  caps(75).c_version       <= conv_std_logic_vector(C_CAP75_VERSION,8);
  caps(75).c_irq           <= conv_std_logic_vector(C_CAP75_IRQ,8);
  caps(75).c_id_associated <= conv_std_logic_vector(C_CAP75_ID_ASSOCIATED,16);
  caps(75).c_id_component  <= conv_std_logic_vector(C_CAP75_ID_COMPONENT,16);
  caps(75).c_irq_enable_en <= '0' when C_CAP75_IRQ_ENABLE_EN = 0 else '1';
  caps(75).c_irq_status_en <= '0' when C_CAP75_IRQ_STATUS_EN = 0 else '1';
  caps(75).c_irq_enable    <= (others => '0') when C_CAP75_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP75_IRQ_ENABLE,15);
  caps(75).c_irq_status    <= (others => '0') when C_CAP75_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP75_IRQ_STATUS,15);
  caps(75).c_base          <= conv_std_logic_vector(C_CAP75_BASE,32);
  caps(75).c_size          <= conv_std_logic_vector(C_CAP75_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(75).c_next          <= C_BASEADDR + conv_std_logic_vector((75+1)*64,16) when 75 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 76
  caps(76).c_type          <= conv_std_logic_vector(C_CAP76_TYPE,16);
  caps(76).c_version       <= conv_std_logic_vector(C_CAP76_VERSION,8);
  caps(76).c_irq           <= conv_std_logic_vector(C_CAP76_IRQ,8);
  caps(76).c_id_associated <= conv_std_logic_vector(C_CAP76_ID_ASSOCIATED,16);
  caps(76).c_id_component  <= conv_std_logic_vector(C_CAP76_ID_COMPONENT,16);
  caps(76).c_irq_enable_en <= '0' when C_CAP76_IRQ_ENABLE_EN = 0 else '1';
  caps(76).c_irq_status_en <= '0' when C_CAP76_IRQ_STATUS_EN = 0 else '1';
  caps(76).c_irq_enable    <= (others => '0') when C_CAP76_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP76_IRQ_ENABLE,15);
  caps(76).c_irq_status    <= (others => '0') when C_CAP76_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP76_IRQ_STATUS,15);
  caps(76).c_base          <= conv_std_logic_vector(C_CAP76_BASE,32);
  caps(76).c_size          <= conv_std_logic_vector(C_CAP76_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(76).c_next          <= C_BASEADDR + conv_std_logic_vector((76+1)*64,16) when 76 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 77
  caps(77).c_type          <= conv_std_logic_vector(C_CAP77_TYPE,16);
  caps(77).c_version       <= conv_std_logic_vector(C_CAP77_VERSION,8);
  caps(77).c_irq           <= conv_std_logic_vector(C_CAP77_IRQ,8);
  caps(77).c_id_associated <= conv_std_logic_vector(C_CAP77_ID_ASSOCIATED,16);
  caps(77).c_id_component  <= conv_std_logic_vector(C_CAP77_ID_COMPONENT,16);
  caps(77).c_irq_enable_en <= '0' when C_CAP77_IRQ_ENABLE_EN = 0 else '1';
  caps(77).c_irq_status_en <= '0' when C_CAP77_IRQ_STATUS_EN = 0 else '1';
  caps(77).c_irq_enable    <= (others => '0') when C_CAP77_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP77_IRQ_ENABLE,15);
  caps(77).c_irq_status    <= (others => '0') when C_CAP77_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP77_IRQ_STATUS,15);
  caps(77).c_base          <= conv_std_logic_vector(C_CAP77_BASE,32);
  caps(77).c_size          <= conv_std_logic_vector(C_CAP77_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(77).c_next          <= C_BASEADDR + conv_std_logic_vector((77+1)*64,16) when 77 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 78
  caps(78).c_type          <= conv_std_logic_vector(C_CAP78_TYPE,16);
  caps(78).c_version       <= conv_std_logic_vector(C_CAP78_VERSION,8);
  caps(78).c_irq           <= conv_std_logic_vector(C_CAP78_IRQ,8);
  caps(78).c_id_associated <= conv_std_logic_vector(C_CAP78_ID_ASSOCIATED,16);
  caps(78).c_id_component  <= conv_std_logic_vector(C_CAP78_ID_COMPONENT,16);
  caps(78).c_irq_enable_en <= '0' when C_CAP78_IRQ_ENABLE_EN = 0 else '1';
  caps(78).c_irq_status_en <= '0' when C_CAP78_IRQ_STATUS_EN = 0 else '1';
  caps(78).c_irq_enable    <= (others => '0') when C_CAP78_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP78_IRQ_ENABLE,15);
  caps(78).c_irq_status    <= (others => '0') when C_CAP78_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP78_IRQ_STATUS,15);
  caps(78).c_base          <= conv_std_logic_vector(C_CAP78_BASE,32);
  caps(78).c_size          <= conv_std_logic_vector(C_CAP78_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(78).c_next          <= C_BASEADDR + conv_std_logic_vector((78+1)*64,16) when 78 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 79
  caps(79).c_type          <= conv_std_logic_vector(C_CAP79_TYPE,16);
  caps(79).c_version       <= conv_std_logic_vector(C_CAP79_VERSION,8);
  caps(79).c_irq           <= conv_std_logic_vector(C_CAP79_IRQ,8);
  caps(79).c_id_associated <= conv_std_logic_vector(C_CAP79_ID_ASSOCIATED,16);
  caps(79).c_id_component  <= conv_std_logic_vector(C_CAP79_ID_COMPONENT,16);
  caps(79).c_irq_enable_en <= '0' when C_CAP79_IRQ_ENABLE_EN = 0 else '1';
  caps(79).c_irq_status_en <= '0' when C_CAP79_IRQ_STATUS_EN = 0 else '1';
  caps(79).c_irq_enable    <= (others => '0') when C_CAP79_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP79_IRQ_ENABLE,15);
  caps(79).c_irq_status    <= (others => '0') when C_CAP79_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP79_IRQ_STATUS,15);
  caps(79).c_base          <= conv_std_logic_vector(C_CAP79_BASE,32);
  caps(79).c_size          <= conv_std_logic_vector(C_CAP79_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(79).c_next          <= C_BASEADDR + conv_std_logic_vector((79+1)*64,16) when 79 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 80
  caps(80).c_type          <= conv_std_logic_vector(C_CAP80_TYPE,16);
  caps(80).c_version       <= conv_std_logic_vector(C_CAP80_VERSION,8);
  caps(80).c_irq           <= conv_std_logic_vector(C_CAP80_IRQ,8);
  caps(80).c_id_associated <= conv_std_logic_vector(C_CAP80_ID_ASSOCIATED,16);
  caps(80).c_id_component  <= conv_std_logic_vector(C_CAP80_ID_COMPONENT,16);
  caps(80).c_irq_enable_en <= '0' when C_CAP80_IRQ_ENABLE_EN = 0 else '1';
  caps(80).c_irq_status_en <= '0' when C_CAP80_IRQ_STATUS_EN = 0 else '1';
  caps(80).c_irq_enable    <= (others => '0') when C_CAP80_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP80_IRQ_ENABLE,15);
  caps(80).c_irq_status    <= (others => '0') when C_CAP80_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP80_IRQ_STATUS,15);
  caps(80).c_base          <= conv_std_logic_vector(C_CAP80_BASE,32);
  caps(80).c_size          <= conv_std_logic_vector(C_CAP80_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(80).c_next          <= C_BASEADDR + conv_std_logic_vector((80+1)*64,16) when 80 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 81
  caps(81).c_type          <= conv_std_logic_vector(C_CAP81_TYPE,16);
  caps(81).c_version       <= conv_std_logic_vector(C_CAP81_VERSION,8);
  caps(81).c_irq           <= conv_std_logic_vector(C_CAP81_IRQ,8);
  caps(81).c_id_associated <= conv_std_logic_vector(C_CAP81_ID_ASSOCIATED,16);
  caps(81).c_id_component  <= conv_std_logic_vector(C_CAP81_ID_COMPONENT,16);
  caps(81).c_irq_enable_en <= '0' when C_CAP81_IRQ_ENABLE_EN = 0 else '1';
  caps(81).c_irq_status_en <= '0' when C_CAP81_IRQ_STATUS_EN = 0 else '1';
  caps(81).c_irq_enable    <= (others => '0') when C_CAP81_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP81_IRQ_ENABLE,15);
  caps(81).c_irq_status    <= (others => '0') when C_CAP81_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP81_IRQ_STATUS,15);
  caps(81).c_base          <= conv_std_logic_vector(C_CAP81_BASE,32);
  caps(81).c_size          <= conv_std_logic_vector(C_CAP81_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(81).c_next          <= C_BASEADDR + conv_std_logic_vector((81+1)*64,16) when 81 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 82
  caps(82).c_type          <= conv_std_logic_vector(C_CAP82_TYPE,16);
  caps(82).c_version       <= conv_std_logic_vector(C_CAP82_VERSION,8);
  caps(82).c_irq           <= conv_std_logic_vector(C_CAP82_IRQ,8);
  caps(82).c_id_associated <= conv_std_logic_vector(C_CAP82_ID_ASSOCIATED,16);
  caps(82).c_id_component  <= conv_std_logic_vector(C_CAP82_ID_COMPONENT,16);
  caps(82).c_irq_enable_en <= '0' when C_CAP82_IRQ_ENABLE_EN = 0 else '1';
  caps(82).c_irq_status_en <= '0' when C_CAP82_IRQ_STATUS_EN = 0 else '1';
  caps(82).c_irq_enable    <= (others => '0') when C_CAP82_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP82_IRQ_ENABLE,15);
  caps(82).c_irq_status    <= (others => '0') when C_CAP82_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP82_IRQ_STATUS,15);
  caps(82).c_base          <= conv_std_logic_vector(C_CAP82_BASE,32);
  caps(82).c_size          <= conv_std_logic_vector(C_CAP82_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(82).c_next          <= C_BASEADDR + conv_std_logic_vector((82+1)*64,16) when 82 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 83
  caps(83).c_type          <= conv_std_logic_vector(C_CAP83_TYPE,16);
  caps(83).c_version       <= conv_std_logic_vector(C_CAP83_VERSION,8);
  caps(83).c_irq           <= conv_std_logic_vector(C_CAP83_IRQ,8);
  caps(83).c_id_associated <= conv_std_logic_vector(C_CAP83_ID_ASSOCIATED,16);
  caps(83).c_id_component  <= conv_std_logic_vector(C_CAP83_ID_COMPONENT,16);
  caps(83).c_irq_enable_en <= '0' when C_CAP83_IRQ_ENABLE_EN = 0 else '1';
  caps(83).c_irq_status_en <= '0' when C_CAP83_IRQ_STATUS_EN = 0 else '1';
  caps(83).c_irq_enable    <= (others => '0') when C_CAP83_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP83_IRQ_ENABLE,15);
  caps(83).c_irq_status    <= (others => '0') when C_CAP83_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP83_IRQ_STATUS,15);
  caps(83).c_base          <= conv_std_logic_vector(C_CAP83_BASE,32);
  caps(83).c_size          <= conv_std_logic_vector(C_CAP83_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(83).c_next          <= C_BASEADDR + conv_std_logic_vector((83+1)*64,16) when 83 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 84
  caps(84).c_type          <= conv_std_logic_vector(C_CAP84_TYPE,16);
  caps(84).c_version       <= conv_std_logic_vector(C_CAP84_VERSION,8);
  caps(84).c_irq           <= conv_std_logic_vector(C_CAP84_IRQ,8);
  caps(84).c_id_associated <= conv_std_logic_vector(C_CAP84_ID_ASSOCIATED,16);
  caps(84).c_id_component  <= conv_std_logic_vector(C_CAP84_ID_COMPONENT,16);
  caps(84).c_irq_enable_en <= '0' when C_CAP84_IRQ_ENABLE_EN = 0 else '1';
  caps(84).c_irq_status_en <= '0' when C_CAP84_IRQ_STATUS_EN = 0 else '1';
  caps(84).c_irq_enable    <= (others => '0') when C_CAP84_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP84_IRQ_ENABLE,15);
  caps(84).c_irq_status    <= (others => '0') when C_CAP84_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP84_IRQ_STATUS,15);
  caps(84).c_base          <= conv_std_logic_vector(C_CAP84_BASE,32);
  caps(84).c_size          <= conv_std_logic_vector(C_CAP84_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(84).c_next          <= C_BASEADDR + conv_std_logic_vector((84+1)*64,16) when 84 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 85
  caps(85).c_type          <= conv_std_logic_vector(C_CAP85_TYPE,16);
  caps(85).c_version       <= conv_std_logic_vector(C_CAP85_VERSION,8);
  caps(85).c_irq           <= conv_std_logic_vector(C_CAP85_IRQ,8);
  caps(85).c_id_associated <= conv_std_logic_vector(C_CAP85_ID_ASSOCIATED,16);
  caps(85).c_id_component  <= conv_std_logic_vector(C_CAP85_ID_COMPONENT,16);
  caps(85).c_irq_enable_en <= '0' when C_CAP85_IRQ_ENABLE_EN = 0 else '1';
  caps(85).c_irq_status_en <= '0' when C_CAP85_IRQ_STATUS_EN = 0 else '1';
  caps(85).c_irq_enable    <= (others => '0') when C_CAP85_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP85_IRQ_ENABLE,15);
  caps(85).c_irq_status    <= (others => '0') when C_CAP85_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP85_IRQ_STATUS,15);
  caps(85).c_base          <= conv_std_logic_vector(C_CAP85_BASE,32);
  caps(85).c_size          <= conv_std_logic_vector(C_CAP85_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(85).c_next          <= C_BASEADDR + conv_std_logic_vector((85+1)*64,16) when 85 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 86
  caps(86).c_type          <= conv_std_logic_vector(C_CAP86_TYPE,16);
  caps(86).c_version       <= conv_std_logic_vector(C_CAP86_VERSION,8);
  caps(86).c_irq           <= conv_std_logic_vector(C_CAP86_IRQ,8);
  caps(86).c_id_associated <= conv_std_logic_vector(C_CAP86_ID_ASSOCIATED,16);
  caps(86).c_id_component  <= conv_std_logic_vector(C_CAP86_ID_COMPONENT,16);
  caps(86).c_irq_enable_en <= '0' when C_CAP86_IRQ_ENABLE_EN = 0 else '1';
  caps(86).c_irq_status_en <= '0' when C_CAP86_IRQ_STATUS_EN = 0 else '1';
  caps(86).c_irq_enable    <= (others => '0') when C_CAP86_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP86_IRQ_ENABLE,15);
  caps(86).c_irq_status    <= (others => '0') when C_CAP86_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP86_IRQ_STATUS,15);
  caps(86).c_base          <= conv_std_logic_vector(C_CAP86_BASE,32);
  caps(86).c_size          <= conv_std_logic_vector(C_CAP86_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(86).c_next          <= C_BASEADDR + conv_std_logic_vector((86+1)*64,16) when 86 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 87
  caps(87).c_type          <= conv_std_logic_vector(C_CAP87_TYPE,16);
  caps(87).c_version       <= conv_std_logic_vector(C_CAP87_VERSION,8);
  caps(87).c_irq           <= conv_std_logic_vector(C_CAP87_IRQ,8);
  caps(87).c_id_associated <= conv_std_logic_vector(C_CAP87_ID_ASSOCIATED,16);
  caps(87).c_id_component  <= conv_std_logic_vector(C_CAP87_ID_COMPONENT,16);
  caps(87).c_irq_enable_en <= '0' when C_CAP87_IRQ_ENABLE_EN = 0 else '1';
  caps(87).c_irq_status_en <= '0' when C_CAP87_IRQ_STATUS_EN = 0 else '1';
  caps(87).c_irq_enable    <= (others => '0') when C_CAP87_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP87_IRQ_ENABLE,15);
  caps(87).c_irq_status    <= (others => '0') when C_CAP87_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP87_IRQ_STATUS,15);
  caps(87).c_base          <= conv_std_logic_vector(C_CAP87_BASE,32);
  caps(87).c_size          <= conv_std_logic_vector(C_CAP87_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(87).c_next          <= C_BASEADDR + conv_std_logic_vector((87+1)*64,16) when 87 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 88
  caps(88).c_type          <= conv_std_logic_vector(C_CAP88_TYPE,16);
  caps(88).c_version       <= conv_std_logic_vector(C_CAP88_VERSION,8);
  caps(88).c_irq           <= conv_std_logic_vector(C_CAP88_IRQ,8);
  caps(88).c_id_associated <= conv_std_logic_vector(C_CAP88_ID_ASSOCIATED,16);
  caps(88).c_id_component  <= conv_std_logic_vector(C_CAP88_ID_COMPONENT,16);
  caps(88).c_irq_enable_en <= '0' when C_CAP88_IRQ_ENABLE_EN = 0 else '1';
  caps(88).c_irq_status_en <= '0' when C_CAP88_IRQ_STATUS_EN = 0 else '1';
  caps(88).c_irq_enable    <= (others => '0') when C_CAP88_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP88_IRQ_ENABLE,15);
  caps(88).c_irq_status    <= (others => '0') when C_CAP88_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP88_IRQ_STATUS,15);
  caps(88).c_base          <= conv_std_logic_vector(C_CAP88_BASE,32);
  caps(88).c_size          <= conv_std_logic_vector(C_CAP88_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(88).c_next          <= C_BASEADDR + conv_std_logic_vector((88+1)*64,16) when 88 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 89
  caps(89).c_type          <= conv_std_logic_vector(C_CAP89_TYPE,16);
  caps(89).c_version       <= conv_std_logic_vector(C_CAP89_VERSION,8);
  caps(89).c_irq           <= conv_std_logic_vector(C_CAP89_IRQ,8);
  caps(89).c_id_associated <= conv_std_logic_vector(C_CAP89_ID_ASSOCIATED,16);
  caps(89).c_id_component  <= conv_std_logic_vector(C_CAP89_ID_COMPONENT,16);
  caps(89).c_irq_enable_en <= '0' when C_CAP89_IRQ_ENABLE_EN = 0 else '1';
  caps(89).c_irq_status_en <= '0' when C_CAP89_IRQ_STATUS_EN = 0 else '1';
  caps(89).c_irq_enable    <= (others => '0') when C_CAP89_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP89_IRQ_ENABLE,15);
  caps(89).c_irq_status    <= (others => '0') when C_CAP89_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP89_IRQ_STATUS,15);
  caps(89).c_base          <= conv_std_logic_vector(C_CAP89_BASE,32);
  caps(89).c_size          <= conv_std_logic_vector(C_CAP89_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(89).c_next          <= C_BASEADDR + conv_std_logic_vector((89+1)*64,16) when 89 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 90
  caps(90).c_type          <= conv_std_logic_vector(C_CAP90_TYPE,16);
  caps(90).c_version       <= conv_std_logic_vector(C_CAP90_VERSION,8);
  caps(90).c_irq           <= conv_std_logic_vector(C_CAP90_IRQ,8);
  caps(90).c_id_associated <= conv_std_logic_vector(C_CAP90_ID_ASSOCIATED,16);
  caps(90).c_id_component  <= conv_std_logic_vector(C_CAP90_ID_COMPONENT,16);
  caps(90).c_irq_enable_en <= '0' when C_CAP90_IRQ_ENABLE_EN = 0 else '1';
  caps(90).c_irq_status_en <= '0' when C_CAP90_IRQ_STATUS_EN = 0 else '1';
  caps(90).c_irq_enable    <= (others => '0') when C_CAP90_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP90_IRQ_ENABLE,15);
  caps(90).c_irq_status    <= (others => '0') when C_CAP90_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP90_IRQ_STATUS,15);
  caps(90).c_base          <= conv_std_logic_vector(C_CAP90_BASE,32);
  caps(90).c_size          <= conv_std_logic_vector(C_CAP90_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(90).c_next          <= C_BASEADDR + conv_std_logic_vector((90+1)*64,16) when 90 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 91
  caps(91).c_type          <= conv_std_logic_vector(C_CAP91_TYPE,16);
  caps(91).c_version       <= conv_std_logic_vector(C_CAP91_VERSION,8);
  caps(91).c_irq           <= conv_std_logic_vector(C_CAP91_IRQ,8);
  caps(91).c_id_associated <= conv_std_logic_vector(C_CAP91_ID_ASSOCIATED,16);
  caps(91).c_id_component  <= conv_std_logic_vector(C_CAP91_ID_COMPONENT,16);
  caps(91).c_irq_enable_en <= '0' when C_CAP91_IRQ_ENABLE_EN = 0 else '1';
  caps(91).c_irq_status_en <= '0' when C_CAP91_IRQ_STATUS_EN = 0 else '1';
  caps(91).c_irq_enable    <= (others => '0') when C_CAP91_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP91_IRQ_ENABLE,15);
  caps(91).c_irq_status    <= (others => '0') when C_CAP91_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP91_IRQ_STATUS,15);
  caps(91).c_base          <= conv_std_logic_vector(C_CAP91_BASE,32);
  caps(91).c_size          <= conv_std_logic_vector(C_CAP91_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(91).c_next          <= C_BASEADDR + conv_std_logic_vector((91+1)*64,16) when 91 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 92
  caps(92).c_type          <= conv_std_logic_vector(C_CAP92_TYPE,16);
  caps(92).c_version       <= conv_std_logic_vector(C_CAP92_VERSION,8);
  caps(92).c_irq           <= conv_std_logic_vector(C_CAP92_IRQ,8);
  caps(92).c_id_associated <= conv_std_logic_vector(C_CAP92_ID_ASSOCIATED,16);
  caps(92).c_id_component  <= conv_std_logic_vector(C_CAP92_ID_COMPONENT,16);
  caps(92).c_irq_enable_en <= '0' when C_CAP92_IRQ_ENABLE_EN = 0 else '1';
  caps(92).c_irq_status_en <= '0' when C_CAP92_IRQ_STATUS_EN = 0 else '1';
  caps(92).c_irq_enable    <= (others => '0') when C_CAP92_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP92_IRQ_ENABLE,15);
  caps(92).c_irq_status    <= (others => '0') when C_CAP92_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP92_IRQ_STATUS,15);
  caps(92).c_base          <= conv_std_logic_vector(C_CAP92_BASE,32);
  caps(92).c_size          <= conv_std_logic_vector(C_CAP92_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(92).c_next          <= C_BASEADDR + conv_std_logic_vector((92+1)*64,16) when 92 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 93
  caps(93).c_type          <= conv_std_logic_vector(C_CAP93_TYPE,16);
  caps(93).c_version       <= conv_std_logic_vector(C_CAP93_VERSION,8);
  caps(93).c_irq           <= conv_std_logic_vector(C_CAP93_IRQ,8);
  caps(93).c_id_associated <= conv_std_logic_vector(C_CAP93_ID_ASSOCIATED,16);
  caps(93).c_id_component  <= conv_std_logic_vector(C_CAP93_ID_COMPONENT,16);
  caps(93).c_irq_enable_en <= '0' when C_CAP93_IRQ_ENABLE_EN = 0 else '1';
  caps(93).c_irq_status_en <= '0' when C_CAP93_IRQ_STATUS_EN = 0 else '1';
  caps(93).c_irq_enable    <= (others => '0') when C_CAP93_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP93_IRQ_ENABLE,15);
  caps(93).c_irq_status    <= (others => '0') when C_CAP93_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP93_IRQ_STATUS,15);
  caps(93).c_base          <= conv_std_logic_vector(C_CAP93_BASE,32);
  caps(93).c_size          <= conv_std_logic_vector(C_CAP93_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(93).c_next          <= C_BASEADDR + conv_std_logic_vector((93+1)*64,16) when 93 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 94
  caps(94).c_type          <= conv_std_logic_vector(C_CAP94_TYPE,16);
  caps(94).c_version       <= conv_std_logic_vector(C_CAP94_VERSION,8);
  caps(94).c_irq           <= conv_std_logic_vector(C_CAP94_IRQ,8);
  caps(94).c_id_associated <= conv_std_logic_vector(C_CAP94_ID_ASSOCIATED,16);
  caps(94).c_id_component  <= conv_std_logic_vector(C_CAP94_ID_COMPONENT,16);
  caps(94).c_irq_enable_en <= '0' when C_CAP94_IRQ_ENABLE_EN = 0 else '1';
  caps(94).c_irq_status_en <= '0' when C_CAP94_IRQ_STATUS_EN = 0 else '1';
  caps(94).c_irq_enable    <= (others => '0') when C_CAP94_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP94_IRQ_ENABLE,15);
  caps(94).c_irq_status    <= (others => '0') when C_CAP94_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP94_IRQ_STATUS,15);
  caps(94).c_base          <= conv_std_logic_vector(C_CAP94_BASE,32);
  caps(94).c_size          <= conv_std_logic_vector(C_CAP94_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(94).c_next          <= C_BASEADDR + conv_std_logic_vector((94+1)*64,16) when 94 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 95
  caps(95).c_type          <= conv_std_logic_vector(C_CAP95_TYPE,16);
  caps(95).c_version       <= conv_std_logic_vector(C_CAP95_VERSION,8);
  caps(95).c_irq           <= conv_std_logic_vector(C_CAP95_IRQ,8);
  caps(95).c_id_associated <= conv_std_logic_vector(C_CAP95_ID_ASSOCIATED,16);
  caps(95).c_id_component  <= conv_std_logic_vector(C_CAP95_ID_COMPONENT,16);
  caps(95).c_irq_enable_en <= '0' when C_CAP95_IRQ_ENABLE_EN = 0 else '1';
  caps(95).c_irq_status_en <= '0' when C_CAP95_IRQ_STATUS_EN = 0 else '1';
  caps(95).c_irq_enable    <= (others => '0') when C_CAP95_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP95_IRQ_ENABLE,15);
  caps(95).c_irq_status    <= (others => '0') when C_CAP95_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP95_IRQ_STATUS,15);
  caps(95).c_base          <= conv_std_logic_vector(C_CAP95_BASE,32);
  caps(95).c_size          <= conv_std_logic_vector(C_CAP95_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(95).c_next          <= C_BASEADDR + conv_std_logic_vector((95+1)*64,16) when 95 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 96
  caps(96).c_type          <= conv_std_logic_vector(C_CAP96_TYPE,16);
  caps(96).c_version       <= conv_std_logic_vector(C_CAP96_VERSION,8);
  caps(96).c_irq           <= conv_std_logic_vector(C_CAP96_IRQ,8);
  caps(96).c_id_associated <= conv_std_logic_vector(C_CAP96_ID_ASSOCIATED,16);
  caps(96).c_id_component  <= conv_std_logic_vector(C_CAP96_ID_COMPONENT,16);
  caps(96).c_irq_enable_en <= '0' when C_CAP96_IRQ_ENABLE_EN = 0 else '1';
  caps(96).c_irq_status_en <= '0' when C_CAP96_IRQ_STATUS_EN = 0 else '1';
  caps(96).c_irq_enable    <= (others => '0') when C_CAP96_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP96_IRQ_ENABLE,15);
  caps(96).c_irq_status    <= (others => '0') when C_CAP96_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP96_IRQ_STATUS,15);
  caps(96).c_base          <= conv_std_logic_vector(C_CAP96_BASE,32);
  caps(96).c_size          <= conv_std_logic_vector(C_CAP96_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(96).c_next          <= C_BASEADDR + conv_std_logic_vector((96+1)*64,16) when 96 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 97
  caps(97).c_type          <= conv_std_logic_vector(C_CAP97_TYPE,16);
  caps(97).c_version       <= conv_std_logic_vector(C_CAP97_VERSION,8);
  caps(97).c_irq           <= conv_std_logic_vector(C_CAP97_IRQ,8);
  caps(97).c_id_associated <= conv_std_logic_vector(C_CAP97_ID_ASSOCIATED,16);
  caps(97).c_id_component  <= conv_std_logic_vector(C_CAP97_ID_COMPONENT,16);
  caps(97).c_irq_enable_en <= '0' when C_CAP97_IRQ_ENABLE_EN = 0 else '1';
  caps(97).c_irq_status_en <= '0' when C_CAP97_IRQ_STATUS_EN = 0 else '1';
  caps(97).c_irq_enable    <= (others => '0') when C_CAP97_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP97_IRQ_ENABLE,15);
  caps(97).c_irq_status    <= (others => '0') when C_CAP97_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP97_IRQ_STATUS,15);
  caps(97).c_base          <= conv_std_logic_vector(C_CAP97_BASE,32);
  caps(97).c_size          <= conv_std_logic_vector(C_CAP97_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(97).c_next          <= C_BASEADDR + conv_std_logic_vector((97+1)*64,16) when 97 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 98
  caps(98).c_type          <= conv_std_logic_vector(C_CAP98_TYPE,16);
  caps(98).c_version       <= conv_std_logic_vector(C_CAP98_VERSION,8);
  caps(98).c_irq           <= conv_std_logic_vector(C_CAP98_IRQ,8);
  caps(98).c_id_associated <= conv_std_logic_vector(C_CAP98_ID_ASSOCIATED,16);
  caps(98).c_id_component  <= conv_std_logic_vector(C_CAP98_ID_COMPONENT,16);
  caps(98).c_irq_enable_en <= '0' when C_CAP98_IRQ_ENABLE_EN = 0 else '1';
  caps(98).c_irq_status_en <= '0' when C_CAP98_IRQ_STATUS_EN = 0 else '1';
  caps(98).c_irq_enable    <= (others => '0') when C_CAP98_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP98_IRQ_ENABLE,15);
  caps(98).c_irq_status    <= (others => '0') when C_CAP98_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP98_IRQ_STATUS,15);
  caps(98).c_base          <= conv_std_logic_vector(C_CAP98_BASE,32);
  caps(98).c_size          <= conv_std_logic_vector(C_CAP98_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(98).c_next          <= C_BASEADDR + conv_std_logic_vector((98+1)*64,16) when 98 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 99
  caps(99).c_type          <= conv_std_logic_vector(C_CAP99_TYPE,16);
  caps(99).c_version       <= conv_std_logic_vector(C_CAP99_VERSION,8);
  caps(99).c_irq           <= conv_std_logic_vector(C_CAP99_IRQ,8);
  caps(99).c_id_associated <= conv_std_logic_vector(C_CAP99_ID_ASSOCIATED,16);
  caps(99).c_id_component  <= conv_std_logic_vector(C_CAP99_ID_COMPONENT,16);
  caps(99).c_irq_enable_en <= '0' when C_CAP99_IRQ_ENABLE_EN = 0 else '1';
  caps(99).c_irq_status_en <= '0' when C_CAP99_IRQ_STATUS_EN = 0 else '1';
  caps(99).c_irq_enable    <= (others => '0') when C_CAP99_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP99_IRQ_ENABLE,15);
  caps(99).c_irq_status    <= (others => '0') when C_CAP99_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP99_IRQ_STATUS,15);
  caps(99).c_base          <= conv_std_logic_vector(C_CAP99_BASE,32);
  caps(99).c_size          <= conv_std_logic_vector(C_CAP99_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(99).c_next          <= C_BASEADDR + conv_std_logic_vector((99+1)*64,16) when 99 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 100
  caps(100).c_type          <= conv_std_logic_vector(C_CAP100_TYPE,16);
  caps(100).c_version       <= conv_std_logic_vector(C_CAP100_VERSION,8);
  caps(100).c_irq           <= conv_std_logic_vector(C_CAP100_IRQ,8);
  caps(100).c_id_associated <= conv_std_logic_vector(C_CAP100_ID_ASSOCIATED,16);
  caps(100).c_id_component  <= conv_std_logic_vector(C_CAP100_ID_COMPONENT,16);
  caps(100).c_irq_enable_en <= '0' when C_CAP100_IRQ_ENABLE_EN = 0 else '1';
  caps(100).c_irq_status_en <= '0' when C_CAP100_IRQ_STATUS_EN = 0 else '1';
  caps(100).c_irq_enable    <= (others => '0') when C_CAP100_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP100_IRQ_ENABLE,15);
  caps(100).c_irq_status    <= (others => '0') when C_CAP100_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP100_IRQ_STATUS,15);
  caps(100).c_base          <= conv_std_logic_vector(C_CAP100_BASE,32);
  caps(100).c_size          <= conv_std_logic_vector(C_CAP100_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(100).c_next          <= C_BASEADDR + conv_std_logic_vector((100+1)*64,16) when 100 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 101
  caps(101).c_type          <= conv_std_logic_vector(C_CAP101_TYPE,16);
  caps(101).c_version       <= conv_std_logic_vector(C_CAP101_VERSION,8);
  caps(101).c_irq           <= conv_std_logic_vector(C_CAP101_IRQ,8);
  caps(101).c_id_associated <= conv_std_logic_vector(C_CAP101_ID_ASSOCIATED,16);
  caps(101).c_id_component  <= conv_std_logic_vector(C_CAP101_ID_COMPONENT,16);
  caps(101).c_irq_enable_en <= '0' when C_CAP101_IRQ_ENABLE_EN = 0 else '1';
  caps(101).c_irq_status_en <= '0' when C_CAP101_IRQ_STATUS_EN = 0 else '1';
  caps(101).c_irq_enable    <= (others => '0') when C_CAP101_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP101_IRQ_ENABLE,15);
  caps(101).c_irq_status    <= (others => '0') when C_CAP101_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP101_IRQ_STATUS,15);
  caps(101).c_base          <= conv_std_logic_vector(C_CAP101_BASE,32);
  caps(101).c_size          <= conv_std_logic_vector(C_CAP101_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(101).c_next          <= C_BASEADDR + conv_std_logic_vector((101+1)*64,16) when 101 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 102
  caps(102).c_type          <= conv_std_logic_vector(C_CAP102_TYPE,16);
  caps(102).c_version       <= conv_std_logic_vector(C_CAP102_VERSION,8);
  caps(102).c_irq           <= conv_std_logic_vector(C_CAP102_IRQ,8);
  caps(102).c_id_associated <= conv_std_logic_vector(C_CAP102_ID_ASSOCIATED,16);
  caps(102).c_id_component  <= conv_std_logic_vector(C_CAP102_ID_COMPONENT,16);
  caps(102).c_irq_enable_en <= '0' when C_CAP102_IRQ_ENABLE_EN = 0 else '1';
  caps(102).c_irq_status_en <= '0' when C_CAP102_IRQ_STATUS_EN = 0 else '1';
  caps(102).c_irq_enable    <= (others => '0') when C_CAP102_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP102_IRQ_ENABLE,15);
  caps(102).c_irq_status    <= (others => '0') when C_CAP102_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP102_IRQ_STATUS,15);
  caps(102).c_base          <= conv_std_logic_vector(C_CAP102_BASE,32);
  caps(102).c_size          <= conv_std_logic_vector(C_CAP102_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(102).c_next          <= C_BASEADDR + conv_std_logic_vector((102+1)*64,16) when 102 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 103
  caps(103).c_type          <= conv_std_logic_vector(C_CAP103_TYPE,16);
  caps(103).c_version       <= conv_std_logic_vector(C_CAP103_VERSION,8);
  caps(103).c_irq           <= conv_std_logic_vector(C_CAP103_IRQ,8);
  caps(103).c_id_associated <= conv_std_logic_vector(C_CAP103_ID_ASSOCIATED,16);
  caps(103).c_id_component  <= conv_std_logic_vector(C_CAP103_ID_COMPONENT,16);
  caps(103).c_irq_enable_en <= '0' when C_CAP103_IRQ_ENABLE_EN = 0 else '1';
  caps(103).c_irq_status_en <= '0' when C_CAP103_IRQ_STATUS_EN = 0 else '1';
  caps(103).c_irq_enable    <= (others => '0') when C_CAP103_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP103_IRQ_ENABLE,15);
  caps(103).c_irq_status    <= (others => '0') when C_CAP103_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP103_IRQ_STATUS,15);
  caps(103).c_base          <= conv_std_logic_vector(C_CAP103_BASE,32);
  caps(103).c_size          <= conv_std_logic_vector(C_CAP103_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(103).c_next          <= C_BASEADDR + conv_std_logic_vector((103+1)*64,16) when 103 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 104
  caps(104).c_type          <= conv_std_logic_vector(C_CAP104_TYPE,16);
  caps(104).c_version       <= conv_std_logic_vector(C_CAP104_VERSION,8);
  caps(104).c_irq           <= conv_std_logic_vector(C_CAP104_IRQ,8);
  caps(104).c_id_associated <= conv_std_logic_vector(C_CAP104_ID_ASSOCIATED,16);
  caps(104).c_id_component  <= conv_std_logic_vector(C_CAP104_ID_COMPONENT,16);
  caps(104).c_irq_enable_en <= '0' when C_CAP104_IRQ_ENABLE_EN = 0 else '1';
  caps(104).c_irq_status_en <= '0' when C_CAP104_IRQ_STATUS_EN = 0 else '1';
  caps(104).c_irq_enable    <= (others => '0') when C_CAP104_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP104_IRQ_ENABLE,15);
  caps(104).c_irq_status    <= (others => '0') when C_CAP104_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP104_IRQ_STATUS,15);
  caps(104).c_base          <= conv_std_logic_vector(C_CAP104_BASE,32);
  caps(104).c_size          <= conv_std_logic_vector(C_CAP104_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(104).c_next          <= C_BASEADDR + conv_std_logic_vector((104+1)*64,16) when 104 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 105
  caps(105).c_type          <= conv_std_logic_vector(C_CAP105_TYPE,16);
  caps(105).c_version       <= conv_std_logic_vector(C_CAP105_VERSION,8);
  caps(105).c_irq           <= conv_std_logic_vector(C_CAP105_IRQ,8);
  caps(105).c_id_associated <= conv_std_logic_vector(C_CAP105_ID_ASSOCIATED,16);
  caps(105).c_id_component  <= conv_std_logic_vector(C_CAP105_ID_COMPONENT,16);
  caps(105).c_irq_enable_en <= '0' when C_CAP105_IRQ_ENABLE_EN = 0 else '1';
  caps(105).c_irq_status_en <= '0' when C_CAP105_IRQ_STATUS_EN = 0 else '1';
  caps(105).c_irq_enable    <= (others => '0') when C_CAP105_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP105_IRQ_ENABLE,15);
  caps(105).c_irq_status    <= (others => '0') when C_CAP105_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP105_IRQ_STATUS,15);
  caps(105).c_base          <= conv_std_logic_vector(C_CAP105_BASE,32);
  caps(105).c_size          <= conv_std_logic_vector(C_CAP105_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(105).c_next          <= C_BASEADDR + conv_std_logic_vector((105+1)*64,16) when 105 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 106
  caps(106).c_type          <= conv_std_logic_vector(C_CAP106_TYPE,16);
  caps(106).c_version       <= conv_std_logic_vector(C_CAP106_VERSION,8);
  caps(106).c_irq           <= conv_std_logic_vector(C_CAP106_IRQ,8);
  caps(106).c_id_associated <= conv_std_logic_vector(C_CAP106_ID_ASSOCIATED,16);
  caps(106).c_id_component  <= conv_std_logic_vector(C_CAP106_ID_COMPONENT,16);
  caps(106).c_irq_enable_en <= '0' when C_CAP106_IRQ_ENABLE_EN = 0 else '1';
  caps(106).c_irq_status_en <= '0' when C_CAP106_IRQ_STATUS_EN = 0 else '1';
  caps(106).c_irq_enable    <= (others => '0') when C_CAP106_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP106_IRQ_ENABLE,15);
  caps(106).c_irq_status    <= (others => '0') when C_CAP106_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP106_IRQ_STATUS,15);
  caps(106).c_base          <= conv_std_logic_vector(C_CAP106_BASE,32);
  caps(106).c_size          <= conv_std_logic_vector(C_CAP106_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(106).c_next          <= C_BASEADDR + conv_std_logic_vector((106+1)*64,16) when 106 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 107
  caps(107).c_type          <= conv_std_logic_vector(C_CAP107_TYPE,16);
  caps(107).c_version       <= conv_std_logic_vector(C_CAP107_VERSION,8);
  caps(107).c_irq           <= conv_std_logic_vector(C_CAP107_IRQ,8);
  caps(107).c_id_associated <= conv_std_logic_vector(C_CAP107_ID_ASSOCIATED,16);
  caps(107).c_id_component  <= conv_std_logic_vector(C_CAP107_ID_COMPONENT,16);
  caps(107).c_irq_enable_en <= '0' when C_CAP107_IRQ_ENABLE_EN = 0 else '1';
  caps(107).c_irq_status_en <= '0' when C_CAP107_IRQ_STATUS_EN = 0 else '1';
  caps(107).c_irq_enable    <= (others => '0') when C_CAP107_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP107_IRQ_ENABLE,15);
  caps(107).c_irq_status    <= (others => '0') when C_CAP107_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP107_IRQ_STATUS,15);
  caps(107).c_base          <= conv_std_logic_vector(C_CAP107_BASE,32);
  caps(107).c_size          <= conv_std_logic_vector(C_CAP107_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(107).c_next          <= C_BASEADDR + conv_std_logic_vector((107+1)*64,16) when 107 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 108
  caps(108).c_type          <= conv_std_logic_vector(C_CAP108_TYPE,16);
  caps(108).c_version       <= conv_std_logic_vector(C_CAP108_VERSION,8);
  caps(108).c_irq           <= conv_std_logic_vector(C_CAP108_IRQ,8);
  caps(108).c_id_associated <= conv_std_logic_vector(C_CAP108_ID_ASSOCIATED,16);
  caps(108).c_id_component  <= conv_std_logic_vector(C_CAP108_ID_COMPONENT,16);
  caps(108).c_irq_enable_en <= '0' when C_CAP108_IRQ_ENABLE_EN = 0 else '1';
  caps(108).c_irq_status_en <= '0' when C_CAP108_IRQ_STATUS_EN = 0 else '1';
  caps(108).c_irq_enable    <= (others => '0') when C_CAP108_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP108_IRQ_ENABLE,15);
  caps(108).c_irq_status    <= (others => '0') when C_CAP108_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP108_IRQ_STATUS,15);
  caps(108).c_base          <= conv_std_logic_vector(C_CAP108_BASE,32);
  caps(108).c_size          <= conv_std_logic_vector(C_CAP108_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(108).c_next          <= C_BASEADDR + conv_std_logic_vector((108+1)*64,16) when 108 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 109
  caps(109).c_type          <= conv_std_logic_vector(C_CAP109_TYPE,16);
  caps(109).c_version       <= conv_std_logic_vector(C_CAP109_VERSION,8);
  caps(109).c_irq           <= conv_std_logic_vector(C_CAP109_IRQ,8);
  caps(109).c_id_associated <= conv_std_logic_vector(C_CAP109_ID_ASSOCIATED,16);
  caps(109).c_id_component  <= conv_std_logic_vector(C_CAP109_ID_COMPONENT,16);
  caps(109).c_irq_enable_en <= '0' when C_CAP109_IRQ_ENABLE_EN = 0 else '1';
  caps(109).c_irq_status_en <= '0' when C_CAP109_IRQ_STATUS_EN = 0 else '1';
  caps(109).c_irq_enable    <= (others => '0') when C_CAP109_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP109_IRQ_ENABLE,15);
  caps(109).c_irq_status    <= (others => '0') when C_CAP109_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP109_IRQ_STATUS,15);
  caps(109).c_base          <= conv_std_logic_vector(C_CAP109_BASE,32);
  caps(109).c_size          <= conv_std_logic_vector(C_CAP109_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(109).c_next          <= C_BASEADDR + conv_std_logic_vector((109+1)*64,16) when 109 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 110
  caps(110).c_type          <= conv_std_logic_vector(C_CAP110_TYPE,16);
  caps(110).c_version       <= conv_std_logic_vector(C_CAP110_VERSION,8);
  caps(110).c_irq           <= conv_std_logic_vector(C_CAP110_IRQ,8);
  caps(110).c_id_associated <= conv_std_logic_vector(C_CAP110_ID_ASSOCIATED,16);
  caps(110).c_id_component  <= conv_std_logic_vector(C_CAP110_ID_COMPONENT,16);
  caps(110).c_irq_enable_en <= '0' when C_CAP110_IRQ_ENABLE_EN = 0 else '1';
  caps(110).c_irq_status_en <= '0' when C_CAP110_IRQ_STATUS_EN = 0 else '1';
  caps(110).c_irq_enable    <= (others => '0') when C_CAP110_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP110_IRQ_ENABLE,15);
  caps(110).c_irq_status    <= (others => '0') when C_CAP110_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP110_IRQ_STATUS,15);
  caps(110).c_base          <= conv_std_logic_vector(C_CAP110_BASE,32);
  caps(110).c_size          <= conv_std_logic_vector(C_CAP110_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(110).c_next          <= C_BASEADDR + conv_std_logic_vector((110+1)*64,16) when 110 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 111
  caps(111).c_type          <= conv_std_logic_vector(C_CAP111_TYPE,16);
  caps(111).c_version       <= conv_std_logic_vector(C_CAP111_VERSION,8);
  caps(111).c_irq           <= conv_std_logic_vector(C_CAP111_IRQ,8);
  caps(111).c_id_associated <= conv_std_logic_vector(C_CAP111_ID_ASSOCIATED,16);
  caps(111).c_id_component  <= conv_std_logic_vector(C_CAP111_ID_COMPONENT,16);
  caps(111).c_irq_enable_en <= '0' when C_CAP111_IRQ_ENABLE_EN = 0 else '1';
  caps(111).c_irq_status_en <= '0' when C_CAP111_IRQ_STATUS_EN = 0 else '1';
  caps(111).c_irq_enable    <= (others => '0') when C_CAP111_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP111_IRQ_ENABLE,15);
  caps(111).c_irq_status    <= (others => '0') when C_CAP111_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP111_IRQ_STATUS,15);
  caps(111).c_base          <= conv_std_logic_vector(C_CAP111_BASE,32);
  caps(111).c_size          <= conv_std_logic_vector(C_CAP111_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(111).c_next          <= C_BASEADDR + conv_std_logic_vector((111+1)*64,16) when 111 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 112
  caps(112).c_type          <= conv_std_logic_vector(C_CAP112_TYPE,16);
  caps(112).c_version       <= conv_std_logic_vector(C_CAP112_VERSION,8);
  caps(112).c_irq           <= conv_std_logic_vector(C_CAP112_IRQ,8);
  caps(112).c_id_associated <= conv_std_logic_vector(C_CAP112_ID_ASSOCIATED,16);
  caps(112).c_id_component  <= conv_std_logic_vector(C_CAP112_ID_COMPONENT,16);
  caps(112).c_irq_enable_en <= '0' when C_CAP112_IRQ_ENABLE_EN = 0 else '1';
  caps(112).c_irq_status_en <= '0' when C_CAP112_IRQ_STATUS_EN = 0 else '1';
  caps(112).c_irq_enable    <= (others => '0') when C_CAP112_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP112_IRQ_ENABLE,15);
  caps(112).c_irq_status    <= (others => '0') when C_CAP112_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP112_IRQ_STATUS,15);
  caps(112).c_base          <= conv_std_logic_vector(C_CAP112_BASE,32);
  caps(112).c_size          <= conv_std_logic_vector(C_CAP112_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(112).c_next          <= C_BASEADDR + conv_std_logic_vector((112+1)*64,16) when 112 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 113
  caps(113).c_type          <= conv_std_logic_vector(C_CAP113_TYPE,16);
  caps(113).c_version       <= conv_std_logic_vector(C_CAP113_VERSION,8);
  caps(113).c_irq           <= conv_std_logic_vector(C_CAP113_IRQ,8);
  caps(113).c_id_associated <= conv_std_logic_vector(C_CAP113_ID_ASSOCIATED,16);
  caps(113).c_id_component  <= conv_std_logic_vector(C_CAP113_ID_COMPONENT,16);
  caps(113).c_irq_enable_en <= '0' when C_CAP113_IRQ_ENABLE_EN = 0 else '1';
  caps(113).c_irq_status_en <= '0' when C_CAP113_IRQ_STATUS_EN = 0 else '1';
  caps(113).c_irq_enable    <= (others => '0') when C_CAP113_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP113_IRQ_ENABLE,15);
  caps(113).c_irq_status    <= (others => '0') when C_CAP113_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP113_IRQ_STATUS,15);
  caps(113).c_base          <= conv_std_logic_vector(C_CAP113_BASE,32);
  caps(113).c_size          <= conv_std_logic_vector(C_CAP113_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(113).c_next          <= C_BASEADDR + conv_std_logic_vector((113+1)*64,16) when 113 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 114
  caps(114).c_type          <= conv_std_logic_vector(C_CAP114_TYPE,16);
  caps(114).c_version       <= conv_std_logic_vector(C_CAP114_VERSION,8);
  caps(114).c_irq           <= conv_std_logic_vector(C_CAP114_IRQ,8);
  caps(114).c_id_associated <= conv_std_logic_vector(C_CAP114_ID_ASSOCIATED,16);
  caps(114).c_id_component  <= conv_std_logic_vector(C_CAP114_ID_COMPONENT,16);
  caps(114).c_irq_enable_en <= '0' when C_CAP114_IRQ_ENABLE_EN = 0 else '1';
  caps(114).c_irq_status_en <= '0' when C_CAP114_IRQ_STATUS_EN = 0 else '1';
  caps(114).c_irq_enable    <= (others => '0') when C_CAP114_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP114_IRQ_ENABLE,15);
  caps(114).c_irq_status    <= (others => '0') when C_CAP114_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP114_IRQ_STATUS,15);
  caps(114).c_base          <= conv_std_logic_vector(C_CAP114_BASE,32);
  caps(114).c_size          <= conv_std_logic_vector(C_CAP114_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(114).c_next          <= C_BASEADDR + conv_std_logic_vector((114+1)*64,16) when 114 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 115
  caps(115).c_type          <= conv_std_logic_vector(C_CAP115_TYPE,16);
  caps(115).c_version       <= conv_std_logic_vector(C_CAP115_VERSION,8);
  caps(115).c_irq           <= conv_std_logic_vector(C_CAP115_IRQ,8);
  caps(115).c_id_associated <= conv_std_logic_vector(C_CAP115_ID_ASSOCIATED,16);
  caps(115).c_id_component  <= conv_std_logic_vector(C_CAP115_ID_COMPONENT,16);
  caps(115).c_irq_enable_en <= '0' when C_CAP115_IRQ_ENABLE_EN = 0 else '1';
  caps(115).c_irq_status_en <= '0' when C_CAP115_IRQ_STATUS_EN = 0 else '1';
  caps(115).c_irq_enable    <= (others => '0') when C_CAP115_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP115_IRQ_ENABLE,15);
  caps(115).c_irq_status    <= (others => '0') when C_CAP115_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP115_IRQ_STATUS,15);
  caps(115).c_base          <= conv_std_logic_vector(C_CAP115_BASE,32);
  caps(115).c_size          <= conv_std_logic_vector(C_CAP115_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(115).c_next          <= C_BASEADDR + conv_std_logic_vector((115+1)*64,16) when 115 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 116
  caps(116).c_type          <= conv_std_logic_vector(C_CAP116_TYPE,16);
  caps(116).c_version       <= conv_std_logic_vector(C_CAP116_VERSION,8);
  caps(116).c_irq           <= conv_std_logic_vector(C_CAP116_IRQ,8);
  caps(116).c_id_associated <= conv_std_logic_vector(C_CAP116_ID_ASSOCIATED,16);
  caps(116).c_id_component  <= conv_std_logic_vector(C_CAP116_ID_COMPONENT,16);
  caps(116).c_irq_enable_en <= '0' when C_CAP116_IRQ_ENABLE_EN = 0 else '1';
  caps(116).c_irq_status_en <= '0' when C_CAP116_IRQ_STATUS_EN = 0 else '1';
  caps(116).c_irq_enable    <= (others => '0') when C_CAP116_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP116_IRQ_ENABLE,15);
  caps(116).c_irq_status    <= (others => '0') when C_CAP116_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP116_IRQ_STATUS,15);
  caps(116).c_base          <= conv_std_logic_vector(C_CAP116_BASE,32);
  caps(116).c_size          <= conv_std_logic_vector(C_CAP116_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(116).c_next          <= C_BASEADDR + conv_std_logic_vector((116+1)*64,16) when 116 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 117
  caps(117).c_type          <= conv_std_logic_vector(C_CAP117_TYPE,16);
  caps(117).c_version       <= conv_std_logic_vector(C_CAP117_VERSION,8);
  caps(117).c_irq           <= conv_std_logic_vector(C_CAP117_IRQ,8);
  caps(117).c_id_associated <= conv_std_logic_vector(C_CAP117_ID_ASSOCIATED,16);
  caps(117).c_id_component  <= conv_std_logic_vector(C_CAP117_ID_COMPONENT,16);
  caps(117).c_irq_enable_en <= '0' when C_CAP117_IRQ_ENABLE_EN = 0 else '1';
  caps(117).c_irq_status_en <= '0' when C_CAP117_IRQ_STATUS_EN = 0 else '1';
  caps(117).c_irq_enable    <= (others => '0') when C_CAP117_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP117_IRQ_ENABLE,15);
  caps(117).c_irq_status    <= (others => '0') when C_CAP117_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP117_IRQ_STATUS,15);
  caps(117).c_base          <= conv_std_logic_vector(C_CAP117_BASE,32);
  caps(117).c_size          <= conv_std_logic_vector(C_CAP117_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(117).c_next          <= C_BASEADDR + conv_std_logic_vector((117+1)*64,16) when 117 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 118
  caps(118).c_type          <= conv_std_logic_vector(C_CAP118_TYPE,16);
  caps(118).c_version       <= conv_std_logic_vector(C_CAP118_VERSION,8);
  caps(118).c_irq           <= conv_std_logic_vector(C_CAP118_IRQ,8);
  caps(118).c_id_associated <= conv_std_logic_vector(C_CAP118_ID_ASSOCIATED,16);
  caps(118).c_id_component  <= conv_std_logic_vector(C_CAP118_ID_COMPONENT,16);
  caps(118).c_irq_enable_en <= '0' when C_CAP118_IRQ_ENABLE_EN = 0 else '1';
  caps(118).c_irq_status_en <= '0' when C_CAP118_IRQ_STATUS_EN = 0 else '1';
  caps(118).c_irq_enable    <= (others => '0') when C_CAP118_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP118_IRQ_ENABLE,15);
  caps(118).c_irq_status    <= (others => '0') when C_CAP118_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP118_IRQ_STATUS,15);
  caps(118).c_base          <= conv_std_logic_vector(C_CAP118_BASE,32);
  caps(118).c_size          <= conv_std_logic_vector(C_CAP118_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(118).c_next          <= C_BASEADDR + conv_std_logic_vector((118+1)*64,16) when 118 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 119
  caps(119).c_type          <= conv_std_logic_vector(C_CAP119_TYPE,16);
  caps(119).c_version       <= conv_std_logic_vector(C_CAP119_VERSION,8);
  caps(119).c_irq           <= conv_std_logic_vector(C_CAP119_IRQ,8);
  caps(119).c_id_associated <= conv_std_logic_vector(C_CAP119_ID_ASSOCIATED,16);
  caps(119).c_id_component  <= conv_std_logic_vector(C_CAP119_ID_COMPONENT,16);
  caps(119).c_irq_enable_en <= '0' when C_CAP119_IRQ_ENABLE_EN = 0 else '1';
  caps(119).c_irq_status_en <= '0' when C_CAP119_IRQ_STATUS_EN = 0 else '1';
  caps(119).c_irq_enable    <= (others => '0') when C_CAP119_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP119_IRQ_ENABLE,15);
  caps(119).c_irq_status    <= (others => '0') when C_CAP119_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP119_IRQ_STATUS,15);
  caps(119).c_base          <= conv_std_logic_vector(C_CAP119_BASE,32);
  caps(119).c_size          <= conv_std_logic_vector(C_CAP119_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(119).c_next          <= C_BASEADDR + conv_std_logic_vector((119+1)*64,16) when 119 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 120
  caps(120).c_type          <= conv_std_logic_vector(C_CAP120_TYPE,16);
  caps(120).c_version       <= conv_std_logic_vector(C_CAP120_VERSION,8);
  caps(120).c_irq           <= conv_std_logic_vector(C_CAP120_IRQ,8);
  caps(120).c_id_associated <= conv_std_logic_vector(C_CAP120_ID_ASSOCIATED,16);
  caps(120).c_id_component  <= conv_std_logic_vector(C_CAP120_ID_COMPONENT,16);
  caps(120).c_irq_enable_en <= '0' when C_CAP120_IRQ_ENABLE_EN = 0 else '1';
  caps(120).c_irq_status_en <= '0' when C_CAP120_IRQ_STATUS_EN = 0 else '1';
  caps(120).c_irq_enable    <= (others => '0') when C_CAP120_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP120_IRQ_ENABLE,15);
  caps(120).c_irq_status    <= (others => '0') when C_CAP120_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP120_IRQ_STATUS,15);
  caps(120).c_base          <= conv_std_logic_vector(C_CAP120_BASE,32);
  caps(120).c_size          <= conv_std_logic_vector(C_CAP120_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(120).c_next          <= C_BASEADDR + conv_std_logic_vector((120+1)*64,16) when 120 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 121
  caps(121).c_type          <= conv_std_logic_vector(C_CAP121_TYPE,16);
  caps(121).c_version       <= conv_std_logic_vector(C_CAP121_VERSION,8);
  caps(121).c_irq           <= conv_std_logic_vector(C_CAP121_IRQ,8);
  caps(121).c_id_associated <= conv_std_logic_vector(C_CAP121_ID_ASSOCIATED,16);
  caps(121).c_id_component  <= conv_std_logic_vector(C_CAP121_ID_COMPONENT,16);
  caps(121).c_irq_enable_en <= '0' when C_CAP121_IRQ_ENABLE_EN = 0 else '1';
  caps(121).c_irq_status_en <= '0' when C_CAP121_IRQ_STATUS_EN = 0 else '1';
  caps(121).c_irq_enable    <= (others => '0') when C_CAP121_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP121_IRQ_ENABLE,15);
  caps(121).c_irq_status    <= (others => '0') when C_CAP121_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP121_IRQ_STATUS,15);
  caps(121).c_base          <= conv_std_logic_vector(C_CAP121_BASE,32);
  caps(121).c_size          <= conv_std_logic_vector(C_CAP121_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(121).c_next          <= C_BASEADDR + conv_std_logic_vector((121+1)*64,16) when 121 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 122
  caps(122).c_type          <= conv_std_logic_vector(C_CAP122_TYPE,16);
  caps(122).c_version       <= conv_std_logic_vector(C_CAP122_VERSION,8);
  caps(122).c_irq           <= conv_std_logic_vector(C_CAP122_IRQ,8);
  caps(122).c_id_associated <= conv_std_logic_vector(C_CAP122_ID_ASSOCIATED,16);
  caps(122).c_id_component  <= conv_std_logic_vector(C_CAP122_ID_COMPONENT,16);
  caps(122).c_irq_enable_en <= '0' when C_CAP122_IRQ_ENABLE_EN = 0 else '1';
  caps(122).c_irq_status_en <= '0' when C_CAP122_IRQ_STATUS_EN = 0 else '1';
  caps(122).c_irq_enable    <= (others => '0') when C_CAP122_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP122_IRQ_ENABLE,15);
  caps(122).c_irq_status    <= (others => '0') when C_CAP122_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP122_IRQ_STATUS,15);
  caps(122).c_base          <= conv_std_logic_vector(C_CAP122_BASE,32);
  caps(122).c_size          <= conv_std_logic_vector(C_CAP122_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(122).c_next          <= C_BASEADDR + conv_std_logic_vector((122+1)*64,16) when 122 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 123
  caps(123).c_type          <= conv_std_logic_vector(C_CAP123_TYPE,16);
  caps(123).c_version       <= conv_std_logic_vector(C_CAP123_VERSION,8);
  caps(123).c_irq           <= conv_std_logic_vector(C_CAP123_IRQ,8);
  caps(123).c_id_associated <= conv_std_logic_vector(C_CAP123_ID_ASSOCIATED,16);
  caps(123).c_id_component  <= conv_std_logic_vector(C_CAP123_ID_COMPONENT,16);
  caps(123).c_irq_enable_en <= '0' when C_CAP123_IRQ_ENABLE_EN = 0 else '1';
  caps(123).c_irq_status_en <= '0' when C_CAP123_IRQ_STATUS_EN = 0 else '1';
  caps(123).c_irq_enable    <= (others => '0') when C_CAP123_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP123_IRQ_ENABLE,15);
  caps(123).c_irq_status    <= (others => '0') when C_CAP123_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP123_IRQ_STATUS,15);
  caps(123).c_base          <= conv_std_logic_vector(C_CAP123_BASE,32);
  caps(123).c_size          <= conv_std_logic_vector(C_CAP123_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(123).c_next          <= C_BASEADDR + conv_std_logic_vector((123+1)*64,16) when 123 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 124
  caps(124).c_type          <= conv_std_logic_vector(C_CAP124_TYPE,16);
  caps(124).c_version       <= conv_std_logic_vector(C_CAP124_VERSION,8);
  caps(124).c_irq           <= conv_std_logic_vector(C_CAP124_IRQ,8);
  caps(124).c_id_associated <= conv_std_logic_vector(C_CAP124_ID_ASSOCIATED,16);
  caps(124).c_id_component  <= conv_std_logic_vector(C_CAP124_ID_COMPONENT,16);
  caps(124).c_irq_enable_en <= '0' when C_CAP124_IRQ_ENABLE_EN = 0 else '1';
  caps(124).c_irq_status_en <= '0' when C_CAP124_IRQ_STATUS_EN = 0 else '1';
  caps(124).c_irq_enable    <= (others => '0') when C_CAP124_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP124_IRQ_ENABLE,15);
  caps(124).c_irq_status    <= (others => '0') when C_CAP124_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP124_IRQ_STATUS,15);
  caps(124).c_base          <= conv_std_logic_vector(C_CAP124_BASE,32);
  caps(124).c_size          <= conv_std_logic_vector(C_CAP124_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(124).c_next          <= C_BASEADDR + conv_std_logic_vector((124+1)*64,16) when 124 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 125
  caps(125).c_type          <= conv_std_logic_vector(C_CAP125_TYPE,16);
  caps(125).c_version       <= conv_std_logic_vector(C_CAP125_VERSION,8);
  caps(125).c_irq           <= conv_std_logic_vector(C_CAP125_IRQ,8);
  caps(125).c_id_associated <= conv_std_logic_vector(C_CAP125_ID_ASSOCIATED,16);
  caps(125).c_id_component  <= conv_std_logic_vector(C_CAP125_ID_COMPONENT,16);
  caps(125).c_irq_enable_en <= '0' when C_CAP125_IRQ_ENABLE_EN = 0 else '1';
  caps(125).c_irq_status_en <= '0' when C_CAP125_IRQ_STATUS_EN = 0 else '1';
  caps(125).c_irq_enable    <= (others => '0') when C_CAP125_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP125_IRQ_ENABLE,15);
  caps(125).c_irq_status    <= (others => '0') when C_CAP125_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP125_IRQ_STATUS,15);
  caps(125).c_base          <= conv_std_logic_vector(C_CAP125_BASE,32);
  caps(125).c_size          <= conv_std_logic_vector(C_CAP125_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(125).c_next          <= C_BASEADDR + conv_std_logic_vector((125+1)*64,16) when 125 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 126
  caps(126).c_type          <= conv_std_logic_vector(C_CAP126_TYPE,16);
  caps(126).c_version       <= conv_std_logic_vector(C_CAP126_VERSION,8);
  caps(126).c_irq           <= conv_std_logic_vector(C_CAP126_IRQ,8);
  caps(126).c_id_associated <= conv_std_logic_vector(C_CAP126_ID_ASSOCIATED,16);
  caps(126).c_id_component  <= conv_std_logic_vector(C_CAP126_ID_COMPONENT,16);
  caps(126).c_irq_enable_en <= '0' when C_CAP126_IRQ_ENABLE_EN = 0 else '1';
  caps(126).c_irq_status_en <= '0' when C_CAP126_IRQ_STATUS_EN = 0 else '1';
  caps(126).c_irq_enable    <= (others => '0') when C_CAP126_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP126_IRQ_ENABLE,15);
  caps(126).c_irq_status    <= (others => '0') when C_CAP126_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP126_IRQ_STATUS,15);
  caps(126).c_base          <= conv_std_logic_vector(C_CAP126_BASE,32);
  caps(126).c_size          <= conv_std_logic_vector(C_CAP126_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(126).c_next          <= C_BASEADDR + conv_std_logic_vector((126+1)*64,16) when 126 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);
  ---------------------------------------------------------------------------------
  -- Constants for Capability 127
  caps(127).c_type          <= conv_std_logic_vector(C_CAP127_TYPE,16);
  caps(127).c_version       <= conv_std_logic_vector(C_CAP127_VERSION,8);
  caps(127).c_irq           <= conv_std_logic_vector(C_CAP127_IRQ,8);
  caps(127).c_id_associated <= conv_std_logic_vector(C_CAP127_ID_ASSOCIATED,16);
  caps(127).c_id_component  <= conv_std_logic_vector(C_CAP127_ID_COMPONENT,16);
  caps(127).c_irq_enable_en <= '0' when C_CAP127_IRQ_ENABLE_EN = 0 else '1';
  caps(127).c_irq_status_en <= '0' when C_CAP127_IRQ_STATUS_EN = 0 else '1';
  caps(127).c_irq_enable    <= (others => '0') when C_CAP127_IRQ_ENABLE_EN = 0 else conv_std_logic_vector(C_CAP127_IRQ_ENABLE,15);
  caps(127).c_irq_status    <= (others => '0') when C_CAP127_IRQ_STATUS_EN = 0 else conv_std_logic_vector(C_CAP127_IRQ_STATUS,15);
  caps(127).c_base          <= conv_std_logic_vector(C_CAP127_BASE,32);
  caps(127).c_size          <= conv_std_logic_vector(C_CAP127_SIZE,24);
  -- Either link to ourself or C_NEXT if assigned, otherwise use C_BASE to ensure we terminate the link-list...
  caps(127).c_next          <= C_BASEADDR + conv_std_logic_vector((127+1)*64,16) when 127 /= (C_NUM_CAPS-1) else
                             conv_std_logic_vector(C_NEXT,32) when C_NEXT /= 0 else conv_std_logic_vector(C_BASE,32);

end struct;
