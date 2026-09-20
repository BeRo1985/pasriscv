# FS=Off makes every FP instruction an illegal instruction (2), also in code that the JIT
# translated while FS was on. Each loop runs 20 times, so the JIT translates it: first with FS
# on, then the same loop with FS=Off (set by M-mode through mstatus, by S-mode through sstatus,
# and for VS-mode through vsstatus by HS-mode), where every fadd.d has to trap.
# expect: a0=0000000000000000 a1=0000000000000014 a2=0000000000000000 a3=0000000000000014 a4=0000000000000000 a5=0000000000000014 a6=0000000000000014
#include "head.inc"
  GSTAGE_IDENTITY
  li t0, 0x2000
  csrs mstatus, t0
  fmv.d.x ft0, zero
  jal t0, fploop
  mv a0, s10
  li t0, 0x6000
  csrc mstatus, t0
  jal t0, fploop
  mv a1, s10
  # S-mode
  li t0, 0x2000
  csrs mstatus, t0
  ENTER_HS s1
s1:
  jal t0, fploop
  mv a2, s10
  li t1, 0x6000
  csrc sstatus, t1
  jal t0, fploop
  mv a3, s10
  TO_M m1
m1:
  # VS-mode: FS on in mstatus and vsstatus, then the guest FS off
  li t0, 0x2000
  csrs mstatus, t0
  csrs vsstatus, t0
  ENTER_VS vs1
vs1:
  jal t0, fploop
  mv a4, s10
  TO_M m2
m2:
  ENTER_HS hs2
hs2:
  li t1, 0x6000
  csrc vsstatus, t1
  li t1, 0x80
  csrs hstatus, t1
  li t1, 0x100
  csrs sstatus, t1
  lla t1, vs2
  csrw sepc, t1
  sret
vs2:
  jal t0, fploop
  mv a5, s10
  TO_M m3
m3:
  # VS-mode with the HS-level FS off (mstatus while V=0) and vsstatus.FS on
  li t0, 0x6000
  csrs vsstatus, t0
  csrc mstatus, t0
  ENTER_VS vs3
vs3:
  jal t0, fploop
  mv a6, s10
  TO_M m4
m4:
  j done

  .balign 4096
# 20 times fadd.d, s10 counts the traps
fploop:
  li s10, 0
  li s9, 20
1:
  fadd.d ft1, ft0, ft0
  addi s9, s9, -1
  bnez s9, 1b
  jr t0
#include "tail.inc"
