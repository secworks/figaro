#===================================================================
#
# Makefile
# --------
# Makefile for building, simulating, linting and test implementing
# the Figaro TRNG.
#
#
# Author: Joachim Strombergson
# Copyright (c) 2021, Assured AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#===================================================================

# Source and constraints.
CORE_SRC = ../src/rtl/firo.v ../src/rtl/garo.v ../src/rtl/figaro_core.v
TOP_SRC = ../src/rtl/figaro.v $(CORE_SRC)
TB_TOP_SRC = ../src/tb/tb_figaro.v

SIM_SRC = ../src/sim/SB_LUT4.v

ARACHNE_DEVICE = 1k
PACKAGE        = tq144

ICETIME_DEVICE = hx1k
PINS_FILE = config/pins.pcf

PROG_BIN = iceprog
TARGET_STEM = figaro


# Tools
CC = iverilog
CC_FLAGS = -Wall

LINT = verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME

YOSYS_LOG  = synth.log
YOSYS_ARGS = -v3 -l $(YOSYS_LOG)

BIN_FILE  = $(TARGET_STEM).bin
JSON_FILE  = $(TARGET_STEM).json
ASC_FILE  = $(TARGET_STEM).asc
BLIF_FILE = $(TARGET_STEM).blif


# Targets.
all:	lint-top sim-top

#$(BIN_FILE):	$(ASC_FILE)
#	icepack	$< $@
#
#$(JSON_FILE): $(VERILOG_SRCS)
#	yosys $(YOSYS_ARGS) -p "synth_ice40 -json $(JSON_FILE)" $(VERILOG_SRCS)
#
#$(ASC_FILE): $(JSON_FILE)
#	$(NEXTPNR_PATH)nextpnr-ice40 --ignore-loops --hx1k --package $(PACKAGE) --json $< \
#         --pcf $(PINS_FILE) --asc $(ASC_FILE)
#
#prog:	$(BIN_FILE)
#	$(PROG_BIN) $<
#
#timings:$(ASC_FILE)
#	icetime -tmd $(ICETIME_DEVICE) $<


sim-top:  $(TB_TOP_SRC) $(TOP_SRC) $(SIM_SRC)
	$(CC) $(CC_FLAGS) -o $@ $^


lint-top:  $(TOP_SRC) $(SIM_SRC)
	$(LINT) $(LINT_FLAGS) $^


clean:
	rm -f sim-*
	rm -f *.log
	rm -f *.txt
	rm -f $(BIN_FILE) $(ASC_FILE) $(BLIF_FILE) $(JSON_FILE) $(YOSYS_LOG)


help:
	@echo "Build system for simulation of Prince core"
	@echo ""
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:      Build all targets."
	@echo "sim-top:  Build top level simulation target."
	@echo "lint-top: Lint top level source files."
	@echo "clean:    Delete all artifacts and support files."

#===================================================================
# Makefile
#===================================================================
