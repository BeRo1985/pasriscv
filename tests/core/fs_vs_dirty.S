# fflags is FP state, so an instruction that only sets flags (compares, conversions to
# integers, vector FP) has to make mstatus.FS Dirty, and so does vfmv.f.s, which writes an FP
# register; writes that change vstart, vxsat, vxrm or vcsr make mstatus.VS Dirty. Every check
# sets FS or VS to Clean first. 10 checks per round, 20 rounds for the JIT.
# expect: a0=00000000000000C8 a1=0000000000000000
#include "head.inc"
#include "fpmacros.inc"

.macro FSCLEAN
  li t0, 0x6000
  csrc mstatus, t0
  li t0, 0x4000
  csrs mstatus, t0
.endm

.macro VSCLEAN
  li t0, 0x600
  csrc mstatus, t0
  li t0, 0x400
  csrs mstatus, t0
.endm

# FS (bits 14:13) or VS (bits 10:9) is Dirty (3)
.macro CHKFS bit
  csrr t0, mstatus
  srli t0, t0, 13
  andi t0, t0, 3
  CHKX t0, 3, \bit
.endm

.macro CHKVS bit
  csrr t0, mstatus
  srli t0, t0, 9
  andi t0, t0, 3
  CHKX t0, 3, \bit
.endm

  li t0, 0x2200
  csrs mstatus, t0
  vsetivli zero, 4, e32, m1, ta, ma
  FLIS ft1, 0x3f800000                      # 1.0
  vfmv.v.f v2, ft1
  li s9, 20
  jal t2, dirtyloop
  j done

  .balign 4096
dirtyloop:
1:
  FLIS ft0, 0x7f800001                      # sNaN
  FLIS ft1, 0x3f800000                      # 1.0
  FLIS ft2, 0x7fc00000                      # qNaN
  FLIS ft3, 0x3fc00000                      # 1.5
  FLIS ft5, 0x30800000                      # 2^-30
  fsflags zero
  FSCLEAN
  feq.s t1, ft0, ft1                        # NV
  CHKFS 0
  FSCLEAN
  flt.s t1, ft2, ft1                        # NV
  CHKFS 1
  FSCLEAN
  fcvt.w.s t1, ft3                          # NX
  CHKFS 2
  FSCLEAN
  vfmv.f.s ft4, v2
  CHKFS 3
  FSCLEAN
  vfadd.vf v3, v2, ft5                      # 1+2^-30: NX
  CHKFS 4
  VSCLEAN
  csrr t1, vxrm
  xori t1, t1, 1
  csrw vxrm, t1
  CHKVS 5
  VSCLEAN
  csrr t1, vxsat
  xori t1, t1, 1
  csrw vxsat, t1
  CHKVS 6
  VSCLEAN
  csrwi vstart, 1
  CHKVS 7
  csrwi vstart, 0
  VSCLEAN
  csrr t1, vcsr
  xori t1, t1, 2
  csrw vcsr, t1
  CHKVS 8
  # vfmv.f.s result is 1.0
  CHKS ft4, 0x3f800000, 9
  addi s9, s9, -1
  bnez s9, 1b
  jr t2
#include "tail.inc"
