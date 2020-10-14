//======================================================================
//
// tb_blake2s_round.v
// ------------------
// Testbench for the Blake2s round function.
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

module tb_blake2s_round();

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
  reg [63 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;
  reg           display_cycle_ctr;

  reg           tb_clk;
  reg           tb_reset_n;


  //----------------------------------------------------------------
  // blake2_G device under test.
  //----------------------------------------------------------------
  blake2s_round dut(
                    .clk(tb_clk),
                    .reset_n(tb_reset_n)
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
        end

    end // dut_monitor


  //----------------------------------------------------------------
  // dump_dut_state
  //
  // Dump the internal state of the dut to std out.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      if (VERBOSE)
        begin
          $display("");
          $display("DUT internal state");
          $display("------------------");
          $display("");
        end
    end
  endtask // dump_dut_state


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
  // init_dut()
  //
  // Set the input to the DUT to defined values.
  //----------------------------------------------------------------
  task init_dut;
    begin
      cycle_ctr  = 0;
      error_ctr  = 0;
      tc_ctr     = 0;
      tb_clk     = 0;
      tb_reset_n = 1;
    end
  endtask // init_dut


  //----------------------------------------------------------------
  // testrunner
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : testrunner
      $display("*** Testbench for Blake2 round function test started ***");
      $display("----------------------------------------------------");
      $display("");

      init_dut();

      display_test_result();

      $display("*** Blake2 round functions simulation completed ****");
      $finish_and_return(error_ctr);
    end // testrunner

endmodule // tb_blake2s_round

//======================================================================
// EOF tb_blake2s_round.v
//======================================================================
