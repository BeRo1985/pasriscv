# A faulting cbo.zero in translated code has to trap precisely: mepc on the cbo.zero, and the
# rest of the block must not run. The loop runs 20 times, the last round zeroes an unmapped
# address (store/AMO access fault, 7).
# expect: a0=0000000000000013 a1=0000000000000007 a2=0000000007000000 a3=0000000000000000
#include "head.inc"
  lla a4, cbobuf
  li a0, 0
  lla s8, after
  jal t2, cboloop
  li s8, 0
after:
  mv a1, s4
  mv a2, s2
  csrr a3, mepc
  lla t0, cboinsn
  sub a3, a3, t0
  j done

  .balign 4096
cboloop:
  li s9, 20
1:
  li t0, 1
  bne s9, t0, 2f
  li a4, 0x7000000
2:
cboinsn:
  cbo.zero (a4)
  addi a0, a0, 1
  addi s9, s9, -1
  bnez s9, 1b
  jr t2

  .balign 64
cbobuf:
  .fill 64, 1, 0xff
#include "tail.inc"
