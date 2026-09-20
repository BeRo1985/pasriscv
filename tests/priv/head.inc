#include "hmacros.inc"
#include "pmacros.inc"
  .option norvc
  .option norelax
  .globl _start
_start:
  lla t0, mtrap
  csrw mtvec, t0
  li s0, 0
  li a0, 0
  li a1, 0
  li a2, 0
  li a3, 0
  li a4, 0
  li a5, 0
  li a6, 0
  li a7, 0
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
  # With s11 set the test is done: power off (only reached in "jit" mode, see tail.inc).
  # Every other trap into M-mode: s4 = mcause, s2 = mtval, s3 = mtval2, s5 = mtinst,
  # s6 = mstatus, s10 counts the traps. With s8 set, the test continues there in M-mode (and s8
  # is cleared), otherwise it resumes after the trapping instruction (2 or 4 bytes, read from
  # mepc, so the code has to be identity mapped, and a fetch fault needs s8) or at it for an
  # interrupt. The handler only changes t6 (and mscratch).
  li t6, 0x1234
  beq s11, t6, poweroff
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
  bltz s4, 3f
  csrw mscratch, t5
  csrr t6, mepc
  lhu t5, 0(t6)
  andi t5, t5, 3
  addi t6, t6, 2
  addi t5, t5, -3
  bnez t5, 2f
  addi t6, t6, 2
2:
  csrw mepc, t6
  csrr t5, mscratch
3:
  mret
poweroff:
  li t0, 0x11100000
  li t1, 0x5555
  sw t1, 0(t0)
4: j 4b
test:
