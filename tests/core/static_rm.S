# The fast interpreter computed with the host rounding mode, which follows frm, and ignored a
# static rm (the JIT honors it); fcvt.h.s always rounded to nearest even (vcvtps2ph imm 0),
# fcvt.h.d rounded twice (double to single to half), fcvt.bf16.s always rounded to nearest even
# and in the JIT turned NaNs into infinities or zeros. A dynamic instruction after a static one
# checks that the host mode is back at frm. 40 checks per round, 20 rounds for the JIT.
# expect: a0=0000000000000320 a1=0000000000000000
#include "head.inc"
#include "fpmacros.inc"
  li t0, 0x2000
  csrs mstatus, t0
  li s9, 20
  jal t2, rmloop
  j done

  .balign 4096
rmloop:
1:
  # frm = RNE
  fsrmi 0
  FLIS ft0, 0x3f800000                      # 1.0
  FLIS ft1, 0x33c00000                      # 1.5*2^-24, 0.75 ulp of 1.0
  fadd.s ft2, ft0, ft1, rtz
  CHKS ft2, 0x3f800000, 0
  fadd.s ft2, ft0, ft1, rup
  CHKS ft2, 0x3f800001, 1
  fadd.s ft2, ft0, ft1, rdn
  CHKS ft2, 0x3f800000, 2
  fadd.s ft2, ft0, ft1
  CHKS ft2, 0x3f800001, 3
  FLID fa0, 0x3ff0000000000000              # 1.0
  FLID fa1, 0x4008000000000000              # 3.0
  fdiv.d fa2, fa0, fa1, rup
  CHKD fa2, 0x3fd5555555555556, 4
  fdiv.d fa2, fa0, fa1
  CHKD fa2, 0x3fd5555555555555, 5
  FLID fa3, 0x4000000000000000              # 2.0
  fsqrt.d fa2, fa3, rtz
  CHKD fa2, 0x3ff6a09e667f3bcc, 6
  FLID fa4, 0x3fd5555555555555              # 1/3
  fcvt.s.d ft2, fa4, rtz
  CHKS ft2, 0x3eaaaaaa, 7
  li t0, 0x7fffffffffffffff
  fcvt.s.l ft2, t0, rtz
  CHKS ft2, 0x5effffff, 8
  fmadd.s ft2, ft0, ft0, ft1, rtz
  CHKS ft2, 0x3f800000, 9
  FLIS ft3, 0x3f801008                      # 1+2^-11+2^-20
  fcvt.h.s ft2, ft3, rtz
  CHKH ft2, 0x3c00, 10
  fcvt.h.s ft2, ft3
  CHKH ft2, 0x3c01, 11
  FLID fa5, 0x3ff0020000001000              # 1+2^-11+2^-40, just above the tie
  fcvt.h.d ft2, fa5
  CHKH ft2, 0x3c01, 12
  FLID fa6, 0x3ff005ffffc00000              # 1+3*2^-11-2^-30, just below the tie
  fcvt.h.d ft2, fa6
  CHKH ft2, 0x3c01, 13
  fcvt.h.d ft2, fa5, rtz
  CHKH ft2, 0x3c00, 14
  FLID fa7, 0xfff8000000000001              # -NaN with payload
  fcvt.h.d ft2, fa7
  CHKH ft2, 0x7e00, 15
  FLIS ft4, 0x3f808000                      # bf16 tie, even below
  fcvt.bf16.s ft2, ft4
  CHKH ft2, 0x3f80, 16
  FLIS ft5, 0x3f818000                      # bf16 tie, odd below
  fcvt.bf16.s ft2, ft5, rne
  CHKH ft2, 0x3f82, 17
  fcvt.bf16.s ft2, ft4, rup
  CHKH ft2, 0x3f81, 18
  FLIS ft6, 0xbf808001                      # negative, just above the tie
  fcvt.bf16.s ft2, ft6, rdn
  CHKH ft2, 0xffffffffffffbf81, 19
  fcvt.bf16.s ft2, ft6, rup
  CHKH ft2, 0xffffffffffffbf80, 20
  fcvt.bf16.s ft2, ft6, rtz
  CHKH ft2, 0xffffffffffffbf80, 21
  FLIS ft7, 0x7f7fffff                      # largest single
  fcvt.bf16.s ft2, ft7, rne
  CHKH ft2, 0x7f80, 22
  fcvt.bf16.s ft2, ft7, rtz
  CHKH ft2, 0x7f7f, 23
  FLIS ft8, 0x7f800001                      # sNaN
  fcvt.bf16.s ft2, ft8
  CHKH ft2, 0x7fc0, 24
  FLIS ft8, 0x7fffffff
  fcvt.bf16.s ft2, ft8
  CHKH ft2, 0x7fc0, 25
  FLIS ft8, 0xffc00000                      # -qNaN
  fcvt.bf16.s ft2, ft8
  CHKH ft2, 0x7fc0, 26
  FLIS ft8, 0x7f800000                      # +inf
  fcvt.bf16.s ft2, ft8, rup
  CHKH ft2, 0x7f80, 27
  FLIS ft8, 0x3f80ffff
  fcvt.bf16.s ft2, ft8, rdn
  CHKH ft2, 0x3f80, 28
  fcvt.bf16.s ft2, ft8, rup
  CHKH ft2, 0x3f81, 29
  # frm = RTZ
  fsrmi 1
  fadd.s ft2, ft0, ft1, rne
  CHKS ft2, 0x3f800001, 30
  fadd.s ft2, ft0, ft1
  CHKS ft2, 0x3f800000, 31
  fcvt.bf16.s ft2, ft5
  CHKH ft2, 0x3f81, 32
  fcvt.bf16.s ft2, ft5, rne
  CHKH ft2, 0x3f82, 33
  fcvt.h.s ft2, ft3
  CHKH ft2, 0x3c00, 34
  fcvt.h.s ft2, ft3, rne
  CHKH ft2, 0x3c01, 35
  # frm = RUP
  fsrmi 3
  fcvt.bf16.s ft2, ft4
  CHKH ft2, 0x3f81, 36
  FLID fa5, 0x3ff0000000001000              # 1+2^-40
  fcvt.h.d ft2, fa5
  CHKH ft2, 0x3c01, 37
  fcvt.bf16.s ft2, ft6
  CHKH ft2, 0xffffffffffffbf80, 38
  FLIS ft8, 0xffc00000                      # -qNaN
  fcvt.h.s ft2, ft8
  CHKHNAN ft2, 39
  fsrmi 0
  addi s9, s9, -1
  beqz s9, 2f
  j 1b
2:
  jr t2
#include "tail.inc"
