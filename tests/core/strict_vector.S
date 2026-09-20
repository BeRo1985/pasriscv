# Two checks in strict mode (switched on with mpasriscvctl bit 0): a masked FP compare cleared the
# mask bits of inactive elements instead of leaving them alone, and vfwadd.wf with SEW=16 took the
# bits of the half scalar as a single precision value instead of widening it. The same checks run
# with the fast path afterwards, both have to agree.
# a0 and a2 = the mask register after a masked vmfeq.vv whose active elements all compare false
# (0x55: the four inactive bits keep their one), a1 and a3 = how many of the four vfwadd.wf results
# are 2.0 (1.0 + the half scalar 1.0).
# expect: a0=0000000000000055 a1=0000000000000004 a2=0000000000000055 a3=0000000000000004
#include "head.inc"

# CMPN reg, count, esize, outbuf, expbuf: counts the matching elements of the two buffers
.macro CMPN reg, count, esize, out, exp
  li \reg, 0
  lla t2, \out
  lla t3, \exp
  li t4, \count
1:
  .if \esize == 4
  lwu t0, 0(t2)
  lwu t1, 0(t3)
  .endif
  bne t0, t1, 2f
  addi \reg, \reg, 1
2:
  addi t2, t2, \esize
  addi t3, t3, \esize
  addi t4, t4, -1
  bnez t4, 1b
.endm

# VCHECKS a, b: the masked compare into a and the widening add into b
.macro VCHECKS mreg, wreg
  # v0 = 0xaa (elements 1, 3, 5, 7 active), v8 = 0xff (the destination bits before the compare)
  li t0, 1
  vsetvli t1, t0, e8, m1, tu, mu
  lla t0, maskbuf
  vle8.v v0, (t0)
  lla t0, onesbuf
  vle8.v v8, (t0)
  li t0, 8
  vsetvli t1, t0, e32, m4, ta, ma
  lla t0, cmpa
  vle32.v v16, (t0)
  lla t0, cmpb
  vle32.v v20, (t0)
  vmfeq.vv v8, v16, v20, v0.t
  li t0, 1
  vsetvli t1, t0, e8, m1, ta, ma
  lla t0, outb
  vse8.v v8, (t0)
  lbu \mreg, 0(t0)

  # vfwadd.wf with SEW=16: vs2 is single precision, the scalar is a half
  li t0, 0x3c00
  fmv.h.x ft0, t0
  li t0, 4
  vsetvli t1, t0, e32, m2, ta, ma
  lla t0, widea
  vle32.v v4, (t0)
  li t0, 4
  vsetvli t1, t0, e16, m1, ta, ma
  vfwadd.wf v8, v4, ft0
  li t0, 4
  vsetvli t1, t0, e32, m2, ta, ma
  lla t0, outw
  vse32.v v8, (t0)
  CMPN \wreg, 4, 4, outw, wideexp
.endm

  # FS and VS to Dirty
  li t0, 0x6600
  csrs mstatus, t0

  # Strict FPU on (bit 0), for every hart (bit 1)
  csrsi 0x7d0, 3
  VCHECKS a0, a1
  # Strict FPU off again
  csrci 0x7d0, 1
  VCHECKS a2, a3
  j done

  .balign 16
maskbuf:
  .byte 0xaa
onesbuf:
  .byte 0xff
  .balign 16
cmpa:
  .word 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000
cmpb:
  .word 0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000, 0x40000000
widea:
  .word 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000
wideexp:
  .word 0x40000000, 0x40000000, 0x40000000, 0x40000000
outb:
  .space 16
outw:
  .space 32
#include "tail.inc"
