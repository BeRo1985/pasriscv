# Instructions that the vector spec allows must not raise an illegal instruction. a0 = vl after a
# vsetivli with an AVL of 0 (it sets vl, it does not keep the old one), s9 = the first element of
# an indexed load whose vd is its own index register, a1 to a7 = the mcause of each probed
# instruction (0 = no trap): indexed load with vd = vs2 and nf = 1,
# vmv.x.s with an unaligned vs2 at LMUL = 2 (the vs2 field is a register here, but the alignment
# rule does not apply to it), vwadd.vv with vs2 in the highest part of the wide vd, vfrec7.v at
# LMUL = 8 (its vs1 field is a sub-opcode, not a register), vrgatherei16.vv whose vs1 is checked
# against the index EMUL and not against LMUL, and vsm3me.vv with vd = vs1 (the SM3 driver of Linux
# uses exactly that).
# expect: a0=0000000000000000 a1=0000000000000000 a2=0000000000000000 a3=0000000000000000 a4=0000000000000000 a5=0000000000000000 a6=0000000000000000 s9=0000000011111111
#include "head.inc"

  # FS and VS to Dirty
  li t0, 0x6600
  csrs mstatus, t0

  # An AVL of 0 in vsetivli sets vl to 0, even with rd = x0
  li t0, 8
  vsetvli t1, t0, e32, m1, ta, ma
  vsetivli x0, 0, e32, m1, ta, ma
  csrr a0, vl

  # indexed load with nf = 1, vd and vs2 the same register group
  li t0, 4
  vsetvli t1, t0, e32, m1, ta, ma
  lla t0, idxbuf
  vle32.v v8, (t0)
  lla t0, databuf
  PROBE a1, vluxei32.v v8, (t0), v8
  vmv.x.s s9, v8

  # vmv.x.s at LMUL = 2 with an odd vs2
  li t0, 4
  vsetvli t1, t0, e32, m2, ta, ma
  PROBE a2, vmv.x.s t4, v1

  # widening, vs2 sits in the highest part of the wide vd
  li t0, 4
  vsetvli t1, t0, e32, m1, ta, ma
  PROBE a3, vwadd.vv v4, v5, v6

  # vfrec7.v at LMUL = 8, its vs1 field is the sub-opcode 5
  li t0, 8
  vsetvli t1, t0, e32, m8, ta, ma
  PROBE a4, vfrec7.v v8, v16

  # vrgatherei16.vv at SEW = 32 and LMUL = 2, the index EMUL is 1, so vs1 may be odd
  li t0, 8
  vsetvli t1, t0, e32, m2, ta, ma
  PROBE a5, vrgatherei16.vv v8, v4, v3

  # vsm3me.vv with vd = vs1 (SEW = 32, vl a multiple of 8, LMUL*VLEN at least 256 bits)
  li t0, 8
  vsetvli t1, t0, e32, m2, ta, ma
  PROBE a6, vsm3me.vv v8, v4, v8
  j done

  .balign 16
idxbuf:
  .word 0, 4, 8, 12
databuf:
  .word 0x11111111, 0x22222222, 0x33333333, 0x44444444
#include "tail.inc"
