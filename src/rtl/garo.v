//======================================================================
//
// garo.v
// ------
// GaloisRing Oscillator with state sampling.
// The Galois depth is 11 bits, and the bits are always sampled.
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

module garo(
            input wire  clk,
            output wire entropy
            );

  parameter POLY = 11'b11111111111;


  //----------------------------------------------------------------
  // Registers and wires.
  //----------------------------------------------------------------
  reg entropy_reg;
  wire [11 : 0] g;
  wire [11 : 0] gp;


  //---------------------------------------------------------------
  // Combinational loop inverters.
  //---------------------------------------------------------------
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv1  (.I0(g[0]),  .O(gp[0]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv2  (.I0(g[1]),  .O(gp[1]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv3  (.I0(g[2]),  .O(gp[2]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv4  (.I0(g[3]),  .O(gp[3]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv5  (.I0(g[4]),  .O(gp[4]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv6  (.I0(g[5]),  .O(gp[5]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv7  (.I0(g[6]),  .O(gp[6]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv8  (.I0(g[7]),  .O(gp[7]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv9  (.I0(g[8]),  .O(gp[8]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv10 (.I0(g[9]),  .O(gp[9]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv11 (.I0(g[10]), .O(gp[10]));
  (* keep *) SB_LUT4 #(.LUT_INIT(1'b1)) osc_inv12 (.I0(g[11]), .O(gp[11]));


  //---------------------------------------------------------------
  // parameterized feedback logic.
  //---------------------------------------------------------------
  assign g[11] = gp[0];
  assign g[10] = gp[11] ^ (POLY[10] & gp[0]);
  assign g[9]  = gp[10] ^ (POLY[9]  & gp[0]);
  assign g[8]  = gp[9]  ^ (POLY[8]  & gp[0]);
  assign g[7]  = gp[8]  ^ (POLY[7]  & gp[0]);
  assign g[6]  = gp[7]  ^ (POLY[6]  & gp[0]);
  assign g[5]  = gp[6]  ^ (POLY[5]  & gp[0]);
  assign g[4]  = gp[5]  ^ (POLY[4]  & gp[0]);
  assign g[3]  = gp[4]  ^ (POLY[3]  & gp[0]);
  assign g[2]  = gp[3]  ^ (POLY[2]  & gp[0]);
  assign g[1]  = gp[2]  ^ (POLY[1]  & gp[0]);
  assign g[0]  = gp[1]  ^ (POLY[0]  & gp[0]);


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign entropy = entropy_reg;


  //---------------------------------------------------------------
  // reg_update
  //---------------------------------------------------------------
  always @(posedge clk)
    begin : reg_update
      entropy_reg <= ^g;
    end

endmodule // garo

//======================================================================
// EOF garo.v
//======================================================================
