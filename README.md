# blake2s
Verilog implementation of the 32-bit version of the
[Blake2](https://blake2.net/) hash function.


## Implementation status
Just started. *Does not work* *Do* *Not* *Use*


## Introduction
Blake2s is an embedded- and hardware-oriented version of the Blake2 hash
function. Both are specified in the
[Blake2 document](https://blake2.net/blake2.pdf). Additionally, a good
description of Blake2 and Blake2s is
[RFC 7693](https://tools.ietf.org/html/rfc7693)


Blake2s operates on 32-bit words and produces digests of up to
32 bytes. This implementation is based on [a previous implementation of
Blake2 (blake2b)](https://github.com/secworks/blake2). But adapted for
32-bit operations.

This core uses the reference imeplentation of Blake2s as golden model.


## Implementation details
The core is an iterative implemenatation, but will use multiple G
instances.

The core perform padding of last block.

## Implementation results
