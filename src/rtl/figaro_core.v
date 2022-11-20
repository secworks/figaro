//======================================================================
// figaro_core.v
// -----------
// FiGaRO based FIGARO for iCE40 device.
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
//======================================================================

module figaro_core(
            input wire 	        clk,
            input wire           reset_n,

            input wire           set_sample_rate,
            input wire [23 : 0]  sample_rate,

            input wire           read_entropy,
            output wire [31 : 0] entropy,

            output wire          ready
	          );


  //---------------------------------------------------------------
  // Local parameters.
  //---------------------------------------------------------------
  localparam DEFAULT_SAMPLE_RATE = 24'h010000;


  //---------------------------------------------------------------
  // Registers.
  //---------------------------------------------------------------
  reg [23 : 0] sample_rate_ctr_reg;
  reg [23 : 0] sample_rate_ctr_new;

  reg [23 : 0] sample_rate_reg;
  reg          sample_rate_we;

  reg [4 : 0]  bit_ctr_reg;
  reg [4 : 0]  bit_ctr_new;
  reg          bit_ctr_rst;
  reg          bit_ctr_inc;
  reg          bit_ctr_we;

  reg [31 : 0] entropy_reg;
  reg [31 : 0] entropy_new;
  reg          entropy_we;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;


  //---------------------------------------------------------------
  // Firo oscillator instances and XOR combined result.
  //---------------------------------------------------------------
  wire firo_ent[3 : 0];
  wire firo_entropy;

  firo #(.POLY(10'b1111110111)) firo0(.clk(clk), .entropy(firo_ent[0]));
  firo #(.POLY(10'b1011111001)) firo1(.clk(clk), .entropy(firo_ent[1]));
  firo #(.POLY(10'b1100000001)) firo2(.clk(clk), .entropy(firo_ent[2]));
  firo #(.POLY(10'b1011111111)) firo3(.clk(clk), .entropy(firo_ent[3]));

  assign firo_entropy = firo_ent[0] ^ firo_ent[1] ^
                        firo_ent[2] ^ firo_ent[3];


  //---------------------------------------------------------------
  // garo oscillator instances and XOR combined result.
  //---------------------------------------------------------------
  wire garo_ent[3 : 0];
  wire garo_entropy;

  garo #(.POLY(11'b11111101111)) garo0(.clk(clk), .entropy(garo_ent[0]));
  garo #(.POLY(11'b10111110011)) garo1(.clk(clk), .entropy(garo_ent[1]));
  garo #(.POLY(11'b11000000011)) garo2(.clk(clk), .entropy(garo_ent[2]));
  garo #(.POLY(11'b10111111111)) garo3(.clk(clk), .entropy(garo_ent[3]));

  assign garo_entropy = garo_ent[0] ^ garo_ent[1] ^
                        garo_ent[2] ^ garo_ent[3];


  //---------------------------------------------------------------
  // Assignments.
  //---------------------------------------------------------------
  assign ready   = ready_reg;
  assign entropy = entropy_reg;


  //---------------------------------------------------------------
  // reg_update
  //---------------------------------------------------------------
  always @(posedge clk)
     begin : reg_update
       if (!reset_n) begin
         sample_rate_reg     <= DEFAULT_SAMPLE_RATE;
         sample_rate_ctr_reg <= 24'h0;
         bit_ctr_reg         <= 5'h0;
         entropy_reg         <= 32'h0;
         ready_reg           <= 1'h0;
       end else begin
         sample_rate_ctr_reg <= sample_rate_ctr_new;

        if (sample_rate_we) begin
          sample_rate_reg <= sample_rate;
        end

         if (bit_ctr_we) begin
           bit_ctr_reg <= bit_ctr_new;
         end

         if (entropy_we) begin
           entropy_reg <= entropy_new;
         end

         if (ready_we) begin
           ready_reg <= ready_new;
         end
       end
     end


  //---------------------------------------------------------------
  // ready_logic
  //
  // After an entropy word has been read we wait 32 bits before
  // setting ready again, indicating that a new word is ready.
  //---------------------------------------------------------------
  always @* begin : ready_logic;
      bit_ctr_new = 5'h0;
      bit_ctr_we  = 1'h0;
      ready_new   = 1'h0;
      ready_we    = 1'h0;


      if (bit_ctr_rst) begin
        bit_ctr_new = 5'h0;
        bit_ctr_we  = 1'h1;
        ready_new   = 1'h0;
        ready_we    = 1'h1;
      end

      else if (bit_ctr_inc) begin
        if (bit_ctr_reg == 5'h1f) begin
          ready_new   = 1'h1;
          ready_we    = 1'h1;
        end

        else begin
          bit_ctr_new = bit_ctr_reg + 1'h1;
          bit_ctr_we = 1'h1;
        end
      end
    end


  //---------------------------------------------------------------
  // figaro_sample_logic
  //
  // Wait sample_rate_reg number of cycles between sampling a bit
  // from the entropy source.
  //---------------------------------------------------------------
  always @*
    begin : figaro_sample_logic
      sample_rate_we = 1'h0;
      bit_ctr_rst    = 1'h0;
      bit_ctr_inc    = 1'h0;
      entropy_we     = 1'h0;

      entropy_new = {entropy_reg[30 : 0], firo_entropy ^ garo_entropy};

      if (read_entropy) begin
        bit_ctr_rst = 1'h1;
      end

      if (set_sample_rate) begin
	      bit_ctr_rst         = 1'h1;
	      sample_rate_we      = 1'h1;
        sample_rate_ctr_new = 24'h0;
      end else if (sample_rate_ctr_reg == sample_rate_reg) begin
        sample_rate_ctr_new = 24'h0;
        entropy_we          = 1'h1;
        bit_ctr_inc         = 1'h1;
      end else begin
        sample_rate_ctr_new = sample_rate_ctr_reg + 1'h1;
      end
    end

endmodule // figaro_core

//======================================================================
// EOF figaro_core.v
//======================================================================
