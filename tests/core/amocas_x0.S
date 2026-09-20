# amocas.w/.d with rd=x0 compare against zero (the JIT used an uninitialized host register),
# and amocas.q takes x0 as a register pair that reads zero in both halves and is not written (not
# x0 and x1); odd rd or rs2 of amocas.q are reserved (illegal instruction, 2). The loops run 20
# times so that the JIT translates them.
# expect: a0=0000000000000014 a3=0000000000000014 s0=0000000000000014 a6=0000000000000077 a7=0000000000000000 s1=0000000000000014 s7=0000000000000202
#include "head.inc"
  lla a2, casbuf
  li a1, 0x5555
  li ra, 0x77
  li a0, 0
  li a3, 0
  li s0, 0
  li s1, 0
  jal t2, casloop
  mv a6, ra
  PROBE8 s7, .insn r 0x2f, 4, 0x14, a1, a2, a4
  PROBE8 s7, .insn r 0x2f, 4, 0x14, a4, a2, a3
  j done

  .balign 4096
casloop:
  li s9, 20
1:
  # amocas.d x0: expected 0
  sd zero, 0(a2)
  amocas.d x0, a1, (a2)
  ld t0, 0(a2)
  bne t0, a1, 2f
  addi a0, a0, 1
2:
  # amocas.w x0: expected 0
  sw zero, 0(a2)
  amocas.w x0, a1, (a2)
  lw t0, 0(a2)
  bne t0, a1, 3f
  addi a3, a3, 1
3:
  # amocas.q x0 (expected 0:0) with the new pair a4:a5
  li a4, 0x1111
  li a5, 0x2222
  sd zero, 0(a2)
  sd zero, 8(a2)
  amocas.q x0, a4, (a2)
  ld t0, 0(a2)
  ld t1, 8(a2)
  xor t0, t0, a4
  xor t1, t1, a5
  or t0, t0, t1
  bnez t0, 4f
  addi s0, s0, 1
4:
  # amocas.q with rs2=x0: stores 0:0, the old value goes to a4:a5
  amocas.q a4, x0, (a2)
  ld t0, 0(a2)
  ld t1, 8(a2)
  or t0, t0, t1
  or a7, a7, t0
  li t0, 0x1111
  bne a4, t0, 5f
  li t0, 0x2222
  bne a5, t0, 5f
  addi s1, s1, 1
5:
  addi s9, s9, -1
  bnez s9, 1b
  jr t2

  .balign 16
casbuf:
  .dword 0, 0
#include "tail.inc"
