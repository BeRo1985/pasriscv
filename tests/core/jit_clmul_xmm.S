# The JIT's clmul/clmulh/clmulr use XMM0 and XMM1, which the register allocator also hands out
# for guest FP registers. FP values live across a clmul must survive. 20 rounds for the JIT.
# expect: a0=0000000000000014
#include "head.inc"
  li t0, 0x2000
  csrs mstatus, t0
  li t1, 0x3ff0000000000000
  li t3, 0x4008000000000000
  li a1, 0x123456789
  li a2, 0x987654321
  li a0, 0
  jal t2, clmulloop
  mv a5, a3
  mv a6, a4
  mv a7, s0
  j done

  .balign 4096
clmulloop:
  li s9, 20
1:
  fmv.d.x f1, t1
  fmv.d.x f2, t1
  fadd.d f3, f1, f2
  clmul a3, a1, a2
  clmulh a4, a1, a2
  clmulr s0, a1, a2
  fadd.d f4, f3, f1
  fmv.x.d t4, f4
  bne t4, t3, 2f
  addi a0, a0, 1
2:
  addi s9, s9, -1
  bnez s9, 1b
  jr t2
#include "tail.inc"
