# mret into U-mode (MPP=U, MPV=0) or VU-mode (MPP=U, MPV=1) at the label
.macro ENTER_U label
  li t0, 0x1800
  csrc mstatus, t0
  li t0, 1
  slli t0, t0, 39
  csrc mstatus, t0
  lla t0, \label
  csrw mepc, t0
  mret
.endm
.macro ENTER_VU label
  li t0, 0x1800
  csrc mstatus, t0
  li t0, 1
  slli t0, t0, 39
  csrs mstatus, t0
  lla t0, \label
  csrw mepc, t0
  mret
.endm
# Back to M-mode at the label (ecall with s8 set, which counts as a trap in s10 and sets s4)
.macro TO_M label
  lla s8, \label
  ecall
.endm
# PROBE reg, insn...: runs the instruction and puts the mcause of its trap (0 without) into reg
.macro PROBE reg, insn:vararg
  li s4, 0
  \insn
  mv \reg, s4
.endm
# PROBE8 reg, insn...: like PROBE, but shifts reg left by 8 and puts the mcause into the low byte,
# so one register collects several results (the first one ends up in the highest byte)
.macro PROBE8 reg, insn:vararg
  li s4, 0
  \insn
  slli \reg, \reg, 8
  or \reg, \reg, s4
.endm
# sret into U-mode (from HS-mode with hstatus.SPV=0) or VU-mode (from VS-mode) at the label
.macro SRET_U label
  li t0, 0x100
  csrc sstatus, t0
  lla t0, \label
  csrw sepc, t0
  sret
.endm
