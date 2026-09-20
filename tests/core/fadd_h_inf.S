# fadd.h/fsub.h in the fast path treated any two infinities as invalid, so +inf + +inf gave
# NaN (and NV). Only inf + -inf (addition with different signs, subtraction with equal signs) is
# invalid, and its result is a NaN. Only checked for being a NaN: the interpreter gives the
# canonical 0x7e00, the JIT only with PasRISCVJITCanonicalHalfNaN (on by default).
# 8 checks per round, 20 rounds for the JIT.
# expect: a0=00000000000000A0 a1=0000000000000000
#include "head.inc"
#include "fpmacros.inc"
  li t0, 0x2000
  csrs mstatus, t0
  li s9, 20
  jal t2, infloop
  j done

  .balign 4096
infloop:
1:
  FLIH ft0, 0x7c00                          # +inf
  FLIH ft1, 0xfc00                          # -inf
  fsflags zero
  fadd.h ft2, ft0, ft0
  CHKH ft2, 0x7c00, 0
  fsub.h ft2, ft0, ft1
  CHKH ft2, 0x7c00, 1
  fadd.h ft2, ft1, ft1
  CHKH ft2, 0xfffffffffffffc00, 2
  fsub.h ft2, ft1, ft0
  CHKH ft2, 0xfffffffffffffc00, 3
  # None of the four above is invalid
  frflags t4
  andi t4, t4, 0x10
  CHKX t4, 0, 4
  fadd.h ft2, ft0, ft1
  CHKHNAN ft2, 5
  fsub.h ft2, ft0, ft0
  CHKHNAN ft2, 6
  fsub.h ft2, ft1, ft1
  CHKHNAN ft2, 7
  fsflags zero
  addi s9, s9, -1
  bnez s9, 1b
  jr t2
#include "tail.inc"
