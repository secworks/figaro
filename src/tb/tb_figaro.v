//======================================================================
//
// tb_figaro.v
// -----------
// Testbench for the figaro top level wrapper
//
//
// Author: Joachim Strombergson
// Copyright (c) 2019, Assured AB
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

`default_nettype none

module tb_figaro();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  localparam ADDR_NAME0        = 8'h00;
  localparam ADDR_NAME1        = 8'h01;
  localparam ADDR_VERSION      = 8'h02;

  localparam ADDR_STATUS       = 8'h09;
  localparam STATUS_READY_BIT  = 0;

  localparam ADDR_SAMPLE_RATE  = 8'h10;

  localparam ADDR_ENTROPY      = 8'h20;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;
  reg           tb_monitor;

  reg           display_dut_state;
  reg           display_core_state;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_we;
  reg [7 : 0]   tb_address;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;

  reg [31 : 0]  read_data;
  reg [255 : 0] digest;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  figaro dut(
           .clk(tb_clk),
           .reset_n(tb_reset_n),

           .cs(tb_cs),
           .we(tb_we),

           .address(tb_address),
           .write_data(tb_write_data),
           .read_data(tb_read_data)
           );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;
      #(CLK_PERIOD);
      if (tb_monitor)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state
  //
  // Dump the internal state of the dut to std out.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("-------------------------------------------------------------------------------------");
      $display("-------------------------------------------------------------------------------------");
      $display("DUT internal state at cycle: %08d", cycle_ctr);
      $display("-------------------------------------");
      $display("ready:       0x%1x", dut.core.ready_reg);
      $display("bit_ctr_reg: 0x%02x", dut.core.bit_ctr_reg);
      $display("bit_ctr_rst: 0x%1x", dut.core.bit_ctr_rst);
      $display("bit_ctr_inc: 0x%1x", dut.core.bit_ctr_inc);
      $display("");
      $display("sample_rate_ctr_reg: 0x%06x", dut.core.sample_rate_ctr_reg);
      $display("sample_rate_reg:     0x%06x", dut.core.sample_rate_reg);
      $display("");
      $display("entropy: 0x%08x", dut.core.entropy_reg);
      $display("read_entropy: 0x%1x", dut.core.read_entropy);
      $display("-------------------------------------------------------------------------------------");
      $display("-------------------------------------------------------------------------------------");
      $display("");
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("--- Toggle reset.");
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      $display("");

      if (error_ctr == 0) begin
        $display("--- All %02d test cases completed successfully", tc_ctr);
      end else begin
        $display("--- %02d tests completed - %02d test cases did not complete successfully.",
                 tc_ctr, error_ctr);
      end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr          = 0;
      error_ctr          = 0;
      tc_ctr             = 0;
      tb_monitor         = 0;
      display_dut_state  = 0;
      display_core_state = 0;

      tb_clk        = 1'h0;
      tb_reset_n    = 1'h1;
      tb_cs         = 1'h0;
      tb_we         = 1'h0;
      tb_address    = 8'h0;
      tb_write_data = 32'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [11 : 0] address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("--- Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      tb_address = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(2 * CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [11 : 0]  address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;

      if (DEBUG)
        begin
          $display("--- Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag to be set in dut.
  //----------------------------------------------------------------
  task wait_ready;
    begin : wready
      read_word(ADDR_STATUS);
      while (read_data == 0)
        read_word(ADDR_STATUS);
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // test_name_version
  //----------------------------------------------------------------
  task test_name_version;
    begin: test_name_version
      reg [31 : 0] name0;
      reg [31 : 0] name1;
      reg [31 : 0] version;

      tc_ctr = tc_ctr + 1;

      $display("");
      $display("--- test_name_version: Started.");

      read_word(ADDR_NAME0);
      name0 = read_data;

      read_word(ADDR_NAME1);
      name1 = read_data;

      read_word(ADDR_VERSION);
      version = read_data;

      $display("--- test_name_version: Name: %c%c%c%c%c%c%c%c",
               name0[31 : 24], name0[23 : 16], name0[15 : 8], name0[7 : 0],
               name1[31 : 24], name1[23 : 16], name1[15 : 8], name1[7 : 0]);

      $display("--- test_name_version: Version: %c%c%c%c",
               version[31 : 24], version[23 : 16], version[15 : 8], version[7 : 0]);


      $display("--- test_name_version: Completed.");
      $display("");
    end
  endtask // test_name_version


  //----------------------------------------------------------------
  // test_read_trng
  //----------------------------------------------------------------
  task test_read_trng;
    begin : test_read_trng
      integer i;
      tc_ctr = tc_ctr + 1;
      tb_monitor = 1'h1;

      $display("");
      $display("--- test_read_trng: Started.");

      $display("--- test_read_trng: Setting a short sample rate.");
      write_word(ADDR_SAMPLE_RATE, 32'h3);
      #(CLK_PERIOD);

      $display("--- test_read_trng: Reading five entropy words.");
      for (i = 1 ; i < 6 ; i = i + 1) begin
	$display("--- test_read_trng: Waiting for ready to be set.");
	wait_ready();
	read_word(ADDR_ENTROPY);
	$display("--- test_read_trng: Entropy word %02d: 0x%08x", i, read_data);
      end

      #(CLK_PERIOD);
      tb_monitor = 1'h0;

      $display("--- test_read_trng: Completed.\n");
      $display("");
    end
  endtask // test_read_trng


  //----------------------------------------------------------------
  // figaro_test
  //----------------------------------------------------------------
  initial
    begin : figaro_test
      $display("   -= Testbench for figaro started =-");
      $display("     ===============================");
      $display("");

      init_sim();
      reset_dut();

      test_name_version();
      test_read_trng();

      display_test_result();
      $display("");
      $display("   -= Testbench for figaro completed =-");
      $display("     =================================");
      $display("");
      $finish;
    end // figaro_test
endmodule // tb_figaro

//======================================================================
// EOF tb_figaro.v
//======================================================================
