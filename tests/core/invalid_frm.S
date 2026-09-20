# An frm of 5 to 7 is a reserved rounding mode. It may be written, but every later FP instruction
# that would round with it is an illegal instruction until frm is valid again: a scalar rm=dyn and
# the vector FP instructions, which take their rounding mode from frm alone. A static rm and scalar
# instructions without a rounding mode field keep working.
# a0 = fadd.s with rm=dyn at frm=5, a1 = fadd.s with the static rtz, a2 = fsgnj.s, a3 = vfadd.vv,
# a4 = vfsgnj.vv (it does not round itself, but the vector FP path checks frm for all of them),
# a5 = fadd.s with rm=dyn at frm=6, a6 = fadd.s with rm=dyn after frm=0 again, a7 = frm read back
# after writing 5 (frm is WARL and keeps the reserved value here).
# The loop runs 20 times so that the JIT translates the code as well: a block traced with a valid
# frm must not keep running once frm is invalid.
# expect: a0=0000000000000002 a1=0000000000000000 a2=0000000000000000 a3=0000000000000002 a4=0000000000000002 a5=0000000000000002 a6=0000000000000000 a7=0000000000000005
#include "head.inc"

  # FS and VS to Dirty
  li t0, 0x6600
  csrs mstatus, t0

  # Four elements at SEW=32, v4 as the source of the vector checks
  li t0, 4
  vsetvli t1, t0, e32, m1, ta, ma
  lla t0, words
  vle32.v v4, (t0)

  li s9, 20
1:
  # frm = 5 (reserved)
  fsrmi 5
  csrr a7, frm

  # rm=dyn rounds with frm, so it is illegal now
  PROBE a0, fadd.s ft2, ft0, ft1

  # a static rm brings its own rounding mode and stays legal
  PROBE a1, fadd.s ft2, ft0, ft1, rtz

  # fsgnj.s has no rounding mode field (funct3 is a sub-opcode)
  PROBE a2, fsgnj.s ft2, ft0, ft1

  # vector FP rounds with frm
  PROBE a3, vfadd.vv v8, v4, v4
  PROBE a4, vfsgnj.vv v8, v4, v4

  # frm = 6 is reserved as well
  fsrmi 6
  PROBE a5, fadd.s ft2, ft0, ft1

  # back to a valid frm
  fsrmi 0
  PROBE a6, fadd.s ft2, ft0, ft1

  addi s9, s9, -1
  bnez s9, 1b
  j done

  .balign 16
words:
  .word 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000
#include "tail.inc"
