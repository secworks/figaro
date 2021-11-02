//======================================================================
//
// firo.v
// ------
// Fibonacci Ring Oscillator with state sampling.
// The Fibonacci depth is 10 bits, and the bits are always sampled.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2021, Assured AB
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

module firo (parameter POLY = 10'b1111111111)
       (
        input wire  clk,
        input wire  reset_n,

        input wire  en,

        output wire rnd
       );


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [9 : 0] sample_reg;
  reg [9 : 0] sample_new;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign rnd = ^sample_reg;


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin: reg_update
      if (!reset_n)
        begin
          sample_reg <= 10'h0;
        end
      else
        begin
          sample_reg <= sample_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // firo_logic;
  //----------------------------------------------------------------
  always @*
    begin : firo_logic
      reg [10 : 0] f;
      reg [9 : 0]  xor_chain;

      xor_chain = (POLY[0] & f[01]) ^ (POLY[1] & f[02]) ^
                  (POLY[2] & f[03]) ^ (POLY[3] & f[04]) ^
                  (POLY[4] & f[05]) ^ (POLY[5] & f[06]) ^
                  (POLY[6] & f[07]) ^ (POLY[7] & f[08]) ^
                  (POLY[8] & f[09]) ^ (POLY[9] & f[10]);

      f[00] = xor_chain & en;
      f[01] = ~f[00];
      f[02] = ~f[01];
      f[03] = ~f[02];
      f[04] = ~f[03];
      f[05] = ~f[04];
      f[06] = ~f[05];
      f[07] = ~f[06];
      f[08] = ~f[07];
      f[09] = ~f[08];
      f[10] = ~f[09];

      sample_new = f[10 : 1];

    end // firo_logic

endmodule // firo

//======================================================================
// EOF firo.v
//======================================================================
