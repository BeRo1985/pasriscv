# The JIT reads some CSRs inline. A read that the privilege level or the counter enables do
# not allow has to trap (2) every time, also after the JIT translated the loop, and a change of
# mcounteren has to drop an inline counter read that was allowed before. Each loop runs 20 times.
# expect: a0=0000000000000014 a1=0000000000000014 a2=0000000000000000 a3=0000000000000014 a4=0000000000000000 a5=0000000000000014
#include "head.inc"
  # S-mode reads mcycle and mhartid (M-level CSRs)
  ENTER_HS s1
s1:
  jal t0, loop_mcycle
  mv a0, s10
  jal t0, loop_mhartid
  mv a1, s10
  TO_M m1
m1:
  # cycle from S-mode with mcounteren.CY=1, then with mcounteren.CY=0 (same code)
  li t1, 1
  csrw mcounteren, t1
  ENTER_HS s2
s2:
  jal t0, loop_cycle
  mv a2, s10
  TO_M m2
m2:
  csrw mcounteren, zero
  ENTER_HS s3
s3:
  jal t0, loop_cycle
  mv a3, s10
  TO_M m3
m3:
  # U-mode: cycle with scounteren.CY=1, then scounteren.CY=0 written by S-mode
  li t1, 1
  csrw mcounteren, t1
  csrw scounteren, t1
  ENTER_U u1
u1:
  jal t0, loop_cycle
  mv a4, s10
  TO_M m4
m4:
  ENTER_HS s4
s4:
  csrw scounteren, zero
  SRET_U u2
u2:
  jal t0, loop_cycle
  mv a5, s10
  TO_M m5
m5:
  j done

# LOOP name, csr: 20 reads of the CSR, s10 counts the traps
.macro LOOP name, csr
  .balign 4096
\name:
  li s10, 0
  li s9, 20
1:
  csrr a6, \csr
  addi s9, s9, -1
  bnez s9, 1b
  jr t0
.endm

  LOOP loop_mcycle, mcycle
  LOOP loop_mhartid, mhartid
  LOOP loop_cycle, cycle
#include "tail.inc"
