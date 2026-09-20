# The same physical code page runs in M-mode and in S-mode, so the JIT holds blocks for both.
# A write to the page sets one dirty bit, and the first lookup after it (here M-mode) consumed that
# bit and only dropped the blocks of its own mode; S-mode kept running the old code. a1 and a2 are
# the result before the patch (1 in both modes), a3 and a4 the one after it (2 in both modes, S was
# 1 before). Every loop runs 20 times so that the JIT translates the routine in both modes.
# expect: a1=0000000000000001 a2=0000000000000001 a3=0000000000000002 a4=0000000000000002
#include "head.inc"
  li s9, 20
1:
  jal ra, sub
  addi s9, s9, -1
  bnez s9, 1b
  mv a1, a0

  ENTER_HS s1
s1:
  li s9, 20
2:
  jal ra, sub
  addi s9, s9, -1
  bnez s9, 2b
  mv a2, a0
  TO_M m1
m1:
  # li a0, 2 (addi a0, x0, 2)
  lla t0, sub
  li t1, 0x00200513
  sw t1, 0(t0)
  fence.i
  li s9, 20
3:
  jal ra, sub
  addi s9, s9, -1
  bnez s9, 3b
  mv a3, a0

  ENTER_HS s2
s2:
  fence.i
  li s9, 20
4:
  jal ra, sub
  addi s9, s9, -1
  bnez s9, 4b
  mv a4, a0
  TO_M m2
m2:
  j done

  .balign 4096
sub:
  li a0, 1
  ret
subpad:
  .word 0
  .balign 4096
#include "tail.inc"
