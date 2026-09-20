# FP and CSR details: fli.h takes its values from a half precision table (the entry
# 2^-8 was 2^-10 in the JIT, and the entry 2^16 raised overflow and inexact through a conversion),
# the reserved rounding modes 5 and 6 and a funct3 other than 0 for fmv.w.x are illegal,
# fcvtmod.w.d of a value just below -2^31 truncates to -2^31 with inexact instead of invalid, a
# write to the read-only mtopi traps, and the seed CSR needs its enable in mseccfg below M-mode.
# The loop runs 20 times so that the JIT translates the code as well.
# expect: a0=0000000000001C00 a1=0000000000007C00 a2=0000000000000000 a3=0000000000000002 a4=0000000000000002 a5=FFFFFFFF80000000 a6=0000000000000001 a7=0000000000000002 s0=0000000000000002 s1=0000000000000001
#include "head.inc"
  # FS to Dirty
  li t0, 0x6000
  csrs mstatus, t0
  li s9, 20
1:
  # fli.h with the index 4 (2^-8) and 29 (2^16, not representable, so infinity), no flags
  csrwi fflags, 0
  .insn r 0x53, 0, 0x7a, ft0, f4, f1
  fmv.x.h a0, ft0
  .insn r 0x53, 0, 0x7a, ft1, f29, f1
  fmv.x.h a1, ft1
  csrr a2, fflags

  # fadd.s with the reserved rounding mode 5
  PROBE a3, .insn r 0x53, 5, 0x00, ft2, ft0, ft1

  # fmv.w.x with funct3 = 1
  PROBE a4, .insn r 0x53, 1, 0x78, ft2, t0, x0

  # fcvtmod.w.d of -(2^31 + 0.5): truncation gives -2^31, which fits, so only inexact
  lla t0, dval
  fld ft3, 0(t0)
  csrwi fflags, 0
  .insn r 0x53, 1, 0x61, a5, ft3, f8
  csrr a6, fflags

  # a write to the read-only mtopi
  li t0, 0
  PROBE a7, csrw 0xfb0, t0

  # the seed CSR: M-mode may read it, S-mode may not without mseccfg.SSEED
  li s1, 0
  csrrw t0, 0x015, x0
  li s1, 1
  ENTER_HS sm
sm:
  PROBE s0, csrrw t0, 0x015, x0
  TO_M mm
mm:
  addi s9, s9, -1
  bnez s9, 1b
  j done

  .balign 16
dval:
  .dword 0xc1e0000000100000
#include "tail.inc"
