//======================================================================
//
// blake2s_core.v
// --------------
// Verilog 2001 implementation of the hash function blake2s.
// This is the internal core with wide interfaces.
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

module blake2s_core(
                    input wire            clk,
                    input wire            reset_n,

                    input wire            init,
                    input wire            next,
                    input wire            finish,

                    input wire [511 : 0]  block,
                    input wire [5 : 0]    blocklen,

                    output wire [255 : 0] digest,
                    output wire           ready
                  );


  //----------------------------------------------------------------
  // Parameter block.
  // See Blake2 paper and RFC 7693 for definition.
  // Chapter 2.8 in https://blake2.net/blake2.pdf
  // Section 2.5 in https://tools.ietf.org/html/rfc7693
  //----------------------------------------------------------------
  // The digest length in bytes. Minimum: 1, Maximum: 32
  parameter [7 : 0] DIGEST_LENGTH = 8'd32;

  // The key length in bytes. Minimum: 0 (for no key used), Maximum: 32
  parameter [7 : 0] KEY_LENGTH = 8'd0;

  // Fanout.
  parameter [7 : 0] FANOUT = 8'd1;

  // Depth (maximal)
  parameter [7 : 0] DEPTH = 8'd01;

  // 4-byte leaf length
  parameter [31 : 0] LEAF_LENGTH = 32'd0;

  // 8-byte node offset
  parameter [47 : 0] NODE_OFFSET = 48'd0;

  // Node Depth
  parameter [7 : 0] NODE_DEPTH = 8'd0;

  // Inner hash length
  parameter [7 : 0] INNER_LENGTH = 8'd0;

  // 16-byte salt, little-endian byte order
  parameter [63 : 0] SALT = 64'h0;

  // 16-byte personalization, little-endian byte order
  parameter [63 : 0] PERSONALIZATION = 64'h0;

  wire [255 : 0] parameter_block = {PERSONALIZATION, SALT, INNER_LENGTH,
                                    NODE_DEPTH, NODE_OFFSET, LEAF_LENGTH, DEPTH,
                                    FANOUT, KEY_LENGTH, DIGEST_LENGTH};


  //----------------------------------------------------------------
  // Internal constant definitions.
  //----------------------------------------------------------------
  localparam NUM_ROUNDS = 10;

  // G function modes.
  localparam G_ROW      = 1'h0;
  localparam G_DIAGONAL = 1'h1;

  // Initial vectors.
  localparam IV0 = 32'h6a09e667;
  localparam IV1 = 32'hbb67ae85;
  localparam IV2 = 32'h3c6ef372;
  localparam IV3 = 32'ha54ff53a;
  localparam IV4 = 32'h510e527f;
  localparam IV5 = 32'h9b05688c;
  localparam IV6 = 32'h1f83d9ab;
  localparam IV7 = 32'h5be0cd19;

  // Control FSM state names.
  localparam CTRL_IDLE       = 3'h0;
  localparam CTRL_G_ROW      = 3'h1;
  localparam CTRL_G_DIAGONAL = 3'h2;
  localparam CTRL_COMP_DONE  = 3'h3;
  localparam CTRL_FINISH     = 3'h4;


  localparam BLAKE2S_BLOCKBYTES = 32'd64;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0] h_reg [0 : 7];
  reg [31 : 0] h_new [0 : 7];
  reg          h_we;

  reg [31 : 0] v_reg [0 : 15];
  reg [31 : 0] v_new [0 : 15];
  reg          v_we;
  reg          init_v;
  reg          update_v;

  reg          G_mode_reg;
  reg          G_mode_new;
  reg          G_mode_we;
  reg          G_mode_inc;
  reg          G_mode_rst;

  reg [3 : 0]  round_ctr_reg;
  reg [3 : 0]  round_ctr_new;
  reg          round_ctr_we;
  reg          round_ctr_inc;
  reg          round_ctr_rst;

  reg [31 : 0] t0_reg;
  reg [31 : 0] t0_new;
  reg          t0_we;
  reg [31 : 0] t1_reg;
  reg [31 : 0] t1_new;
  reg          t1_we;
  reg          t_ctr_inc;
  reg          t_ctr_rst;

  reg [31 : 0] f0_reg;
  reg [31 : 0] f0_new;
  reg          f0_we;

  reg [31 : 0] f1_reg;
  reg [31 : 0] f1_new;
  reg          f1_we;

  reg  ready_reg;
  reg  ready_new;
  reg  ready_we;

  reg [2 : 0] blake2s_ctrl_reg;
  reg [2 : 0] blake2s_ctrl_new;
  reg         blake2s_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg init_state;
  reg update_state;
  reg load_m;
  reg fix_final_block;
  reg update_chain_value;

  reg  [31 : 0] G0_a;
  reg  [31 : 0] G0_b;
  reg  [31 : 0] G0_c;
  reg  [31 : 0] G0_d;
  wire [31 : 0] G0_m0;
  wire [31 : 0] G0_m1;
  wire [31 : 0] G0_a_prim;
  wire [31 : 0] G0_b_prim;
  wire [31 : 0] G0_c_prim;
  wire [31 : 0] G0_d_prim;

  reg  [31 : 0] G1_a;
  reg  [31 : 0] G1_b;
  reg  [31 : 0] G1_c;
  reg  [31 : 0] G1_d;
  wire [31 : 0] G1_m0;
  wire [31 : 0] G1_m1;
  wire [31 : 0] G1_a_prim;
  wire [31 : 0] G1_b_prim;
  wire [31 : 0] G1_c_prim;
  wire [31 : 0] G1_d_prim;

  reg  [31 : 0] G2_a;
  reg  [31 : 0] G2_b;
  reg  [31 : 0] G2_c;
  reg  [31 : 0] G2_d;
  wire [31 : 0] G2_m0;
  wire [31 : 0] G2_m1;
  wire [31 : 0] G2_a_prim;
  wire [31 : 0] G2_b_prim;
  wire [31 : 0] G2_c_prim;
  wire [31 : 0] G2_d_prim;

  reg  [31 : 0] G3_a;
  reg  [31 : 0] G3_b;
  reg  [31 : 0] G3_c;
  reg  [31 : 0] G3_d;
  wire [31 : 0] G3_m0;
  wire [31 : 0] G3_m1;
  wire [31 : 0] G3_a_prim;
  wire [31 : 0] G3_b_prim;
  wire [31 : 0] G3_c_prim;
  wire [31 : 0] G3_d_prim;


  //----------------------------------------------------------------
  // Module instantations.
  //----------------------------------------------------------------
  blake2s_m_select mselect(
                           .clk(clk),
                           .reset_n(reset_n),
                           .load(load_m),
                           .m(block),
                           .r(round_ctr_reg),
                           .mode(G_mode_reg),
                           .G0_m0(G0_m0),
                           .G0_m1(G0_m1),
                           .G1_m0(G1_m0),
                           .G1_m1(G1_m1),
                           .G2_m0(G2_m0),
                           .G2_m1(G2_m1),
                           .G3_m0(G3_m0),
                           .G3_m1(G3_m1)
                          );


  blake2s_G G0(
               .a(G0_a),
               .b(G0_b),
               .c(G0_c),
               .d(G0_d),
               .m0(G0_m0),
               .m1(G0_m1),
               .a_prim(G0_a_prim),
               .b_prim(G0_b_prim),
               .c_prim(G0_c_prim),
               .d_prim(G0_d_prim)
              );


  blake2s_G G1(
               .a(G1_a),
               .b(G1_b),
               .c(G1_c),
               .d(G1_d),
               .m0(G1_m0),
               .m1(G1_m1),
               .a_prim(G1_a_prim),
               .b_prim(G1_b_prim),
               .c_prim(G1_c_prim),
               .d_prim(G1_d_prim)
              );


  blake2s_G G2(
               .a(G2_a),
               .b(G2_b),
               .c(G2_c),
               .d(G2_d),
               .m0(G2_m0),
               .m1(G2_m1),

               .a_prim(G2_a_prim),
               .b_prim(G2_b_prim),
               .c_prim(G2_c_prim),
               .d_prim(G2_d_prim)
              );


  blake2s_G G3(
               .a(G3_a),
               .b(G3_b),
               .c(G3_c),
               .d(G3_d),
               .m0(G3_m0),
               .m1(G3_m1),
               .a_prim(G3_a_prim),
               .b_prim(G3_b_prim),
               .c_prim(G3_c_prim),
               .d_prim(G3_d_prim)
              );


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  // Note little to big endian conversion.
  assign digest = {h_reg[0][7:0], h_reg[0][15:8], h_reg[0][23:16], h_reg[0][31:24],
                   h_reg[1][7:0], h_reg[1][15:8], h_reg[1][23:16], h_reg[1][31:24],
                   h_reg[2][7:0], h_reg[2][15:8], h_reg[2][23:16], h_reg[2][31:24],
                   h_reg[3][7:0], h_reg[3][15:8], h_reg[3][23:16], h_reg[3][31:24],
                   h_reg[4][7:0], h_reg[4][15:8], h_reg[4][23:16], h_reg[4][31:24],
                   h_reg[5][7:0], h_reg[5][15:8], h_reg[5][23:16], h_reg[5][31:24],
                   h_reg[6][7:0], h_reg[6][15:8], h_reg[6][23:16], h_reg[6][31:24],
                   h_reg[7][7:0], h_reg[7][15:8], h_reg[7][23:16], h_reg[7][31:24]};

  assign ready = ready_reg;


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
          for (i = 0; i < 8; i = i + 1)
            h_reg[i] <= 32'h0;

          for (i = 0; i < 16; i = i + 1)
            v_reg[i] <= 32'h0;

          t0_reg           <= 32'h0;
          t1_reg           <= 32'h0;
          f0_reg           <= 32'h0;
          f1_reg           <= 32'h0;
          ready_reg        <= 1'h1;
          G_mode_reg       <= G_ROW;
          round_ctr_reg       <= 4'h0;
          blake2s_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (h_we)
            begin
              for (i = 0; i < 8; i = i + 1)
                h_reg[i] <= h_new[i];
            end

          if (v_we)
            begin
              for (i = 0; i < 8; i = i + 1)
                v_reg[i] <= v_new[i];
            end

          if (t0_we)
            t0_reg <= t0_new;

          if (t1_we)
            t1_reg <= t1_new;

          if (f0_we)
            f0_reg <= f0_new;

          if (f1_we)
            f1_reg <= f1_new;

          if (ready_we)
            ready_reg <= ready_new;

          if (G_mode_we)
            G_mode_reg <= G_mode_new;

          if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

          if (blake2s_ctrl_we)
            blake2s_ctrl_reg <= blake2s_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // chain_logic
  //
  // Logic for updating the chain registers.
  //----------------------------------------------------------------
  always @*
    begin : chain_logic
      integer i;

      for (i = 0; i < 8; i = i + 1)
        h_new[i] = 32'h0;
      h_we   = 1'h0;

      if (init_state)
        begin
          h_new[0] = IV0 ^ parameter_block[31:0];
          h_new[1] = IV1 ^ parameter_block[63:32];
          h_new[2] = IV2 ^ parameter_block[95:64];
          h_new[3] = IV3 ^ parameter_block[127:96];
          h_new[4] = IV4 ^ parameter_block[159:128];
          h_new[5] = IV5 ^ parameter_block[191:160];
          h_new[6] = IV6 ^ parameter_block[223:192];
          h_new[7] = IV7 ^ parameter_block[255:224];
          h_we = 1;
        end

      if (update_chain_value)
        begin
          h_new[0] = h_reg[0] ^ v_reg[0] ^ v_reg[8];
          h_new[1] = h_reg[1] ^ v_reg[1] ^ v_reg[9];
          h_new[2] = h_reg[2] ^ v_reg[2] ^ v_reg[10];
          h_new[3] = h_reg[3] ^ v_reg[3] ^ v_reg[11];
          h_new[4] = h_reg[4] ^ v_reg[4] ^ v_reg[12];
          h_new[5] = h_reg[5] ^ v_reg[5] ^ v_reg[13];
          h_new[6] = h_reg[6] ^ v_reg[6] ^ v_reg[14];
          h_new[7] = h_reg[7] ^ v_reg[7] ^ v_reg[15];
          h_we = 1;
        end
    end // chain_logic


  //----------------------------------------------------------------
  // compress_logic
  //----------------------------------------------------------------
  always @*
    begin : compress_logic
      integer i;

      f0_new = 32'h0;;

      for (i = 0; i < 16; i = i + 1)
        v_new[i] = 32'h0;
      v_we = 1'h0;

      G0_a = 32'h0;
      G0_b = 32'h0;
      G0_c = 32'h0;
      G0_d = 32'h0;
      G1_a = 32'h0;
      G1_b = 32'h0;
      G1_c = 32'h0;
      G1_d = 32'h0;
      G2_a = 32'h0;
      G2_b = 32'h0;
      G2_c = 32'h0;
      G2_d = 32'h0;
      G3_a = 32'h0;
      G3_b = 32'h0;
      G3_c = 32'h0;
      G3_d = 32'h0;

      if (init_v)
        begin
          v_new[0]  = h_reg[0];
          v_new[1]  = h_reg[0];
          v_new[2]  = h_reg[0];
          v_new[3]  = h_reg[0];
          v_new[4]  = h_reg[0];
          v_new[5]  = h_reg[0];
          v_new[6]  = h_reg[0];
          v_new[7]  = h_reg[0];
          v_new[8]  = IV0;
          v_new[9]  = IV1;
          v_new[10] = IV2;
          v_new[11] = IV3;
          v_new[12] = t0_reg ^ IV4;
          v_new[13] = t1_reg ^ IV5;
          v_new[14] = f0_reg ^ IV6;
          v_new[15] = f1_reg ^ IV7;
          v_we = 1;
        end

      if (update_v)
        begin
          v_we = 1;

          if (G_mode_reg == G_ROW)
            begin
              G0_a      = v_reg[0];
              G0_b      = v_reg[4];
              G0_c      = v_reg[8];
              G0_d      = v_reg[12];
              v_new[0]  = G0_a_prim;
              v_new[4]  = G0_b_prim;
              v_new[8]  = G0_c_prim;
              v_new[12] = G0_d_prim;

              G1_a      = v_reg[1];
              G1_b      = v_reg[5];
              G1_c      = v_reg[9];
              G1_d      = v_reg[13];
              v_new[1]  = G1_a_prim;
              v_new[5]  = G1_b_prim;
              v_new[9]  = G1_c_prim;
              v_new[13] = G1_d_prim;

              G2_a      = v_reg[2];
              G2_b      = v_reg[6];
              G2_c      = v_reg[10];
              G2_d      = v_reg[14];
              v_new[2]  = G2_a_prim;
              v_new[6]  = G2_b_prim;
              v_new[10] = G2_c_prim;
              v_new[14] = G2_d_prim;

              G3_a      = v_reg[3];
              G3_b      = v_reg[7];
              G3_c      = v_reg[11];
              G3_d      = v_reg[15];
              v_new[3]  = G3_a_prim;
              v_new[7]  = G3_b_prim;
              v_new[11] = G3_c_prim;
              v_new[15] = G3_d_prim;
            end

          else
            begin
              // Diagonal updates.
              G0_a      = v_reg[0];
              G0_b      = v_reg[5];
              G0_c      = v_reg[10];
              G0_d      = v_reg[15];
              v_new[0]  = G0_a_prim;
              v_new[5]  = G0_b_prim;
              v_new[10] = G0_c_prim;
              v_new[15] = G0_d_prim;

              G1_a      = v_reg[1];
              G1_b      = v_reg[6];
              G1_c      = v_reg[11];
              G1_d      = v_reg[12];
              v_new[1]  = G1_a_prim;
              v_new[6]  = G1_b_prim;
              v_new[11] = G1_c_prim;
              v_new[12] = G1_d_prim;

              G2_a      = v_reg[2];
              G2_b      = v_reg[7];
              G2_c      = v_reg[8];
              G2_d      = v_reg[13];
              v_new[2]  = G2_a_prim;
              v_new[7]  = G2_b_prim;
              v_new[8]  = G2_c_prim;
              v_new[13] = G2_d_prim;

              G3_a      = v_reg[3];
              G3_b      = v_reg[4];
              G3_c      = v_reg[9];
              G3_d      = v_reg[14];
              v_new[3]  = G3_a_prim;
              v_new[4]  = G3_b_prim;
              v_new[9]  = G3_c_prim;
              v_new[14] = G3_d_prim;
            end // else: !if(G_mode_reg == STATE_G0)
        end // if (update_state)
    end // compress_logic


  //----------------------------------------------------------------
  // G_mode
  // Update logic for the G mode. Basically a one bit
  // counter that selects if we column of diaginal updates.
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : G_mode
      G_mode_new = G_ROW;
      G_mode_we  = 1'h0;

      if (G_mode_rst)
        begin
          G_mode_new = G_ROW;
          G_mode_we  = 1;
        end

      if (G_mode_inc)
        begin
          G_mode_new = G_mode_reg + 1'b1;
          G_mode_we  = 1;
        end
    end // G_mode


  //----------------------------------------------------------------
  // round_ctr
  // Update logic for the round counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : round_ctr
      round_ctr_new = 4'h0;
      round_ctr_we  = 1'h0;

      if (round_ctr_rst)
        begin
          round_ctr_new = 4'h0;
          round_ctr_we  = 1'h1;
        end

      if (round_ctr_inc)
        begin
          round_ctr_new = round_ctr_reg + 1'b1;
          round_ctr_we  = 1'h1;
        end
    end // round_ctr


  //----------------------------------------------------------------
  // t_ctr
  // Update logic for the length counter t, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : t_ctr
      t0_new = 32'h0;
      t0_we  = 1'h1;
      t1_new = 32'h0;
      t1_we  = 1'h1;

      if (t_ctr_rst)
        begin
          t0_we = 1'h1;
          t1_we = 1'h1;
        end

      if (t_ctr_inc)
        begin
          t0_we = 1'h1;
          t1_we = 1'h1;

          if (fix_final_block)
            t0_new = t0_reg + blocklen;
          else
            t0_new = t0_reg + BLAKE2S_BLOCKBYTES;

          if (t0_new < t0_reg)
            t1_new = t1_reg + 1'h1;
          else
            t1_new = t1_reg + 1'h1;
        end
    end // t_ctr


  //----------------------------------------------------------------
  // blake2s_ctrl_fsm
  // Logic for the state machine controlling the core behaviour.
  //----------------------------------------------------------------
  always @*
    begin : blake2s_ctrl_fsm
      init_state         = 1'h0;
      update_state       = 1'h0;
      init_v             = 1'h0;
      update_v           = 1'h0;
      fix_final_block    = 1'h0;
      load_m             = 1'h0;
      G_mode_inc         = 1'h0;
      G_mode_rst         = 1'h0;
      round_ctr_inc      = 1'h0;
      round_ctr_rst      = 1'h0;
      t_ctr_inc          = 1'h0;
      t_ctr_rst          = 1'h0;
      f1_new             = 32'h0;
      f1_we              = 1'h0;
      update_chain_value = 1'h0;
      ready_new          = 1'h0;
      ready_we           = 1'h0;
      blake2s_ctrl_new   = CTRL_IDLE;
      blake2s_ctrl_we    = 1'h0;


      case (blake2s_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                init_state = 1'h1;
              end

            if (next)
              begin
                ready_new        = 1'h0;
                ready_we         = 1'h1;
                init_v           = 1'h1;
                load_m           = 1'h1;
                G_mode_rst       = 1'h1;
                round_ctr_rst    = 1'h1;
                blake2s_ctrl_new = CTRL_G_ROW;
                blake2s_ctrl_we  = 1'h1;
              end
          end


        CTRL_G_ROW:
          begin
            update_v         = 1'h1;
            blake2s_ctrl_new = CTRL_G_DIAGONAL;
            blake2s_ctrl_we  = 1'h1;
          end


        CTRL_G_DIAGONAL:
          begin
            update_v         = 1'h1;
            round_ctr_inc    = 1'h1;
            if (round_ctr_reg == (NUM_ROUNDS - 1))
              begin
                blake2s_ctrl_new = CTRL_COMP_DONE;
                blake2s_ctrl_we  = 1'h1;
              end
            else
              begin
                blake2s_ctrl_new = CTRL_G_ROW;
                blake2s_ctrl_we  = 1'h1;
              end
          end


        CTRL_COMP_DONE:
          begin
            update_state     = 1'h1;
            ready_new        = 1'h1;
            ready_we         = 1'h1;
            blake2s_ctrl_new = CTRL_IDLE;
            blake2s_ctrl_we  = 1'h1;
          end


        CTRL_FINISH:
          begin
            update_chain_value = 1'h1;
            ready_new          = 1'h1;
            ready_we           = 1'h1;
            blake2s_ctrl_new   = CTRL_IDLE;
            blake2s_ctrl_we    = 1'h1;
          end


        default:
          begin
          end
      endcase // case (blake2s_ctrl_reg)
    end // blake2s_ctrl_fsm
endmodule // blake2s_core

//======================================================================
// EOF blake2s_core.v
//======================================================================
