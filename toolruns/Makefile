#===================================================================
#
# Makefile
# --------
# Makefile for building the blake2s simulation targets, perform
# linting etc.
#
#
# Author: Joachim Strombergson
# Copyright (c) 2018, Assured AB
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

# Sources.
GF_SRC = ../src/rtl/blake2s_G.v
TB_GF_SRC = ../src/tb/tb_blake2s_G.v

M_SELECT_SRC = ../src/rtl/blake2s_m_select.v
TB_M_SELECT_SRC = ../src/tb/tb_blake2s_m_select.v

CORE_SRC = ../src/rtl/blake2s_core.v $(M_SELECT_SRC) $(ROUND_SRC) $(GF_SRC)
TB_CORE_SRC = ../src/tb/tb_blake2s_core.v

TOP_SRC= ../src/rtl/blake2s.v $(CORE_SRC)
TB_TOP_SRC = ../src/tb/tb_blake2s.v


# Tools and flags.
CC= iverilog
CC_FLAGS= -Wall

LINT= verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME


# Targets.
all: gf.sim m.sim core.sim top.sim


gf.sim:  $(TB_GF_SRC) $(GF_SRC)
	$(CC) $(CC_FLAGS) -o $@ $^


m.sim:  $(TB_M_SELECT_SRC) $(M_SELECT_SRC)
	$(CC) $(CC_FLAGS) -o $@ $^


core.sim:  $(TB_CORE_SRC) $(CORE_SRC)
	$(CC) $(CC_FLAGS) -o $@ $^


top.sim:  $(TB_TOP_SRC) $(TOP_SRC)
	$(CC) $(CC_FLAGS) -o $@ $^


lint: $(TOP_SRC)
	$(LINT) $(LINT_FLAGS)  $^


clean:
	rm -f *.sim
	rm -f *.log
	rm -f *.txt


help:
	@echo "Build system for simulation of BLAKE2s core."
	@echo ""
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:          Build all simulation targets."
	@echo "lint:         Run linter on  all rtl source files."
	@echo "top.sim:      Build top level simulation target."
	@echo "core.sim:     Build core level simulation target."
	@echo "gf.sim:       Build G function simulation target."
	@echo "m.sim:        Build m select module simulation target."
	@echo "clean:        Delete all built files."
	@echo "help:         This is it."

#===================================================================
# EOF Makefile
#===================================================================
