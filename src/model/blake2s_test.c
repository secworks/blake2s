//======================================================================
//
// blake2s_test.c
// --------------
//
//======================================================================

#include <stdio.h>
#include "blake2s.h"

//------------------------------------------------------------------
// selftest_seq
// Deterministic sequences (Fibonacci generator).
//------------------------------------------------------------------
static void selftest_seq(uint8_t *out, size_t len, uint32_t seed)
{
    size_t i;
    uint32_t t, a , b;

    a = 0xDEAD4BAD * seed;              // prime
    b = 1;

    for (i = 0; i < len; i++) {         // fill the buf
        t = a + b;
        a = b;
        b = t;
        out[i] = (t >> 24) & 0xFF;
    }
}


//------------------------------------------------------------------
// blake2s_selftest
// BLAKE2s self-test validation. Return 0 when OK.
//------------------------------------------------------------------
int blake2s_selftest() {
  // Grand hash of hash results.
  const uint8_t blake2s_res[32] = {
    0x6a, 0x41, 0x1f, 0x08, 0xce, 0x25, 0xad, 0xcd,
    0xfb, 0x02, 0xab, 0xa6, 0x41, 0x45, 0x1c, 0xec,
    0x53, 0xc5, 0x98, 0xb2, 0x4f, 0x4f, 0xc7, 0x87,
    0xfb, 0xdc, 0x88, 0x79, 0x7f, 0x4c, 0x1d, 0xfe
  };

  // Parameter sets.
  const size_t b2s_md_len[4] = {16, 20, 28, 32};
  const size_t b2s_in_len[6] = {0,  3,  64, 65, 255, 1024};

  size_t i, j, outlen, inlen;
  uint8_t in[1024], md[32], key[32];
  blake2s_ctx ctx;

  // 256-bit hash for testing.
  if (blake2s_init(&ctx, 32, NULL, 0))
    return -1;

  for (i = 0; i < 4; i++) {
    outlen = b2s_md_len[i];
    for (j = 0; j < 6; j++) {
      inlen = b2s_in_len[j];

      selftest_seq(in, inlen, inlen);     // unkeyed hash
      blake2s(md, outlen, NULL, 0, in, inlen);
      blake2s_update(&ctx, md, outlen);   // hash the hash

      selftest_seq(key, outlen, outlen);  // keyed hash
      blake2s(md, outlen, key, outlen, in, inlen);
      blake2s_update(&ctx, md, outlen);   // hash the hash
    }
  }

  // Compute and compare the hash of hashes.
  blake2s_final(&ctx, md);
  for (i = 0; i < 32; i++) {
    if (md[i] != blake2s_res[i])
      return -1;
  }

  return 0;
}


//------------------------------------------------------------------
//------------------------------------------------------------------
void print_message(uint8_t *m, int mlen) {
  printf("The message:\n");
  for (int i = 1 ; i <= mlen ; i++) {
    printf("0x%02x ", m[(i - 1)]);
    if (i % 8 == 0) {
      printf("\n");
    }
  }
  printf("\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
void print_digest(uint8_t *md) {
  printf("The digest:\n");
  for (int j = 0 ; j < 4 ; j++) {
    for (int i = 0 ; i < 8 ; i++) {
      printf("0x%02x ", md[i + 8 * j]);
    }
    printf("\n");
  }
  printf("\n");
}


//------------------------------------------------------------------
// test_zero_length()
// Test with a zero length mwssage.
//------------------------------------------------------------------
void test_zero_length() {

  uint8_t md[32];

  printf("Testing zero byte message.\n");
  blake2s(md, 32, NULL, 0, NULL, 0);
  print_digest(md);
  printf("\n");
}


//------------------------------------------------------------------
// test_abc_message()
// Test with a zero length mwssage.
//------------------------------------------------------------------
void test_abc_message() {

  uint8_t md[32];
  uint8_t msg[64] = {'a', 'b', 'c'};

  printf("Testing with three byte 'abc' message.\n");
  print_message(msg, 3);

  blake2s(md, 32, NULL, 0, msg, 3);
  print_digest(md);
  printf("\n");
}


//------------------------------------------------------------------
// test_one_block_message()
// Test with a 64 byte message, filling one block.
//------------------------------------------------------------------
void test_one_block_message() {

  uint8_t md[32];
  uint8_t msg[64];

  for (uint8_t i = 0 ; i < 64 ; i++) {
    msg[i] = i;
  }

  printf("Testing with 64 byte message.\n");
  print_message(msg, 64);

  blake2s(md, 32, NULL, 0, msg, 64);
  print_digest(md);
  printf("\n");
}


//------------------------------------------------------------------
// test_one_block_one_byte_message()
// Test with a 65 byte message, filling one block and a single
// byte in the next block.
//------------------------------------------------------------------
void test_one_block_one_byte_message() {

  uint8_t md[32];
  uint8_t msg[65];

  for (uint8_t i = 0 ; i < 65 ; i++) {
    msg[i] = i;
  }

  printf("Testing with 65 byte message.\n");
  print_message(msg, 65);

  blake2s(md, 32, NULL, 0, msg, 65);
  print_digest(md);
  printf("\n");
}


//------------------------------------------------------------------
// self_test
// The original self test.
//------------------------------------------------------------------
void self_test() {
  printf("blake2s_selftest() = %s\n",
         blake2s_selftest() ? "FAIL" : "OK");
  printf("\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
int main(void) {
  printf("Blake2s reference model. Performing a set of tests..\n");

  self_test();
  test_zero_length();
  test_abc_message();
  test_one_block_message();
  test_one_block_one_byte_message();

  return 0;
}

//======================================================================
/// EOF blake2s_test.c
//======================================================================
