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
*/

//----------------------------------------------------------------------------//
//                         intel_fpga_shared_mem
// Adds AXI4-Lite or APB interfaces around a true dual port memory.
// Also includes optional error correction code function.
//----------------------------------------------------------------------------//
`default_nettype none

//****************************************************************************//
module intel_fpga_shared_mem
//****************************************************************************//
# (
  string P_RAMSTYLE          = "M20K", // also could be "MLAB"
  bit    P_S0_BUS_IS_AXI     = 0,
  bit    P_S1_BUS_IS_AXI     = 1,
  bit    P_USE_ECC           = 1,
  int    P_S_AXI_ADDR_WIDTH  = 4,
  int    P_S_AXI_DATA_WIDTH  = 32
) (

  input  wire                                     s_axi_aclk,
  input  wire                                     s_axi_aresetn,

  input  wire                                     reset_safety_n,

  (* altera_attribute = "-name REMOVE_DUPLICATE_REGISTERS OFF" *) output logic memory_fault_p,
  (* altera_attribute = "-name REMOVE_DUPLICATE_REGISTERS OFF" *) output logic memory_fault_n,

  // AXI4 Lite buis us only used if P_S0_BUS_IS_AXI == 1
  input  wire  [2 : 0]                            s0_axi_awprot,
  input  wire  [2 : 0]                            s0_axi_arprot,
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s0_axi_awaddr,
  input  wire                                     s0_axi_awvalid,
  output logic                                    s0_axi_awready,
  input  wire  [3 : 0]                            s0_axi_wstrb,
  input  wire  [P_S_AXI_DATA_WIDTH - 1 : 0]       s0_axi_wdata,
  input  wire                                     s0_axi_wvalid,
  output logic                                    s0_axi_wready,
  output logic [1 : 0]                            s0_axi_bresp,
  output logic                                    s0_axi_bvalid,
  input  wire                                     s0_axi_bready,
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s0_axi_araddr,
  input  wire                                     s0_axi_arvalid,
  output logic                                    s0_axi_arready,
  output logic [P_S_AXI_DATA_WIDTH - 1 : 0]       s0_axi_rdata,
  output logic [1 : 0]                            s0_axi_rresp,
  output logic                                    s0_axi_rvalid,
  input  wire                                     s0_axi_rready,

  // APB bus only used if P_S0_BUS_IS_AXI == 0
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s0_apb_paddr,
  input  wire                                     s0_apb_pwrite,
  input  wire                                     s0_apb_psel,
  input  wire                                     s0_apb_penable,
  input  wire  [P_S_AXI_DATA_WIDTH - 1 : 0]       s0_apb_pwdata,
  output logic [P_S_AXI_DATA_WIDTH - 1 : 0]       s0_apb_prdata,
  output logic                                    s0_apb_pready,

  // AXI4 Lite bus us only used if P_S1_BUS_IS_AXI == 1
  input  wire  [2 : 0]                            s1_axi_awprot,
  input  wire  [2 : 0]                            s1_axi_arprot,
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s1_axi_awaddr,
  input  wire                                     s1_axi_awvalid,
  output logic                                    s1_axi_awready,
  input  wire  [3 : 0]                            s1_axi_wstrb,
  input  wire  [P_S_AXI_DATA_WIDTH - 1 : 0]       s1_axi_wdata,
  input  wire                                     s1_axi_wvalid,
  output logic                                    s1_axi_wready,
  output logic [1 : 0]                            s1_axi_bresp,
  output logic                                    s1_axi_bvalid,
  input  wire                                     s1_axi_bready,
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s1_axi_araddr,
  input  wire                                     s1_axi_arvalid,
  output logic                                    s1_axi_arready,
  output logic [P_S_AXI_DATA_WIDTH - 1 : 0]       s1_axi_rdata,
  output logic [1 : 0]                            s1_axi_rresp,
  output logic                                    s1_axi_rvalid,
  input  wire                                     s1_axi_rready,

  // AXI4 Lite bus us only used if P_S1_BUS_IS_AXI == 0
  input  wire  [P_S_AXI_ADDR_WIDTH - 1 : 0]       s1_apb_paddr,
  input  wire                                     s1_apb_pwrite,
  input  wire                                     s1_apb_psel,
  input  wire                                     s1_apb_penable,
  input  wire  [P_S_AXI_DATA_WIDTH - 1 : 0]       s1_apb_pwdata,
  output logic [P_S_AXI_DATA_WIDTH - 1 : 0]       s1_apb_prdata,
  output logic                                    s1_apb_pready

);

timeunit 1ns;
timeprecision 1ps;
//****************************************************************************//
localparam P_RAM_DATA_WIDTH  = (P_USE_ECC == 0 ? P_S_AXI_DATA_WIDTH : (P_S_AXI_DATA_WIDTH + 7));
localparam P_RAM_ADDR_WIDTH  = P_S_AXI_ADDR_WIDTH - 2;

logic [P_S_AXI_DATA_WIDTH - 1 : 0] s0_wdata;
logic [P_S_AXI_DATA_WIDTH - 1 : 0] s0_rdata;
logic [P_S_AXI_ADDR_WIDTH - 1 : 0] s0_addr;
logic                              s0_re;
logic                              s0_we;
logic                              s0_pwrite;
logic                              s0_psel;
logic                              s0_penable;
logic                              s0_pready;
logic                              s0_clk_en;
logic                              s0_req;
logic                              s0_gnt;

logic [P_S_AXI_DATA_WIDTH - 1 : 0] s1_wdata;
logic [P_S_AXI_DATA_WIDTH - 1 : 0] s1_rdata;
logic [P_S_AXI_ADDR_WIDTH - 1 : 0] s1_addr;
logic                              s1_re;
logic                              s1_we;
logic                              s1_pwrite;
logic                              s1_psel;
logic                              s1_penable;
logic                              s1_pready;
logic                              s1_clk_en;
logic                              s1_req;
logic                              s1_gnt;

logic                              s01_priority;
logic                              conflict;

logic                              re_a;
logic                              we_a;
logic [P_RAM_ADDR_WIDTH - 1 : 0]   addr_a;
logic [P_RAM_DATA_WIDTH - 1 : 0]   data_in_a;
logic [P_RAM_DATA_WIDTH - 1 : 0]   data_out_a;
logic                              re_b;
logic                              we_b;
logic [P_RAM_ADDR_WIDTH - 1 : 0]   addr_b;
logic [P_RAM_DATA_WIDTH - 1 : 0]   data_in_b;
logic [P_RAM_DATA_WIDTH - 1 : 0]   data_out_b;

logic [1 : 0]                      ecc_err_fatal;

logic [2 : 0]                      aresetn_sr;
logic                              aresetn;
logic                              areset;
logic                              reset_ecc;

//----------------------------------------------------------------------------//
always_ff @ (posedge s_axi_aclk, negedge s_axi_aresetn) begin
    if (s_axi_aresetn == 1'b0) begin
        aresetn_sr <= 'd0;
    end else begin
        aresetn_sr <= {1'b1, aresetn_sr [$left(aresetn_sr) : 1]};
    end //if
end //always_ff

assign aresetn = aresetn_sr [0];
assign areset = ~aresetn;

always_ff @ (posedge s_axi_aclk) begin
    reset_ecc <= ~reset_safety_n;
end //always_ff

//----------------------------------------------------------------------------//
//                                 S0 Interface
//----------------------------------------------------------------------------//
generate
    if (P_S0_BUS_IS_AXI == 0) begin : GEN_S0_APB

        assign s0_wdata      = s0_apb_pwdata;
        assign s0_addr       = s0_apb_paddr;
        assign s0_re         = s0_apb_psel & s0_apb_penable & ~s0_apb_pwrite & ~s0_pready & s0_gnt;
        assign s0_we         = s0_apb_psel & s0_apb_penable & s0_apb_pwrite & ~s0_pready & s0_gnt;
        assign s0_psel       = s0_apb_psel;
        assign s0_penable    = s0_apb_penable;
        assign s0_apb_prdata = s0_rdata;
        assign s0_apb_pready = s0_pready;

    end else begin : GEN_S0_AXI

        intel_fpga_axil2apb
        # (
        .P_S_AXI_ADDR_WIDTH  (P_S_AXI_ADDR_WIDTH),
        .P_S_AXI_DATA_WIDTH  (P_S_AXI_DATA_WIDTH),
        .P_WATCHDOG_EN       (1)
        ) axil2apb_s0 (
        .s_axi_aclk      (s_axi_aclk),
        .s_axi_aresetn   (aresetn),

        .s_axi_awprot    (s0_axi_awprot),
        .s_axi_arprot    (s0_axi_arprot),
        .s_axi_awaddr    (s0_axi_awaddr),
        .s_axi_awvalid   (s0_axi_awvalid),
        .s_axi_awready   (s0_axi_awready),
        .s_axi_wstrb     (s0_axi_wstrb),
        .s_axi_wdata     (s0_axi_wdata),
        .s_axi_wvalid    (s0_axi_wvalid),
        .s_axi_wready    (s0_axi_wready),
        .s_axi_bresp     (s0_axi_bresp),
        .s_axi_bvalid    (s0_axi_bvalid),
        .s_axi_bready    (s0_axi_bready),
        .s_axi_araddr    (s0_axi_araddr),
        .s_axi_arvalid   (s0_axi_arvalid),
        .s_axi_arready   (s0_axi_arready),
        .s_axi_rdata     (s0_axi_rdata),
        .s_axi_rresp     (s0_axi_rresp),
        .s_axi_rvalid    (s0_axi_rvalid),
        .s_axi_rready    (s0_axi_rready),

        .m_apb_paddr     (s0_addr),
        .m_apb_pwrite    (s0_pwrite),
        .m_apb_psel      (s0_psel),
        .m_apb_penable   (s0_penable),
        .m_apb_pwdata    (s0_wdata),
        .m_apb_prdata    (s0_rdata),
        .m_apb_pready    (s0_pready)
        );

        assign s0_re = ~s0_pwrite & s0_psel & s0_penable & ~s0_pready & s0_gnt;
        assign s0_we = s0_pwrite & s0_psel & s0_penable & ~s0_pready & s0_gnt;

    end //if


endgenerate

//----------------------------------------------------------------------------//
//                                 S1 Interface
//----------------------------------------------------------------------------//
generate
    if (P_S1_BUS_IS_AXI == 0) begin : GEN_S1_APB
        assign s1_wdata      = s1_apb_pwdata;
        assign s1_addr       = s1_apb_paddr;
        assign s1_re         = s1_apb_psel & s1_apb_penable & ~s1_apb_pwrite & ~s1_pready & s1_gnt;
        assign s1_we         = s1_apb_psel & s1_apb_penable & s1_apb_pwrite & ~s1_pready & s1_gnt;
        assign s1_psel       = s1_apb_psel;
        assign s1_penable    = s1_apb_penable;
        assign s1_apb_prdata = s1_rdata;
        assign s1_apb_pready = s1_pready;

    end else begin : GEN_S1_AXI

        intel_fpga_axil2apb
        # (
        .P_S_AXI_ADDR_WIDTH   (P_S_AXI_ADDR_WIDTH),
        .P_S_AXI_DATA_WIDTH   (P_S_AXI_DATA_WIDTH),
        .P_WATCHDOG_EN        (1)
        ) axil2apb_s0 (
        .s_axi_aclk      (s_axi_aclk),
        .s_axi_aresetn   (aresetn),

        .s_axi_awprot    (s1_axi_awprot),
        .s_axi_arprot    (s1_axi_arprot),
        .s_axi_awaddr    (s1_axi_awaddr),
        .s_axi_awvalid   (s1_axi_awvalid),
        .s_axi_awready   (s1_axi_awready),
        .s_axi_wstrb     (s1_axi_wstrb),
        .s_axi_wdata     (s1_axi_wdata),
        .s_axi_wvalid    (s1_axi_wvalid),
        .s_axi_wready    (s1_axi_wready),
        .s_axi_bresp     (s1_axi_bresp),
        .s_axi_bvalid    (s1_axi_bvalid),
        .s_axi_bready    (s1_axi_bready),
        .s_axi_araddr    (s1_axi_araddr),
        .s_axi_arvalid   (s1_axi_arvalid),
        .s_axi_arready   (s1_axi_arready),
        .s_axi_rdata     (s1_axi_rdata),
        .s_axi_rresp     (s1_axi_rresp),
        .s_axi_rvalid    (s1_axi_rvalid),
        .s_axi_rready    (s1_axi_rready),

        .m_apb_paddr     (s1_addr),
        .m_apb_pwrite    (s1_pwrite),
        .m_apb_psel      (s1_psel),
        .m_apb_penable   (s1_penable),
        .m_apb_pwdata    (s1_wdata),
        .m_apb_prdata    (s1_rdata),
        .m_apb_pready    (s1_pready)
    );

        assign s1_re = ~s1_pwrite & s1_psel & s1_penable & ~s1_pready & s1_gnt;
        assign s1_we = s1_pwrite & s1_psel & s1_penable & ~s1_pready & s1_gnt;

    end //if
endgenerate

//----------------------------------------------------------------------------//
// RAM address is for the word so strip off the bottom 2 bits of the AXI / APB
// byte address
assign addr_a    = s0_addr [$left(s0_addr) : 2];
assign addr_b    = s1_addr [$left(s1_addr) : 2];

always_ff @(posedge s_axi_aclk) begin
    if (areset == 'b1) begin
        s0_req <= 1'b0;
    end else begin
        if ((s0_psel == 'b1) && (s0_penable == 'b0)) begin
            s0_req <= 1'b1;
        end else if (s0_gnt == 1'b1) begin
            s0_req <= 1'b0;
        end //if
    end //if
end //always_ff

always_ff @(posedge s_axi_aclk) begin
    if (areset == 'b1) begin
        s0_gnt <= 1'b0;
    end else begin
        if (s0_req == 'b1) begin
            if (  (s1_req == 1'b0) && (s1_gnt == 1'b0)  ) begin
                s0_gnt <= 1'b1;
            end else begin
                if (  (s0_addr != s1_addr) || ((s0_addr == s1_addr) && (s01_priority == 1'b0))  ) begin
                    s0_gnt <= 1'b1;
                end //if
            end //if
        end else if ((s0_gnt == 1'b1) && (s0_pready == 'b1)) begin
            s0_gnt <= 1'b0;
        end //if
    end //if
end //always_ff

always_ff @(posedge s_axi_aclk) begin
    if (areset == 'b1) begin
        s1_req <= 1'b0;
    end else begin
        if ((s1_psel == 'b1) && (s1_penable == 'b0)) begin
            s1_req <= 1'b1;
        end else if (s1_gnt == 1'b1) begin
            s1_req <= 1'b0;
        end //if
    end //if
end //always_ff

always_ff @(posedge s_axi_aclk) begin
    if (areset == 'b1) begin
        s1_gnt <= 1'b0;
    end else begin
        if (s1_req == 'b1) begin
            if (  (s0_req == 1'b0) && (s0_gnt == 1'b0)  ) begin
                s1_gnt <= 1'b1;
            end else begin
                if (  (s0_addr != s1_addr) || ((s0_addr == s1_addr) && (s01_priority == 1'b1))  ) begin
                    s1_gnt <= 1'b1;
                end //if
            end //if
        end else if ((s1_gnt == 1'b1) && (s1_pready == 'b1)) begin
            s1_gnt <= 1'b0;
        end //if
    end //if
end //always_ff

always_ff @(posedge s_axi_aclk) begin
    if (areset == 'b1) begin
        s01_priority <= 1'b0;
    end else begin
        if (conflict == 1'b1) begin
            if (  (s0_gnt == 1'b1) && (s0_pready == 'b1) ) begin
                s01_priority <= 1'b1;
            end else if ( (s1_gnt == 1'b1) && (s1_pready == 'b1) ) begin
                s01_priority <= 1'b0;
            end //if
        end //if
    end //if
end //always_ff

always_ff @(posedge s_axi_aclk) begin
    if (areset == 'b1) begin
        conflict <= 1'b0;
    end else begin
        if (((s0_gnt == 1'b1) && (s0_pready == 'b1)) ||
            ((s1_gnt == 1'b1) && (s1_pready == 'b1))) begin
            conflict <= 1'b0;
        end else if ((s0_addr == s1_addr) && (
                    ((s0_req == 1'b1) && (s1_req == 1'b1)) ||
                    ((s0_req == 1'b1) && (s1_gnt == 1'b1)) ||
                    ((s1_req == 1'b1) && (s0_gnt == 1'b1)))) begin
            conflict <= 1'b1;
        end //if
    end //if
end //always

//----------------------------------------------------------------------------//
generate
    if (P_USE_ECC == 0) begin : GEN_NO_ECC
//--------------------------------------------------------------------------//
//                                 Bypass ECC
//--------------------------------------------------------------------------//
        assign data_in_a = s0_wdata;
        assign re_a      = s0_re;
        assign we_a      = s0_we;
        assign s0_rdata  = data_out_a;

        always_ff @(posedge s_axi_aclk) begin
            if ((s0_psel == 'b1) && (s0_penable == 'b1)) begin
                if (s0_pready == 'b1) begin
                    s0_pready <= 1'b0;
                end else begin
                    s0_pready <= 1'b1;
                end //if
            end else begin
                s0_pready <= 1'b0;
            end //if
        end //always_ff

        assign data_in_b = s1_wdata;
        assign we_b      = s1_we;
        assign re_b      = s1_re;
        assign s1_rdata  = data_out_b;

        always_ff @ (posedge s_axi_aclk) begin
            if ((s1_psel == 'b1) && (s1_penable == 'b1)) begin
                if (s1_pready == 'b1) begin
                    s1_pready <= 1'b0;
                end else begin
                    s1_pready <= 1'b1;
                end //if
            end else begin
                s1_pready <= 1'b0;
            end //if
        end //always_ff

        assign memory_fault_p = 1'b0;
        assign memory_fault_n = 1'b1;

    end else begin : GEN_ECC
  
//--------------------------------------------------------------------------//
//                              Instantiate ECC
//--------------------------------------------------------------------------//
        always_ff @ (posedge s_axi_aclk) begin
            we_a      <= s0_we;
            re_a      <= s0_re;
            s0_clk_en <= re_a & ~s0_pready;
        end //always_ff

        always_ff @(posedge s_axi_aclk) begin
            if ( (s0_psel == 'b1) && (s0_penable == 'b1) && ((s0_clk_en == 'b1) || (we_a == 1'b1)) ) begin
                if (s0_pready == 'b1) begin
                    s0_pready <= 1'b0;
                end else begin
                    s0_pready <= 1'b1;
                end //if
            end else begin
                s0_pready <= 1'b0;
            end //if
        end //always_ff

        always_ff @ (posedge s_axi_aclk) begin
            we_b      <= s1_we;
            re_b      <= s1_re;
            s1_clk_en <= re_b & ~s1_pready;
        end //always_ff

        always_ff @(posedge s_axi_aclk) begin
            if (  (s1_psel == 'b1) && (s1_penable == 'b1) && ((s1_clk_en == 'b1) || (we_b == 1'b1)) ) begin
                if (s1_pready == 'b1) begin
                    s1_pready <= 1'b0;
                end else begin
                    s1_pready <= 1'b1;
                end //if
            end else begin
                s1_pready <= 1'b0;
            end //if
        end //always_ff

        ecc_encoder ecc_encoder_0 (
            .data           (s0_wdata),           // data.data
            .q              (data_in_a),          // q.q
            .clock          (s_axi_aclk),         // clock.clock
            .aclr           (reset_ecc),
            .clocken        (s0_we)               // clocken.clocken
        );

        ecc_encoder ecc_encoder_1 (
            .data           (s1_wdata),           // data.data
            .q              (data_in_b),          // q.q
            .clock          (s_axi_aclk),         // clock.clock
            .aclr           (reset_ecc),
            .clocken        (s1_we)               // clocken.clocken
        );

        ecc_decoder ecc_decoder_0 (
            .data           (data_out_a),        // data.data
            .q              (s0_rdata),          // q.q
            .err_corrected  (),                  // err_corrected.err_corrected
            .err_detected   (),                  // err_detected.err_detected
            .err_fatal      (ecc_err_fatal[0]),  // err_fatal.err_fatal
            .syn_e          (),                  // syn_e.syn_e
            .clock          (s_axi_aclk),        // clock.clock
            .aclr           (reset_ecc),
            .clocken        (s0_clk_en)          // clocken.clocken
        );

        ecc_decoder ecc_decoder_1 (
            .data           (data_out_b),        // data.data
            .q              (s1_rdata),          // q.q
            .err_corrected  (),                  // err_corrected.err_corrected
            .err_detected   (),                  // err_detected.err_detected
            .err_fatal      (ecc_err_fatal[1]),  // err_fatal.err_fatal
            .syn_e          (),                  // syn_e.syn_e
            .clock          (s_axi_aclk),        // clock.clock
            .aclr           (reset_ecc),
            .clocken        (s1_clk_en)          // clocken.clocken
        );

        always_ff @ (posedge s_axi_aclk) begin
            if ((aresetn == 'b0) || (reset_safety_n == 1'b0)) begin
                memory_fault_p = 1'b0;
                memory_fault_n = 1'b1;
            end else if (ecc_err_fatal != 'd0) begin
                memory_fault_p = 1'b1;
                memory_fault_n = 1'b0;
            end //if
        end //if

    end //if
endgenerate

//----------------------------------------------------------------------------//
//                       Shared Memory - True Dual Port
//----------------------------------------------------------------------------//
intel_fpga_shared_mem_dpram
# (
    .P_RAMSTYLE     ("M20K"),
    .P_ADDR_WIDTH   (P_RAM_ADDR_WIDTH),
    .P_DATA_WIDTH   (P_RAM_DATA_WIDTH)
) intel_fpga_shared_mem_dpram_inst (
    .clk            (s_axi_aclk),
    .data_in_a      (data_in_a),
    .data_in_b      (data_in_b),
    .addr_a         (addr_a),
    .addr_b         (addr_b),
    .re_a           (re_a),
    .we_a           (we_a),
    .re_b           (re_b),
    .we_b           (we_b),
    .data_out_a     (data_out_a),
    .data_out_b     (data_out_b)
);

//****************************************************************************//
endmodule : intel_fpga_shared_mem
//****************************************************************************//

`default_nettype wire