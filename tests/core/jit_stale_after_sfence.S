# sfence.vma for a page dropped the JIT TLB entries of the page only when the execute TLB
# entry of the page was present. The TLB is direct mapped with one slot for all access types, so
# another page with the same index (here the calling code at VPN 0x80000 and a load from VA
# 0x40100000) takes the slot away, and after remapping VA 0x40000000 the JIT kept running the old
# code. S-mode with Sv39: VA 0x40000000 maps page subA (li a0, 1), is called 20 times, then the PTE
# is switched to page subB (li a0, 2) and sfence.vma for 0x40000000 runs; the next calls have to
# run subB.
# expect: a1=0000000000000001 a2=0000000000000002
#include "head.inc"
  li t0, 0x80200000
  li t1, 0x200000cf
  sd t1, 16(t0)
  li t1, 0x20080401
  sd t1, 8(t0)
  li t0, 0x80201000
  li t1, 0x20080801
  sd t1, 0(t0)
  # L0[0]: VA 0x40000000 -> subA (X, A), L0[256]: VA 0x40100000 -> data page (R, W, A, D)
  li t0, 0x80202000
  lla t1, subA
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, 0x4b
  sd t1, 0(t0)
  lla t1, datapage
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, 0xc7
  li t2, 2048
  add t2, t2, t0
  sd t1, 0(t2)
  li t0, 0x8000000000080200
  csrw satp, t0
  sfence.vma
  ENTER_HS s1
s1:
  li s0, 0x40000000
  li s9, 20
1:
  jalr ra, 0(s0)
  addi s9, s9, -1
  bnez s9, 1b
  mv a1, a0
  # evict the execute entry of VA 0x40000000 (same TLB index)
  li t0, 0x40100000
  ld t0, 0(t0)
  # switch VA 0x40000000 to subB
  li t0, 0x80202000
  lla t1, subB
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, 0x4b
  sd t1, 0(t0)
  sfence.vma s0
  li s9, 20
2:
  jalr ra, 0(s0)
  addi s9, s9, -1
  bnez s9, 2b
  mv a2, a0
  TO_M m1
m1:
  j done
  .balign 4096
subA:
  li a0, 1
  ret
  .balign 4096
subB:
  li a0, 2
  ret
  .balign 4096
datapage:
  .dword 0
  .balign 4096
#include "tail.inc"
