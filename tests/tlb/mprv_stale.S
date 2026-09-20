# M-mode TLB entries from before MPRV=1 must not serve MPRV accesses, and the other way round
# expect: s0=0000000000005555 s1=0000000000006666 s2=0000000000005555 cause=0000000000000000
#include "head.inc"
#include "pmpall.inc"
  li t0, 0x80005000
  li t1, 0x5555
  sd t1, 0(t0)
  li t0, 0x80006000
  li t1, 0x6666
  sd t1, 0(t0)
  li t0, 0x80010000
  li t1, 0x20004401            # root[2] -> 0x80011000
  sd t1, 16(t0)
  li t0, 0x80011000
  li t1, 0x20004801            # l1[0] -> 0x80012000
  sd t1, 0(t0)
  li t0, 0x80012028
  li t1, 0x200018c7            # l0[5]: VA 0x80005000 -> PA 0x80006000
  sd t1, 0(t0)
  li t1, 0x8000000000080010
  csrw satp, t1
  sfence.vma
  li t0, 0x80005000
  ld s0, 0(t0)                 # M-mode, physical: 0x5555
  li t1, 0x20800               # MPRV=1, MPP=S
  csrs mstatus, t1
  ld s1, 0(t0)                 # translated: 0x6666
  csrc mstatus, t1
  ld s2, 0(t0)                 # physical again: 0x5555
#include "tail.inc"
