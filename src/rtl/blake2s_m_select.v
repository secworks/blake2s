//======================================================================
//
// blake2s_m_select.v
// ------------------
// Verilog 2001 implementation of the message word selection in the
// blake2 hash function core. Based on the given round we extract
// the indices for the four different sets of m words to select.
// The words are then selected and returned. This is basically a
// mux based implementation of the permutation table in combination
// with the actual word selection.
//
//
// Note that we use the state to signal which indices to select
// for a given round. This is because we don't do 8 G functions
// in a single cycle.
//
//
// Author: Joachim Strömbergson
// Copyright (c) 2018, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module blake2s_m_select(
                        input wire           clk,
                        input wire           reset_n,

                        input wire           load,

                        input wire [511 : 0] m,
                        input wire [3 : 0]   r,
                        input wire           mode,

                        output wire [31 : 0] G0_m0,
                        output wire [31 : 0] G0_m1,
                        output wire [31 : 0] G1_m0,
                        output wire [31 : 0] G1_m1,
                        output wire [31 : 0] G2_m0,
                        output wire [31 : 0] G2_m1,
                        output wire [31 : 0] G3_m0,
                        output wire [31 : 0] G3_m1
                       );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // Ten rounds, but with row and diagonal modes indicated by LSB.
  parameter R0_0 = 5'd0;
  parameter R0_1 = 5'd1;
  parameter R1_0 = 5'd2;
  parameter R1_1 = 5'd3;
  parameter R2_0 = 5'd4;
  parameter R2_1 = 5'd5;
  parameter R3_0 = 5'd6;
  parameter R3_1 = 5'd7;
  parameter R4_0 = 5'd8;
  parameter R4_1 = 5'd9;
  parameter R5_0 = 5'd10;
  parameter R5_1 = 5'd11;
  parameter R6_0 = 5'd12;
  parameter R6_1 = 5'd13;
  parameter R7_0 = 5'd14;
  parameter R7_1 = 5'd15;
  parameter R8_0 = 5'd16;
  parameter R8_1 = 5'd17;
  parameter R9_0 = 5'd18;
  parameter R9_1 = 5'd19;


  //----------------------------------------------------------------
  // regs.
  //----------------------------------------------------------------
  reg [31 : 0] m_mem [0 : 15];


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [3 : 0] G0_m0_i;
  reg [3 : 0] G0_m1_i;
  reg [3 : 0] G1_m0_i;
  reg [3 : 0] G1_m1_i;
  reg [3 : 0] G2_m0_i;
  reg [3 : 0] G2_m1_i;
  reg [3 : 0] G3_m0_i;
  reg [3 : 0] G3_m1_i;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports.
  //----------------------------------------------------------------
  // Muxes that extract the message block words.
  assign G0_m0 = m_mem[G0_m0_i];
  assign G0_m1 = m_mem[G0_m1_i];

  assign G1_m0 = m_mem[G1_m0_i];
  assign G1_m1 = m_mem[G1_m1_i];

  assign G2_m0 = m_mem[G2_m0_i];
  assign G2_m1 = m_mem[G2_m1_i];

  assign G3_m0 = m_mem[G3_m0_i];
  assign G3_m1 = m_mem[G3_m1_i];


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < 16 ; i = i + 1)
            m_mem[i] <= 32'h0;
        end
      else
        begin
          if (load)
            begin
              // Big to little endian conversion during register load.
              m_mem[15] <= {m[0007 : 0000], m[0015 : 0008], m[0023 : 0016], m[0031 : 0024]};
              m_mem[14] <= {m[0039 : 0032], m[0047 : 0040], m[0055 : 0048], m[0063 : 0056]};
              m_mem[13] <= {m[0071 : 0064], m[0079 : 0072], m[0087 : 0080], m[0095 : 0088]};
              m_mem[12] <= {m[0103 : 0096], m[0111 : 0104], m[0119 : 0112], m[0127 : 0120]};
              m_mem[11] <= {m[0135 : 0128], m[0143 : 0136], m[0151 : 0144], m[0159 : 0152]};
              m_mem[10] <= {m[0167 : 0160], m[0175 : 0168], m[0183 : 0176], m[0191 : 0184]};
              m_mem[09] <= {m[0199 : 0192], m[0207 : 0200], m[0215 : 0208], m[0223 : 0216]};
              m_mem[08] <= {m[0231 : 0224], m[0239 : 0232], m[0247 : 0240], m[0255 : 0248]};
              m_mem[07] <= {m[0263 : 0256], m[0271 : 0264], m[0279 : 0272], m[0287 : 0280]};
              m_mem[06] <= {m[0295 : 0288], m[0303 : 0296], m[0311 : 0304], m[0319 : 0312]};
              m_mem[05] <= {m[0327 : 0320], m[0335 : 0328], m[0343 : 0336], m[0351 : 0344]};
              m_mem[04] <= {m[0359 : 0352], m[0367 : 0360], m[0375 : 0368], m[0383 : 0376]};
              m_mem[03] <= {m[0391 : 0384], m[0399 : 0392], m[0407 : 0400], m[0415 : 0408]};
              m_mem[02] <= {m[0423 : 0416], m[0431 : 0424], m[0439 : 0432], m[0447 : 0440]};
              m_mem[01] <= {m[0455 : 0448], m[0463 : 0456], m[0471 : 0464], m[0479 : 0472]};
              m_mem[00] <= {m[0487 : 0480], m[0495 : 0488], m[0503 : 0496], m[0511 : 0504]};
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // get_indices
  //
  // Get the indices from the permutation table given the
  // round and the G function mode. This is the SIGMA table.
  //----------------------------------------------------------------
  always @*
    begin : get_indices
      G0_m0_i = 4'h0;
      G0_m1_i = 4'h0;
      G1_m0_i = 4'h0;
      G1_m1_i = 4'h0;
      G2_m0_i = 4'h0;
      G2_m1_i = 4'h0;
      G3_m0_i = 4'h0;
      G3_m1_i = 4'h0;

      case ({mode, r})
        R0_0:
          begin
            G0_m0_i = 0;
            G0_m1_i = 1;
            G1_m0_i = 2;
            G1_m1_i = 3;
            G2_m0_i = 4;
            G2_m1_i = 5;
            G3_m0_i = 6;
            G3_m1_i = 7;
          end

        R0_1:
          begin
            G0_m0_i = 8;
            G0_m1_i = 9;
            G1_m0_i = 10;
            G1_m1_i = 11;
            G2_m0_i = 12;
            G2_m1_i = 13;
            G3_m0_i = 14;
            G3_m1_i = 15;
          end

        R1_0:
          begin
            G0_m0_i = 14;
            G0_m1_i = 10;
            G1_m0_i = 4;
            G1_m1_i = 8;
            G2_m0_i = 9;
            G2_m1_i = 15;
            G3_m0_i = 13;
            G3_m1_i = 6;
          end

        R1_1:
          begin
            G0_m0_i = 1;
            G0_m1_i = 12;
            G1_m0_i = 0;
            G1_m1_i = 2;
            G2_m0_i = 11;
            G2_m1_i = 7;
            G3_m0_i = 5;
            G3_m1_i = 3;
          end

        R2_0:
          begin
            G0_m0_i = 11;
            G0_m1_i = 8;
            G1_m0_i = 12;
            G1_m1_i = 0;
            G2_m0_i = 5;
            G2_m1_i = 2;
            G3_m0_i = 15;
            G3_m1_i = 13;
          end

        R2_1:
          begin
            G0_m0_i = 10;
            G0_m1_i = 14;
            G1_m0_i = 3;
            G1_m1_i = 6;
            G2_m0_i = 7;
            G2_m1_i = 1;
            G3_m0_i = 9;
            G3_m1_i = 4;
          end

        R3_0:
          begin
            G0_m0_i = 7;
            G0_m1_i = 9;
            G1_m0_i = 3;
            G1_m1_i = 1;
            G2_m0_i = 13;
            G2_m1_i = 12;
            G3_m0_i = 11;
            G3_m1_i = 14;
          end

        R3_1:
          begin
            G0_m0_i = 2;
            G0_m1_i = 6;
            G1_m0_i = 5;
            G1_m1_i = 10;
            G2_m0_i = 4;
            G2_m1_i = 0;
            G3_m0_i = 15;
            G3_m1_i = 8;
          end

        R4_0:
          begin
            G0_m0_i = 9;
            G0_m1_i = 0;
            G1_m0_i = 5;
            G1_m1_i = 7;
            G2_m0_i = 2;
            G2_m1_i = 4;
            G3_m0_i = 10;
            G3_m1_i = 15;
          end

        R4_1:
          begin
            G0_m0_i = 14;
            G0_m1_i = 1;
            G1_m0_i = 11;
            G1_m1_i = 12;
            G2_m0_i = 6;
            G2_m1_i = 8;
            G3_m0_i = 3;
            G3_m1_i = 13;
          end

        R5_0:
          begin
            G0_m0_i = 2;
            G0_m1_i = 12;
            G1_m0_i = 6;
            G1_m1_i = 10;
            G2_m0_i = 0;
            G2_m1_i = 11;
            G3_m0_i = 8;
            G3_m1_i = 3;
          end

        R5_1:
          begin
            G0_m0_i = 4;
            G0_m1_i = 13;
            G1_m0_i = 7;
            G1_m1_i = 5;
            G2_m0_i = 15;
            G2_m1_i = 14;
            G3_m0_i = 1;
            G3_m1_i = 9;
          end

        R6_0:
          begin
            G0_m0_i = 12;
            G0_m1_i = 5;
            G1_m0_i = 1;
            G1_m1_i = 15;
            G2_m0_i = 14;
            G2_m1_i = 13;
            G3_m0_i = 4;
            G3_m1_i = 10;
          end

        R6_1:
          begin
            G0_m0_i = 0;
            G0_m1_i = 7;
            G1_m0_i = 6;
            G1_m1_i = 3;
            G2_m0_i = 9;
            G2_m1_i = 2;
            G3_m0_i = 8;
            G3_m1_i = 11;
          end

        R7_0:
          begin
            G0_m0_i = 13;
            G0_m1_i = 11;
            G1_m0_i = 7;
            G1_m1_i = 14;
            G2_m0_i = 12;
            G2_m1_i = 1;
            G3_m0_i = 3;
            G3_m1_i = 9;
          end

        R7_1:
          begin
            G0_m0_i = 5;
            G0_m1_i = 0;
            G1_m0_i = 15;
            G1_m1_i = 4;
            G2_m0_i = 8;
            G2_m1_i = 6;
            G3_m0_i = 2;
            G3_m1_i = 10;
          end

        R8_0:
          begin
            G0_m0_i = 6;
            G0_m1_i = 15;
            G1_m0_i = 14;
            G1_m1_i = 9;
            G2_m0_i = 11;
            G2_m1_i = 3;
            G3_m0_i = 0;
            G3_m1_i = 8;
          end

        R8_1:
          begin
            G0_m0_i = 12;
            G0_m1_i = 2;
            G1_m0_i = 13;
            G1_m1_i = 7;
            G2_m0_i = 1;
            G2_m1_i = 4;
            G3_m0_i = 10;
            G3_m1_i = 5;
          end

        R9_0:
          begin
            G0_m0_i = 10;
            G0_m1_i = 2;
            G1_m0_i = 8;
            G1_m1_i = 4;
            G2_m0_i = 7;
            G2_m1_i = 6;
            G3_m0_i = 1;
            G3_m1_i = 5;
          end

        R9_1:
          begin
            G0_m0_i = 15;
            G0_m1_i = 11;
            G1_m0_i = 9;
            G1_m1_i = 14;
            G2_m0_i = 3;
            G2_m1_i = 12;
            G3_m0_i = 13;
            G3_m1_i = 0;
          end

        default:
          begin
          end
      endcase // case ({r, state})
    end

endmodule // blake2s_m_select

//======================================================================
// EOF blake2s_m_select.v
//======================================================================
