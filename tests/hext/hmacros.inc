# G-stage Sv39x4 root table at 0x80100000 (16 KiB aligned), hgatp pointing to it, and GPA
# 0x80000000 (1 GiB) mapped 1:1 with V R W X U A D
.macro GSTAGE_IDENTITY
  li t0, 0x80100000
  li t1, 0x200000df
  sd t1, 16(t0)
  li t1, 0x8000000000080100
  csrw hgatp, t1
  hfence.gvma zero, zero
.endm
# GPA 0xC0000000 (1 GiB) as an alias of host 0x80000000 with the given PTE flags
.macro GSTAGE_ALIAS perm
  li t0, 0x80100000
  li t1, 0x20000000 | \perm
  sd t1, 24(t0)
  hfence.gvma zero, zero
.endm
# mret into VS-mode (MPP=S, MPV=1) or HS-mode (MPP=S, MPV=0) at the label
.macro ENTER_VS label
  li t0, 0x1800
  csrc mstatus, t0
  li t0, 0x0800
  csrs mstatus, t0
  li t0, 1
  slli t0, t0, 39
  csrs mstatus, t0
  lla t0, \label
  csrw mepc, t0
  mret
.endm
.macro ENTER_HS label
  li t0, 0x1800
  csrc mstatus, t0
  li t0, 0x0800
  csrs mstatus, t0
  li t0, 1
  slli t0, t0, 39
  csrc mstatus, t0
  lla t0, \label
  csrw mepc, t0
  mret
.endm
