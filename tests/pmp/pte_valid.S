# Control test: a valid R/W leaf PTE works (from the external audit)
# expect: s0=0000000000000001 s1=0000000000000000 s2=0000000000000000 cause=0000000000000000
#include "head.inc"
  li t0, 0x80002000
  li t1, 0x200000c7
  sd t1, 0(t0)
  li t0, 0x80004000
  li t1, 0x12345678
  sd t1, 0(t0)
  li t1, -1
  csrw pmpaddr1, t1
  li t1, 0x1f00
  csrw pmpcfg0, t1
  li t1, 0x200009ff
  csrw pmpaddr0, t1
  li t1, 0x8000000000080002
  csrw satp, t1
  sfence.vma
  li t1, 0x20800
  csrw mstatus, t1
  li t0, 0x4000
  sd zero,0(t0)
  li s0,1
#include "tail.inc"
