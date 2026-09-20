# HINVAL.VVMA and HINVAL.GVMA (Svinval) have funct7 0010011 and 0110011; they were decoded at
# the wrong values, so a real HINVAL.GVMA ran as ecall/ebreak/xRET by its rs2 field (the Linux
# KVM host crashed in kvm_riscv_hfence_process). In HS-mode they are fences, in VS-mode virtual
# instructions.
# expect: a0=0000000000000000 a1=0000000000000000 a2=0000000000000000 a3=0000000000000016 a4=0000000000000016
#include "head.inc"
  GSTAGE_IDENTITY
  ENTER_HS hs
hs:
  li s4, 0
  hinval.gvma zero, zero
  mv a0, s4
  li s4, 0
  li t1, 0x20002000
  li t2, 1
  hinval.gvma t1, t2
  mv a1, s4
  li s4, 0
  hinval.vvma zero, zero
  mv a2, s4
  li t0, 0x80
  csrs hstatus, t0              # SPV=1
  li t0, 0x100
  csrs sstatus, t0              # SPP=S
  lla t0, vs
  csrw sepc, t0
  sret
vs:
  li s4, 0
  hinval.gvma zero, zero
  mv a3, s4
  li s4, 0
  hinval.vvma zero, zero
  mv a4, s4
  j done
#include "tail.inc"
