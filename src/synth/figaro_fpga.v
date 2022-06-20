//======================================================================
// figaro_fpga.v
// -------------
// FPGA design for test implementation of the figaroTRNG core.
// The design basically
// (1) Sets the sample rate to get new entropy about once per second
// (2) Continuously read entropy words
// (3) Set LEDs to bits in the entropy word
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

module figaro_fpga(
		   input wire  clk,

		   output wire red_led0,
		   output wire red_led1,
		   output wire red_led2,
		   output wire red_led3,
		   output wire green_led
		  );


  //---------------------------------------------------------------
  // Local parameters.
  //---------------------------------------------------------------
  // API for the figaro core.
  localparam ADDR_STATUS       = 8'h09;
  localparam STATUS_READY_BIT  = 0;
  localparam ADDR_SAMPLE_RATE  = 8'h10;
  localparam ADDR_ENTROPY      = 8'h20;


  // State for control FSM.
  localparam CTRL_IDLE          = 0;
  localparam CTRL_WAIT_READY1   = 1;
  localparam CTRL_WAIT_READY2   = 2;
  localparam CTRL_READ_ENTROPY1 = 3;


  // 12 MHz / 32 to get a word one per second.
  localparam TEST_SAMPLE_RATE = 32'h0005b8d8;


  //---------------------------------------------------------------
  // Registers.
  //---------------------------------------------------------------
  reg [31 : 0] entropy_reg;
  reg          entropy_we;

  reg [2 : 0] fpga_ctrl_reg;
  reg [2 : 0] fpga_ctrl_new;
  reg         fpga_ctrl_we;

  //---------------------------------------------------------------
  // Wires.
  //---------------------------------------------------------------
  wire          reset_n;

  reg           led_we;

  reg           figaro_cs;
  reg           figaro_we;
  reg  [7 : 0]  figaro_address;
  reg  [31 : 0] figaro_write_data;
  wire [31 : 0] figaro_read_data;


  //---------------------------------------------------------------
  // Module instantiations.
  //---------------------------------------------------------------
  reset_gen reset_gen_inst (.clk(clk), .reset_n(reset_n));


  figaro figaro_inst(
                     .clk(clk),
                     .reset_n(reset_n),

                     .cs(figaro_cs),
                     .we(figaro_we),
                     .address(figaro_address),
                     .write_data(figaro_write_data),
                     .read_data(figaro_read_data)
                     );


  //---------------------------------------------------------------
  // Assignments.
  //---------------------------------------------------------------
  assign red_led0  = entropy_reg[0];
  assign red_led1  = entropy_reg[1];
  assign red_led2  = entropy_reg[10];
  assign red_led3  = entropy_reg[11];
  assign green_led = entropy_reg[31];


  //---------------------------------------------------------------
  // reg_update
  //---------------------------------------------------------------
  always @(posedge clk)
     begin : reg_update
       if (!reset_n) begin
	 entropy_reg   <= 32'hffff_ffff;
	 fpga_ctrl_reg <= CTRL_IDLE;
       end
       else begin
	 if (entropy_we) begin
	   entropy_reg <= figaro_read_data;
	 end

	 if (fpga_ctrl_we) begin
	   fpga_ctrl_reg <= fpga_ctrl_new;
	 end
       end
     end


   //---------------------------------------------------------------
   // fpga_ctrl
   //---------------------------------------------------------------
   always @*
     begin : fpga_ctrl
       figaro_cs         = 1'h0;
       figaro_we         = 1'h0;
       figaro_address    = 8'h0;
       figaro_write_data = 32'h0;
       entropy_we        = 1'h0;
       fpga_ctrl_new     = CTRL_IDLE;
       fpga_ctrl_we      = 1'h0;

       case (fpga_ctrl_reg)
	 CTRL_IDLE: begin
	   figaro_cs         = 1'h1;
	   figaro_we         = 1'h1;
	   figaro_address    = ADDR_SAMPLE_RATE;
	   figaro_write_data = TEST_SAMPLE_RATE;
	   fpga_ctrl_new     = CTRL_WAIT_READY1;
	   fpga_ctrl_we      = 1'h1;
	 end

	 CTRL_WAIT_READY1: begin
	   figaro_cs         = 1'h1;
	   figaro_address    = ADDR_STATUS;
	   fpga_ctrl_new     = CTRL_WAIT_READY2;
	   fpga_ctrl_we      = 1'h1;
	 end

	 CTRL_WAIT_READY2: begin
	   figaro_cs         = 1'h1;
	   figaro_address    = ADDR_STATUS;
	   if (figaro_read_data[STATUS_READY_BIT]) begin
	     fpga_ctrl_new = CTRL_READ_ENTROPY1;
	     fpga_ctrl_we  = 1'h1;
	   end
	   else begin
	     fpga_ctrl_new = CTRL_WAIT_READY1;
	     fpga_ctrl_we  = 1'h1;
	   end
	 end

	 CTRL_READ_ENTROPY1: begin
	   figaro_cs      = 1'h1;
	   figaro_address = ADDR_ENTROPY;
	   entropy_we     = 1'h1;
	   fpga_ctrl_new  = CTRL_WAIT_READY1;
	   fpga_ctrl_we   = 1'h1;
	 end

	 default: begin
	 end
       endcase // case (fpga_ctrl_reg)
     end

endmodule // fpga_ctrl

//======================================================================
// EOF figaro_fpga.v
//======================================================================
