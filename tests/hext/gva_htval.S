# htval/hstatus.GVA are written when a trap goes to HS-mode, not when it goes to M-mode;
# GVA=1 for a guest-page fault, GVA=0 (and htval=0) for a virtual-instruction exception
# expect: a0=0000000000001234 a1=0000000030000000 a2=0000000000000015 a3=00000000C0000008 a4=0000000030000002 a5=0000000000000001 a6=0000000000000016 a7=0000000000000000 s0=0000000000000000 s1=0000000000000001
#include "head.inc"
  GSTAGE_IDENTITY
  GSTAGE_ALIAS 0xcf             # U=0: guest-page faults
  li t0, 0x1234
  csrw htval, t0
  lla s8, back1
  ENTER_VS guest1
guest1:
  li t0, 0xC0000000
  lw t1, 0(t0)                  # guest-page fault into M-mode
back1:
  csrr a0, htval                # untouched
  mv a1, s3                     # mtval2
  li t0, (1 << 21) | (1 << 22)
  csrs medeleg, t0              # load guest-page faults and virtual-instruction exceptions to HS
  lla t0, hs_trap1
  csrw stvec, t0
  ENTER_VS guest2
guest2:
  li t0, 0xC0000008
  lw t1, 0(t0)
  j done
hs_trap1:
  csrr a2, scause
  csrr a3, stval
  csrr a4, htval
  csrr t0, hstatus
  srli a5, t0, 6                # GVA
  andi a5, a5, 1
  srli s1, t0, 7                # SPV
  andi s1, s1, 1
  lla t0, hs_trap2
  csrw stvec, t0
  lla t0, guest3
  csrw sepc, t0
  sret
guest3:
  csrr t0, hstatus              # virtual-instruction exception
  j done
hs_trap2:
  csrr a6, scause
  csrr t0, hstatus
  srli a7, t0, 6
  andi a7, a7, 1
  csrr s0, htval
  j done
#include "tail.inc"
