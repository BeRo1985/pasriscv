# sfence.vma with an address inside a 2 MiB superpage must drop all of its cached 4 KiB parts
# expect: s0=0000000011111111 s1=0000000022222222 s2=0000000000000000 cause=0000000000000000
#include "head.inc"
#include "pmpall.inc"
  li t0, 0x80201000
  li t1, 0x11111111
  sd t1, 0(t0)
  li t0, 0x80401000
  li t1, 0x22222222
  sd t1, 0(t0)
  li t0, 0x80010000
  li t1, 0x20004401            # root[0] -> 0x80011000
  sd t1, 0(t0)
  li t1, 0x200000cf            # root[2]: 1 GiB identity at 0x80000000, so MPRV stores can reach the tables
  sd t1, 16(t0)
  li t0, 0x80011008
  li t1, 0x200800cf            # l1[1]: 2 MiB at VA 0x200000 -> PA 0x80200000
  sd t1, 0(t0)
  li t1, 0x8000000000080010
  csrw satp, t1
  sfence.vma
  li t1, 0x20800               # MPRV=1, MPP=S
  csrs mstatus, t1
  li t0, 0x200000
  ld t2, 0(t0)                 # caches the first 4 KiB part
  li t3, 0x201000
  ld s0, 0(t3)                 # caches the second one: 0x11111111
  li t2, 0x80011008
  li t1, 0x201000cf            # remap the superpage to PA 0x80400000
  sd t1, 0(t2)
  sfence.vma t0                # address of the first part only
  ld s1, 0(t3)                 # expect 0x22222222 from the new mapping
#include "tail.inc"
