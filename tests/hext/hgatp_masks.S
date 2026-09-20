# WARL masks of hgatp (PPN[1:0] zero, unsupported MODE ignored), medeleg (bit 10,
# ecall from VS, is delegable), hedeleg, hideleg ($444), mideleg (VS-level interrupts and SGEI
# read-only one), hie, hgeie, hvip and the henvcfg reset value (no VS pointer masking)
# expect: a0=0000000000F4B7FF a1=000000000004B1FF a2=0000000000000444 a3=0000000000001444 a4=0000000000001444 a5=80000000000802FC a6=80000000000802FC a7=0000000000000000 s0=0000000000000002 s1=0000000000000444
#include "head.inc"
  li t0, -1
  csrw medeleg, t0
  csrr a0, medeleg
  csrw hedeleg, t0
  csrr a1, hedeleg
  csrw hideleg, t0
  csrr a2, hideleg
  csrw mideleg, zero
  csrr a3, mideleg
  csrw hie, t0
  csrr a4, hie
  li t1, 0x80000000000802ff
  csrw hgatp, t1
  csrr a5, hgatp
  li t1, 0x50000000000802ff
  csrw hgatp, t1
  csrr a6, hgatp
  csrr a7, henvcfg
  srli a7, a7, 32
  andi a7, a7, 3
  csrw hgeie, t0
  csrr s0, hgeie
  csrw hvip, t0
  csrr s1, hvip
  j done
#include "tail.inc"
