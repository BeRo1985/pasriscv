# After clearing SUM, S-mode must not reach a user page through a TLB entry filled with SUM=1
# expect: s0=0000000000004444 s1=0000000000000000 s2=0000000000004000 cause=000000000000000D
#include "head.inc"
#include "pmpall.inc"
  li t0, 0x80004000
  li t1, 0x4444
  sd t1, 0(t0)
  li t0, 0x80010000
  li t1, 0x20004401            # root[0] -> 0x80011000
  sd t1, 0(t0)
  li t1, 0x200000cf            # root[2]: 1 GiB identity for the S-mode code
  sd t1, 16(t0)
  li t0, 0x80011000
  li t1, 0x20004801            # l1[0] -> 0x80012000
  sd t1, 0(t0)
  li t0, 0x80012020
  li t1, 0x200010d7            # l0[4]: user page VA 0x4000 -> PA 0x80004000
  sd t1, 0(t0)
  li t1, 0x8000000000080010
  csrw satp, t1
  sfence.vma
  li t0, 0x1800
  csrc mstatus, t0
  li t0, 0x0800
  csrs mstatus, t0             # MPP=S
  lla t0, s_code
  csrw mepc, t0
  mret
s_code:
  li t1, 0x40000               # SUM
  csrs sstatus, t1
  li t0, 0x4000
  ld s0, 0(t0)                 # SUM=1: 0x4444
  csrc sstatus, t1
  ld s1, 0(t0)                 # SUM=0: load page fault
#include "tail.inc"
