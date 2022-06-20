//======================================================================
//
// figaro.v
// --------
// Top level wrapper for the figaro core.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2022, Assured AB
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

module figaro(
              input wire           clk,
              input wire           reset_n,

              input wire           cs,
              input wire  [7 : 0]  address,
              output wire [31 : 0] read_data
             );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_NAME0        = 8'h00;
  localparam ADDR_NAME1        = 8'h01;
  localparam ADDR_VERSION      = 8'h02;

  localparam ADDR_STATUS       = 8'h09;
  localparam STATUS_READY_BIT  = 0;

  localparam ADDR_ENTROPY      = 8'h10;

  localparam CORE_NAME0        = 32'h66696761; // "figa"
  localparam CORE_NAME1        = 32'h726f2020; // "ro  "
  localparam CORE_VERSION      = 32'h302e3130; // "0.10"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg read_entropy_reg;
  reg read_entropy_new;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire [31 : 0] core_entropy;
  wire          core_ready;
  reg  [31 : 0] tmp_read_data;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  figaro_core core(
                   .clk(clk),
                   .reset_n(reset_n),
                   .read_entropy(read_entropy_reg),
                   .entropy(core_entropy),
                   .ready(core_ready)
                  );


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      if (!reset_n) begin
        read_entropy_reg <= 1'h0;
      end

      else begin
        read_entropy_reg <= read_entropy_new;
      end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      read_entropy_new = 1'h0;
      tmp_read_data    = 32'h0;

      if (cs) begin
	if (address == ADDR_NAME0) begin
	  tmp_read_data = CORE_NAME0;
        end

	if (address == ADDR_NAME1) begin
	  tmp_read_data = CORE_NAME1;
	end

	if (address == ADDR_VERSION) begin
	  tmp_read_data = CORE_VERSION;
	end

        if (address == ADDR_STATUS) begin
          tmp_read_data[STATUS_READY_BIT] = core_ready;
        end

        if (address == ADDR_ENTROPY) begin
          tmp_read_data = core_entropy;
          read_entropy_new = 1'h1;
        end
      end
    end // api
endmodule // figaro

//======================================================================
// EOF figaro.v
//======================================================================
