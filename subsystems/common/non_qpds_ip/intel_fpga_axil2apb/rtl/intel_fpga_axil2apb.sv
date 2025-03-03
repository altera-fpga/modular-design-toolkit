/* ##################################################################################
 * Copyright (C) 2025 Intel Corporation
 *
 * This software and the related documents are Intel copyrighted materials, and
 * your use of them is governed by the express license under which they were
 * provided to you ("License"). Unless the License provides otherwise, you may
 * not use, modify, copy, publish, distribute, disclose or transmit this software
 * or the related documents without Intel's prior written permission.
 *
 * This software and the related documents are provided as is, with no express
 * or implied warranties, other than those that are expressly stated in the License.
* ##################################################################################
*/

`default_nettype none

//****************************************************************************//
module intel_fpga_axil2apb
//****************************************************************************//
# (
  int    P_S_AXI_ADDR_WIDTH  = 4,
  int    P_S_AXI_DATA_WIDTH  = 32,
  bit    P_WATCHDOG_EN       = 1
) (
  input  wire                                     s_axi_aclk,
  input  wire                                     s_axi_aresetn,
  input  wire  [2 : 0]                            s_axi_awprot,
  input  wire  [2 : 0]                            s_axi_arprot,
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s_axi_awaddr,
  input  wire                                     s_axi_awvalid,
  output logic                                    s_axi_awready,
  input  wire  [3 : 0]                            s_axi_wstrb,
  input  wire  [P_S_AXI_DATA_WIDTH - 1 : 0]       s_axi_wdata,
  input  wire                                     s_axi_wvalid,
  output logic                                    s_axi_wready,
  output logic [1 : 0]                            s_axi_bresp,
  output logic                                    s_axi_bvalid,
  input  wire                                     s_axi_bready,
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s_axi_araddr,
  input  wire                                     s_axi_arvalid,
  output logic                                    s_axi_arready,
  output logic [P_S_AXI_DATA_WIDTH - 1 : 0]       s_axi_rdata,
  output logic [1 : 0]                            s_axi_rresp,
  output logic                                    s_axi_rvalid,
  input  wire                                     s_axi_rready,

  output logic [P_S_AXI_ADDR_WIDTH - 1 : 0]       m_apb_paddr,
  output logic                                    m_apb_pwrite,
  output logic                                    m_apb_psel,
  output logic                                    m_apb_penable,
  output logic [P_S_AXI_DATA_WIDTH - 1 : 0]       m_apb_pwdata,
  input  wire  [P_S_AXI_DATA_WIDTH - 1 : 0]       m_apb_prdata,
  input  wire                                     m_apb_pready

);

timeunit 1ns;
timeprecision 1ps;
//****************************************************************************//
logic idle;
logic transction_done;
logic axi_req;

logic pfinish;

logic [15 : 0] watchdog_count;
logic watchdog_ack = 'b0;
//----------------------------------------------------------------------------//

assign s_axi_bresp = watchdog_ack ? 2'b10 : 2'b00; // Error if the watchdog kicks in otherwise OK
assign s_axi_rresp = watchdog_ack ? 2'b10 : 2'b00; // Error if the watchdog kicks in otherwise OK

assign s_axi_awready = s_axi_awvalid & s_axi_wvalid & idle;
assign s_axi_wready  = s_axi_awvalid & s_axi_wvalid & idle;
assign s_axi_arready = s_axi_arvalid & idle;

assign transction_done = ((s_axi_rvalid & s_axi_rready) | (s_axi_bvalid & s_axi_bready)) & ~idle;

always_comb begin
  if ((((s_axi_awvalid == 'b1) && (s_axi_wvalid == 'b1)) || (s_axi_arvalid == 'b1)) && (idle == 'b1)) begin
    axi_req = 1'b1;
  end else begin
    axi_req = 1'b0;
  end //if
end //always_comb

always_ff @ (posedge s_axi_aclk) begin
  if (s_axi_aresetn == 'b0) begin
    idle <= 1'b1;
  end else if (axi_req == 'b1) begin
    idle <= 1'b0;
  end else if (transction_done == 'b1) begin
    idle <= 1'b1;
  end //if
end //always

// ---------------------------------------------------------------------------//
// CPU interface timeout watchdog.
// ---------------------------------------------------------------------------//
always_ff @ (posedge s_axi_aclk) begin
  if (idle == 'b1) begin
    watchdog_count <= 'd0;
  end else if (watchdog_count[15] == 'b0) begin
    watchdog_count <= watchdog_count + 1'b1;

    // speed up timeout for simulation
    // synthesis translate_off
    watchdog_count <= watchdog_count + 'd1024;
    // synthesis translate_on
  end // if

  watchdog_ack <= P_WATCHDOG_EN & watchdog_count [$left(watchdog_count)] & ~idle;

end //always_ff

// ---------------------------------------------------------------------------//
assign pfinish = (m_apb_psel & m_apb_penable & m_apb_pready) | watchdog_ack;

always_ff @ (posedge s_axi_aclk) begin
  if (axi_req == 'b1) begin
    if (s_axi_awvalid == 'b1) begin
      m_apb_paddr <= s_axi_awaddr;
    end else if (s_axi_arvalid == 'b1) begin
      m_apb_paddr <= s_axi_araddr;
    end //if
  end //if
end //always

always_ff @ (posedge s_axi_aclk) begin
  if ((axi_req == 'b1) && (s_axi_awvalid == 'b1)) begin
    m_apb_pwdata <= s_axi_wdata;
  end //if
end //always

always_ff @ (posedge s_axi_aclk) begin
  if (s_axi_aresetn == 'b0) begin
    m_apb_pwrite <= 'b0;
  end else begin
    if (pfinish == 'b1) begin
      m_apb_pwrite <= 'b0;
    end else if ((axi_req == 'b1) && (s_axi_awvalid == 'b1)) begin
      m_apb_pwrite <= 'b1;
    end //if
  end //if
end //always

always_ff @ (posedge s_axi_aclk) begin
  if (s_axi_aresetn == 'b0)  begin
    m_apb_psel <= 'b0;
  end else begin
    if (pfinish == 'b1) begin
      m_apb_psel <= 'b0;
    end else if (axi_req == 'b1) begin
      m_apb_psel <= 'b1;
    end //if
  end //if
end //always

always_ff @ (posedge s_axi_aclk) begin
  if (s_axi_aresetn == 'b0) begin
    m_apb_penable <= 'b0;
  end else begin
    if (pfinish == 'b1) begin
      m_apb_penable <= 'b0;
    end else if (m_apb_psel == 'b1) begin
      m_apb_penable <= 'b1;
    end //if
  end //if
end //always

always_ff @ (posedge s_axi_aclk) begin
  if ((pfinish == 'b1)  && (m_apb_pwrite == 'b0)) begin
    s_axi_rdata <= m_apb_prdata;
  end //if
end //always

always_ff @ (posedge s_axi_aclk) begin
  if (s_axi_aresetn == 'b0) begin
    s_axi_rvalid <= 'b0;
  end else begin
    if (transction_done == 'b1) begin
      s_axi_rvalid <= 'b0;
    end else if ((pfinish == 'b1) && (m_apb_pwrite == 'b0) && (idle == 'b0)) begin
      s_axi_rvalid <= 'b1;
    end //if
  end //if
end //always

always_ff @ (posedge s_axi_aclk) begin
  if (s_axi_aresetn == 'b0) begin
    s_axi_bvalid <= 'b0;
  end else begin
    if (transction_done == 'b1) begin
      s_axi_bvalid <= 'b0;
    end else if ((pfinish == 'b1) && (m_apb_pwrite == 'b1) && (idle == 'b0)) begin
      s_axi_bvalid <= 'b1;
    end //if
  end //if
end //always

//****************************************************************************//
endmodule : intel_fpga_axil2apb
//****************************************************************************//

`default_nettype wire
