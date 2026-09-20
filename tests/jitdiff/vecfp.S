# vecfp.S: bare-metal checks for the vector and floating point fixes below, meant to be compared
# against QEMU with VLEN=256.
# Signature: count (dwords) at 0x807ffff8, data from 0x80800000. Traps are counted and
# skipped; the last three signature words are trap count, last mcause and last mepc,
# all of them must be zero.
  .option norvc
  .globl _start

  .macro SIGX reg
  sd \reg, 0(s0)
  addi s0, s0, 8
  .endm
  .macro SIGV vreg
  vs1r.v \vreg, (s0)
  addi s0, s0, 32
  .endm
  .macro SIGF freg
  fsd \freg, 0(s0)
  addi s0, s0, 8
  csrr t6, fflags
  sd t6, 0(s0)
  addi s0, s0, 8
  csrw fflags, zero
  .endm
  # fill v0..v7 and v8..v15 with distinct patterns, whole registers
  .macro VINIT
  li t0, -1
  vsetvli t1, t0, e64, m8, tu, mu
  li t0, 0x8123456789abcdef
  vmv.v.x v8, t0
  vid.v v16
  vadd.vv v8, v8, v16
  li t0, 0xfedcba9876543210
  vmv.v.x v0, t0
  vid.v v16
  vxor.vv v0, v0, v16
  .endm

_start:
  lla t0, trap
  csrw mtvec, t0
  li t0, 0x2200
  csrs mstatus, t0
  csrw fflags, zero
  csrwi vxrm, 0
  li s1, 4
  li s0, 0x80800000
  # The loop starts on a fresh page, so that the JIT finds its blocks (the interpreter refetches through the TLB there)
  j pass_loop
  .align 12
pass_loop:

  # ---- strict fsqrt, odd and even exponents ----
  lla t0, fpdata
  fld f1, 0(t0)
  fsqrt.d f2, f1
  SIGF f2
  fld f1, 8(t0)
  fsqrt.d f2, f1
  SIGF f2
  fld f1, 16(t0)
  fsqrt.d f2, f1
  SIGF f2
  fld f1, 24(t0)
  fsqrt.d f2, f1
  SIGF f2
  fld f1, 32(t0)
  fsqrt.d f2, f1
  SIGF f2
  fld f1, 40(t0)
  fsqrt.d f2, f1
  SIGF f2
  flw f1, 48(t0)
  fsqrt.s f2, f1
  SIGF f2
  flw f1, 52(t0)
  fsqrt.s f2, f1
  SIGF f2
  flw f1, 56(t0)
  fsqrt.s f2, f1
  SIGF f2
  flh f1, 60(t0)
  fsqrt.h f2, f1
  SIGF f2
  flh f1, 62(t0)
  fsqrt.h f2, f1
  SIGF f2

  # ---- vsetvli with rd == rs1 (see also vsetvli_alias.S) ----
  li a0, 5
  vsetvli a0, a0, e32, m1, tu, mu
  SIGX a0
  csrr t0, vl
  SIGX t0
  li a1, 100
  vsetvli a1, a1, e8, m1, tu, mu
  SIGX a1
  csrr t0, vl
  SIGX t0
  li a2, 3
  vsetvli a2, a2, e64, m2, tu, mu
  SIGX a2
  csrr t0, vl
  SIGX t0

  # ---- shift immediates >= 16 with SEW=64 ----
  VINIT
  li t0, 4
  vsetvli zero, t0, e64, m1, tu, mu
  vsll.vi v4, v8, 20
  SIGV v4
  vsrl.vi v5, v8, 17
  SIGV v5
  vsra.vi v6, v8, 31
  SIGV v6
  vssrl.vi v7, v8, 30
  SIGV v7
  vssra.vi v3, v8, 19
  SIGV v3
  # narrowing from 64 to 32 bits, shift amount 20..31
  VINIT
  li t0, 8
  vsetvli zero, t0, e32, m1, tu, mu
  vnsrl.wi v4, v8, 20
  SIGV v4
  vnsra.wi v5, v8, 27
  SIGV v5
  vnclipu.wi v6, v8, 24
  SIGV v6
  vnclip.wi v7, v8, 31
  SIGV v7
  # widening shift 32 -> 64 by 20
  VINIT
  li t0, 4
  vsetvli zero, t0, e32, m1, tu, mu
  vwsll.vi v4, v8, 20
  SIGV v4
  SIGV v5

  # ---- vwmaccsu.vv / .vx (signed vs1/rs1, unsigned vs2) ----
  VINIT
  li t0, 8
  vsetvli zero, t0, e16, m1, tu, mu
  vwmaccsu.vv v4, v8, v0
  SIGV v4
  SIGV v5
  VINIT
  li t0, 8
  vsetvli zero, t0, e16, m1, tu, mu
  li t1, -3
  vwmaccsu.vx v4, t1, v0
  SIGV v4
  SIGV v5
  VINIT
  li t0, 8
  vsetvli zero, t0, e16, m1, tu, mu
  li t1, -3
  vwmaccus.vx v4, t1, v0
  SIGV v4
  SIGV v5

  # ---- vmacc.vx, vnmsac.vx, vmadd.vx, vnmsub.vx ----
  VINIT
  li t0, 8
  vsetvli zero, t0, e32, m1, tu, mu
  li t1, 0x12345677
  vmv.v.v v4, v0
  vmacc.vx v4, t1, v8
  SIGV v4
  vmv.v.v v5, v0
  vnmsac.vx v5, t1, v8
  SIGV v5
  vmv.v.v v6, v0
  vmadd.vx v6, t1, v8
  SIGV v6
  vmv.v.v v7, v0
  vnmsub.vx v7, t1, v8
  SIGV v7

  # ---- narrowing with vd == vs2 ----
  VINIT
  li t0, 8
  vsetvli zero, t0, e32, m1, tu, mu
  vnsrl.wi v8, v8, 3
  SIGV v8
  VINIT
  li t0, 16
  vsetvli zero, t0, e32, m2, tu, mu
  vnsra.wi v8, v8, 5
  SIGV v8
  SIGV v9

  # ---- c.add x0, rs2 HINTs must not trap ----
  .option push
  .option rvc
  c.ntl.p1
  c.ntl.all
  .option pop

  addi s1, s1, -1
  beqz s1, finish
  j pass_loop

finish:
  # append the trap log
  lla t0, traplog
  ld t1, 0(t0)
  SIGX t1
  ld t1, 8(t0)
  SIGX t1
  ld t1, 16(t0)
  SIGX t1
  li t0, 0x80800000
  sub t1, s0, t0
  srli t1, t1, 3
  li t0, 0x807ffff8
  sd t1, 0(t0)
  li t0, 0x11100000
  li t1, 0x5555
  sw t1, 0(t0)
1: j 1b

  # count the trap, remember cause and pc, skip the trapping instruction (2 or 4 bytes)
  .align 2
trap:
  csrr t5, mcause
  lla t6, traplog
  sd t5, 8(t6)
  ld t5, 0(t6)
  addi t5, t5, 1
  sd t5, 0(t6)
  csrr t5, mepc
  lla t6, traplog
  sd t5, 16(t6)
  lhu t6, 0(t5)
  andi t6, t6, 3
  addi t6, t6, -3
  addi t5, t5, 2
  bnez t6, 2f
  addi t5, t5, 2
2:
  csrw mepc, t5
  mret

  .align 3
fpdata:
  .double 2.0
  .double 3.0
  .double 0.5
  .double 8.0
  .double 3.141592653589793
  .double 1.0e-310
  .float 2.0
  .float 3.0
  .float 7.0
  .half 0x4000
  .half 0x4200
  .align 3
traplog:
  .dword 0
  .dword 0
  .dword 0
