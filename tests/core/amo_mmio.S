# AMOs on a device register without direct memory access (here REG_GUEST_FLAGS of the shared
# memory device, which offers the bounce buffer) read the old value from the device and write the
# result back to the same physical address, also with rd=rs1. A device without bounce support
# (the ACLINT) and unmapped addresses give access faults instead of silently doing nothing:
# store/AMO access fault (7) for AMOs and cbo.zero, load access fault (5) for LR, with the address
# in mtval.
# expect: a0=0000000000000005 a2=0000000000000008 a3=0000000000000008 s0=0000000000001234 a7=0000000007070507 s2=0000000007000000
#include "head.inc"
  li a4, 0x2f000008
  li t0, 5
  sw t0, 0(a4)
  li a1, 3
  amoadd.w a0, a1, (a4)
  lw a2, 0(a4)
  # rd=rs1: the write back has to go to the address, not to the loaded value
  mv a3, a4
  li a5, 0x1234
  amoswap.w a3, a5, (a3)
  lw s0, 0(a4)
  sw zero, 0(a4)
  # ACLINT mtimecmp: no AMOs
  li t1, 0x2004000
  PROBE8 a7, amoadd.d t0, a1, (t1)
  # unmapped
  li t1, 0x7000000
  PROBE8 a7, amoadd.d t0, a1, (t1)
  PROBE8 a7, lr.d t0, (t1)
  PROBE8 a7, cbo.zero 0(t1)
  j done
#include "tail.inc"
