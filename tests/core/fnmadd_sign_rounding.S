# fnmadd is (-a*b)-c with one rounding. The fast path computed a*b+c and negated it, which
# gives -0 instead of +0 for 1*1-1 (and +0 instead of -0 with RDN) and rounds RUP/RDN the wrong
# way. Static rm and frm, single and double. 10 checks per round, 20 rounds for the JIT.
# expect: a0=00000000000000C8 a1=0000000000000000
#include "head.inc"
#include "fpmacros.inc"
  li t0, 0x2000
  csrs mstatus, t0
  li s9, 20
  jal t2, fnmaddloop
  j done

  .balign 4096
fnmaddloop:
1:
  fsrmi 0
  FLIS ft0, 0x3f800000                      # 1.0
  FLIS ft1, 0xbf800000                      # -1.0
  fnmadd.s ft2, ft0, ft0, ft1, rne          # -(1*1)-(-1) = +0
  CHKS ft2, 0x0000000000000000, 0
  fnmadd.s ft2, ft0, ft0, ft1, rdn          # -0 when rounding down
  CHKS ft2, 0xffffffff80000000, 1
  FLIS ft3, 0x3f800001                      # 1+2^-23
  FLIS ft4, 0x30800000                      # 2^-30
  fnmadd.s ft2, ft0, ft3, ft4, rup          # -(1+2^-23)-2^-30 up: -(1+2^-23)
  CHKS ft2, 0xffffffffbf800001, 2
  fnmadd.s ft2, ft0, ft3, ft4, rdn          # down: -(1+2^-22)
  CHKS ft2, 0xffffffffbf800002, 3
  FLIS ft5, 0x40000000                      # 2.0
  FLIS ft6, 0x40400000                      # 3.0
  fnmadd.s ft2, ft5, ft6, ft0               # -(2*3)-1 = -7
  CHKS ft2, 0xffffffffc0e00000, 4
  fsrmi 2                                   # frm = RDN, dynamic
  fnmadd.s ft2, ft0, ft0, ft1
  CHKS ft2, 0xffffffff80000000, 5
  fsrmi 0
  FLID fa0, 0x3ff0000000000000              # 1.0
  FLID fa1, 0xbff0000000000000              # -1.0
  fnmadd.d fa2, fa0, fa0, fa1, rne
  CHKD fa2, 0x0000000000000000, 6
  fnmadd.d fa2, fa0, fa0, fa1, rdn
  CHKD fa2, 0x8000000000000000, 7
  FLID fa3, 0x3ff0000000000001              # 1+2^-52
  FLID fa4, 0x3c30000000000000              # 2^-60
  fnmadd.d fa2, fa0, fa3, fa4, rup
  CHKD fa2, 0xbff0000000000001, 8
  fnmadd.d fa2, fa0, fa3, fa4, rdn
  CHKD fa2, 0xbff0000000000002, 9
  addi s9, s9, -1
  bnez s9, 1b
  jr t2
#include "tail.inc"
