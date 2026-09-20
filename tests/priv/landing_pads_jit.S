# With Zicfilp enabled (here mseccfg.MLPE for M-mode) an indirect jump through a register
# other than ra, t0 and t2 (jalr, c.jalr, c.jr) expects a landing pad at its target, else a
# software-check exception (18, tval 2). Every caller loop runs 20 times, so the JIT translates
# it: the old JIT never set ELP in translated code. The first loop runs with MLPE=0 and the
# second loop is the same code with MLPE=1, which must not reuse the translation of the first.
# The trap handler continues at s8 with "jr t6", so the resume points are landing pads, too.
# expect: a0=0000000000000014 a1=0000000000000000 a2=0000000000000000 a3=0000000000000014 s0=0000000000001400 s1=0000000000001400 a7=0000000000001414 s4=0000000000000012 s2=0000000000000002
#include "head.inc"
  jal t0, caller_jalr
  mv a0, a4
  mv a1, s10
  # mseccfg.MLPE
  li t1, 1 << 10
  csrs 0x747, t1
  jal t0, caller_jalr
  mv a2, a4
  mv a3, s10
  jal t0, caller_lpad
  slli s0, a4, 8
  or s0, s0, s10
  jal t0, caller_t2
  slli s1, a4, 8
  or s1, s1, s10
  jal t0, caller_cjalr
  slli a7, s10, 8
  jal t0, caller_cjr
  or a7, a7, s10
  j done

# CALLER name, kind: 20 indirect calls, a4 counts the returns and s10 the traps
.macro CALLER name, kind
  .balign 4096
\name:
  li a4, 0
  li s10, 0
  li s9, 20
1:
  lla s8, 3f
  .ifc \kind,jalr
  lla a5, target_plain
  jalr ra, 0(a5)
  .endif
  .ifc \kind,lpad
  lla a5, target_lpad
  jalr ra, 0(a5)
  .endif
  .ifc \kind,t2
  lla t2, target_plain
  jalr ra, 0(t2)
  .endif
  .ifc \kind,cjalr
  lla a5, target_plain
  .option push
  .option rvc
  c.jalr a5
  c.nop
  .option pop
  .endif
  .ifc \kind,cjr
  lla a5, target_plain
  lla ra, 2f
  .option push
  .option rvc
  c.jr a5
  c.nop
  .option pop
  .endif
2:
  li s8, 0
  addi a4, a4, 1
3:
  lpad 0
  addi s9, s9, -1
  bnez s9, 1b
  jr t0
.endm

  CALLER caller_jalr, jalr
  CALLER caller_lpad, lpad
  CALLER caller_t2, t2
  CALLER caller_cjalr, cjalr
  CALLER caller_cjr, cjr

  .balign 4096
target_plain:
  addi a6, a6, 1
  ret
target_lpad:
  lpad 0
  addi a6, a6, 1
  ret
#include "tail.inc"
