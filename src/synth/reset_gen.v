//======================================================================
//
// reset_gen.v
// -----------
// Reset generator.
//
//
// Copyright (c) 2022, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following
// conditions are met:
//
// * Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in
//   the documentation and/or other materials provided with
//   the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

`default_nettype none

module reset_gen #(parameter RESET_CYCLES = 200)
                (
                 input clk,
                 output wire reset_n
                 );


  //----------------------------------------------------------------
  // Registers with associated wires.
  //----------------------------------------------------------------
  reg [7 : 0] reset_ctr_reg = 8'h0;
  reg [7 : 0] reset_ctr_new;
  reg         reset_ctr_we;

  reg         reset_n_reg = 1'h0;
  reg         reset_n_new;


  //----------------------------------------------------------------
  // Concurrent assignment.
  //----------------------------------------------------------------
  assign reset_n = reset_n_reg;


  //----------------------------------------------------------------
  // reg_update.
  //----------------------------------------------------------------
    always @(posedge clk)
      begin : reg_update
        reset_n_reg <= reset_n_new;

        if (reset_ctr_we)
          reset_ctr_reg <= reset_ctr_new;
      end


  //----------------------------------------------------------------
  // reset_logic.
  //----------------------------------------------------------------
  always @*
    begin : reset_logic
      reset_n_new   = 1'h1;
      reset_ctr_new = 8'h0;
      reset_ctr_we  = 1'h0;

      if (reset_ctr_reg < RESET_CYCLES) begin
        reset_n_new   = 1'h0;
        reset_ctr_new = reset_ctr_reg + 1'h1;
        reset_ctr_we  = 1'h1;
      end
    end

endmodule // reset_gen

//======================================================================
// EOF reset_gen.v
//======================================================================
