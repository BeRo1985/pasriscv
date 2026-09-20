# S-mode (satp Bare) writes a page, M-mode then runs code from that page (the JIT translates
# it), and S-mode patches the code through its older write TLB entry (another privilege mode, so
# another TLB). After fence.i M-mode has to run the new code; the store did not mark the page
# dirty, so the JIT kept the old translation.
# expect: a1=0000000000000001 a2=0000000000000002
#include "head.inc"
  ENTER_HS s1
s1:
  lla t0, subpad
  sw zero, 0(t0)
  TO_M m1
m1:
  li s9, 20
1:
  jal ra, sub
  addi s9, s9, -1
  bnez s9, 1b
  mv a1, a0
  ENTER_HS s2
s2:
  # li a0, 2 (addi a0, x0, 2)
  lla t0, sub
  li t1, 0x00200513
  sw t1, 0(t0)
  TO_M m2
m2:
  fence.i
  li s9, 20
2:
  jal ra, sub
  addi s9, s9, -1
  bnez s9, 2b
  mv a2, a0
  j done

  .balign 4096
sub:
  li a0, 1
  ret
subpad:
  .word 0
  .balign 4096
#include "tail.inc"
