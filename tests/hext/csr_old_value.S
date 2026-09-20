# csrrw/csrrs/csrrc on mie, mip, sie and sip return the old value (they returned the new
# one); sie/sip only show interrupts that mideleg delegates, and STIP is not writable through sip
# expect: a0=0000000000000002 a1=0000000000000020 a2=0000000000000020 a3=0000000000000002 a4=0000000000000002 a5=0000000000000022
#include "head.inc"
  li t0, 0x2
  csrw mie, t0
  li t1, 0x20
  csrrw a0, mie, t1
  csrr a1, mie
  li t0, 0x22
  csrw mideleg, t0
  li t0, 0x2
  csrrw a2, sie, t0
  csrr a3, mie
  csrw mie, zero
  li t0, 0x22
  csrw mip, t0
  li t0, 0x2
  csrw mideleg, t0
  csrr a4, sip
  li t0, 0x22
  csrw mideleg, t0
  li t0, 0x20
  csrc sip, t0
  csrr a5, mip
  andi a5, a5, 0x22
  csrw mip, zero
  j done
#include "tail.inc"
