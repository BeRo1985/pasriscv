# With V=1 an FP instruction needs the HS-level FS on as well (else illegal instruction), and
# a change of the FP state in the guest makes the HS-level FS Dirty (KVM saves the guest FP
# registers only then)
# expect: a0=0000000000000003 a1=0000000000000003 a2=000000000000000A a3=0000000000000002
#include "head.inc"
  li t0, 0x6000
  csrc mstatus, t0
  li t0, 0x2000
  csrs mstatus, t0              # HS FS=Initial
  csrw vsstatus, t0             # VS FS=Initial
  GSTAGE_IDENTITY
  lla s8, back1
  ENTER_VS guest1
guest1:
  fmv.d.x f0, zero
  ecall
back1:
  csrr t0, mstatus
  srli a0, t0, 13
  andi a0, a0, 3
  csrr t0, vsstatus
  srli a1, t0, 13
  andi a1, a1, 3
  mv a2, s4
  li t0, 0x6000
  csrc mstatus, t0              # HS FS=Off
  li t0, 0x2000
  csrw vsstatus, t0             # VS FS=Initial
  li s4, 0
  lla s8, back2
  ENTER_VS guest2
guest2:
  fmv.d.x f0, zero              # illegal instruction
  nop
back2:
  mv a3, s4
  j done
#include "tail.inc"
