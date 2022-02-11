//======================================================================
//
// tb_blake2s_core.v
// ------------------
// Testbench for the Blake2s core function.
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

module tb_blake2s_core();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;
  parameter VERBOSE = 0;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [63 : 0]   cycle_ctr;
  reg [31 : 0]   error_ctr;
  reg [31 : 0]   tc_ctr;
  reg            display_cycle_ctr;
  reg            display_dut_state;

  reg            tb_clk;
  reg            tb_reset_n;

  reg            tb_init;
  reg            tb_update;
  reg            tb_finish;
  reg [511 : 0]  tb_block;
  reg [6 : 0]    tb_blocklen;
  wire [255 : 0] tb_digest;
  wire           tb_ready;


  //----------------------------------------------------------------
  // Device under test.
  //----------------------------------------------------------------
  blake2s_core dut(
                   .clk(tb_clk),
                   .reset_n(tb_reset_n),

                   .init(tb_init),
                   .update(tb_update),
                   .finish(tb_finish),

                   .block(tb_block),
                   .blocklen(tb_blocklen),

                   .digest(tb_digest),
                   .ready(tb_ready)
                   );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD tb_clk = !tb_clk;
    end // clk_gen


  //--------------------------------------------------------------------
  // dut_monitor
  //
  // Monitor displaying information every cycle.
  // Includes the cycle counter.
  //--------------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : dut_monitor
      cycle_ctr = cycle_ctr + 1;

      if (display_cycle_ctr)
        begin
          $display("cycle = %016x:", cycle_ctr);
          $display("");
        end

      if (display_dut_state)
        dump_dut_state();
    end // dut_monitor


  //----------------------------------------------------------------
  // dump_dut_state
  //
  // Dump the internal state of the dut to std out.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("-------------------------------------------------------------------------------------");
      $display("");
      $display("DUT internal state");
      $display("------------------");
      $display("init:    0x%01x, update: 0x%01x, finish: 0x%01x", dut.init, dut.update, dut.finish);
      $display("block M: 0x%064x", dut.block[511 : 256]);
      $display("block L: 0x%064x", dut.block[255 : 000]);
      $display("ready:   0x%01x", dut.ready);
      $display("");
      $display("blake2s_ctrl_reg: 0x%02x, blake2s_ctrl_new: 0x%02x, blake2s_ctrl_we: 0x%01x",
               dut.blake2s_ctrl_reg, dut.blake2s_ctrl_new, dut.blake2s_ctrl_we);
      $display("");
      $display("h0: 0x%08x, h1: 0x%08x, h2: 0x%08x, h3: 0x%08x",
               dut.h_reg[0], dut.h_reg[1], dut.h_reg[2], dut.h_reg[3]);
      $display("h4: 0x%08x, h5: 0x%08x, h6: 0x%08x, h7: 0x%08x",
               dut.h_reg[4], dut.h_reg[5], dut.h_reg[6], dut.h_reg[7]);
      $display("");
      $display("v0:  0x%08x, v1:  0x%08x, v2:  0x%08x, v3:  0x%08x",
               dut.v_reg[0], dut.v_reg[1], dut.v_reg[2], dut.v_reg[3]);
      $display("v4:  0x%08x, v5:  0x%08x, v6:  0x%08x, v7:  0x%08x",
               dut.v_reg[4], dut.v_reg[5], dut.v_reg[6], dut.v_reg[7]);
      $display("v8:  0x%08x, v9:  0x%08x, v10: 0x%08x, v11: 0x%08x",
               dut.v_reg[8], dut.v_reg[8], dut.v_reg[10], dut.v_reg[11]);
      $display("v12: 0x%08x, v13: 0x%08x, v14: 0x%08x, v15: 0x%08x",
               dut.v_reg[12], dut.v_reg[13], dut.v_reg[14], dut.v_reg[15]);
      $display("");
      $display("t0_reg: 0x%08x, t0_new: 0x%08x", dut.t0_reg, dut.t0_new);
      $display("t1_reg: 0x%08x, t1_new: 0x%08x", dut.t1_reg, dut.t1_new);
      $display("");
      $display("f0_reg: 0x%08x, f0_new: 0x%08x", dut.f0_reg, dut.f0_new);
      $display("f1_reg: 0x%08x, f1_new: 0x%08x", dut.f1_reg, dut.f1_new);
      $display("-------------------------------------------------------------------------------------");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // inc_tc_ctr
  //----------------------------------------------------------------
  task inc_tc_ctr;
    tc_ctr = tc_ctr + 1;
  endtask // inc_tc_ctr


  //----------------------------------------------------------------
  // inc_error_ctr
  //----------------------------------------------------------------
  task inc_error_ctr;
    error_ctr = error_ctr + 1;
  endtask // inc_error_ctr


  //----------------------------------------------------------------
  // pause_finish()
  //
  // Pause for a given number of cycles and then finish sim.
  //----------------------------------------------------------------
  task pause_finish(input [31 : 0] num_cycles);
    begin
      $display("Pausing for %04d cycles and then finishing hard.", num_cycles);
      #(num_cycles * CLK_PERIOD);
      $finish;
    end
  endtask // pause_finish


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag to be set in dut.
  //----------------------------------------------------------------
  task wait_ready;
    begin : wready
      while (!tb_ready)
        #(CLK_PERIOD);
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      $display("*** %02d test cases executed ****", tc_ctr);
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully ****", tc_ctr);
        end
      else
        begin
          $display("*** %02d test cases did not complete successfully. ***", error_ctr);
        end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // init_sim()
  //
  // Set the input to the DUT to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr   = 0;
      error_ctr   = 0;
      tc_ctr      = 0;

      display_cycle_ctr = 1;
      display_dut_state = 0;

      tb_clk      = 1'h0;
      tb_reset_n  = 1'h1;
      tb_init     = 1'h0;
      tb_update   = 1'h0;
      tb_finish   = 1'h0;
      tb_block    = 512'h0;
      tb_blocklen = 7'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("TB: Resetting dut.");
      tb_reset_n = 1'h0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1'h1;
      #(2 * CLK_PERIOD);
      $display("TB: Reset done.");
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_ctx
  //----------------------------------------------------------------
  task display_ctx;
    begin: display_ctx

    end
  endtask // display_ctx


  //----------------------------------------------------------------
  // test_rfc_7693
  // Test using testvectors from RFC 7693.
  //----------------------------------------------------------------
  task test_rfc_7693;
    begin : test_rfc_7693
      tc_ctr = tc_ctr + 1;

      $display("");
      $display("*** test_rfc_7693 started.\n");

      display_dut_state = 1;
      $display("test_rfc_7693: asserting init.\n");
      tb_init = 1'h1;
      #(CLK_PERIOD);
      tb_init = 1'h0;
      $display("test_rfc_7693: init should be completed.\n");
      $display("");

      display_ctx();

//      #(CLK_PERIOD);
//      $display("test_rfc_7693: asserting update.\n");
//      tb_block = {32'h00636261, {15{32'h0}}};
//      tb_update = 1'h1;
//      #(CLK_PERIOD);
//      tb_update = 1'h0;
//      wait_ready();
//      $display("test_rfc_7693: update should be completed.\n");
//      $display("");
//
//
//      #(CLK_PERIOD);
//      $display("test_rfc_7693: asserting finish.\n");
//      tb_finish = 1'h1;
//      #(CLK_PERIOD);
//      tb_finish = 1'h1;
//      wait_ready();
//      $display("test_rfc_7693: finish should be completed.\n");
//      $display("");
//      #(CLK_PERIOD);
//      display_dut_state = 0;
//
//      $display("test_rfc_7693: Checking generated digest.\n");
//      if (tb_digest == 256'h508c5e8c327c14e2_e1a72ba34eeb452f_37458b209ed63a29_4d999b4c86675982)
//        $display("test_rfc_7693: Correct digest generated.");
//      else begin
//        $display("test_rfc_7693: Error. Incorrect digest generated.");
//        $display("test_rfc_7693: Expected: 0x508c5e8c327c14e2e1a72ba34eeb452f37458b209ed63a294d999b4c86675982");
//        $display("test_rfc_7693: Got:      0x%064x", tb_digest);
//        error_ctr = error_ctr + 1;
//      end

      $display("*** test_rfc_7693 completed.\n");
      $display("");
    end
  endtask // test_rfc_7693


  //----------------------------------------------------------------
  // testrunner
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : testrunner
      $display("*** Testbench for Blake2s core function test started ***");
      $display("--------------------------------------------------------");
      $display("");

      init_sim();
      reset_dut();

      test_rfc_7693();

      display_test_result();

      $display("*** Blake2s core functions simulation completed ****");
      $display("-----------------------------------------------------");
      $display("");
      $finish_and_return(error_ctr);
    end // testrunner

endmodule // tb_blake2s_core

//======================================================================
// EOF tb_blake2s_core.v
//======================================================================
