#=======================================================================
#
# Makefile
# --------
# Makefile for building and running the blake2s reference model and
# the test program.
# (c) 2020 Joachim Strömbergson.
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
#======================================================================

CC = clang
CFLAGS = -O2  -Wall -Wextra -std=c99 -pedantic -Wno-long-long
BLAKEBINS = blake2s test_blake2s


all:		$(BLAKEBINS) check

blake2s:	blake2s-ref.c
		$(CC) blake2s-ref.c -o $@ $(CFLAGS) -DBLAKE2S_SELFTEST

test_blake2s:	test_blake2s.c
		$(CC) test_blake2s.c -o $@ $(CFLAGS)

check:          $(BLAKEBINS)
	        ./blake2s
		./test_blake2s

clean:
		rm -rf $(BLAKEBINS)

#=======================================================================
# EOF Makefile
#=======================================================================
