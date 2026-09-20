# A page table outside of RAM gives an access fault, not a page fault
# expect: s0=0000000000000000 s1=0000000000000000 s2=0000000000004000 cause=0000000000000005
#include "head.inc"
  li t1, -1
  csrw pmpaddr0, t1
  li t1, 0x1f
  csrw pmpcfg0, t1
  li t1, 0x8000000000050000   # Sv39, root table at 0x50000000 (no RAM there)
  csrw satp, t1
  sfence.vma
  li t1, 0x20800              # MPRV, MPP=S
  csrw mstatus, t1
  li t0, 0x4000
  ld s0, 0(t0)                # expect load access fault (5), not page fault (13)
#include "tail.inc"
