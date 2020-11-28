/*
   BLAKE2 reference source code package - reference C implementations

   Copyright 2012, Samuel Neves <sneves@dei.uc.pt>.  You may use this under the
   terms of the CC0, the OpenSSL Licence, or the Apache Public License 2.0, at
   your option.  The terms of these licenses can be found at:

   - CC0 1.0 Universal : http://creativecommons.org/publicdomain/zero/1.0
   - OpenSSL license   : https://www.openssl.org/source/license.html
   - Apache 2.0        : http://www.apache.org/licenses/LICENSE-2.0

   More information about the BLAKE2 hash function can be found at
   https://blake2.net.
*/

#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include "blake2.h"
#include "blake2-impl.h"

static const uint32_t blake2s_IV[8] =
{
  0x6A09E667UL, 0xBB67AE85UL, 0x3C6EF372UL, 0xA54FF53AUL,
  0x510E527FUL, 0x9B05688CUL, 0x1F83D9ABUL, 0x5BE0CD19UL
};

static const uint8_t blake2s_sigma[10][16] =
{
  {  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 } ,
  { 14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3 } ,
  { 11,  8, 12,  0,  5,  2, 15, 13, 10, 14,  3,  6,  7,  1,  9,  4 } ,
  {  7,  9,  3,  1, 13, 12, 11, 14,  2,  6,  5, 10,  4,  0, 15,  8 } ,
  {  9,  0,  5,  7,  2,  4, 10, 15, 14,  1, 11, 12,  6,  8,  3, 13 } ,
  {  2, 12,  6, 10,  0, 11,  8,  3,  4, 13,  7,  5, 15, 14,  1,  9 } ,
  { 12,  5,  1, 15, 14, 13,  4, 10,  0,  7,  6,  3,  9,  2,  8, 11 } ,
  { 13, 11,  7, 14, 12,  1,  3,  9,  5,  0, 15,  4,  8,  6,  2, 10 } ,
  {  6, 15, 14,  9, 11,  3,  0,  8, 12,  2, 13,  7,  1,  4, 10,  5 } ,
  { 10,  2,  8,  4,  7,  6,  1,  5, 15, 11,  9, 14,  3, 12, 13 , 0 } ,
};



//------------------------------------------------------------------
// print_hexbytes()
//------------------------------------------------------------------
void print_hexbytes(uint8_t *data, uint32_t len) {
  printf("Length: 0x%08x\n", len);

  for (uint32_t i = 0 ; i < len ; i += 1) {
    printf("0x%02x ", data[i]);
    if ((i > 0) && ((i + 1) % 8 == 0))
      printf("\n");
  }

  printf("\n");
}

//------------------------------------------------------------------
// print_hexwords()
//------------------------------------------------------------------
void print_hexwords(uint32_t *data, uint32_t len) {
  printf("Length: 0x%08x\n", len);

  for (uint32_t i = 0 ; i < len ; i += 1) {
    printf("0x%08x ", data[i]);
    if ((i > 0) && ((i + 1) % 8 == 0))
      printf("\n");
  }

  printf("\n");
}


//------------------------------------------------------------------
// dump_state()
//------------------------------------------------------------------
void dump_state(blake2s_state *s) {
  printf("h0: 0x%08x, h1: 0x%08x, h2: 0x%08x, h3: 0x%08x\n",
         s->h[0], s->h[1], s->h[2], s->h[3]);
  printf("h4: 0x%08x, h5: 0x%08x, h6: 0x%08x, h7: 0x%08x\n",
         s->h[4], s->h[5], s->h[6], s->h[7]);

  printf("t0: 0x%08x, t1: 0x%08x\n", s->t[0], s->t[1]);
  printf("f0: 0x%08x, f1: 0x%08x\n", s->f[0], s->f[1]);

  printf("buf:\n");
  for (int j = 0 ; j < 8 ; j++) {
    for (int i = 0 ; i < 8 ; i++) {
      printf("0x%02x ", s->buf[i + (8 * j)]);
    }
    printf("\n");
  }
  printf("\n");

  printf("buflen:    0x%016zx\n", s->buflen);
  printf("outlen:    0x%016zx\n", s->outlen);
  printf("last_node: 0x%02x\n", s->last_node);

  printf("\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
static void blake2s_set_lastnode( blake2s_state *S )
{
  S->f[1] = (uint32_t)-1;
}

/* Some helper functions, not necessarily useful */
static int blake2s_is_lastblock( const blake2s_state *S )
{
  return S->f[0] != 0;
}

static void blake2s_set_lastblock( blake2s_state *S )
{
  if( S->last_node ) blake2s_set_lastnode( S );

  S->f[0] = (uint32_t)-1;
}


static void blake2s_increment_counter( blake2s_state *S, const uint32_t inc )
{
  printf("blake2s_increment_counter called with inc: 0x%08x\n", inc);
  printf("Counter before increment\n");
  printf("t[0]: 0x%08x, t[1]: 0x%08x\n", S->t[0], S->t[1]);

  S->t[0] += inc;
  S->t[1] += ( S->t[0] < inc );

  printf("Counter after increment\n");
  printf("t[0]: 0x%08x, t[1]: 0x%08x\n", S->t[0], S->t[1]);
  printf("blake2s_increment_counter done\n");
  printf("\n");
}


static void blake2s_init0( blake2s_state *S )
{
  size_t i;
  memset( S, 0, sizeof( blake2s_state ) );

  for( i = 0; i < 8; ++i ) S->h[i] = blake2s_IV[i];
}

/* init2 xors IV with input parameter block */
int blake2s_init_param( blake2s_state *S, const blake2s_param *P )
{
  const unsigned char *p = ( const unsigned char * )( P );
  size_t i;

  blake2s_init0( S );

  /* IV XOR ParamBlock */
  for( i = 0; i < 8; ++i )
    S->h[i] ^= load32( &p[i * 4] );

  S->outlen = P->digest_length;
  return 0;
}


/* Sequential blake2s initialization */
int blake2s_init( blake2s_state *S, size_t outlen )
{
  blake2s_param P[1];

  /* Move interval verification here? */
  if ( ( !outlen ) || ( outlen > BLAKE2S_OUTBYTES ) ) return -1;

  P->digest_length = (uint8_t)outlen;
  P->key_length    = 0;
  P->fanout        = 1;
  P->depth         = 1;
  store32( &P->leaf_length, 0 );
  store32( &P->node_offset, 0 );
  store16( &P->xof_length, 0 );
  P->node_depth    = 0;
  P->inner_length  = 0;
  /* memset(P->reserved, 0, sizeof(P->reserved) ); */
  memset( P->salt,     0, sizeof( P->salt ) );
  memset( P->personal, 0, sizeof( P->personal ) );

  return blake2s_init_param( S, P );
}

int blake2s_init_key( blake2s_state *S, size_t outlen, const void *key, size_t keylen )
{
  blake2s_param P[1];

  if ( ( !outlen ) || ( outlen > BLAKE2S_OUTBYTES ) ) return -1;

  if ( !key || !keylen || keylen > BLAKE2S_KEYBYTES ) return -1;

  P->digest_length = (uint8_t)outlen;
  P->key_length    = (uint8_t)keylen;
  P->fanout        = 1;
  P->depth         = 1;
  store32( &P->leaf_length, 0 );
  store32( &P->node_offset, 0 );
  store16( &P->xof_length, 0 );
  P->node_depth    = 0;
  P->inner_length  = 0;
  /* memset(P->reserved, 0, sizeof(P->reserved) ); */
  memset( P->salt,     0, sizeof( P->salt ) );
  memset( P->personal, 0, sizeof( P->personal ) );

  if( blake2s_init_param( S, P ) < 0 ) return -1;

  {
    uint8_t block[BLAKE2S_BLOCKBYTES];
    memset( block, 0, BLAKE2S_BLOCKBYTES );
    memcpy( block, key, keylen );
    blake2s_update( S, block, BLAKE2S_BLOCKBYTES );
    secure_zero_memory( block, BLAKE2S_BLOCKBYTES ); /* Burn the key from stack */
  }

  return 0;
}


#define G(r,i,a,b,c,d)                      \
  do {                                      \
    printf("Inside G function.\n");         \
    a = a + b + m[blake2s_sigma[r][2*i+0]]; \
    printf("a0: 0x%08x\n", a);              \
    d = rotr32(d ^ a, 16);                  \
    printf("d0: 0x%08x\n", d);              \
    c = c + d;                              \
    printf("c0: 0x%08x\n", c);              \
    b = rotr32(b ^ c, 12);                  \
    printf("b0: 0x%08x\n", b);              \
    a = a + b + m[blake2s_sigma[r][2*i+1]]; \
    printf("a1: 0x%08x\n", a);              \
    d = rotr32(d ^ a, 8);                   \
    printf("d1: 0x%08x\n", d);              \
    c = c + d;                              \
    printf("c1: 0x%08x\n", c);              \
    b = rotr32(b ^ c, 7);                   \
    printf("b1: 0x%08x\n", b);              \
    printf("LeavingG function.\n\n");       \
  } while(0)


#define ROUND(r)                    \
  do {                              \
    G(r,0,v[ 0],v[ 4],v[ 8],v[12]); \
    G(r,1,v[ 1],v[ 5],v[ 9],v[13]); \
    G(r,2,v[ 2],v[ 6],v[10],v[14]); \
    G(r,3,v[ 3],v[ 7],v[11],v[15]); \
    G(r,4,v[ 0],v[ 5],v[10],v[15]); \
    G(r,5,v[ 1],v[ 6],v[11],v[12]); \
    G(r,6,v[ 2],v[ 7],v[ 8],v[13]); \
    G(r,7,v[ 3],v[ 4],v[ 9],v[14]); \
  } while(0)


static void blake2s_compress( blake2s_state *S, const uint8_t in[BLAKE2S_BLOCKBYTES] )
{
  uint32_t m[16];
  uint32_t v[16];
  size_t i;

  printf("\n");
  printf("blake2s_compress called.\n");

  printf("blake2s_compress: State before compressing:\n");
  dump_state(S);

  printf("blake2s_compress: Indata given:\n");
  print_hexbytes(in, BLAKE2S_BLOCKBYTES);

  for( i = 0; i < 16; ++i ) {
    m[i] = load32( in + i * sizeof( m[i] ) );
  }
  printf("blake2s_compress: Indata loaded into m:\n");
  print_hexwords(m, 16);

  for( i = 0; i < 8; ++i ) {
    v[i] = S->h[i];
  }

  v[ 8] = blake2s_IV[0];
  v[ 9] = blake2s_IV[1];
  v[10] = blake2s_IV[2];
  v[11] = blake2s_IV[3];
  v[12] = S->t[0] ^ blake2s_IV[4];
  v[13] = S->t[1] ^ blake2s_IV[5];
  v[14] = S->f[0] ^ blake2s_IV[6];
  v[15] = S->f[1] ^ blake2s_IV[7];

  printf("blake2s_compress: State of v before rounds:\n");
  print_hexwords(v, 16);

  ROUND( 0 );

  printf("blake2s_compress: State of v after round 0:\n");
  print_hexwords(v, 16);

  ROUND( 1 );

  printf("blake2s_compress: State of v after round 1:\n");
  print_hexwords(v, 16);

  ROUND( 2 );

  printf("blake2s_compress: State of v after round 2:\n");
  print_hexwords(v, 16);

  ROUND( 3 );

  printf("blake2s_compress: State of v after round 3:\n");
  print_hexwords(v, 16);

  ROUND( 4 );

  printf("blake2s_compress: State of v after round 4:\n");
  print_hexwords(v, 16);

  ROUND( 5 );

  printf("blake2s_compress: State of v after round 5:\n");
  print_hexwords(v, 16);

  ROUND( 6 );

  printf("blake2s_compress: State of v after round 6:\n");
  print_hexwords(v, 16);

  ROUND( 7 );

  printf("blake2s_compress: State of v after round 7:\n");
  print_hexwords(v, 16);

  ROUND( 8 );

  printf("blake2s_compress: State of v after round 8:\n");
  print_hexwords(v, 16);

  ROUND( 9 );

  printf("blake2s_compress: State of v after round 9:\n");
  print_hexwords(v, 16);


  for( i = 0; i < 8; ++i ) {
    S->h[i] = S->h[i] ^ v[i] ^ v[i + 8];
  }

  printf("State after compressing:\n");
  dump_state(S);

  printf("blake2s_compress completed.\n");
  printf("\n");
}

#undef G
#undef ROUND

int blake2s_update( blake2s_state *S, const void *pin, size_t inlen )
{
  printf("blake2s_update called\n");
  printf("\n");

  const unsigned char * in = (const unsigned char *)pin;
  if( inlen > 0 )
  {
    size_t left = S->buflen;
    size_t fill = BLAKE2S_BLOCKBYTES - left;
    if( inlen > fill )
    {
      S->buflen = 0;
      memcpy( S->buf + left, in, fill ); /* Fill buffer */
      blake2s_increment_counter( S, BLAKE2S_BLOCKBYTES );
      blake2s_compress( S, S->buf ); /* Compress */
      in += fill; inlen -= fill;
      while(inlen > BLAKE2S_BLOCKBYTES) {
        blake2s_increment_counter(S, BLAKE2S_BLOCKBYTES);
        blake2s_compress( S, in );
        in += BLAKE2S_BLOCKBYTES;
        inlen -= BLAKE2S_BLOCKBYTES;
      }
    }
    memcpy( S->buf + S->buflen, in, inlen );
    S->buflen += inlen;
  }

  printf("blake2s_update completed\n");
  printf("\n");
  return 0;
}


int blake2s_final( blake2s_state *S, void *out, size_t outlen )
{
  printf("blake2s_final called\n");
  printf("\n");

  uint8_t buffer[BLAKE2S_OUTBYTES] = {0};
  size_t i;

  if( out == NULL || outlen < S->outlen )
    return -1;

  if( blake2s_is_lastblock( S ) )
    return -1;

  blake2s_increment_counter( S, ( uint32_t )S->buflen );
  blake2s_set_lastblock( S );
  memset( S->buf + S->buflen, 0, BLAKE2S_BLOCKBYTES - S->buflen ); /* Padding */
  blake2s_compress( S, S->buf );

  for( i = 0; i < 8; ++i ) /* Output full hash to temp buffer */
    store32( buffer + sizeof( S->h[i] ) * i, S->h[i] );

  memcpy( out, buffer, outlen );
  secure_zero_memory(buffer, sizeof(buffer));

  printf("blake2s_final completed\n");
  printf("\n");

  return 0;
}


int blake2s( void *out, size_t outlen, const void *in, size_t inlen, const void *key, size_t keylen )
{
  blake2s_state S[1];

  /* Verify parameters */
  if ( NULL == in && inlen > 0 ) return -1;

  if ( NULL == out ) return -1;

  if ( NULL == key && keylen > 0) return -1;

  if( !outlen || outlen > BLAKE2S_OUTBYTES ) return -1;

  if( keylen > BLAKE2S_KEYBYTES ) return -1;

  if( keylen > 0 )
  {
    if( blake2s_init_key( S, outlen, key, keylen ) < 0 ) return -1;
  }
  else
  {
    if( blake2s_init( S, outlen ) < 0 ) return -1;
  }

  blake2s_update( S, ( const uint8_t * )in, inlen );
  blake2s_final( S, out, outlen );
  return 0;
}
