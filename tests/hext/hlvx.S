# HLVX needs execute instead of read permission and reports load faults (not instruction
# faults), HLV needs read permission, and a faulting HLV leaves rd alone
# expect: a0=0000000000000297 a1=0000000000000015 a2=0000000000000015 a3=0000000000001111 a4=0000000000002222
#include "head.inc"
  GSTAGE_IDENTITY
  GSTAGE_ALIAS 0xd9             # execute only: V X U A D
  ENTER_HS hs
hs:
  li t0, 0xC0000000
  hlvx.wu a0, (t0)              # executable: reads the first instruction
  li s4, 0
  li a3, 0x1111
  hlv.w a3, (t0)                # not readable: load guest-page fault
  mv a1, s4
  li t1, 0x80100018
  li t2, 0x200000d3             # read only: V R U A D
  sd t2, 0(t1)
  hfence.gvma zero, zero
  li s4, 0
  li a4, 0x2222
  hlvx.wu a4, (t0)              # not executable: load guest-page fault (not instruction guest-page fault)
  mv a2, s4
  j done
#include "tail.inc"
