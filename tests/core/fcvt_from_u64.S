# fcvt.s.lu/fcvt.d.lu from 2^63 on rounded twice in the fast interpreter (the compiler
# converts the signed value and adds 2^64). Values just above a tie show it. 7 checks per round,
# 20 rounds for the JIT (which halves with a sticky bit and was right already).
# expect: a0=000000000000008C a1=0000000000000000
#include "head.inc"
#include "fpmacros.inc"
  li t0, 0x2000
  csrs mstatus, t0
  li s9, 20
  jal t2, u64loop
  j done

  .balign 4096
u64loop:
1:
  fsrmi 0
  li t0, 0x8000008000000001                 # 2^63+2^39+1, just above the single tie
  fcvt.s.lu ft0, t0
  CHKS ft0, 0x5f000001, 0
  li t0, 0x8000000000000401                 # 2^63+2^10+1, just above the double tie
  fcvt.d.lu fa0, t0
  CHKD fa0, 0x43e0000000000001, 1
  li t0, 0xffffffffffffffff
  fcvt.s.lu ft0, t0, rtz
  CHKS ft0, 0x5f7fffff, 2
  fcvt.s.lu ft0, t0, rne
  CHKS ft0, 0x5f800000, 3
  fcvt.d.lu fa0, t0, rtz
  CHKD fa0, 0x43efffffffffffff, 4
  fcvt.d.lu fa0, t0, rne
  CHKD fa0, 0x43f0000000000000, 5
  li t0, 0x8000000000000000
  fcvt.s.lu ft0, t0
  CHKS ft0, 0x5f000000, 6
  addi s9, s9, -1
  bnez s9, 1b
  jr t2
#include "tail.inc"
