# An MMIO TLB entry filled by a load must not let a store to a read-only mapping through
# expect: s0=0000000000000005 s1=0000000000000000 s2=0000000000004004 cause=000000000000000F
#include "head.inc"
#include "pmpall.inc"
  li t0, 0x0c000004
  li t1, 5
  sw t1, 0(t0)                 # PLIC priority 1 = 5
  li t0, 0x80010000
  li t1, 0x20004401            # root[0] -> 0x80011000
  sd t1, 0(t0)
  li t0, 0x80011000
  li t1, 0x20004801            # l1[0] -> 0x80012000
  sd t1, 0(t0)
  li t0, 0x80012020
  li t1, 0x03000043            # l0[4]: VA 0x4000 -> PLIC page 0, read-only
  sd t1, 0(t0)
  li t1, 0x8000000000080010
  csrw satp, t1
  sfence.vma
  li t1, 0x20800               # MPRV=1, MPP=S
  csrs mstatus, t1
  li t0, 0x4000
  lw s0, 4(t0)                 # 5
  sw zero, 4(t0)               # expect store page fault
  li s1, 1
#include "tail.inc"
