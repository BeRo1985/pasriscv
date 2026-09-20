# vfrec7.v and vfrsqrt7.v normalized a subnormal input with an exponent that was one too high
# and kept the leading one in place instead of shifting it out, the fp16 path took a detour through
# single precision (and so never saw the overflow of vfrec7, which follows frm), and a negative
# quiet NaN raised NV in vfrsqrt7 because the sign was checked before the NaN. The expected values
# come from the algorithm of the V spec (the reference implementation of QEMU, frec7/frsqrt7).
# a0 to a6 count matching elements (9, 9, 9, 9, 9, 6, 6), a7 the three NaN and negative results,
# s0 and s1 are the fflags of the two vfrec7 runs with an overflowing subnormal (OF and NX = 5),
# s9 those of a vfrsqrt7 run (none), s7 collects the fflags of a negative quiet NaN (none), of a
# signaling NaN (NV) and of -1.0 (NV).
# expect: a0=0000000000000009 a1=0000000000000009 a2=0000000000000009 a3=0000000000000009 a4=0000000000000009 a5=0000000000000006 a6=0000000000000006 a7=0000000000000003 s0=0000000000000005 s1=0000000000000005 s7=0000000000001010 s9=0000000000000000
#include "head.inc"

# CMPN reg, count, esize, outbuf, expbuf: counts the matching elements of the two buffers
.macro CMPN reg, count, esize, out, exp
  li \reg, 0
  lla t2, \out
  lla t3, \exp
  li t4, \count
1:
  .if \esize == 2
  lhu t0, 0(t2)
  lhu t1, 0(t3)
  .endif
  .if \esize == 4
  lwu t0, 0(t2)
  lwu t1, 0(t3)
  .endif
  .if \esize == 8
  ld t0, 0(t2)
  ld t1, 0(t3)
  .endif
  bne t0, t1, 2f
  addi \reg, \reg, 1
2:
  addi t2, t2, \esize
  addi t3, t3, \esize
  addi t4, t4, -1
  bnez t4, 1b
.endm

  # FS and VS to Dirty
  li t0, 0x6600
  csrs mstatus, t0

  # fp16 vfrec7 with frm = RNE
  csrwi frm, 0
  csrwi fflags, 0
  li t0, 9
  vsetvli t1, t0, e16, m4, ta, ma
  lla t0, hin
  vle16.v v4, (t0)
  vfrec7.v v8, v4
  lla t0, hout
  vse16.v v8, (t0)
  csrr s0, fflags
  CMPN a0, 9, 2, hout, hrecrne

  # fp16 vfrec7 with frm = RTZ
  csrwi frm, 1
  csrwi fflags, 0
  li t0, 9
  vsetvli t1, t0, e16, m4, ta, ma
  lla t0, hin
  vle16.v v4, (t0)
  vfrec7.v v8, v4
  lla t0, hout
  vse16.v v8, (t0)
  CMPN a1, 9, 2, hout, hrecrtz
  csrwi frm, 0

  # fp16 vfrsqrt7
  csrwi fflags, 0
  li t0, 9
  vsetvli t1, t0, e16, m4, ta, ma
  lla t0, hin
  vle16.v v4, (t0)
  vfrsqrt7.v v8, v4
  lla t0, hout
  vse16.v v8, (t0)
  csrr s9, fflags
  CMPN a2, 9, 2, hout, hrsqrt

  # fp32 vfrec7
  csrwi fflags, 0
  li t0, 9
  vsetvli t1, t0, e32, m4, ta, ma
  lla t0, sin
  vle32.v v4, (t0)
  vfrec7.v v8, v4
  lla t0, sout
  vse32.v v8, (t0)
  csrr s1, fflags
  CMPN a3, 9, 4, sout, srec

  # fp32 vfrsqrt7
  csrwi fflags, 0
  li t0, 9
  vsetvli t1, t0, e32, m4, ta, ma
  lla t0, sin
  vle32.v v4, (t0)
  vfrsqrt7.v v8, v4
  lla t0, sout
  vse32.v v8, (t0)
  CMPN a4, 9, 4, sout, srsqrt

  # fp64 vfrec7
  csrwi fflags, 0
  li t0, 6
  vsetvli t1, t0, e64, m4, ta, ma
  lla t0, din
  vle64.v v4, (t0)
  vfrec7.v v8, v4
  lla t0, dout
  vse64.v v8, (t0)
  CMPN a5, 6, 8, dout, drec

  # fp64 vfrsqrt7
  csrwi fflags, 0
  li t0, 6
  vsetvli t1, t0, e64, m4, ta, ma
  lla t0, din
  vle64.v v4, (t0)
  vfrsqrt7.v v8, v4
  lla t0, dout
  vse64.v v8, (t0)
  CMPN a6, 6, 8, dout, drsqrt

  # vfrsqrt7 of a negative quiet NaN, of a signaling NaN and of -1.0, each a single element
  li a7, 0
  li s7, 0
  li t0, 1
  vsetvli t1, t0, e16, m1, ta, ma

  csrwi fflags, 0
  li t0, 0xfe00
  vmv.v.x v1, t0
  vfrsqrt7.v v2, v1
  vmv.x.s t0, v2
  csrr t1, fflags
  slli s7, s7, 8
  or s7, s7, t1
  li t1, 0x7e00
  bne t0, t1, 1f
  addi a7, a7, 1
1:
  csrwi fflags, 0
  li t0, 0xfc01
  vmv.v.x v1, t0
  vfrsqrt7.v v2, v1
  vmv.x.s t0, v2
  csrr t1, fflags
  slli s7, s7, 8
  or s7, s7, t1
  li t1, 0x7e00
  bne t0, t1, 2f
  addi a7, a7, 1
2:
  csrwi fflags, 0
  li t0, 0xbc00
  vmv.v.x v1, t0
  vfrsqrt7.v v2, v1
  vmv.x.s t0, v2
  csrr t1, fflags
  slli s7, s7, 8
  or s7, s7, t1
  li t1, 0x7e00
  bne t0, t1, 3f
  addi a7, a7, 1
3:
  j done

  .balign 16
hin:
  .half 0x0001, 0x0080, 0x0100, 0x0200, 0x0201, 0x0400, 0x3c00, 0x4200, 0x7bff
hrecrne:
  .half 0x7c00, 0x7c00, 0x7bf8, 0x77f8, 0x77f8, 0x73f8, 0x3bf8, 0x3550, 0x0100
hrecrtz:
  .half 0x7bff, 0x7bff, 0x7bf8, 0x77f8, 0x77f8, 0x73f8, 0x3bf8, 0x3550, 0x0100
hrsqrt:
  .half 0x6bf8, 0x5da0, 0x5bf8, 0x59a0, 0x59a0, 0x57f8, 0x3bf8, 0x3898, 0x1c00
sin:
  .word 0x00000001, 0x00100000, 0x00200000, 0x00400000, 0x00400001, 0x00800000, 0x3f800000, 0x40800000, 0x7f7fffff
srec:
  .word 0x7f800000, 0x7f800000, 0x7f7f0000, 0x7eff0000, 0x7eff0000, 0x7e7f0000, 0x3f7f0000, 0x3e7f0000, 0x00200000
srsqrt:
  .word 0x64b40000, 0x5fb40000, 0x5f7f0000, 0x5f340000, 0x5f340000, 0x5eff0000, 0x3f7f0000, 0x3eff0000, 0x1f800000
din:
  .dword 0x0000000000000001, 0x0004000000000000, 0x0008000000000000, 0x0010000000000000, 0x3ff0000000000000, 0x7fefffffffffffff
drec:
  .dword 0x7ff0000000000000, 0x7fefe00000000000, 0x7fdfe00000000000, 0x7fcfe00000000000, 0x3fefe00000000000, 0x0004000000000000
drsqrt:
  .dword 0x617fe00000000000, 0x5fefe00000000000, 0x5fe6800000000000, 0x5fdfe00000000000, 0x3fefe00000000000, 0x1ff0000000000000
hout:
  .space 64
sout:
  .space 64
dout:
  .space 64
#include "tail.inc"
