//======================================================================
//
// test_blake2s.c
// --------------
// Test application for the blake2s reference model.
// The purpose of the application is to verify that we understand
// how the reference model used and works.
//
// (c) 2020 Joachim Strömbergson.
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

#include <stdio.h>
#include <stdint.h>
#include "blake2.h"

//------------------------------------------------------------------
// print_hexdata()
// Dump hex data
//------------------------------------------------------------------
void print_hexdata(uint8_t *data, uint32_t len) {
  printf("Length: 0x%08x\n", len);

  for (uint32_t i = 0 ; i < len ; i += 1) {
    printf("0x%02x ", data[i]);
    if ((i > 0) && ((i + 1) % 8 == 0))
      printf("\n");
  }

  printf("\n");
}


//------------------------------------------------------------------
// check_tag()
// Check the generated tag against an expected tag.
// The tag is expected to be 16 bytes.
//------------------------------------------------------------------
int check_tag(uint8_t *tag, uint8_t *expected) {
  uint8_t error = 0;
  for (uint8_t i = 0 ; i < 16 ; i++) {
    if (tag[i] != expected[i])
      error = 1;
  }

  if (!error) {
    printf("Correct tag generated.\n");
  }
  else {
    printf("Correct tag NOT generated.\n");
    printf("Expected:\n");
    print_hexdata(&expected[0], 16);
    printf("Got:\n");
    print_hexdata(&tag[0], 16);
  }
  return error;
}


//------------------------------------------------------------------
// test_rfc_7693
// Implement the test from RFC 7693.
//------------------------------------------------------------------
int test_rfc_7693() {
  int errors = 0;
  printf("test_rfc_7693 started\n");

//  uint8_t my_key[32] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

  blake2s_state my_state;
  blake2s_init(&my_state, 32);


  uint32_t my_message[16] = {0x00636261, 0x00000000, 0x00000000, 0x00000000,
                             0x00000000, 0x00000000, 0x00000000, 0x00000000,
                             0x00000000, 0x00000000, 0x00000000, 0x00000000,
                             0x00000000, 0x00000000, 0x00000000, 0x00000000};
  blake2s_update(&my_state, &my_message[0], 3);


  uint8_t my_expected[32] = {0x50, 0x8c, 0x5e, 0x8c, 0x32, 0x7c, 0x14, 0xe2,
                             0xe1, 0xa7, 0x2b, 0xa3, 0x4e, 0xeb, 0x45, 0x2f,
                             0x37, 0x45, 0x8b, 0x20, 0x9e, 0xd6, 0x3a, 0x29,
                             0x4d, 0x99, 0x9b, 0x4c, 0x86, 0x67, 0x59, 0x82};

  uint8_t my_tag[32];
  blake2s_final(&my_state, &my_tag[0], 32);

  printf("Generated tag:\n");
  print_hexdata(&my_tag[0], 32);
  errors += check_tag(&my_tag[0], &my_expected[0]);

  printf("test_rfc_7693 completed with %d errors\n", errors);
  return errors;
}


//------------------------------------------------------------------
//------------------------------------------------------------------
int run_tests() {
  int test_results = 0;

  test_results += test_rfc_7693();

  printf("Number of failing test cases: %d\n", test_results);

  return test_results;
}


//------------------------------------------------------------------
// int main()
//------------------------------------------------------------------
int main(void) {
  printf("\n");
  printf("Test of Blake2s reference model started\n");
  printf("---------------------------------------\n");
  return run_tests();
}

//======================================================================
// EOF test_blake2s.c
//======================================================================
