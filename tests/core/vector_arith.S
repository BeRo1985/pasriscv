# Vector arithmetic and conversions. a0 = vmadc.vim at SEW = 64 with an all-ones immediate and a
# carry-in of 1 (the sum equals vs2 there, which is a carry), a1 = vmsbc.vxm with an all-ones
# scalar (the sum of scalar and borrow-in must not wrap), a2 and a3 = vslidedown.vx and
# vrgather.vx with an offset of 2^32, which must give zeros and must not be cut to 32 bit,
# a4 = vfcvt.xu.f.v of 3e9 rounded down and a5 = vfcvt.x.f.v of 1.5e18 rounded down (the floor of
# the host was 32 bit wide), a6 and a7 = trap and results of vfwcvt.f.x.v from int8 to fp16,
# s0 and s1 = the same for vfncvt.x.f.w from fp16 to int8 (both are Zvfh conversions that were
# missing).
# expect: a0=0000000000000001 a1=0000000000000003 a2=0000000000000000 a3=0000000000000000 a4=00000000B2D05E00 a5=14D1120D7B160000 a6=0000000000000000 a7=0000000000000004 s0=0000000000000000 s1=0000000000000004
#include "head.inc"

# CMPN reg, count, esize, outbuf, expbuf: counts the matching elements of the two buffers
.macro CMPN reg, count, esize, out, exp
  li \reg, 0
  lla t2, \out
  lla t3, \exp
  li t4, \count
1:
  .if \esize == 1
  lbu t0, 0(t2)
  lbu t1, 0(t3)
  .endif
  .if \esize == 2
  lhu t0, 0(t2)
  lhu t1, 0(t3)
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

  # v0 = 0b01: a carry-in for element 0, none for element 1
  li t0, 1
  vsetvli t1, t0, e8, m1, tu, mu
  lla t0, maskbuf
  vle8.v v0, (t0)

  # vmadc.vim with the immediate -1 and vs2 = 0
  li t0, 2
  vsetvli t1, t0, e64, m1, ta, ma
  vmv.v.i v4, 0
  vmadc.vim v8, v4, -1, v0
  li t0, 1
  vsetvli t1, t0, e8, m1, ta, ma
  lla t0, outb
  vse8.v v8, (t0)
  lbu a0, 0(t0)

  # vmsbc.vxm with the scalar -1 and vs2 = 0
  li t0, 2
  vsetvli t1, t0, e64, m1, ta, ma
  li t2, -1
  vmsbc.vxm v8, v4, t2, v0
  li t0, 1
  vsetvli t1, t0, e8, m1, ta, ma
  lla t0, outb
  vse8.v v8, (t0)
  lbu a1, 0(t0)

  # A slide offset and a gather index of 2^32
  li t0, 4
  vsetvli t1, t0, e32, m1, ta, ma
  lla t0, words
  vle32.v v4, (t0)
  li t2, 1
  slli t2, t2, 32
  vslidedown.vx v8, v4, t2
  lla t0, outw
  vse32.v v8, (t0)
  lwu t3, 0(t0)
  lwu t4, 4(t0)
  add a2, t3, t4
  lwu t3, 8(t0)
  lwu t4, 12(t0)
  add a2, a2, t3
  add a2, a2, t4
  vrgather.vx v8, v4, t2
  lla t0, outw
  vse32.v v8, (t0)
  lwu t3, 0(t0)
  lwu t4, 4(t0)
  add a3, t3, t4
  lwu t3, 8(t0)
  lwu t4, 12(t0)
  add a3, a3, t3
  add a3, a3, t4

  # Conversions to integers with rounding down, from 2^31 and from 2^63
  fsrmi 2
  li t0, 4
  vsetvli t1, t0, e32, m1, ta, ma
  lla t0, f3e9
  vle32.v v4, (t0)
  vfcvt.xu.f.v v8, v4
  lla t0, outw
  vse32.v v8, (t0)
  lwu a4, 0(t0)
  li t0, 2
  vsetvli t1, t0, e64, m1, ta, ma
  lla t0, d15e17
  vle64.v v4, (t0)
  vfcvt.x.f.v v8, v4
  lla t0, outw
  vse64.v v8, (t0)
  ld a5, 0(t0)
  fsrmi 0

  # int8 to fp16
  li t0, 4
  vsetvli t1, t0, e8, m1, ta, ma
  lla t0, bytes
  vle8.v v4, (t0)
  PROBE a6, vfwcvt.f.x.v v8, v4
  li t0, 4
  vsetvli t1, t0, e16, m1, ta, ma
  lla t0, outw
  vse16.v v8, (t0)
  CMPN a7, 4, 2, outw, halfexp

  # fp16 to int8
  li t0, 4
  vsetvli t1, t0, e16, m1, ta, ma
  lla t0, halfin
  vle16.v v4, (t0)
  li t0, 4
  vsetvli t1, t0, e8, m1, ta, ma
  PROBE s0, vfncvt.x.f.w v8, v4
  lla t0, outw
  vse8.v v8, (t0)
  CMPN s1, 4, 1, outw, byteexp
  j done

  .balign 16
maskbuf:
  .byte 0x01
bytes:
  .byte -2, 3, -128, 127
byteexp:
  .byte 0x02, 0xfc, 0x7f, 0x80
  .balign 16
halfin:
  .half 0x4100, 0xc300, 0x5a40, 0xda40
halfexp:
  .half 0xc000, 0x4200, 0xd800, 0x57f0
words:
  .word 1, 2, 3, 4
f3e9:
  .word 0x4f32d05e, 0x4f32d05e, 0x4f32d05e, 0x4f32d05e
d15e17:
  .dword 0x43b4d1120d7b1600, 0x43b4d1120d7b1600
outb:
  .space 16
outw:
  .space 64
#include "tail.inc"
