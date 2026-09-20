# sfence.vma with an address must drop the MMIO TLB entry of that page too
# expect: s0=0000000000000005 s1=0000000000000000 s2=0000000000000000 cause=0000000000000000
#include "head.inc"
#include "pmpall.inc"
  li t0, 0x0c000004
  li t1, 5
  sw t1, 0(t0)                 # PLIC priority 1 = 5
  li t0, 0x80010000
  li t1, 0x20004401            # root[0] -> 0x80011000
  sd t1, 0(t0)
  li t1, 0x200000cf            # root[2]: 1 GiB identity, so MPRV stores can reach the tables
  sd t1, 16(t0)
  li t0, 0x80011000
  li t1, 0x20004801            # l1[0] -> 0x80012000
  sd t1, 0(t0)
  li t0, 0x80012020
  li t1, 0x030000c7            # l0[4]: VA 0x4000 -> PLIC page 0
  sd t1, 0(t0)
  li t1, 0x8000000000080010
  csrw satp, t1
  sfence.vma
  li t1, 0x20800               # MPRV=1, MPP=S
  csrs mstatus, t1
  li t0, 0x4000
  lw s0, 4(t0)                 # 5
  li t2, 0x80012020
  li t1, 0x030008c7            # remap VA 0x4000 -> PLIC page 2 (enable bits, 0)
  sd t1, 0(t2)
  sfence.vma t0
  lw s1, 4(t0)                 # expect 0 from the new page
#include "tail.inc"
