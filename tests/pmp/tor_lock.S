# The bottom address of a locked TOR entry can not be changed
# expect: s0=0000000010000000 s1=0000000000008900 s2=0000000000000000 cause=0000000000000000
#include "head.inc"
  li t0, 0x10000000
  csrw pmpaddr0, t0
  li t0, 0x10000400
  csrw pmpaddr1, t0
  li t0, 0x8900
  csrw pmpcfg0, t0        # entry 1: locked TOR (R) on top of pmpaddr0
  li t0, 0x12345
  csrw pmpaddr0, t0       # bottom of a locked TOR entry: write ignored
  csrr s0, pmpaddr0       # expect 0x10000000
  csrr s1, pmpcfg0        # expect 0x8900
#include "tail.inc"
