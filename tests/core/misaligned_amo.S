# Misaligned AMOs raise a store/AMO address misaligned exception (cause 6), inside a naturally
# aligned 16-byte granule as well. zama16b only fixes the atomicity granule of misaligned loads and
# stores, the A extension does not ask for misaligned AMOs (QEMU traps them too). The loop runs 20
# times so that the JIT translates the trapping instruction, run.sh runs the test in both modes, so
# it also checks that interpreter and JIT agree. a0 = the aligned AMO of the same loop still counts
# to 20, a1 = the cause of the last misaligned AMO, a2 = how many of the 20 trapped, a3 = the rest
# of the buffer stays untouched, s7 = the causes of a misaligned word AMO inside the granule and of
# a misaligned doubleword AMO across it.
# expect: a0=0000000000000014 a1=0000000000000006 a2=0000000000000014 a3=0000000000000000 s7=0000000000000606
#include "head.inc"
  lla a4, amobuf
  addi a6, a4, 1
  li a5, 1
  li a0, 0
  li a2, 0
  jal t2, amoloop
  lw a0, 0(a4)
  ld a3, 8(a4)
  ld t0, 0(a4)
  srli t0, t0, 32
  or a3, a3, t0
  PROBE8 s7, amoadd.w t0, a5, (a6)
  addi a7, a4, 9
  PROBE8 s7, amoadd.d t0, a5, (a7)
  j done

  .balign 4096
amoloop:
  li s9, 20
1:
  amoadd.w t0, a5, (a4)
  PROBE a1, amoadd.w t0, a5, (a6)
  li t1, 6
  bne a1, t1, 2f
  addi a2, a2, 1
2:
  addi s9, s9, -1
  bnez s9, 1b
  jr t2

  .balign 16
amobuf:
  .dword 0, 0
#include "tail.inc"
