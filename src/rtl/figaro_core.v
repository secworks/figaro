//======================================================================
//
// figaro_core.v
// -------------
// Fibonacci and Galois Ring Oscillator based true random
// number source. The sample rate is controlled by a
// divisor.
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

module figaro_core (
                    input wire          clk,
                    input wire          reset_n,

                    input wire          enable,
                    input wire [23 : 0] divsor;

                    output wire         rnd
                   );


  //----------------------------------------------------------------
  // Registers.
  //----------------------------------------------------------------
  reg en_reg;

  reg rnd_reg;
  reg rnd_new;
  reg rnd_we;

  reg [23 : 0] sample_rate_ctr_reg;
  reg [23 : 0] sample_rate_ctr_new;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire firo0_rnd;
  wire firo1_rnd;
  wire firo2_rnd;
  wire firo3_rnd;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign rnd = rnd_reg;


  //----------------------------------------------------------------
  // Module instantiations
  //----------------------------------------------------------------
  // 1 + x + x2 + x3 + x5 + x6 + x7 + x8 + x9 + x10
  firo (#POLY = 10'b1111110111)
  firo0 (
         .clk(clk),
         .reset_n(reset_n),
         .en(en_reg),
         .rnd(firo0_rnd)
        );


  // 1 + x + x2 + x3 + x4 + x6 + x7 + x10
  firo (#POLY = 10'b1001101111)
  firo1 (
         .clk(clk),
         .reset_n(reset_n),
         .en(en_reg),
         .rnd(firo1_rnd)
        );

  // 1 + x + x2 + x3 + x4 + x5 + x6 + x10
  firo (#POLY = 10'b1000111111)
  firo2 (
         .clk(clk),
         .reset_n(reset_n),
         .en(en_reg),
         .rnd(firo2_rnd)
        );

  // 1 + x + x2 + x3 + x4 + x5 + x6 + x7 + x9 + x10
  firo (#POLY = 10'b1101111111)
  firo3 (
         .clk(clk),
         .reset_n(reset_n),
         .en(enable_reg),
         .rnd(firo3_rnd)
        );


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin: reg_update
      if (!reset_n)
        begin
          en_reg              <= 1'h0;
          rnd_reg             <= 1'h0;
          sample_rate_ctr_reg <= 24'h0;
        end
      else
        begin
          en_reg              <= en;
          sample_rate_ctr_reg <= sample_rate_ctr_new;

          if (rnd_we) begin
            rnd_reg <= rnd_new;
          end

        end
    end // reg_update


  //----------------------------------------------------------------
  // figaro_logic
  //----------------------------------------------------------------
  always @*
    begin : figaro_logic
      rnd_we  = 1'h0;
      rnd_new = firo0_rnd ^ firo1_rnd ^ firo2_rnd ^ firo3_rnd;

      if (sample_rate_ctr_reg < SAMPLE_DIVIDOR) begin
        sample_rate_ctr_new = sample_rate_ctr_reg + 1'h1;
      end
      else begin
        sample_rate_ctr_new = 24'h0;
        rnd_we              = 1'h1;
      end
    end

endmodule // figaro

//======================================================================
// EOF figaro_core.v
//======================================================================
