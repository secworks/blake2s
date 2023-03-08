[![build-openlane-sky130](https://github.com/secworks/blake2s/actions/workflows/ci.yml/badge.svg?branch=master&event=push)](https://github.com/secworks/blake2s/actions/workflows/ci.yml)

# blake2s
Verilog implementation of the [BLAKE2s](https://blake2.net/) hash function.


## Implementation status
Implementation completed. Functionally correct. Functionally verified in
real hardware.  *Ready for use*.


## Introduction
BLAKE2s is 32-bit,  embedded- and hardware-oriented version of the BLAKE2 hash
function. See the [BLAKE2 paper](https://blake2.net/blake2.pdf) for more
information. Additionally, [RFC
7693](https://tools.ietf.org/html/rfc7693) contains a good description,
a reference model and a test vecrtor.

BLAKE2s operates on 32-bit words and produces digests of up to
32 bytes. This version of BLAKE2s always generates a 32 byte (i.e. 256
bit) digest.

This repository contains a forked version of the BLAKE2s reference model
by  Markku-Juhani O. Saarinen that appears in [RFC 7693](https://www.rfc-editor.org/rfc/rfc7693.html).
The original repository [can be found
here](https://github.com/mjosaarinen/blake2_mjosref). The forked version
contains additional test cases that checks corner cases. The forked
version has also been instrumented to display internal values during
processing. The model has been used to drive the functional
verification of the core.


## Operation
The core API follows the description in the BLAKE2s paper and the RFC,
with separate calls to init(), update() and finish() the
processing. (Note that finish() is called final() in the paper and the
RFC, but final() is a reserved word in Verilog).

One must always perform a init() operation separately, before any
update() or finish() operations. One must also always perform a finish()
operation to get the final digest.

For messages smaller than a single 64 byte block, update() should not be
called. Instead finish() should be called. It is the callers
responsibility to set the blocklength to indicate the number of
bytes. (A possible future improvement is to assume that the block size
is 64 bytes for all blocks processed using the update() operation.)

For messages spanning more than one block, perform as many update()
operations as there are complete blocks and then a single final()
operation.



### FuseSoC
This core is supported by the
[FuseSoC](https://github.com/olofk/fusesoc) core package manager and
build system. Some quick  FuseSoC instructions:

install FuseSoC
~~~
pip install fusesoc
~~~

Create and enter a new workspace
~~~
mkdir workspace && cd workspace
~~~

Register blake2s as a library in the workspace
~~~
fusesoc library add blake2s /path/to/blake2s
~~~

...if repo is available locally or...
...to get the upstream repo
~~~
fusesoc library add blake2s https://github.com/secworks/blake2s
~~~

To run lint
~~~
fusesoc run --target=lint secworks:crypto:blake2s
~~~

Run tb_blake2s testbench
~~~
fusesoc run --target=tb_blake2s secworks:crypto:blake2s
~~~

Run with modelsim instead of default tool (icarus)
~~~
fusesoc run --target=tb_blake2s --tool=modelsim secworks:crypto:blake2s
~~~

List all targets
~~~
fusesoc core show secworks:crypto:blake2s
~~~


## Performance
A single block is processed in 24 cycles. Of these 20 cycles is for the 10
rounds. The init() operation takes two cycles, and the finish()
operation takes two additional cycles besides 24 cycles for the final
block processing. This means that for long messages, the core will take
0.375 cycles/byte.


## Implementation details
The core is a high speed, big, yet iterative implemenatation. It will
perform 10 rounds in sequence. But the core contains four G_function
instantiations and can perform a round in two cycles.

For more compact implementations, the core can be restructured to use
two or just a single, shared G_function.

The G_function itself is purely combinational logic, with no registers
and no sharing of operations. For higher clock frequency, and/or a more
compact implementation the G_function can be rewored to be pipelined and
to share for example the adders. Note that this will have a big impact
on the number of cycles required to process a block. Also the core
itself will have to be updated to handle G_function latency beyond the
currently expected one cycle latency.

Note that there is no separate ports for key and key length.

It is the callers responsibility to clear the unused bits in block
containing less than 64 bytes. This holds for both the blake2s_core
module and the blake2s top level wrapper. For the latter, this means
writing one or more 32-bit all zero words.

The core calculate message length based on the number of bytes given
with each block. The core will also handle the last block as defined by
the paper and the RFC.

The message block buffer in blake_m_select.v is not mapped into a
specific memory macro, and may be implemented with registers by the
synthesis tool. For an efficient implementation, one would probably want
to to change the implementation to use technology specific memory
blocks.


## Implementation results
Any implementation results provided would be greatly appreciated.


### Xilinx Artix 7 200T-1 ###
- LUTs: 3387
- Regs: 1893
- Fmax: 61 MHz
