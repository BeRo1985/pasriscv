# HLV/HSV work across a page boundary, a store through a read-only G-stage mapping faults, and
# a split HLV whose second part faults leaves rd alone
# expect: a0=0000000055667788 a5=0000000011223344 a1=1122334455667788 a2=0000000000005555 a3=0000000000000017 a4=0000000000000015
#include "head.inc"
  GSTAGE_IDENTITY
  GSTAGE_ALIAS 0xd3             # read only: V R U A D
  ENTER_HS hs
hs:
  li t0, 0x80011ffc
  li t1, 0x1122334455667788
  hsv.d t1, (t0)                # across 0x80012000
  lwu a0, 0(t0)
  li t2, 0x80012000
  lwu a5, 0(t2)
  hlv.d a1, (t0)
  li s4, 0
  li t0, 0xC0011ffc
  hsv.d t1, (t0)                # read-only alias: store guest-page fault
  mv a3, s4
  li s4, 0
  li a2, 0x5555
  li t0, 0xFFFFFFFC             # second half at GPA 0x100000000, which is not mapped
  hlv.d a2, (t0)
  mv a4, s4
  j done
#include "tail.inc"
