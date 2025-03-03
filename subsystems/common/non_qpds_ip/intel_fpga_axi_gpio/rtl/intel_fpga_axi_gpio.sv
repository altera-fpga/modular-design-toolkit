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
module intel_fpga_axi_gpio
//****************************************************************************//

# (
  int            P_S_AXI_ADDR_WIDTH  = 4,
  int            P_S_AXI_DATA_WIDTH  = 32,
  int            P_GPI_WIDTH         = 32,
  int            P_GPO_WIDTH         = 32,
  logic [31 : 0] P_GPO_DEFAULT       = 32'h00000000

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
  output logic [P_GPO_WIDTH - 1 : 0]              gpo,
  input  wire  [P_GPI_WIDTH - 1 : 0]              gpi
);

timeunit 1ns;
timeprecision 1ps;

//****************************************************************************//

localparam [P_S_AXI_ADDR_WIDTH - 1 : 0] LP_GPO_ADDR = 'h0;
localparam [P_S_AXI_ADDR_WIDTH - 1 : 0] LP_GPI_ADDR = 'h4;

logic [P_S_AXI_DATA_WIDTH - 1 : 0] m_pwdata;
logic [P_S_AXI_DATA_WIDTH - 1 : 0] m_prdata;
logic [P_S_AXI_ADDR_WIDTH - 1 : 0] m_paddr;
logic                              m_pwrite;
logic                              m_psel;
logic                              m_penable;
logic                              m_pready;
logic [P_GPI_WIDTH - 1 : 0]        gpi_meta;
logic [P_GPI_WIDTH - 1 : 0]        gpi_safe;
logic [2 : 0]                      aresetn_sr;
logic                              aresetn;

logic pwrite_en;
logic pread_en;

//----------------------------------------------------------------------------//

always_ff @ (posedge s_axi_aclk, negedge s_axi_aresetn) begin
  if (s_axi_aresetn == 1'b0) begin
    aresetn_sr <= 'd0;
  end else begin
    aresetn_sr <= {1'b1, aresetn_sr [$left(aresetn_sr) : 1]};
  end //if
end //always_ff

assign aresetn = aresetn_sr [0];

intel_fpga_axil2apb
# (
  .P_S_AXI_ADDR_WIDTH  (P_S_AXI_ADDR_WIDTH),
  .P_S_AXI_DATA_WIDTH  (P_S_AXI_DATA_WIDTH),
  .P_WATCHDOG_EN       (1)
) intel_fpga_axil2apb_inst (

  .s_axi_aclk      (s_axi_aclk),
  .s_axi_aresetn   (s_axi_aresetn),
  .s_axi_awprot    (s_axi_awprot),
  .s_axi_arprot    (s_axi_arprot),
  .s_axi_awaddr    (s_axi_awaddr),
  .s_axi_awvalid   (s_axi_awvalid),
  .s_axi_awready   (s_axi_awready),
  .s_axi_wstrb     (s_axi_wstrb),
  .s_axi_wdata     (s_axi_wdata),
  .s_axi_wvalid    (s_axi_wvalid),
  .s_axi_wready    (s_axi_wready),
  .s_axi_bresp     (s_axi_bresp),
  .s_axi_bvalid    (s_axi_bvalid),
  .s_axi_bready    (s_axi_bready),
  .s_axi_araddr    (s_axi_araddr),
  .s_axi_arvalid   (s_axi_arvalid),
  .s_axi_arready   (s_axi_arready),
  .s_axi_rdata     (s_axi_rdata),
  .s_axi_rresp     (s_axi_rresp),
  .s_axi_rvalid    (s_axi_rvalid),
  .s_axi_rready    (s_axi_rready),

  .m_apb_paddr     (m_paddr),
  .m_apb_pwrite    (m_pwrite),
  .m_apb_psel      (m_psel),
  .m_apb_penable   (m_penable),
  .m_apb_pwdata    (m_pwdata),
  .m_apb_prdata    (m_prdata),
  .m_apb_pready    (m_pready)

);

always_ff @ (posedge s_axi_aclk) begin
  gpi_meta <= gpi;
  gpi_safe <= gpi_meta;
end //always_ff

assign m_pready  = m_psel & m_penable;
assign pwrite_en = m_psel & m_penable & m_pwrite;
assign pread_en  = m_psel & m_penable;

always_ff @ (posedge s_axi_aclk, negedge aresetn) begin
  if (aresetn == 1'b0) begin
    gpo <= P_GPO_DEFAULT [P_GPO_WIDTH - 1 : 0];
  end else begin
    if ((m_paddr == LP_GPO_ADDR) && (pwrite_en == 1'b1)) begin
      gpo <= m_pwdata [P_GPO_WIDTH - 1 : 0];
    end //if
  end //if
end //always_ff

always_ff @ (posedge s_axi_aclk) begin
  if (m_psel == 1'b1) begin
    m_prdata <= 'd0;
    case (m_paddr)
      LP_GPO_ADDR : begin
        m_prdata [P_GPO_WIDTH - 1 : 0] <= gpo;
      end //LP_GPO_ADDR

      LP_GPI_ADDR : begin
        m_prdata [P_GPO_WIDTH - 1 : 0] <= gpi_safe;
      end //LP_GPO_ADDR

      default : begin
        m_prdata <= 'h5D0C4610;
      end //default
    endcase
  end //if
end //always_ff

//****************************************************************************//
endmodule : intel_fpga_axi_gpio
//****************************************************************************//
`default_nettype wire
