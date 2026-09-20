# A device smaller than a page must not answer for the rest of the page (UART is 0x100 bytes)
# expect: s0=0000000000000000 s1=0000000000000000 s2=0000000010000800 cause=0000000000000005
#include "head.inc"
  li t0, 0x10000000
  lbu t2, 5(t0)                # UART LSR, fills the MMIO TLB in the old code
  li t3, 0x10000800
  lbu s0, 0(t3)                # no device there: expect load access fault
#include "tail.inc"
