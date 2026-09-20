# vsetvli_alias.S: JIT check for vsetvli with rd == rs1 and
# slli.uw with rd == rs1. The loop keeps vtype stable, so that the JIT block is really
# executed from the second iteration on. Expected: every a0 is 5, every a3 is 0x10eca8642.
  .option norvc
  .globl _start
_start:
  li t0, 0x2200
  csrs mstatus, t0
  li s1, 50
  li s0, 0x80800000
  li t0, 7
  vsetvli zero, t0, e32, m1, tu, mu
  # the loop starts on a fresh page, so that the JIT finds its blocks (the interpreter refetches through the TLB there)
  j loop
  .align 12
loop:
  li a3, 0xfedcba9887654321
  slli.uw a3, a3, 1
  sd a3, 0(s0)
  li a0, 5
  vsetvli a0, a0, e32, m1, tu, mu
  sd a0, 8(s0)
  addi s0, s0, 16
  addi s1, s1, -1
  bnez s1, loop
  csrr t0, vl
  sd t0, 0(s0)
  addi s0, s0, 8
  li t0, 0x80800000
  sub t1, s0, t0
  srli t1, t1, 3
  li t0, 0x807ffff8
  sd t1, 0(t0)
  li t0, 0x11100000
  li t1, 0x5555
  sw t1, 0(t0)
1: j 1b
