CC=clang
CFLAGS=-O2  -Wall -Wextra -std=c89 -pedantic -Wno-long-long
BLAKEBINS=blake2s

all:		$(BLAKEBINS) check

blake2s:	blake2s-ref.c
		$(CC) blake2s-ref.c -o $@ $(CFLAGS) -DBLAKE2S_SELFTEST

check:          blake2s
	        ./blake2s

clean:
		rm -rf $(BLAKEBINS)
