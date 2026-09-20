# Decoding and trap details: xtval of ecall (0) and of ebreak (the address of the
# instruction, not its bits), reserved code points that have to trap (c.jr with rs1=x0, jalr with
# funct3<>0, aes64im with bit 25 set, wrs.nto with a field that is not zero, cbo.zero with the
# fifth rd bit set, an encoding in the Zimop space that is neither mop.r.n nor mop.rr.n), the
# misaligned lr.w as a load exception, and mop.rr.7 with rd<>x0 writing zero instead of acting as
# an sspush. Everything runs twice, once in a loop of 20 rounds so that the JIT sees it too.
# expect: a0=0000000000000000 a1=0000000000000001 a2=0000000000000002 a3=0000000000000002 a4=0000000000000002 a5=0000000000000002 a6=0000000000000002 a7=0000000000000004 s0=0000000000000000 s1=0000000000000002
#include "head.inc"
  li s9, 20
1:
  # ecall: xtval stays 0
  li s2, -1
  ecall
  mv a0, s2

  # ebreak: xtval is the address of the breakpoint instruction
  li s2, 0
ebrk:
  ebreak
  lla t0, ebrk
  sub t0, s2, t0
  seqz a1, t0

  # c.jr with rs1=x0 is reserved
  PROBE a2, .insn 2, 0x8002

  # jalr with funct3=1
  PROBE a3, .insn r 0x67, 1, 0, x0, ra, x0

  # aes64im (funct7 0011000) with bit 25 set, so funct7 0011001
  PROBE a4, .insn i 0x13, 1, t0, t1, 0x320

  # wrs.nto with rs1<>0
  PROBE a5, .insn i 0x73, 0, x0, ra, 0x00d

  # cbo.zero with rd = 16 (only four of the five rd bits were checked)
  PROBE a6, .insn i 0x0f, 2, x16, t0, 4

  # misaligned lr.w is a load exception, not a store one
  lla t0, buf
  addi t0, t0, 1
  PROBE a7, lr.w t1, (t0)

  # mop.rr.7 with rs1=x0 and rd<>x0 writes 0
  li s0, -1
  .insn r 0x73, 4, 0x67, s0, x0, ra
  # a Zimop code point with bit 25 = 0 and bits 25:22 <> 0111 is reserved
  PROBE s1, .insn r 0x73, 4, 0x60, x0, x0, x0

  addi s9, s9, -1
  bnez s9, 1b
  j done

  .balign 16
buf:
  .dword 0, 0
#include "tail.inc"
