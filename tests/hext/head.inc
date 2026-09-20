#include "hmacros.inc"
  .option norvc
  .globl _start
_start:
  lla t0, mtrap
  csrw mtvec, t0
  li s0, 0
  li s1, 0
  li s2, 0
  li s3, 0
  li s4, 0
  li s5, 0
  li s6, 0
  li s7, 0
  li s8, 0
  li s9, 0
  li s10, 0
  # PMP: all memory accessible for S- and U-mode
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f
  csrw pmpcfg0, t0
  j test
  .align 8
mtrap:
  # Every trap into M-mode: s4 = mcause, s2 = mtval, s3 = mtval2, s5 = mtinst, s6 = mstatus
  # (GVA is bit 38, MPV bit 39), s10 counts the traps. With s8 set, the test continues there in
  # M-mode, otherwise it resumes after the trapping instruction (at it for an interrupt).
  csrr s4, mcause
  csrr s2, mtval
  csrr s3, mtval2
  csrr s5, mtinst
  csrr s6, mstatus
  addi s10, s10, 1
  beqz s8, 1f
  mv t6, s8
  li s8, 0
  jr t6
1:
  bltz s4, 2f
  csrr t6, mepc
  addi t6, t6, 4
  csrw mepc, t6
2:
  mret
test:
