# An invalid Svnapot PTE faults before its A bit is set
# expect: s0=8000000020001007 s1=0000000000000000 s2=0000000000004000 cause=000000000000000D
#include "head.inc"
  li t1, -1
  csrw pmpaddr0, t1
  li t1, 0x1f
  csrw pmpcfg0, t1
  li t0, 0x80002000
  li t1, 0x20000c01           # root[0] -> 0x80003000
  sd t1, 0(t0)
  li t0, 0x80003000
  li t1, 0x20001401           # l1[0] -> 0x80005000
  sd t1, 0(t0)
  li t0, 0x80005020
  li t1, 0x8000000020001007   # l0[4]: N=1 with PPN low bits 0100 (invalid NAPOT), V R W, A=0
  sd t1, 0(t0)
  li t1, 1
  slli t1, t1, 61
  csrs 0x30a, t1              # menvcfg.ADUE: hardware A/D updates
  li t1, 0x8000000000080002
  csrw satp, t1
  sfence.vma
  li t1, 0x20800
  csrw mstatus, t1
  li t0, 0x4000
  ld s1, 0(t0)                # expect load page fault (13) and the PTE left untouched
  j done
  .align 8
trap:
  csrr s4, mcause
  csrr s2, mtval
  li t0, 0x80005020
  ld s0, 0(t0)                # expect 0x8000000020001007 (A bit not set)
done:
  li s11, 0x1234
1: j 1b
