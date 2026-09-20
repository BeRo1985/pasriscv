# Control test: without an earlier allowed access, lwu at 0x80004004 outside the NA4 region faults (from the external audit)
# expect: s0=0000000000000000 s1=0000000000000000 s2=0000000080004004 cause=0000000000000005
#include "head.inc"
  csrw satp, zero
  li t0, 0x80004000
  li t1, 0x11111111
  sw t1, 0(t0)
  li t1, 0x22222222
  sw t1, 4(t0)
  srli t1, t0, 2
  csrw pmpaddr0, t1
  li t1, -1
  csrw pmpaddr1, t1
  li t1, 0x1811
  csrw pmpcfg0, t1
  sfence.vma
  li t1, 0x20800
  csrw mstatus, t1
  lwu s1,4(t0)
#include "tail.inc"
