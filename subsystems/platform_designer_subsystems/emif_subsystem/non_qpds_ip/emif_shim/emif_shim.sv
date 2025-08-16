/* ##################################################################################
 * Copyright (C) 2025 Altera Corporation
 *
 * This software and the related documents are Altera copyrighted materials, and
 * your use of them is governed by the express license under which they were
 * provided to you ("License"). Unless the License provides otherwise, you may
 * not use, modify, copy, publish, distribute, disclose or transmit this software
 * or the related documents without Altera's prior written permission.
 *
 * This software and the related documents are provided as is, with no express
 * or implied warranties, other than those that are expressly stated in the License.
 * ##################################################################################

 * ##################################################################################
 *
 * Module: emif_shim
 *
 * Description: Creates a shim around for the EMIF interface, preserving all signals
 *
 * ##################################################################################
*/

`default_nettype none

module emif_shim
#(
    parameter ADDR_W = 33
)
(
  input  wire [ADDR_W-1:0]  s_axi_awaddr    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [1:0]   s_axi_awburst   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [6:0]   s_axi_awid      /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [7:0]   s_axi_awlen     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire         s_axi_awlock    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [3:0]   s_axi_awqos     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [2:0]   s_axi_awsize    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire         s_axi_awvalid   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [3:0]   s_axi_awuser    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [2:0]   s_axi_awprot    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire         s_axi_awready   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  input  wire [ADDR_W-1:0]  s_axi_araddr    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [1:0]   s_axi_arburst   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [6:0]   s_axi_arid      /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [7:0]   s_axi_arlen     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire         s_axi_arlock    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [3:0]   s_axi_arqos     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [2:0]   s_axi_arsize    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire         s_axi_arvalid   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [3:0]   s_axi_aruser    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [2:0]   s_axi_arprot    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire         s_axi_arready   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  input  wire         s_axi_bready    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire [6:0]   s_axi_bid       /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire [1:0]   s_axi_bresp     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire         s_axi_bvalid    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  input  wire         s_axi_rready    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire [63:0]  s_axi_ruser     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire [6:0]   s_axi_rid       /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire         s_axi_rlast     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire [1:0]   s_axi_rresp     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire         s_axi_rvalid    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire [255:0] s_axi_rdata     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [63:0]  s_axi_wuser     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [255:0] s_axi_wdata     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire [31:0]  s_axi_wstrb     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire         s_axi_wlast     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input  wire         s_axi_wvalid    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output wire         s_axi_wready    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  output  wire [ADDR_W-1:0]  m_axi_awaddr    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [1:0]   m_axi_awburst  /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [6:0]   m_axi_awid     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [7:0]   m_axi_awlen    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire         m_axi_awlock   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [3:0]   m_axi_awqos    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [2:0]   m_axi_awsize   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire         m_axi_awvalid  /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [3:0]   m_axi_awuser   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [2:0]   m_axi_awprot   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire         m_axi_awready  /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  output  wire [ADDR_W-1:0]  m_axi_araddr    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [1:0]   m_axi_arburst  /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [6:0]   m_axi_arid     /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [7:0]   m_axi_arlen    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire         m_axi_arlock   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [3:0]   m_axi_arqos    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [2:0]   m_axi_arsize   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire         m_axi_arvalid  /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [3:0]   m_axi_aruser   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [2:0]   m_axi_arprot   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire         m_axi_arready  /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  output  wire         m_axi_bready   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire [6:0]   m_axi_bid      /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire [1:0]   m_axi_bresp    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire         m_axi_bvalid   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  output  wire         m_axi_rready   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire [63:0]  m_axi_ruser    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire [6:0]   m_axi_rid      /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire         m_axi_rlast    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire [1:0]   m_axi_rresp    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire         m_axi_rvalid   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire [255:0] m_axi_rdata    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  output  wire [63:0]  m_axi_wuser    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [255:0] m_axi_wdata    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire [31:0]  m_axi_wstrb    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire         m_axi_wlast    /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  output  wire         m_axi_wvalid   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,
  input   wire         m_axi_wready   /* synthesis preserve_for_debug dont_merge syn_preserve = 1 */,

  input   wire         axi_clk,
  input   wire         axi_reset
);


  localparam AW_WIDTH = ADDR_W+2+7+8+1+4+3+4+3;
  localparam AR_WIDTH = ADDR_W+2+7+8+1+4+3+4+3;
  localparam W_WIDTH  = 64+256+32+1;
  localparam R_WIDTH  = 64+7+1+2+256;
  localparam B_WIDTH  = 7+2;

  logic [AW_WIDTH-1:0] s_aw,m_aw;
  logic [AR_WIDTH-1:0] s_ar,m_ar;
  logic [W_WIDTH-1:0]  s_w,m_w;
  logic [R_WIDTH-1:0]  s_r,m_r;
  logic [B_WIDTH-1:0]  s_b,m_b;

  assign s_ar = {s_axi_araddr,s_axi_arburst,s_axi_arid,s_axi_arlen,s_axi_arlock,s_axi_arqos,s_axi_arsize,s_axi_aruser,s_axi_arprot};
  assign s_aw = {s_axi_awaddr,s_axi_awburst,s_axi_awid,s_axi_awlen,s_axi_awlock,s_axi_awqos,s_axi_awsize,s_axi_awuser,s_axi_awprot};
  assign s_w = {s_axi_wuser,s_axi_wdata,s_axi_wstrb,s_axi_wlast};
  assign {s_axi_ruser,s_axi_rid,s_axi_rlast,s_axi_rresp,s_axi_rdata} = s_r;
  assign {s_axi_bid,s_axi_bresp} = s_b;

  assign {m_axi_araddr,m_axi_arburst,m_axi_arid,m_axi_arlen,m_axi_arlock,m_axi_arqos,m_axi_arsize,m_axi_aruser,m_axi_arprot} = m_ar;
  assign {m_axi_awaddr,m_axi_awburst,m_axi_awid,m_axi_awlen,m_axi_awlock,m_axi_awqos,m_axi_awsize,m_axi_awuser,m_axi_awprot} = m_aw;
  assign {m_axi_wuser,m_axi_wdata,m_axi_wstrb,m_axi_wlast} = m_w;
  assign m_r = {m_axi_ruser,m_axi_rid,m_axi_rlast,m_axi_rresp,m_axi_rdata};
  assign m_b = {m_axi_bid,m_axi_bresp};

  emif_shim_skid #( .P_WIDTH(AW_WIDTH)) i_aw (
    .clk           (axi_clk),
    .rst           (axi_reset),
    .in_valid      (s_axi_awvalid),
    .in_data       (s_aw),
    .in_ready      (s_axi_awready),
    .out_valid     (m_axi_awvalid),
    .out_data      (m_aw),
    .out_ready     (m_axi_awready)
  );

  emif_shim_skid #( .P_WIDTH(AW_WIDTH)) i_ar (
    .clk           (axi_clk),
    .rst           (axi_reset),
    .in_valid      (s_axi_arvalid),
    .in_data       (s_ar),
    .in_ready      (s_axi_arready),
    .out_valid     (m_axi_arvalid),
    .out_data      (m_ar),
    .out_ready     (m_axi_arready)
  );

  emif_shim_skid #( .P_WIDTH(W_WIDTH)) i_w (
    .clk           (axi_clk),
    .rst           (axi_reset),
    .in_valid      (s_axi_wvalid),
    .in_data       (s_w),
    .in_ready      (s_axi_wready),
    .out_valid     (m_axi_wvalid),
    .out_data      (m_w),
    .out_ready     (m_axi_wready)
  );

  emif_shim_skid #( .P_WIDTH(R_WIDTH)) i_r (
    .clk           (axi_clk),
    .rst           (axi_reset),
    .in_valid      (m_axi_rvalid),
    .in_data       (m_r),
    .in_ready      (m_axi_rready),
    .out_valid     (s_axi_rvalid),
    .out_data      (s_r),
    .out_ready     (s_axi_rready)
  );

  emif_shim_skid #( .P_WIDTH(B_WIDTH)) i_b (
    .clk           (axi_clk),
    .rst           (axi_reset),
    .in_valid      (m_axi_bvalid),
    .in_data       (m_b),
    .in_ready      (m_axi_bready),
    .out_valid     (s_axi_bvalid),
    .out_data      (s_b),
    .out_ready     (s_axi_bready)
  );

endmodule

`default_nettype wire
